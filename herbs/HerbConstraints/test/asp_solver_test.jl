@testitem "ASPSolver" begin
    using HerbCore, HerbGrammar
    using Clingo_jll

    using HerbConstraints: grammar_to_ASP, constraint_to_ASP, rulenode_to_ASP,
        constraint_rulenode_to_ASP, ASPSolver, isfeasible, get_grammar
    using HerbConstraints
    using TestSetExtensions: ExtendedTestSet

    @testset "rulenode_transformations" begin
        @testset ExtendedTestSet "single rule no children" begin
            g = @csgrammar begin
                S = 1
            end

            tree = RuleNode(1)

            asp, _ = rulenode_to_ASP(tree, g, 1)

            expected_asp = """
            node(1,1).
            """

            @test asp == expected_asp
        end
        @testset "rulenode_to_ASP" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end

            tree = RuleNode(3, [
                RuleNode(1),
                RuleNode(4, [
                    RuleNode(1),
                    RuleNode(2)
                ])
            ])

            asp, next_index = rulenode_to_ASP(tree, g, 1)
            expected_asp = """
            node(1,3).
            child(1,1,2).
            node(2,1).
            child(1,2,3).
            node(3,4).
            child(3,1,4).
            node(4,1).
            child(3,2,5).
            node(5,2).
            """
            @test asp == expected_asp
        end

        @testset "uniformhole_to_ASP" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end

            tree = UniformHole(BitVector((0, 0, 1, 1)), [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 0, 0)), [])
            ])

            asp, next_index = rulenode_to_ASP(tree, g, 1)
            expected_asp = """
            1 { node(1,3);node(1,4) } 1.
            child(1,1,2).
            1 { node(2,1);node(2,2) } 1.
            child(1,2,3).
            1 { node(3,1);node(3,2) } 1.
            """
            @test asp == expected_asp
        end

        @testset "statehole_to_ASP" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end

            tree = UniformHole(BitVector((0, 0, 1, 1)), [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 1, 1)), [])
            ])
            sm = HerbConstraints.StateManager()
            statehole = HerbConstraints.StateHole(sm, tree)

            asp, next_index = rulenode_to_ASP(statehole, g, 1)
            expected_asp = """
            1 { node(1,4);node(1,3) } 1.
            child(1,1,2).
            1 { node(2,1);node(2,2) } 1.
            child(1,2,3).
            1 { node(3,1);node(3,2);node(3,3);node(3,4) } 1.
            """
            @test asp == expected_asp
        end
    end


    @testset "constraint_transformations" begin
        @testset ExtendedTestSet "constraint_rulenode_to_ASP" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end

            tree = UniformHole(BitVector((0, 0, 1, 1)), [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 0, 0)), [])
            ])

            c = Unique(4)
            addconstraint!(g, c)

            asp, next_index, _ = constraint_rulenode_to_ASP(g, tree, 1, 1)
            expected_asp = "node(X1,D1),allowed(c1x1,D1),child(X1,1,X2),node(X2,D2),allowed(c1x2,D2),child(X1,2,X3),node(X3,D3),allowed(c1x3,D3)"
            @test asp == expected_asp
        end

        @testset "constraint_uniformhole_to_ASP" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end

            tree = UniformHole(BitVector((0, 0, 1, 1)), [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 0, 0)), [])
            ])

            c = ContainsSubtree(UniformHole(BitVector((0, 0, 1, 1)), [
                RuleNode(1),
                RuleNode(2)
            ]))
            addconstraint!(g, c; allow_empty_children=true)
            asp_tree, additional, _ = constraint_rulenode_to_ASP(g, tree, 1, 1)
            expected_asp = "node(X1,D1),allowed(c1x1,D1),child(X1,1,X2),node(X2,D2),allowed(c1x2,D2),child(X1,2,X3),node(X3,D3),allowed(c1x3,D3)"
            @test asp_tree == expected_asp

            expected_domains = """
            allowed(c1x1,3).
            allowed(c1x1,4).
            allowed(c1x2,1).
            allowed(c1x2,2).
            allowed(c1x3,1).
            allowed(c1x3,2).
            """
            @test additional == expected_domains
        end

        @testset "constraint_statehole_to_ASP" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end

            tree = UniformHole(BitVector((0, 0, 1, 1)), [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 1, 1)), [])
            ])
            sm = HerbConstraints.StateManager()
            statehole = HerbConstraints.StateHole(sm, tree)

            c = ContainsSubtree(RuleNode(4, [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 1, 1)), [])
            ])) # children are not included
            addconstraint!(g, c; allow_empty_children=true) 

            asp_tree, additional, _ = constraint_rulenode_to_ASP(g, statehole, 1, 1)
            expected_asp = "node(X1,D1),allowed(c1x1,D1),child(X1,1,X2),node(X2,D2),allowed(c1x2,D2),child(X1,2,X3),node(X3,D3),allowed(c1x3,D3)"
            @test asp_tree == expected_asp

            expected_domains = """
            allowed(c1x1,4).
            allowed(c1x1,3).
            allowed(c1x2,1).
            allowed(c1x2,2).
            allowed(c1x3,1).
            allowed(c1x3,2).
            allowed(c1x3,3).
            allowed(c1x3,4).
            """
            @test additional == expected_domains
        end

        @testset "constraint_varnode_to_ASP" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end

            tree = UniformHole(BitVector((0, 0, 1, 1)), [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 1, 1)), [])
            ])

            c = Forbidden(UniformHole(BitVector((0, 0, 1, 1)), [
                VarNode(:a),
                VarNode(:b)
            ]))
            addconstraint!(g, c; allow_empty_children=true)
            asp_tree, additional, _ = constraint_rulenode_to_ASP(g, tree, 1, 1)
            expected_asp = "node(X1,D1),allowed(c1x1,D1),child(X1,1,X2),node(X2,D2),allowed(c1x2,D2),child(X1,2,X3),node(X3,D3),allowed(c1x3,D3)"
            @test asp_tree == expected_asp

            expected_domains = """
            allowed(c1x1,3).
            allowed(c1x1,4).
            allowed(c1x2,1).
            allowed(c1x2,2).
            allowed(c1x3,1).
            allowed(c1x3,2).
            allowed(c1x3,3).
            allowed(c1x3,4).
            """
            @test additional == expected_domains
        end

        @testset "constraint_single_varnode_to_ASP" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end
            tree = UniformHole(BitVector((0, 0, 1, 1)), [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 1, 1)), [])
            ])
            c = Forbidden(VarNode(:a))
            addconstraint!(g, c; allow_empty_children=true)

            asp_tree, additional, _ = constraint_rulenode_to_ASP(g, tree, 1, 1)
            expected_asp = "node(X1,D1),allowed(c1x1,D1),child(X1,1,X2),node(X2,D2),allowed(c1x2,D2),child(X1,2,X3),node(X3,D3),allowed(c1x3,D3)"
            @test asp_tree == expected_asp

            expected_domains = """
            allowed(c1x1,3).
            allowed(c1x1,4).
            allowed(c1x2,1).
            allowed(c1x2,2).
            allowed(c1x3,1).
            allowed(c1x3,2).
            allowed(c1x3,3).
            allowed(c1x3,4).
            """
            @test additional == expected_domains
        end
    end

    @testset "constraint_to_ASP" begin
        @testset "forbidden_constraint_to_ASP" begin
            g = @csgrammar begin
                Number = |(1:2)
                Number = x
                Number = Number + Number
                Number = Number * Number
            end

            constraint = Forbidden(RuleNode(5, [RuleNode(3), RuleNode(3)]))

            asp = constraint_to_ASP(g, constraint, 1)
            expected_asp = "subtree(c1) :- node(X1,5),child(X1,1,X2),node(X2,3),child(X1,2,X3),node(X3,3).\n:- subtree(c1).\n"
            @test asp == expected_asp
        end

        @testset "contains_rulenode_constraint_to_ASP" begin
            g = @csgrammar begin
                Number = |(1:2)
                Number = x
                Number = Number + Number
                Number = Number * Number
            end
            constraint = Contains(4)
            asp = constraint_to_ASP(g, constraint, 1)
            expected_asp = ":- not node(_,4).\n"

            @test asp == expected_asp
        end

        @testset "unique_constraint_to_ASP" begin
            g = @csgrammar begin
                Number = |(1:2)
                Number = x
                Number = Number + Number
                Number = Number * Number
            end
            constraint = Unique(5)
            asp = constraint_to_ASP(g, constraint, 1)
            expected_asp = "{ node(X,5) : node(X,5) } 1.\n"

            @test asp == expected_asp
        end

        @testset ExtendedTestSet "ordered_constraint_to_ASP" begin
            g = @csgrammar begin
                Number = |(1:2)
                Number = x
                Number = Number + Number
                Number = Number * Number
            end
            constraint = Ordered(RuleNode(5, [VarNode(:X), VarNode(:Y)]), [:X, :Y])
            asp = constraint_to_ASP(g, constraint, 1)
            expected_asp = """
            :- node(X1,5),child(X1,1,X2),child(X1,2,X3),not is_smaller(X2,X3).
            """
            @test asp == expected_asp
        end

        @testset "contains_subtree_constraint_to_ASP" begin
            g = @csgrammar begin
                Number = |(1:2)
                Number = x
                Number = Number + Number
                Number = Number * Number
            end
            constraint = ContainsSubtree(RuleNode(4, [UniformHole(BitVector((1, 1, 0, 0, 0)), []), RuleNode(3)]))
            asp = constraint_to_ASP(g, constraint, 1)
            expected_asp = """
            allowed(c1x2,1).
            allowed(c1x2,2).
            subtree(c1) :- node(X1,4),child(X1,1,X2),node(X2,D2),allowed(c1x2,D2),child(X1,2,X3),node(X3,3).
            :- not subtree(c1).
            """
            @test asp == expected_asp
        end
    end

    @testset "Solver struct" begin
        @testset "asp_solver_uniform_holes" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end
            addconstraint!(g, Unique(1); allow_empty_children=true)
            addconstraint!(g, Unique(2); allow_empty_children=true)

            tree = UniformHole(BitVector((0, 0, 1, 1)), [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 0, 0)), [])
            ])

            solver = ASPSolver(g, tree)
            @test length(solver.solutions) == 4

            @test Dict{Int64,Int64}(1 => 3, 2 => 1, 3 => 2) in solver.solutions
            @test Dict{Int64,Int64}(1 => 3, 2 => 2, 3 => 1) in solver.solutions
            @test Dict{Int64,Int64}(1 => 4, 2 => 1, 3 => 2) in solver.solutions
            @test Dict{Int64,Int64}(1 => 4, 2 => 2, 3 => 1) in solver.solutions
        end

        @testset "asp_solver_filled_rulenode" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end

            tree = RuleNode(3, [
                RuleNode(4, [
                    RuleNode(1),
                    RuleNode(2)
                ]),
                RuleNode(3, [
                    RuleNode(1),
                    RuleNode(2)
                ]),
            ])

            solver = ASPSolver(g, tree)
            @test length(solver.solutions) == 1
        end

        @testset "asp_solver_filled_rulenode_constraints" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end
            addconstraint!(g, Unique(1); allow_empty_children=true)
            addconstraint!(g, Unique(2); allow_empty_children=true)

            tree = RuleNode(3, [
                RuleNode(4, [
                    RuleNode(1),
                    RuleNode(2)
                ]),
                RuleNode(3, [
                    RuleNode(1),
                    RuleNode(2)
                ]),
            ])

            solver = ASPSolver(g, tree)
            @test length(solver.solutions) == 0
            @test isfeasible(solver) == false
        end

        @testset "asp_solver_non_uniform" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end

            tree = Hole(BitVector([1, 1, 1, 1]))

            try
                solver = ASPSolver(g, tree)
            catch AssertionError
                @test true
            end
        end

        @testset "asp_solver_properties" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end

            tree = UniformHole(BitVector((0, 0, 1, 1)), [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 0, 0)), [])
            ])

            solver = ASPSolver(g, tree)
            @test get_grammar(solver) === g
            @test get_tree(solver) === tree
            @test HerbConstraints.get_name(solver) == "ASPSolver"
            @test isfeasible(solver) === true
        end
    end
    @testset "Full pipeline" begin
        @testset ExtendedTestSet "Single solution, single derivation rule" begin
            g = @csgrammar begin
                S = 1
            end

            tree = UniformHole(BitVector((1,)))

            asp_solver = @test_nowarn ASPSolver(g, tree)
            @test isfeasible(asp_solver)
            @test length(asp_solver.solutions) == 1
            @test asp_solver.solutions[1] == Dict(1 => 1)
        end

        @testset ExtendedTestSet "No solutions (ordered constraint)" begin
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
            @test !isfeasible(asp_solver)
            @test length(asp_solver.solutions) == 0
        end

        @testset ExtendedTestSet "No solutions (forbidden constraint)" begin
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

            constraint_tree_asp = grammar_to_ASP(grammar)
            expected_asp_constraints = """
            % Forbidden(3{a,b})
            subtree(c1) :- node(X1,3),child(X1,1,X2),child(X1,2,X3).
            :- subtree(c1).

            % Forbidden(4{a,b})
            subtree(c2) :- node(X1,4),child(X1,1,X2),child(X1,2,X3).
            :- subtree(c2).

            """
            @test constraint_tree_asp == expected_asp_constraints

            tree = UniformHole(BitVector((0, 0, 1, 1)), [
                UniformHole(BitVector((0, 0, 1, 1)), [
                    UniformHole(BitVector((1, 1, 0, 0)), []),
                    UniformHole(BitVector((1, 1, 0, 0)), [])
                ]),
                UniformHole(BitVector((1, 1, 0, 0)), [])
            ])

            asp_tree, _ = rulenode_to_ASP(tree, grammar, 1)
            expected_asp_tree = """
            1 { node(1,3);node(1,4) } 1.
            child(1,1,2).
            1 { node(2,3);node(2,4) } 1.
            child(2,1,3).
            1 { node(3,1);node(3,2) } 1.
            child(2,2,4).
            1 { node(4,1);node(4,2) } 1.
            child(1,2,5).
            1 { node(5,1);node(5,2) } 1.
            """
            @test asp_tree == expected_asp_tree

            asp_solver = @test_nowarn ASPSolver(grammar, tree)
            @test !isfeasible(asp_solver)
            @test length(asp_solver.solutions) == 0
        end

        @testset "varnode_same_symbol" begin
            g = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end
            tree = RuleNode(3, [
                VarNode(:a),
                VarNode(:a)
            ])
            asp_tree, additional, _ = constraint_rulenode_to_ASP(g, tree, 1, 1)
            expected_asp = "node(X1,3),child(X1,1,X2),child(X1,2,X3),is_same(X2,X3)"
            @test asp_tree == expected_asp
        end

        @testset ExtendedTestSet "ordered_constraint_three_children_order" begin
            g = @csgrammar begin
                S = 1 | 2 | 3
                S = S + S + S
            end
            tree = RuleNode(4, [
                UniformHole(BitVector((1, 1, 1, 0)), []),
                UniformHole(BitVector((1, 1, 1, 0)), []),
                UniformHole(BitVector((1, 1, 1, 0)), [])
            ])
            c1 = Ordered(RuleNode(4, [
                    VarNode(:a),
                    VarNode(:b),
                    VarNode(:c)
                ]), [:b, :c, :a])

            addconstraint!(g, c1)

            asp_tree = grammar_to_ASP(g)
            expected_asp = """
            % Ordered(4{a,b,c}, [:b, :c, :a])
            :- node(X1,4),child(X1,1,X2),child(X1,2,X3),child(X1,3,X4),not is_smaller(X3,X4).
            :- node(X1,4),child(X1,1,X2),child(X1,2,X3),child(X1,3,X4),not is_smaller(X4,X2).

            """
            @test asp_tree == expected_asp

            solver = @test_nowarn ASPSolver(g, tree)
            @test 10 == length(solver.solutions)
            @testset "Check order" for sol in solver.solutions
                @test sol[1] == 4
                @test sol[3] <= sol[4] <= sol[2]
            end
        end

        @testset "constraints_with_varnode" begin
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
            constraint2 = Forbidden(RuleNode(3, [
                VarNode(:a),
                VarNode(:a)
            ]))
            addconstraint!(grammar, constraint1)
            addconstraint!(grammar, constraint2)

            tree = RuleNode(3, [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 0, 0)), [])
            ])

            asp_tree = grammar_to_ASP(grammar)
            expected_asp = """
            % Ordered(3{a,b}, [:a, :b])
            :- node(X1,3),child(X1,1,X2),child(X1,2,X3),not is_smaller(X2,X3).

            % Forbidden(3{a,a})
            subtree(c2) :- node(X1,3),child(X1,1,X2),child(X1,2,X3),is_same(X2,X3).
            :- subtree(c2).

            """
            @test asp_tree == expected_asp

            solver = @test_nowarn ASPSolver(grammar, tree)
            @test length(solver.solutions) == 1
            @test solver.solutions[1] == Dict(1 => 3, 2 => 1, 3 => 2)
        end
        @testset "Forbidden with {a,a} pattern" begin
            grammar = @csgrammar begin
                Number = 1
                Number = x
                Number = Number + Number
            end
            constraint = Forbidden(RuleNode(3, [
                VarNode(:a),
                VarNode(:a)
            ]))
            addconstraint!(grammar, constraint)

            tree = RuleNode(3, [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 0, 0)), [])
            ])

            asp_tree = grammar_to_ASP(grammar)
            expected_asp = """
            % Forbidden(3{a,a})
            subtree(c1) :- node(X1,3),child(X1,1,X2),child(X1,2,X3),is_same(X2,X3).
            :- subtree(c1).

            """
            @test asp_tree == expected_asp

            solver = @test_nowarn ASPSolver(grammar, tree)
            @test length(solver.solutions) == 2
            @test Dict(1 => 3, 2 => 1, 3 => 2) ∈ solver.solutions
            @test Dict(1 => 3, 2 => 2, 3 => 1) ∈ solver.solutions
        end
    end
end

