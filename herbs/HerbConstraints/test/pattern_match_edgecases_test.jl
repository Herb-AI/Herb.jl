#These test contain edgecases that fail in the current implemention
@testitem "PatternMatch Edgecase" begin
    using HerbCore, HerbGrammar

    @testset "3 VarNodes: pairwise Softfail, triplewise HardFail" begin
        rn = RuleNode(4, [
            RuleNode(4, [Hole(BitVector((1, 1, 0))), Hole(BitVector((0, 1, 1)))]), 
            Hole(BitVector((1, 0, 1)))
        ])
        mn = RuleNode(4, [
            RuleNode(4, [VarNode(:x), VarNode(:x)]),
            VarNode(:x)
        ])
        @test_broken pattern_match(rn, mn) isa HerbConstraints.PatternMatchHardFail
    end

    @testset "3 VarNodes: HardFail on instance 2 and 3" begin
        rn = RuleNode(4, [
            RuleNode(4, [Hole(BitVector((1, 1, 1))), RuleNode(1)]), 
            RuleNode(2)
        ])
        mn = RuleNode(4, [
            RuleNode(4, [VarNode(:x), VarNode(:x)]),
            VarNode(:x)
        ])
        @test_broken pattern_match(rn, mn) isa HerbConstraints.PatternMatchHardFail
    end
end
