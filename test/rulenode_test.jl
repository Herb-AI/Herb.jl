@testitem "T <: AbstractRuleNode" begin
    using AbstractTrees: children, nodevalue, treeheight
    @testset "AbstractTrees Interface" begin
        @test nodevalue(RuleNode(1)) == 1
        @test isempty(children(RuleNode(1)))
        @test length(children(RuleNode(1, [RuleNode(2), RuleNode(2)]))) == 2
        @test treeheight(RuleNode(1)) == 0
        @test treeheight(RuleNode(1, [RuleNode(2), RuleNode(2)])) == 1
    end

    @testset "RuleNode tests" begin
        @testset "Equality tests" begin
            @test RuleNode(1) == RuleNode(1)

            node = RuleNode(1, [RuleNode(2), RuleNode(3)])
            @test node == node
            @test RuleNode(1, [RuleNode(2), RuleNode(3)]) ==
                RuleNode(1, [RuleNode(2), RuleNode(3)])
            @test RuleNode(1, [RuleNode(2), node]) == RuleNode(1, [RuleNode(2), node])

            @test RuleNode(1) !== RuleNode(2)
            @test RuleNode(1, [RuleNode(2), RuleNode(3)]) !==
                RuleNode(2, [RuleNode(2), RuleNode(3)])
        end

        @testset "Hash tests" begin
            node = RuleNode(1, [RuleNode(2), RuleNode(3)])
            @test hash(node) == hash(node)
            @test hash(node) == hash(RuleNode(1, [RuleNode(2), RuleNode(3)]))
            @test hash(RuleNode(1, [RuleNode(2)])) !== hash(RuleNode(1))
        end

        @testset "Depth tests" begin
            @test depth(RuleNode(1)) == 1
            @test depth(RuleNode(1, [RuleNode(2), RuleNode(3)])) == 2
        end

        @testset "Length tests" begin
            @test length(RuleNode(1)) == 1
            @test length(RuleNode(1, [RuleNode(2), RuleNode(3)])) == 3
            @test length(RuleNode(1, [RuleNode(2, [RuleNode(3), RuleNode(4)])])) == 4
        end
        @testset "RuleNode compare" begin
            @test HerbCore._rulenode_compare(RuleNode(1), RuleNode(1)) == 0
            @test RuleNode(1) < RuleNode(2)
            @test RuleNode(2) > RuleNode(1)
            @test RuleNode(1, [RuleNode(2)]) < RuleNode(1, [RuleNode(3)])
            @test RuleNode(1, [RuleNode(2)]) < RuleNode(2, [RuleNode(1)])
            @test_throws ArgumentError RuleNode(1) < Hole(BitVector((1, 1)))
            @test_throws ArgumentError Hole(BitVector((1, 1))) < RuleNode(1)
        end

        @testset "Node depth from a tree" begin
            #=    1      -- depth 1
            			   2  3  4   -- depth 2
            					5  6 -- depth 3

            			=#
            rulenode = @rulenode 1{2, 3, 4{5, 6}}

            @test node_depth(rulenode, rulenode) == 1

            @test node_depth(rulenode, rulenode.children[1]) == 2
            @test node_depth(rulenode, rulenode.children[2]) == 2
            @test node_depth(rulenode, rulenode.children[3]) == 2

            @test node_depth(rulenode, rulenode.children[3].children[1]) == 3
            @test node_depth(rulenode, rulenode.children[3].children[2]) == 3

            # in case a random node appears the node_depth is 0
            @test node_depth(rulenode, RuleNode(100)) == 0
        end

        @testset "rulesoftype" begin
            #=    1
            			   2  3  4
            					5  6
            				   7    9
            						  10
            			=#
            rulenode = @rulenode 1{2, 3, 4{5{7}, 6{9{10}}}}
            ruleset = Set((1, 3, 7, 9, 10, 15, 23))
            expected = Set((1, 3, 7, 9, 10))
            hole = Hole([1, 1, 1, 1, 0]) # hole domain is irrelevant

            @test isempty(rulesoftype(rulenode, Set((11, 12))))
            @test rulesoftype(rulenode, ruleset) == expected
            @test rulesoftype(rulenode, Set(1)) == Set(1)
            @test isempty(rulesoftype(rulenode, Set{Int}()))
            @test rulesoftype(RuleNode(1), Set((1, 2))) == Set(1)

            ignorenode = @rulenode 4{5{7}, 6{9{10}}}

            @test rulesoftype(rulenode, ruleset, hole) == rulesoftype(rulenode, ruleset)
            @test rulesoftype(rulenode, ruleset) == Set{Int}([1, 3, 7, 9, 10])
            @test rulesoftype(rulenode, ruleset, ignorenode) == Set{Int}([1, 3])
            @test rulesoftype(hole, ruleset, rulenode) == Set()
            @test rulesoftype(hole, ruleset, hole) == Set()
            @test rulesoftype(rulenode, 2) == rulesoftype(rulenode, Set{Int}(2))

            @test contains_index(rulenode, 2)
            @test !contains_index(rulenode, 0)
        end

        @testset "rule sequence" begin

            #=    1      
            			   2  3  4   
            					5  6 
            				   7    9
            						  10 
            			=#
            rulenode = @rulenode 1{2, 3, 4{5{7}, 6{9{10}}}}

            @test get_rulesequence(rulenode, [3, 1, 1]) == [1, 4, 5, 7]
            @test get_rulesequence(rulenode, [3, 2, 1]) == [1, 4, 6, 9]
            @test get_rulesequence(rulenode, [3, 2, 1, 1]) == [1, 4, 6, 9, 10]

            # putting out of bounds indices returns the root
            @test get_rulesequence(rulenode, [100, 4, 1000]) == [1]
        end

        @testset "get_node_at_location" begin
            rulenode = UniformHole(BitVector((1, 1, 0, 0)), [RuleNode(3), RuleNode(4)])
            @test get_node_at_location(rulenode, Vector{Int64}()) isa UniformHole
            @test get_node_at_location(rulenode, [1]).ind == 3
            @test get_node_at_location(rulenode, [2]).ind == 4
            @testset "Hole" begin
                hole = Hole(BitVector([1, 1]))
                @test get_node_at_location(hole, Vector{Int}()).domain == hole.domain #because hole != hole
                @test_throws Exception get_node_at_location(hole, [1])
            end
        end

        @testset "get_path" begin
            n1 = RuleNode(1)
            n2 = RuleNode(2)
            n3 = UniformHole(BitVector((1, 1, 1)), [RuleNode(1), n2])
            n4 = RuleNode(1)
            root = RuleNode(
                4, [
                    RuleNode(
                        4, [
                            n1,
                            RuleNode(1),
                        ]
                    ),
                    n3,
                ]
            )
            @test get_path(root, n1) == [1, 1]
            @test get_path(root, n2) == [2, 2]
            @test get_path(root, n3) == [2]
            @test isnothing(get_path(root, n4))
        end

        @testset "Length tests with holes" begin
            domain = BitVector((1, 1))
            @test length(UniformHole(domain, [])) == 1
            @test length(UniformHole(domain, [RuleNode(2)])) == 2
            @test length(RuleNode(1, [RuleNode(2, [Hole(domain), RuleNode(4)])])) == 4
            @test length(UniformHole(domain, [RuleNode(2, [RuleNode(4), RuleNode(4)])])) ==
                4
        end

        @testset "Depth tests with holes" begin
            domain = BitVector((1, 1))
            @test depth(UniformHole(domain, [])) == 1
            @test depth(UniformHole(domain, [RuleNode(2)])) == 2
            @test depth(RuleNode(1, [RuleNode(2, [Hole(domain), RuleNode(4)])])) == 3
            @test depth(UniformHole(domain, [RuleNode(2, [RuleNode(4), RuleNode(4)])])) == 3
        end

        @testset "number_of_holes" begin
            domain = BitVector((1, 1))
            @test number_of_holes(RuleNode(1)) == 0
            @test number_of_holes(Hole(domain)) == 1
            @test number_of_holes(UniformHole(domain, [RuleNode(1), RuleNode(1)])) == 1
            @test number_of_holes(UniformHole(domain, [Hole(domain), RuleNode(1)])) == 2
            @test number_of_holes(RuleNode(2, [Hole(domain), RuleNode(1)])) == 1
            @test number_of_holes(
                UniformHole(
                    domain,
                    [
                        Hole(domain),
                        UniformHole(domain, [Hole(domain), RuleNode(1)]),
                    ]
                ),
            ) == 4
        end

        @testset "isuniform" begin
            domain = BitVector((1, 1))

            @test isuniform(RuleNode(1, [RuleNode(2)])) == true
            @test isuniform(UniformHole(domain, [RuleNode(2)])) == true

            @test isuniform(RuleNode(1)) == true
            @test isuniform(RuleNode(1, [])) == true
            @test isuniform(UniformHole(domain, [])) == true

            @test isuniform(Hole(domain)) == false
        end

        @testset "isfilled" begin
            domain1 = BitVector((0, 1, 0, 0, 0))
            domain2 = BitVector((0, 1, 0, 1, 0))
            @test isfilled(RuleNode(1, [])) == true
            @test isfilled(RuleNode(1, [RuleNode(2)])) == true
            @test isfilled(RuleNode(1, [Hole(domain1)])) == true
            @test isfilled(RuleNode(1, [Hole(domain2)])) == true

            @test isfilled(UniformHole(domain1, [Hole(domain2)])) == true
            @test isfilled(UniformHole(domain2, [Hole(domain2)])) == false

            @test isfilled(Hole(domain1)) == true
            @test isfilled(Hole(domain2)) == false
        end

        @testset "get_rule" begin
            domain_of_size_1 = BitVector((0, 1, 0, 0, 0))
            @test get_rule(RuleNode(99, [RuleNode(3), RuleNode(4)])) == 99
            @test get_rule(RuleNode(2, [RuleNode(3), RuleNode(4)])) == 2
            @test get_rule(UniformHole(domain_of_size_1, [RuleNode(5), RuleNode(6)])) == 2
            @test get_rule(Hole(domain_of_size_1)) == 2
        end

        @testset "have_same_shape" begin
            domain = BitVector((1, 1, 1, 1, 1, 1, 1, 1, 1))
            @test have_same_shape(RuleNode(1), RuleNode(2))
            @test have_same_shape(RuleNode(1), Hole(domain))
            @test have_same_shape(RuleNode(1), RuleNode(4, [RuleNode(1)])) == false
            @test have_same_shape(RuleNode(4, [RuleNode(1)]), RuleNode(1)) == false

            node1 = @rulenode 3{1, 1}
            node2 = RuleNode(
                9, [
                    RuleNode(2),
                    Hole(domain),
                ]
            )
            @test have_same_shape(node1, node2)

            node1 = @rulenode 3{1, 1}
            node2 = @rulenode 9{2, 3{1, 1}}
            @test have_same_shape(node1, node2) == false
        end

        @testset "hasdynamicvalue" begin
            @test hasdynamicvalue(RuleNode(1, "DynamicValue")) == true
            @test hasdynamicvalue(RuleNode(1)) == false
            @test hasdynamicvalue(
                UniformHole(
                    BitVector((1, 0)), [RuleNode(1, "DynamicValue")]
                )
            ) == false
            @test hasdynamicvalue(UniformHole(BitVector((1, 0)), [RuleNode(1)])) == false
            @test hasdynamicvalue(Hole(BitVector((1, 0)))) == false
        end

        @testset "show" begin
            node = RuleNode(1, [RuleNode(1), RuleNode(2), RuleNode(3)])
            io = IOBuffer()
            Base.show(io, node)
            @test String(take!(io)) == "1{1,2,3}"

            # 12{14,2{4{9}},2{4{6}}}
            node = @rulenode 12{14, 2{4{9}}, 2{4{6}}}
            io = IOBuffer()
            Base.show(io, node)
            @test String(take!(io)) == "12{14,2{4{9}},2{4{6}}}"
        end
        @testset "swap_node" begin
            child1 = RuleNode(2, 1, [])
            child2 = RuleNode(3, 2, [])
            root = RuleNode(1, 0, [child1, child2])
            new_node = RuleNode(4, 99, [])

            swap_node(root, new_node, [1])
            @test root.children[1] === new_node
            @test root.children[1].ind == 4
            @test root.children[1]._val == 99

            # Reset tree
            root.children[1] = child1

            swap_node(root, root, 2, new_node)
            @test root.children[2] === new_node
            @test root.children[2].ind == 4
            @test root.children[2]._val == 99
        end
        @testset "rulesonleft" begin
            #=      1
            				/   |   \
            				2    3    4
            					/ \   / \
            					5  6  7  8    
            			=#
            node = @rulenode 1{2, 3{5, 6}, 4{7, 8}}
            @test rulesonleft(node, Vector{Int}()) ==
                Set{Int}([1, 2, 3, 4, 5, 6, 7, 8])
            @test rulesonleft(node, [2, 1]) == Set{Int}([1, 2, 3])
            @test rulesonleft(node, [2, 2]) == Set{Int}([1, 2, 3, 5])
        end
        @testset "contains_hole" begin
            hole = Hole([1, 1])
            node = RuleNode(1, [RuleNode(2), RuleNode(3, [hole])])

            @test contains_hole(node) == true
            @test contains_hole(RuleNode(2)) == false
            @test contains_hole(hole) == true
        end
        @testset "contains_nonuniform_hole" begin
            hole = Hole([1, 1])
            uniform_hole = UniformHole([1, 0], [])
            node = RuleNode(1, [RuleNode(2), RuleNode(3, [hole])])
            node2 = RuleNode(1, [RuleNode(2), RuleNode(3, [uniform_hole])])

            @test contains_nonuniform_hole(node) == true
            @test contains_nonuniform_hole(node2) == false
        end
    end

    @testset "UniformHole" begin
        @testset "show" begin
            # UniformHole[Bool[0, 0, 1]]{14,2{4{9}},2{4{6}}}
            node = UniformHole(
                [0, 0, 1],
                [
                    RuleNode(14),
                    RuleNode(
                        2, [
                            RuleNode(
                                4, [
                                    RuleNode(9),
                                ]
                            ),
                        ]
                    ),
                    RuleNode(
                        2, [
                            RuleNode(
                                4, [
                                    RuleNode(6),
                                ]
                            ),
                        ]
                    ),
                ]
            )
            io = IOBuffer()
            Base.show(io, node)
            @test String(take!(io)) == "UniformHole[Bool[0, 0, 1]]{14,2{4{9}},2{4{6}}}"
        end
    end

    @testset "Hole" begin
        @testset "show" begin
            # 12{14,2{4{Hole[...]}},2{4{6}}}
            node = RuleNode(
                12,
                [
                    RuleNode(14),
                    RuleNode(
                        2, [
                            RuleNode(
                                4, [
                                    Hole(ones(14)),
                                ]
                            ),
                        ]
                    ),
                    RuleNode(
                        2, [
                            RuleNode(
                                4, [
                                    RuleNode(6),
                                ]
                            ),
                        ]
                    ),
                ]
            )
            io = IOBuffer()
            Base.show(io, node)
            @test String(take!(io)) ==
                "12{14,2{4{Hole[Bool[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]}},2{4{6}}}"
        end
        @testset "Hole not Equal Hole" begin
            hole1 = Hole([1, 1, 0, 1])
            hole2 = Hole([1, 1, 0, 1])
            hole3 = hole1
            @test hole1 == hole2
            @test hole3 == hole1
        end
    end

    @testset "@rulenode" begin
        @testset "just RuleNodes" begin
            node = @rulenode 1{2, 3}
            children = get_children(node)
            @test get_rule(node) == 1
            @test get_rule(children[1]) == 2
            @test get_rule(children[2]) == 3

            node = @rulenode 1
            children = get_children(node)
            @test get_rule(node) == 1
            @test isempty(children)

            node = @rulenode 1{4{5, 6}, 1{2, 3}}
            @test get_rule(node) == 1
            @test depth(node) == 3

            node2 = copy(node)
            @test node2 == node
            @test node2.ind == node.ind
            @test node2._val == node._val
            @test node2.children == node.children
        end

        @testset "just Holes" begin
            node = @rulenode Hole[1, 1, 0, 0]

            @test node.domain == BitVector([1, 1, 0, 0])

            node = @rulenode UniformHole[1, 1, 0, 0]

            @test node.domain == BitVector([1, 1, 0, 0])

            node = @rulenode UniformHole[1, 1, 0, 0]{
                UniformHole[0, 0, 1, 1], UniformHole[0, 0, 1, 1],
            }

            @test node.domain == BitVector([1, 1, 0, 0])
            for c in children(node)
                @test c.domain == BitVector([0, 0, 1, 1])
            end

            node2 = copy(node)
            @test node2.domain == node.domain

            @testset "Hole hash test" begin
                node = @rulenode Hole[1, 1, 0, 0]
                @test hash(node) == hash(node.domain)
            end
        end

        @testset "mixture" begin
            node = @rulenode UniformHole[1, 1, 0, 0]{2, 3}
            @test node.domain == BitVector([1, 1, 0, 0])
            for c in children(node)
                @test c isa RuleNode
                @test c.ind in [2, 3]
            end
        end

        @testset "with extra Bool[...] notation from Base.show" begin
            node = @rulenode UniformHole[Bool[1, 1, 0, 0]]{2, 3}
            @test node.domain == BitVector([1, 1, 0, 0])
            for c in children(node)
                @test c isa RuleNode
                @test c.ind in [2, 3]
            end

            node = @rulenode Hole[Bool[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]]
            @test node.domain ==
                BitVector([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0])
            @test isempty(children(node))
        end

        @testset "Non-existent hole type" begin
            check = startswith("ArgumentError: Input to the @rulenode macro appears to be a hole")
            @test_throws check @macroexpand @rulenode HolyHole[1, 0, 0, 0]
        end
    end

    @testset "update rule indices" verbose = true begin
        @testset "RuleNode" verbose = true begin
            @testset "RuleNode" begin
                node = @rulenode 1{4{5, 6{3, 2, 1}}}
                expected_node = @rulenode 1{4{5, 6{3, 2, 1}}}
                n_rules = 10 # doesn't do anything in this case
                update_rule_indices!(node, n_rules)
                @test node == expected_node
                # with mapping
                mapping = Dict(1 => 7)
                expected_node = @rulenode 7{4{5, 6{3, 2, 7}}}
                n_rules = 10 # doesn't do anything in this case
                update_rule_indices!(node, n_rules, mapping)
                @test node == expected_node

                # error
                n_rules = 3
                @test_throws ErrorException update_rule_indices!(node, n_rules)
                @test_throws ErrorException update_rule_indices!(node, n_rules, mapping)
            end
        end
        @testset "AbstractHole" verbose = true begin
            mapping = Dict(1 => 5, 2 => 6, 3 => 1)
            @testset "UniformHole" begin
                n_rules = 6
                uniform_hole = @rulenode UniformHole[1, 1, 0, 0]{2, 3}
                expected_node = @rulenode UniformHole[1, 1, 0, 0, 0, 0]{2, 3}
                update_rule_indices!(uniform_hole, n_rules)
                @test uniform_hole.domain == expected_node.domain
                # with mapping
                uniform_hole = @rulenode UniformHole[1, 1, 0, 0]{2, 3}
                expected_uniform_hole = @rulenode UniformHole[0, 0, 0, 0, 1, 1]{6, 1}
                update_rule_indices!(uniform_hole, n_rules, mapping)
                @test uniform_hole.domain == expected_uniform_hole.domain
                @test uniform_hole.children == expected_uniform_hole.children
                # error
                n_rules = 2
                @test_throws ErrorException update_rule_indices!(uniform_hole, n_rules)
                @test_throws ErrorException update_rule_indices!(
                    uniform_hole, n_rules, mapping
                )
            end
            @testset "Hole" begin
                n_rules = 6
                hole = @rulenode Hole[1, 1, 0, 0]
                expected_hole = @rulenode Hole[1, 1, 0, 0, 0, 0]
                update_rule_indices!(hole, n_rules)
                @test hole.domain == expected_hole.domain
                # with mapping
                expected_hole = @rulenode Hole[0, 0, 0, 0, 1, 1]
                hole = @rulenode Hole[1, 1, 0, 0, 0, 0]
                update_rule_indices!(hole, n_rules, mapping)
                @test hole.domain == expected_hole.domain
                # error
                n_rules = 2
                @test_throws ErrorException update_rule_indices!(hole, n_rules)
                @test_throws ErrorException update_rule_indices!(hole, n_rules, mapping)
            end
        end
    end
    @testset "is_domain_valid" begin
        node = @rulenode 1{2, 3, 4{5{7}, 6{9{10}}}}
        n_rules = 10
        @test is_domain_valid(node, n_rules) == true
        @test is_domain_valid(node, 9) == false

        hole = UniformHole(BitVector((1, 1, 0, 0)), [RuleNode(3), RuleNode(4)])
        @test is_domain_valid(hole, 9) == false
        @test is_domain_valid(hole, 4) == true
    end

    @testset "isequal" begin
        # RuleNode
        node1 = @rulenode 1{4{5, 6}, 1{2, 3}}
        node2 = @rulenode 1{4{5, 6}, 1{2, 3}}
        node3 = @rulenode 1{4{5, 5}, 1{2, 3}}
        @test node1 == node2
        @test node1 != node3
        # Hole
        hole1 = Hole([1, 1, 0, 1])
        hole2 = Hole([1, 1, 0, 1])
        hole3 = Hole([1, 0, 0, 1])
        @test hole1 == hole2
        @test hole2 != hole3

        # UniformHole
        uhole1 = UniformHole(
            [0, 0, 1],
            [
                RuleNode(14),
                RuleNode(
                    2, [
                        RuleNode(
                            4, [
                                RuleNode(6),
                            ]
                        ),
                    ]
                ),
            ]
        )
        uhole2 = UniformHole(
            [0, 0, 1],
            [
                RuleNode(14),
                RuleNode(
                    2, [
                        RuleNode(
                            4, [
                                RuleNode(6),
                            ]
                        ),
                    ]
                ),
            ]
        )
        uhole3 = UniformHole(
            [0, 0, 1],
            [
                RuleNode(14),
                RuleNode(
                    2, [
                        RuleNode(
                            4, [
                                RuleNode(66),
                            ]
                        ),
                    ]
                ),
            ]
        )
        uhole4 = UniformHole([0, 0, 1], [RuleNode(14)])
        uhole5 = UniformHole([1, 0, 1], [RuleNode(14)])
        @test uhole1 == uhole2
        @test uhole1 != uhole3
        @test uhole4 != uhole5
        # compare different types
        @test node1 != uhole2
        @test hole3 != uhole5
    end
end
