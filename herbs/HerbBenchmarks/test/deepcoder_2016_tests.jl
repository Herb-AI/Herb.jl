@testitem "DeepCoder 2016" begin
    import HerbBenchmarks.DeepCoder_2016 as DeepCoder
    import HerbCore: @rulenode, RuleNode
    import HerbGrammar: nonterminals, expr2rulenode

    pgp = first(HerbBenchmarks.get_all_problem_grammar_pairs(DeepCoder))
    p = pgp.problem
    spec = p.spec
    _arg_1s = [s.in[:_arg_1] for s in spec]
    _arg_2s = [s.in[:_arg_2] for s in spec]
    g = pgp.grammar
    interpret = DeepCoder.make_deepcoder_interpreter(g)

    maximum_rn = expr2rulenode(:(maximum(_arg_1)), g)
    minimum_rn = expr2rulenode(:(minimum(_arg_1)), g)
    sum_rn = expr2rulenode(:(sum(_arg_1)), g)
    first_rn = expr2rulenode(:(first(_arg_1)), g)
    last_rn = expr2rulenode(:(last(_arg_1)), g)
    getindex_rn = expr2rulenode(:(getindex(_arg_1, 1)), g)
    countst_rn = expr2rulenode(:(countSt(_arg_1, 3)), g)
    countgt_rn = expr2rulenode(:(countGt(_arg_1, 3)), g)
    counteq_rn = expr2rulenode(:(countEq(_arg_1, 1)), g)
    countneq_rn = expr2rulenode(:(countNeq(_arg_1, 1)), g)
    countmod_rn = expr2rulenode(:(countMod(_arg_1, 2)), g)
    countnmod_rn = expr2rulenode(:(countNmod(_arg_1, 2)), g)
    drop_rn = expr2rulenode(:(drop(_arg_1, 2)), g)
    take_rn = expr2rulenode(:(take(_arg_1, 2)), g)
    reverse_rn = expr2rulenode(:(reverse(_arg_1)), g)
    filterst_rn = expr2rulenode(:(filterSt(_arg_1, 3)), g)
    filtergt_rn = expr2rulenode(:(filterGt(_arg_1, 3)), g)
    filtereq_rn = expr2rulenode(:(filterEq(_arg_1, 3)), g)
    filterneq_rn = expr2rulenode(:(filterNeq(_arg_1, 2)), g)
    filtermod_rn = expr2rulenode(:(filterMod(_arg_1, 2)), g)
    filternmod_rn = expr2rulenode(:(filterNmod(_arg_1, 2)), g)
    mapplus_rn = expr2rulenode(:(mapPlus(_arg_1, 2)), g)
    mapmult_rn = expr2rulenode(:(mapMult(_arg_1, 2)), g)
    mapDiv_rn = expr2rulenode(:(mapDiv(_arg_1, 2)), g)
    mappow_rn = expr2rulenode(:(mapPow(_arg_1, 2)), g)
    zipwithmax_rn = expr2rulenode(:(zipwithMax(_arg_1, _arg_2)), g)
    zipwithmin_rn = expr2rulenode(:(zipwithMin(_arg_1, _arg_2)), g)
    zipwithplus_rn = expr2rulenode(:(zipwithPlus(_arg_1, _arg_2)), g)
    zipwithminus_rn = expr2rulenode(:(zipwithMinus(_arg_1, _arg_2)), g)
    zipwithmult_rn = expr2rulenode(:(zipwithMult(_arg_1, _arg_2)), g)
    scanl1max_rn = expr2rulenode(:(scanl1Max(_arg_1)), g)
    scanl1min_rn = expr2rulenode(:(scanl1Min(_arg_1)), g)
    scanl1plus_rn = expr2rulenode(:(scanl1Plus(_arg_1)), g)
    scanl1minus_rn = expr2rulenode(:(scanl1Minus(_arg_1)), g)
    scanl1mult_rn = expr2rulenode(:(scanl1Mult(_arg_1)), g)
    arg1_rn = expr2rulenode(:(_arg_1), g)
    arg2_rn = expr2rulenode(:(_arg_2), g)

    @test interpret(maximum_rn, spec) == maximum.(_arg_1s)
    @test interpret(minimum_rn, spec) == minimum.(_arg_1s)
    @test interpret(sum_rn, spec) == sum.(_arg_1s)
    @test interpret(first_rn, spec) == first.(_arg_1s)
    @test interpret(last_rn, spec) == last.(_arg_1s)
    @test interpret(getindex_rn, spec) == getindex.(_arg_1s, ones(Int, length(_arg_1s)))
    @test interpret(countst_rn, spec) == count.(>(3), _arg_1s)
    @test interpret(countgt_rn, spec) == count.(<(3), _arg_1s)
    @test interpret(counteq_rn, spec) == count.(==(1), _arg_1s)
    @test interpret(countneq_rn, spec) == count.(!=(1), _arg_1s)
    @test interpret(countmod_rn, spec) == count.(==(0), [mod.(a, 2) for a in _arg_1s])
    @test interpret(countnmod_rn, spec) == count.(!=(0), [mod.(a, 2) for a in _arg_1s])
    @test interpret(drop_rn, spec) == [a[3:end] for a in _arg_1s]
    @test interpret(take_rn, spec) == [a[begin:2] for a in _arg_1s]
    @test interpret(reverse_rn, spec) == reverse.(_arg_1s)
    @test interpret(filterst_rn, spec) == filter.(>(3), _arg_1s)
    @test interpret(filtergt_rn, spec) == filter.(<(3), _arg_1s)
    @test interpret(filtereq_rn, spec) == filter.(==(3), _arg_1s)
    @test interpret(filterneq_rn, spec) == filter.(!=(2), _arg_1s)
    @test interpret(filtermod_rn, spec) == filter.(x -> mod(x, 2) == 0, _arg_1s)
    @test interpret(filternmod_rn, spec) == filter.(x -> mod(x, 2) != 0, _arg_1s)
    @test interpret(mapplus_rn, spec) == map.(x -> x + 2, _arg_1s)
    @test interpret(mapmult_rn, spec) == map.(x -> x * 2, _arg_1s)
    @test interpret(mappow_rn, spec) == map.(x -> x^2, _arg_1s)
    @test interpret(zipwithmax_rn, spec) == map.(x -> max(x...), zip.(_arg_1s, _arg_2s))
    @test interpret(zipwithmin_rn, spec) == map.(x -> min(x...), zip.(_arg_1s, _arg_2s))
    @test interpret(zipwithplus_rn, spec) == map.(x -> +(x...), zip.(_arg_1s, _arg_2s))
    @test interpret(zipwithminus_rn, spec) == map.(x -> -(x...), zip.(_arg_1s, _arg_2s))
    @test interpret(zipwithmult_rn, spec) == map.(x -> *(x...), zip.(_arg_1s, _arg_2s))
    @test interpret(scanl1min_rn, spec) == accumulate.(min, _arg_1s)
    @test interpret(scanl1max_rn, spec) == accumulate.(max, _arg_1s)
    @test interpret(scanl1plus_rn, spec) == accumulate.(+, _arg_1s)
    @test interpret(scanl1minus_rn, spec) == accumulate.(-, _arg_1s)
    @test interpret(scanl1mult_rn, spec) == accumulate.(*, _arg_1s)
    @test interpret(arg1_rn, spec) == _arg_1s
    @test interpret(arg2_rn, spec) == _arg_2s
end
