@testitem "rulenode2expr" begin
    using HerbCore

    grammar = @csgrammar begin
        S = 1
        S = x
        S = S + S
        S = S * S
    end

    @testset "RuleNode" begin
        node = RuleNode(3, [
            RuleNode(3, [
                RuleNode(1),
                RuleNode(1)
            ]),
            RuleNode(3, [
                RuleNode(2),
                RuleNode(1)
            ]),
        ])
        @test string(rulenode2expr(node, grammar)) == "(1 + 1) + (x + 1)"
    end

    @testset "Hole" begin
        node = RuleNode(3, [
            RuleNode(3, [
                RuleNode(1),
                RuleNode(1)
            ]),
            RuleNode(3, [
                RuleNode(2),
                Hole(get_domain(grammar, :S))
            ]),
        ])
        @test string(rulenode2expr(node, grammar)) == "(1 + 1) + (x + S)"
    end

    @testset "UniformHole" begin
        node = RuleNode(3, [
            RuleNode(3, [
                RuleNode(1),
                RuleNode(1)
            ]),
            UniformHole(BitVector((0, 0, 1, 1)), [
                RuleNode(2),
                RuleNode(1)
            ]),
        ])
        @test string(rulenode2expr(node, grammar)) == "(1 + 1) + S"
    end
end
