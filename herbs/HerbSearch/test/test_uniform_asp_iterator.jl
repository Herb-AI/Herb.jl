@testset verbose = true "UniformASPIterator" begin
    using Clingo_jll

    @testset "ASP_solution_conversion" begin
        g = @csgrammar begin
            S = 1 | x
            S = S + S
            S = S * S
        end
        addconstraint!(g, Unique(1))

        tree = UniformHole(BitVector((0, 0, 1, 1)), [
            UniformHole(BitVector((1, 1, 0, 0)), []),
            UniformHole(BitVector((1, 1, 0, 0)), [])
        ])

        asp_solver = @test_nowarn ASPSolver(g, tree)
        asp_iterator = UniformASPIterator(asp_solver, nothing)
        @test length(asp_solver.solutions) == 6
        sol = next_solution!(asp_iterator)
        while !isnothing(sol)
            @test sol isa RuleNode
            @test get_children(sol)[1] isa RuleNode
            @test get_children(sol)[2] isa RuleNode
            sol = next_solution!(asp_iterator)
        end
    end

    @testset "ASP_solution_conversion_nonuniform" begin
        g = @csgrammar begin
            S = 1 | x
            S = S + S
            S = S * S
        end
        addconstraint!(g, Unique(1))

        tree = UniformHole(BitVector([0, 0, 1, 1]), [
            UniformHole(BitVector([1, 1, 1, 1]), []),
            UniformHole(BitVector((1, 1, 0, 0)), [])
        ])

        asp_solver = @test_nowarn ASPSolver(g, tree)
        asp_iterator = UniformASPIterator(asp_solver, nothing)
        @test length(asp_solver.solutions) == 14

        sol = next_solution!(asp_iterator)
        while !isnothing(sol)
            @test sol isa RuleNode
            @test get_children(sol)[1] isa RuleNode
            @test get_children(sol)[2] isa RuleNode
            sol = next_solution!(asp_iterator)
        end
    end

    function create_dummy_grammar_and_tree_128programs()
        grammar = @csgrammar begin
            Number = Number + Number
            Number = Number - Number
            Number = Number * Number
            Number = Number / Number
            Number = x | 1 | 2 | 3
        end

        uniform_tree = RuleNode(1, [
            UniformHole(
                BitVector((1, 1, 1, 1, 0, 0, 0, 0)),
                [
                    UniformHole(BitVector((0, 0, 0, 0, 1, 1, 1, 1)), [])
                    UniformHole(BitVector((0, 0, 0, 0, 1, 0, 0, 1)), [])
                ]
            ),
            UniformHole(BitVector((0, 0, 0, 0, 1, 1, 1, 1)), [])
        ])
        # 4 * 4 * 2 * 4 = 128 programs without constraints

        return grammar, uniform_tree
    end

    @testset "Without constraints" begin
        grammar, uniform_tree = create_dummy_grammar_and_tree_128programs()
        asp_solver = @test_nowarn ASPSolver(grammar, uniform_tree)
        asp_iterator = UniformASPIterator(asp_solver, nothing)
        @test length(asp_iterator) == 128
    end

    @testset "Forbidden constraint" begin
        #forbid "a - a"
        grammar, uniform_tree = create_dummy_grammar_and_tree_128programs()
        addconstraint!(grammar, Forbidden(RuleNode(2, [VarNode(:a), VarNode(:a)])))
        asp_solver = @test_nowarn ASPSolver(grammar, uniform_tree)
        asp_iterator = UniformASPIterator(asp_solver, nothing)
        @test length(asp_iterator) == 120

        #forbid all rulenodes
        grammar, uniform_tree = create_dummy_grammar_and_tree_128programs()
        addconstraint!(grammar, Forbidden(VarNode(:a)))
        asp_solver = @test_nowarn ASPSolver(grammar, uniform_tree)
        asp_iterator = UniformASPIterator(asp_solver, nothing)
        @test length(asp_iterator) == 0
    end

    @testset "The root is the only solution" begin
        grammar = @csgrammar begin
            S = 1
        end

        asp_solver = @test_nowarn ASPSolver(grammar, RuleNode(1))
        asp_iterator = UniformASPIterator(asp_solver, nothing)

        @test next_solution!(asp_iterator) == RuleNode(1)
        @test isnothing(next_solution!(asp_iterator))
    end

    @testset "No solutions (ordered constraint)" begin
        grammar = @csgrammar begin
            Number = 1
            Number = x
            Number = Number + Number
            Number = Number - Number
        end
        constraint1 = Ordered(RuleNode(3, [
                VarNode(:a),
                VarNode(:b)
            ]), [:a, :b])
        constraint2 = Ordered(RuleNode(4, [
                VarNode(:a),
                VarNode(:b)
            ]), [:a, :b])
        addconstraint!(grammar, constraint1)
        addconstraint!(grammar, constraint2)

        tree = UniformHole(BitVector((0, 0, 1, 1)), [
            UniformHole(BitVector((0, 0, 1, 1)), [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 0, 0)), [])
            ]),
            UniformHole(BitVector((1, 1, 0, 0)), [])
        ])
        asp_solver = @test_nowarn ASPSolver(grammar, tree)
        asp_iterator = UniformASPIterator(asp_solver, nothing)
        @test isnothing(next_solution!(asp_iterator))
    end

    @testset "No solutions (forbidden constraint)" begin
        grammar = @csgrammar begin
            Number = 1
            Number = x
            Number = Number + Number
            Number = Number - Number
        end
        constraint1 = Forbidden(RuleNode(3, [
            VarNode(:a),
            VarNode(:b)
        ]))
        constraint2 = Forbidden(RuleNode(4, [
            VarNode(:a),
            VarNode(:b)
        ]))
        addconstraint!(grammar, constraint1)
        addconstraint!(grammar, constraint2)

        tree = UniformHole(BitVector((0, 0, 1, 1)), [
            UniformHole(BitVector((0, 0, 1, 1)), [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 0, 0)), [])
            ]),
            UniformHole(BitVector((1, 1, 0, 0)), [])
        ])
        asp_solver = @test_nowarn ASPSolver(grammar, tree)
        asp_iterator = UniformASPIterator(asp_solver, nothing)
        @test isnothing(next_solution!(asp_iterator))
    end
end
