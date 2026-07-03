@testitem "PBE BV Track 2018" begin
    import HerbBenchmarks.PBE_BV_Track_2018 as BV
    import HerbGrammar: nonterminals, expr2rulenode

    pgp = first(HerbBenchmarks.get_all_problem_grammar_pairs(BV))
    g = pgp.grammar
    spec = pgp.problem.spec
    args1 = [s.in[:_arg_1] for s in spec]
    interpret = BV.make_bv_interpreter(g)

    bvnot_rn = expr2rulenode(:(bvnot_cvc(_arg_1)), g)
    smol_rn = expr2rulenode(:(smol_cvc(_arg_1)), g)
    ehad_rn = expr2rulenode(:(ehad_cvc(_arg_1)), g)
    arba_rn = expr2rulenode(:(arba_cvc(_arg_1)), g)
    shesh_rn = expr2rulenode(:(shesh_cvc(_arg_1)), g)
    bvand_rn = expr2rulenode(:(bvand_cvc(_arg_1, 0x0000000000000000)), g)
    bvor_rn = expr2rulenode(:(bvor_cvc(_arg_1, 0x0000000000000001)), g)
    bvadd_rn = expr2rulenode(:(bvadd_cvc(_arg_1, 0x0000000000000001)), g)
    im_rn = expr2rulenode(:(im_cvc(0x0000000000000001, _arg_1, 0x0000000000000001)), g)
    im_rn0 = expr2rulenode(:(im_cvc(0x0000000000000000, 0x0000000000000001, _arg_1)), g)

    @test interpret(bvnot_rn, spec) == [.~bv for bv in args1]
    @test interpret(smol_rn, spec) == [bv << 1 for bv in args1]
    @test interpret(ehad_rn, spec) == [bv >>> 1 for bv in args1]
    @test interpret(arba_rn, spec) == [bv >>> 4 for bv in args1]
    @test interpret(shesh_rn, spec) == [bv >>> 16 for bv in args1]
    @test interpret(bvand_rn, spec) == (&).(args1, 0)
    @test interpret(bvor_rn, spec) == (|).(args1, 1)
    @test interpret(bvadd_rn, spec) == (+).(args1, 1)
    @test interpret(im_rn, spec) == args1
    @test interpret(im_rn0, spec) == args1

    g = BV.grammar_if0_70_10
    interpret = BV.make_bv_interpreter(g)
    if0_rn = expr2rulenode(:(if0_cvc(0x0000000000000000, 0x0000000000000001, 0x0000000000000000)), g)
    if01_rn = expr2rulenode(:(if0_cvc(0x0000000000000001, 0x0000000000000000, 0x0000000000000001)), g)
    @test all(interpret(if0_rn, spec) .== 1)
    @test all(interpret(if01_rn, spec) .== 1)
end
