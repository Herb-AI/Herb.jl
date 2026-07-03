@testitem "PBE SLIA Track 2019" begin
    import HerbBenchmarks.PBE_SLIA_Track_2019 as SLIA
    import HerbGrammar: expr2rulenode
    import HerbCore: @rulenode

    pgp = first(HerbBenchmarks.get_all_problem_grammar_pairs(SLIA))
    g = pgp.grammar
    spec = pgp.problem.spec

    args1 = [s.in[:_arg_1] for s in spec]

    interpret = SLIA.make_SLIA_interpreter(g)

    const_expected(x) = fill(x, length(spec))

    function expected_indexof(str::String, substring::String, index::Int)
        n = findfirst(substring, str)
        return n === nothing ? -1 : (first(n) >= index ? first(n) : -1)
    end

    # String typed
    concat_rn = expr2rulenode(:(concat_cvc(_arg_1, "US")), g)
    replace_rn = expr2rulenode(:(replace_cvc(_arg_1, "US", "CAN")), g)
    at_rn = expr2rulenode(:(at_cvc(_arg_1, 1)), g)
    int_to_str_rn = expr2rulenode(:(int_to_str_cvc(1)), g)
    substr_rn = expr2rulenode(:(substr_cvc(_arg_1, 1, 1)), g)

    @test interpret(concat_rn, spec) == [str * "US" for str in args1]
    @test interpret(replace_rn, spec) == [replace(str, "US" => "CAN") for str in args1]
    @test interpret(at_rn, spec) == [string(str[1]) for str in args1]
    @test interpret(int_to_str_rn, spec) == const_expected("1")
    @test interpret(substr_rn, spec) == [str[1:1] for str in args1]

    # Int typed
    len_rn = expr2rulenode(:(len_cvc(_arg_1)), g)
    str_to_int_rn = expr2rulenode(:(str_to_int_cvc(int_to_str_cvc(1))), g)
    indexof_us_rn = expr2rulenode(:(indexof_cvc(_arg_1, "US", 1)), g)
    indexof_can_rn = expr2rulenode(:(indexof_cvc(_arg_1, "CAN", 1)), g)

    @test interpret(len_rn, spec) == length.(args1)
    @test interpret(str_to_int_rn, spec) == const_expected(1)
    @test interpret(indexof_us_rn, spec) == [expected_indexof(str, "US", 1) for str in args1]
    @test interpret(indexof_can_rn, spec) == [expected_indexof(str, "CAN", 1) for str in args1]

    # Bool typed
    prefixof_rn = expr2rulenode(:(prefixof_cvc("US", _arg_1)), g)
    suffixof_rn = expr2rulenode(:(suffixof_cvc("US", _arg_1)), g)
    contains_rn = expr2rulenode(:(contains_cvc(_arg_1, "CAN")), g)

    @test interpret(prefixof_rn, spec) == [startswith(str, "US") for str in args1]
    @test interpret(suffixof_rn, spec) == [endswith(str, "US") for str in args1]
    @test interpret(contains_rn, spec) == [contains(str, "CAN") for str in args1]

    # If expressions

    # if contains_cvc(_arg_1, "US")
    #     "US"
    # else
    #     "CAN"
    # end
    if_string_rn = @rulenode 11{27{2,5},5,6}

    # if contains_cvc(_arg_1, "US")
    #     1
    # else
    #     0
    # end
    if_int_rn = @rulenode 20{27{2,5},13,14}

    @test interpret(if_string_rn, spec) ==
        [contains(str, "US") ? "US" : "CAN" for str in args1]

    @test interpret(if_int_rn, spec) ==
        [contains(str, "US") ? 1 : 0 for str in args1]
end