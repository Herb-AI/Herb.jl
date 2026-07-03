@testset verbose=true "UniformIterator" begin

    function create_dummy_grammar_and_tree_128programs()
        grammar = @csgrammar begin
            Number = Number + Number
            Number = Number - Number
            Number = Number * Number
            Number = Number / Number
            Number = x | 1 | 2 | 3
        end

        uniform_tree = RuleNode(1, [
            UniformHole(BitVector((1, 1, 1, 1, 0, 0, 0, 0)), [
                UniformHole(BitVector((0, 0, 0, 0, 1, 1, 1, 1)), [])
                UniformHole(BitVector((0, 0, 0, 0, 1, 0, 0, 1)), [])
            ]),
            UniformHole(BitVector((0, 0, 0, 0, 1, 1, 1, 1)), [])
        ])
         # 4 * 4 * 2 * 4 = 128 programs without constraints

        return grammar, uniform_tree
    end

    @testset "Without constraints" begin
        grammar, uniform_tree = create_dummy_grammar_and_tree_128programs()
        uniform_solver = UniformSolver(grammar, uniform_tree)
        uniform_iterator = UniformIterator(uniform_solver, nothing)
        @test length(uniform_iterator) == 128
    end

    @testset "Forbidden constraint" begin
        #forbid "a - a"
        grammar, uniform_tree = create_dummy_grammar_and_tree_128programs()
        addconstraint!(grammar, Forbidden(RuleNode(2, [VarNode(:a), VarNode(:a)])))
        uniform_solver = UniformSolver(grammar, uniform_tree)
        uniform_iterator = UniformIterator(uniform_solver, nothing)
        @test length(uniform_iterator) == 120

        #forbid all rulenodes
        grammar, uniform_tree = create_dummy_grammar_and_tree_128programs()
        addconstraint!(grammar, Forbidden(VarNode(:a)))
        uniform_solver = UniformSolver(grammar, uniform_tree)
        uniform_iterator = UniformIterator(uniform_solver, nothing)
        @test length(uniform_iterator) == 0
    end

    @testset "The root is the only solution" begin
        grammar = @csgrammar begin
            S = 1
        end
        
        uniform_solver = UniformSolver(grammar, RuleNode(1))
        uniform_iterator = UniformIterator(uniform_solver, nothing)
        
        @test next_solution!(uniform_iterator) == RuleNode(1)
        @test isnothing(next_solution!(uniform_iterator))
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
        uniform_solver = UniformSolver(grammar, tree)
        uniform_iterator = UniformIterator(uniform_solver, nothing)
        @test isnothing(next_solution!(uniform_iterator))
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
        uniform_solver = UniformSolver(grammar, tree)
        uniform_iterator = UniformIterator(uniform_solver, nothing)
        @test isnothing(next_solution!(uniform_iterator))
    end
end
