@testitem "Tree valid with respect to a grammar" begin
    import HerbCore: UniformHole, RuleNode
    import HerbGrammar: @csgrammar, is_constraint_valid, is_tree_valid

    @testset "too many children" begin
        grammar = @csgrammar begin
            Int = Int + 1
            Int = 0
        end
        t = RuleNode(1, [RuleNode(2), RuleNode(2)])
        @test !is_tree_valid(t, grammar)
    end

    @testset "Incorrect tree" begin
        grammar = @csgrammar begin
            Int = Int +  1
            Int = Zero
            Zero = 0
        end
        tw = RuleNode(1, [RuleNode(3)])
        @test !is_tree_valid(tw, grammar)
        t = RuleNode(1, [RuleNode(2, [RuleNode(3)])])
        @test is_tree_valid(t, grammar)
    end

    @testset "Incorrect with holes" begin
        grammar = @csgrammar begin
            Exp = Op
            Op = Exp + Exp
            Op = Exp * Exp
            Exp = 0
            Exp = 1
        end
        tw = UniformHole(BitVector([1, 1, 1, 0, 0]), [RuleNode(4), RuleNode(4)])
        @test !is_tree_valid(tw, grammar)
        t = UniformHole(BitVector([0, 1, 1, 0, 0]), [RuleNode(4), RuleNode(4)])
        @test is_tree_valid(t, grammar)
    end

    @testset "Uniform Holes" begin
        grammar = @csgrammar begin
            Number = |(1:2)
            Number = x
            Number = Number + Number
            Number = Number * Number
        end
        tree = UniformHole(BitVector((0, 0, 0, 1, 1)), [RuleNode(1), RuleNode(3)])
        @test is_tree_valid(tree, grammar)
        
        tree1 = UniformHole(BitVector((0, 0, 0, 1, 1)), [RuleNode(2), RuleNode(4, [])])
        @test is_tree_valid(tree1, grammar; allow_empty_children=true)
        # empty children
        tree2 = RuleNode(4, [])
        @test is_tree_valid(tree2, grammar; allow_empty_children=true)
        tree3 = UniformHole(BitVector((0, 0, 0, 1, 1)), [])
        @test is_tree_valid(tree3, grammar; allow_empty_children=true)
        tree4 = UniformHole(BitVector((0, 0, 0, 1, 1)), [])
        @test !is_tree_valid(tree4, grammar)
        tree5 = UniformHole(BitVector((0, 1, 1, 1, 1)), [])
        @test is_tree_valid(tree5, grammar; allow_empty_children=true)
        
    end
end