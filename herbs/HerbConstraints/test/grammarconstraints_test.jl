@testitem "AbstractGrammarConstraint" begin
    using HerbCore, HerbGrammar

    @testset "add_rule! to grammar and update constraints" begin
        # define grammar
        grammar = @cfgrammar begin
            Number = |(1:2)
            Number = x
            Number = Number + Number
            Number = Number * Number
        end

        # add constraints
        contains = Contains(3)
        forbidden_sequence = ForbiddenSequence([4, 1])
        tree1 = UniformHole(BitVector((0, 0, 0, 1, 1)), [RuleNode(2), RuleNode(4, [UniformHole(BitVector((1, 1, 0, 0, 0)), []), UniformHole(BitVector((1, 1, 0, 0, 0)), [])])])
        tree2 = RuleNode(4, [VarNode(:a), RuleNode(1)])
        contains_subtree = ContainsSubtree(tree1)
        forbidden = Forbidden(tree2)

        addconstraint!(grammar, contains)
        addconstraint!(grammar, forbidden_sequence)
        addconstraint!(grammar, contains_subtree)
        addconstraint!(grammar, forbidden)

        # add more rules to grammar
        add_rule!(grammar, :(Number = 3 | 4))
        @test length(grammar.rules) == 7

        expected_bv1 = BitVector((0, 0, 0, 1, 1, 0, 0))
        expected_bv2 = BitVector((1, 1, 0, 0, 0, 0, 0))
        expected_bv3 = BitVector((1, 1, 0, 0, 0, 0, 0))

        @test grammar.constraints[1] == Contains(3) # no changes
        @test grammar.constraints[2].sequence == [4, 1] # no changes
        @test grammar.constraints[3].tree.domain == expected_bv1 # size BV changes
        @test grammar.constraints[3].tree.children[2].children[1].domain == expected_bv2
        @test grammar.constraints[3].tree.children[2].children[2].domain == expected_bv3
        @test grammar.constraints[4].tree == tree2 # no changes
    end
    @testset "merge_grammars! and update constraints" begin
        @testset "Simple example" begin
            merge_to = @csgrammar begin
                Real = |(1:2)
                Real = x
            end
            merge_from = @csgrammar begin
                Real = Real + Real
                Real = Real * Real
            end

            forbidden = Forbidden(UniformHole(BitVector((0, 0, 1))))
            ordered = Ordered(DomainRuleNode([1, 1], [VarNode(:v), VarNode(:w)]), [:v, :w])
            tree = UniformHole(BitVector((1, 0)), [RuleNode(1), RuleNode(2)]) 
            contains_subtree = ContainsSubtree(tree)
            addconstraint!(merge_to, forbidden)
            addconstraint!(merge_from, ordered)
            addconstraint!(merge_from, contains_subtree; allow_empty_children=true)

            merge_grammars!(merge_to, merge_from)
            # test that merge_grammars! does not modify merge_from.constraints
            @test length(merge_from.constraints) == 2
            @test merge_from.constraints[1].tree.domain == BitVector((1, 1))
            # test that rule nodes were updated correctly
            @test merge_to.constraints[1].tree.domain == BitVector((0, 0, 1, 0, 0))
            @test merge_to.constraints[2].tree.domain == BitVector((0, 0, 0, 1, 1))
            @test merge_to.constraints[3].tree.domain == BitVector((0, 0, 0, 1, 0))
            @test merge_to.constraints[3].tree.children == [RuleNode(4), RuleNode(5)]
        end
        @testset "Duplicate rules" begin
            merge_to = @csgrammar begin
                Int = Int + Int
                Int = x | 1 | 2 | 3
            end
            addconstraint!(merge_to, Contains(1))

            merge_from = @csgrammar begin
                Int = x | 1 | 2 | 3
                Int = Int + Int
            end
            addconstraint!(merge_from, Contains(5))
            addconstraint!(merge_from, Contains(3))

            merge_grammars!(merge_to, merge_from)
            @test length(merge_to.constraints) == 2 # duplicate constraint 
            @test Contains(1) in merge_to.constraints
            @test Contains(4) in merge_to.constraints
        end
    end
    @testset "addconstraint!" begin
        grammar = @cfgrammar begin
            Number = |(1:2)
            Number = x
            Number = Number + Number
            Number = Number * Number
        end
        # valid domains
        @test isempty(grammar.constraints) == true
        forbidden = Forbidden(UniformHole(BitVector((0, 0, 1, 0, 0))))
        addconstraint!(grammar, forbidden)
        @test length(grammar.constraints) == 1
        addconstraint!(grammar, Unique(2))
        @test length(grammar.constraints) == 2

        # try to add same constraint again
        addconstraint!(grammar, forbidden)
        @test length(grammar.constraints) == 2


        # invalid domains
        forbidden_invalid = Forbidden(UniformHole(BitVector((0, 0, 1))))
        @test_throws ErrorException addconstraint!(grammar, forbidden_invalid)


    end
    @testset "isequal" begin
        @test Contains(1) == Contains(1)
        @test Contains(1) != Unique(1)
    end
end
