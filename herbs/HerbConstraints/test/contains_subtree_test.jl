@testitem "ContainsSubtree" begin
    using HerbCore, HerbGrammar

    function has_active_constraints(solver::UniformSolver)::Bool
        for c ∈ keys(solver.isactive)
            if get_value(solver.isactive[c]) == 1
                return true
            end
        end
        return false
    end

    @testset "check_tree$with_varnode" for with_varnode ∈ ["", " (with VarNode)"]
        contains_subtree = ContainsSubtree(
            RuleNode(3, [
                RuleNode(1),
                isempty(with_varnode) ? RuleNode(2) : VarNode(:a)
            ])
        )

        tree_true = RuleNode(3, [
            RuleNode(3, [
                RuleNode(1),
                RuleNode(2)
            ]),
            RuleNode(2)
        ])

        tree_false = RuleNode(3, [
            RuleNode(3, [
                RuleNode(2),
                RuleNode(2)
            ]),
            RuleNode(2)
        ])

        @test check_tree(contains_subtree, tree_true) == true
        @test check_tree(contains_subtree, tree_false) == false
    end

    @testset "check_tree, 2 VarNodes" begin
        contains_subtree = ContainsSubtree(
            RuleNode(3, [
                VarNode(:a),
                VarNode(:a)
            ])
        )

        tree_true = RuleNode(3, [
            RuleNode(3, [
                RuleNode(1),
                RuleNode(2)
            ]),
            RuleNode(3, [
                RuleNode(1),
                RuleNode(2)
            ]),
        ])

        tree_false = RuleNode(3, [
            RuleNode(3, [
                RuleNode(1),
                RuleNode(2)
            ]),
            RuleNode(4, [
                RuleNode(1),
                RuleNode(2)
            ]),
        ])

        @test check_tree(contains_subtree, tree_true) == true
        @test check_tree(contains_subtree, tree_false) == false
    end

    @testset "propagate (UniformSolver)" begin
        @testset "1 VarNode" begin
            subtree = RuleNode(3, [
                RuleNode(1),
                VarNode(:a)
            ])
            grammar = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end
            addconstraint!(grammar, ContainsSubtree(subtree))

            @testset "0 candidates" begin
                # 3{1, :a} is never contained in the tree

                tree = UniformHole(BitVector((0, 0, 1, 1)), [
                    RuleNode(2),
                    RuleNode(4, [
                        UniformHole(BitVector((1, 1, 0, 0)), []),
                        UniformHole(BitVector((1, 1, 0, 0)), [])
                    ])
                ])

                solver = UniformSolver(grammar, tree)
                @test !isfeasible(solver)
            end

            @testset "1 candidate" begin
                # 3{1, :a} can only appear at the root

                tree = UniformHole(BitVector((0, 0, 1, 1)), [
                    RuleNode(1),
                    RuleNode(4, [
                        UniformHole(BitVector((1, 1, 0, 0)), []),
                        UniformHole(BitVector((1, 1, 0, 0)), [])
                    ])
                ])

                solver = UniformSolver(grammar, tree)
                tree = get_tree(solver)
                @test isfeasible(solver)
                @test isfilled(tree) && (get_rule(tree) == 3) # the root is filled with a 3
                @test !isfilled(tree.children[2].children[1]) # the other two holes remain unfilled.
                @test !isfilled(tree.children[2].children[2]) # the other two holes remain unfilled.
                @test !has_active_constraints(solver) # constraint is satisfied and deleted
            end

            @testset "2 candidates" begin
                # 3{1, :a} can appear at path=[] and path=[2].

                tree = UniformHole(BitVector((0, 0, 1, 1)), [
                    RuleNode(1),
                    RuleNode(3, [
                        UniformHole(BitVector((1, 1, 0, 0)), []),
                        UniformHole(BitVector((1, 1, 0, 0)), [])
                    ])
                ])

                #initial propagation: softfail, all holes remain unfilled
                solver = UniformSolver(grammar, tree)
                tree = get_tree(solver)
                @test isfeasible(solver)
                @test !isfilled(tree)
                @test !isfilled(tree.children[2].children[1])
                @test !isfilled(tree.children[2].children[2])
                @test has_active_constraints(solver) # softfail: constraint remains active

                #remove rule 3 from the root, now 3{1, :a} can only appear at path=[2]
                remove!(solver, Vector{Int}(), 3)
                hole = tree.children[2].children[1]
                @test isfeasible(solver)
                @test isfilled(hole) && (get_rule(hole) == 1) #the hole is filled with rule 1
                @test !has_active_constraints(solver) # constraint is satisfied and deleted
            end
        end

        @testset "2 VarNodes, softfails" begin
            subtree = RuleNode(3, [
                VarNode(:a),
                VarNode(:a)
            ])
            grammar = @csgrammar begin
                S = 1 | x
                S = S + S
                S = S * S
            end
            addconstraint!(grammar, ContainsSubtree(subtree))

            @testset "1 candidate, partial softfail" begin
                # 3{:a, :a} can only appear at the root
                # the first hole can be filled with a 3
                # filling the other two holes is ambiguous

                tree = UniformHole(BitVector((0, 0, 1, 1)), [
                    UniformHole(BitVector((1, 1, 0, 0)), []),
                    UniformHole(BitVector((1, 1, 0, 0)), [])
                ])

                solver = UniformSolver(grammar, tree)
                tree = get_tree(solver)
                @test isfeasible(solver)
                @test isfilled(tree) && (get_rule(tree) == 3) # the root is filled with a 3
                @test !isfilled(tree.children[1]) # the other two holes remain unfilled.
                @test !isfilled(tree.children[2]) # the other two holes remain unfilled.
                @test has_active_constraints(solver) # the constraint remains active
            end

            @testset "2 candidates, softfail" begin
                # 3{:a, :a} can appear at the root, or at child 1
                # Three out of the four possible trees are valid:
                # - 3{3{1, 1}, 4{1, 1}} VALID (contains the subtree at child 1)
                # - 3{4{1, 1}, 4{1, 1}} VALID (contains the subtree at root)
                # - 4{3{1, 1}, 4{1, 1}} VALID (contains the subtree at child 1)
                # - 4{4{1, 1}, 4{1, 1}} INVALID
                # no deductions can be made at this point.

                tree = UniformHole(
                    BitVector((0, 0, 1, 1)),
                    [
                        UniformHole(BitVector((0, 0, 1, 1)), [
                            RuleNode(1),
                            RuleNode(1)
                        ])
                        RuleNode(4, [
                            RuleNode(1),
                            RuleNode(1)
                        ])
                    ]
                )

                solver = UniformSolver(grammar, tree)
                tree = get_tree(solver)
                @test isfeasible(solver)
                @test !isfilled(tree)
                @test !isfilled(tree.children[1])
                @test has_active_constraints(solver)
            end
        end
    end

    @testset "DomainRuleNode" begin
        tests = [
            (
                "SoftFail large domain",
                BitVector((0, 0, 0, 1, 1, 1)), # domain_root
                BitVector((0, 0, 0, 1, 1, 1)), # domain_root_target
                BitVector((1, 1, 1, 0, 0, 0)), # domain_leaf
                BitVector((1, 1, 1, 0, 0, 0)), # domain_leaf_target
            ),
            (
                "SoftFail small domain",
                BitVector((0, 0, 0, 1, 1, 0)), # domain_root
                BitVector((0, 0, 0, 1, 1, 0)), # domain_root_target
                BitVector((1, 1, 0, 0, 0, 0)), # domain_leaf
                BitVector((1, 1, 0, 0, 0, 0)), # domain_leaf_target
            ),
            (
                "Deduction in Root",
                BitVector((0, 0, 0, 1, 0, 1)), # domain_root
                BitVector((0, 0, 0, 1, 0, 0)), # domain_root_target
                BitVector((1, 1, 0, 0, 0, 0)), # domain_leaf
                BitVector((1, 1, 0, 0, 0, 0)), # domain_leaf_target
            ),
            (
                "Deduction in Leaf",
                BitVector((0, 0, 0, 1, 1, 0)), # domain_root
                BitVector((0, 0, 0, 1, 1, 0)), # domain_root_target
                BitVector((0, 1, 1, 0, 0, 0)), # domain_leaf
                BitVector((0, 1, 0, 0, 0, 0)), # domain_leaf_target
            ),
            (
                "Deduction in Root and Leaf",
                BitVector((0, 0, 0, 1, 0, 1)), # domain_root
                BitVector((0, 0, 0, 1, 0, 0)), # domain_root_target
                BitVector((0, 1, 1, 0, 0, 0)), # domain_leaf
                BitVector((0, 1, 0, 0, 0, 0)), # domain_leaf_target
            )
        ]

        @testset "$name" for (name, domain_root, domain_root_target, domain_leaf, domain_leaf_target) ∈ tests
            grammar = @csgrammar begin
                S = 1
                S = 2
                S = 3
                S = 4, S
                S = 5, S
                S = 6, S
            end

            # must contain at least rule 4 or 5 in the root.
            # must contain at least rule 1 or 2 in the leaf. 
            addconstraint!(grammar, ContainsSubtree(DomainRuleNode(grammar, [4, 5], [
                DomainRuleNode(grammar, [1, 2])
            ])))

            tree = UniformHole(domain_root, [
                UniformHole(domain_leaf, [])
            ])
            solver = UniformSolver(grammar, tree)
            tree = get_tree(solver)

            for rule ∈ 1:6
                @test domain_root_target[rule] == tree.domain[rule]
                @test domain_leaf_target[rule] == tree.children[1].domain[rule]
            end
        end

        @testset "HardFail" begin
            grammar = @csgrammar begin
                S = 1
                S = 2
                S = 3
                S = 4
            end
            addconstraint!(grammar, ContainsSubtree(DomainRuleNode(grammar, [1, 2])))

            @test !isfeasible(UniformSolver(grammar, RuleNode(3)))
            @test !isfeasible(UniformSolver(grammar, UniformHole(BitVector((0, 0, 1, 1)), [])))
        end
    end
    @testset verbose = true "Update rule indices" begin
        @testset "Update rule index only." begin
            expected_contains_subtree = ContainsSubtree(
                RuleNode(3, [
                    VarNode(:a),
                    VarNode(:a),
                ]),
            )
            tree = @rulenode 3{3{1,1},2}
            mapping = Dict(1 => 7, 5 => 3)
            @testset "interface without grammar" begin
                n_rules = 5
                contains_subtree = ContainsSubtree(
                    RuleNode(5, [
                        VarNode(:a),
                        VarNode(:a),
                    ]),
                )
                HerbCore.update_rule_indices!(contains_subtree, n_rules) # no change to RuleNode and VarNode
                @test check_tree(contains_subtree, tree) == false
                # with mapping
                constraints = [contains_subtree]
                HerbCore.update_rule_indices!(contains_subtree, n_rules, mapping, constraints)
                @test check_tree(contains_subtree, tree) == true
                @test contains_subtree.tree == expected_contains_subtree.tree
            end
            @testset "interface with grammar" begin
                grammar = @csgrammar begin
                    Int = 1
                    Int = x
                    Int = -Int
                    Int = Int + Int
                    Int = Int * Int
                end
                contains_subtree = ContainsSubtree(
                    RuleNode(5, [
                        VarNode(:a),
                        VarNode(:a),
                    ]),
                )
                HerbCore.update_rule_indices!(contains_subtree, grammar)
                @test check_tree(contains_subtree, tree) == false
                # with mapping
                HerbCore.update_rule_indices!(contains_subtree, grammar, mapping)
                @test check_tree(contains_subtree, tree) == true
                @test contains_subtree.tree == expected_contains_subtree.tree
            end
        end

    end
    @testset verbose = true "is_domain_valid" begin
        grammar = @csgrammar begin
            Int = 1
            Int = x
            Int = -Int
            Int = Int + Int
            Int = Int * Int
        end
        contains_subtree = ContainsSubtree(
            RuleNode(5, [
                VarNode(:a),
                VarNode(:a),
            ]),
        )
        @test HerbCore.is_domain_valid(contains_subtree, grammar) == true
    end
    @testset "isequal" begin
        tree1 = UniformHole(BitVector((0, 0, 1, 1)), [
            RuleNode(1),
            RuleNode(4, [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 0, 0)), [])
            ])
        ])
        tree2 = UniformHole(BitVector((0, 0, 1, 1)), [
            RuleNode(1),
            RuleNode(4, [
                UniformHole(BitVector((1, 1, 0, 0)), []),
                UniformHole(BitVector((1, 1, 1, 0)), [])
            ])
        ])
        @test ContainsSubtree(tree1) == ContainsSubtree(tree1)
        @test ContainsSubtree(tree1) != ContainsSubtree(tree2)
    end
end
