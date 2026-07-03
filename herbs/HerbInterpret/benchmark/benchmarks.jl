using BenchmarkTools
using Random: seed!
using HerbGrammar: @csgrammar, grammar2symboltable, rulenode2expr
using HerbCore: RuleNode
# currently this is defined in Search, but should ideally have a definition in Core
# because having to add Search here in the benchmark environment creates annoying
# circular dependencies. For now, store the expressions tested in `exprs.jl`
# using HerbSearch: rand
using HerbInterpret: interpret

include("exprs.jl")

function create_interpret_benchmark()
    suite = BenchmarkGroup()
    seed!(42) # keep random expressions constant
    g = @csgrammar begin
        Var = Var + Var
        Var = Var * Var
        Var = Var / Var
        Var = |(0:5)
    end

    # once we move random RuleNode sampling to Core
    # exprs = [rulenode2expr(rand(RuleNode, g), g) for _ in 1:1000]

    st = grammar2symboltable(g)

    suite["Random Expressions"] = @benchmarkable interpret.(($st,), $EXPRS)

    return suite
end

function create_benchmarks()
    suite = BenchmarkGroup()
    suite["interpret"] = create_interpret_benchmark()
    return suite
end

const SUITE = create_benchmarks()
