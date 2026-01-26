@testset "Test make_interpreter" begin
    g = @cfgrammar begin
        Number = |(1:2)
        Number = x
        Number = Number + Number
        Number = Number * Number
        Number = Number + 1
        Number = x * 2
    end

    tags = HerbInterpret.get_relevant_tags(g)

    @test tags[1] == 1
    @test tags[2] == 2
    @test tags[3] == :x
    @test tags[4] == :+
    @test tags[5] == :*
    @test tags[6] == :(Number + 1)
    @test tags[7] == :(x * 2)

    input = Dict{Symbol,Any}(:x => 1)

    ex = HerbInterpret.make_interpreter(g; input_symbols=[:x], name=:interpret_custom)

    # Define interpret_custom *in this test module*
    Core.eval(@__MODULE__, ex)

    # Leaves
    @test interpret_custom((@rulenode 1), tags, input) == 1
    @test interpret_custom((@rulenode 2), tags, input) == 2
    @test interpret_custom((@rulenode 3), tags, input) == 1

    # Pure operators
    @test interpret_custom((@rulenode 4{1,2}), tags, input) == 3           # 1 + 2
    @test interpret_custom((@rulenode 5{1,2}), tags, input) == 2           # 1 * 2

    # Partial rules
    @test interpret_custom((@rulenode 6{3}), tags, input) == 2             # (x) + 1
    @test interpret_custom((@rulenode 7), tags, input) == 2                # x * 2

    # Your composite example: (x + 2) * (x * 2) with x=1 => (1+2)*(2)=6
    rn = @rulenode 5{4{3,2},7}
    @test interpret_custom(rn, tags, input) == 6
end