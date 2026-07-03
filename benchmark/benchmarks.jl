import BenchmarkTools: BenchmarkGroup, @benchmarkable
import Herb: @csgrammar, BFSIterator, DFSIterator, Forbidden, Ordered,
    DomainRuleNode, VarNode, RuleNode, addconstraint! 

function create_constrained_grammar()
    grammar = @csgrammar begin
        Int = Int + Int
        Int = Int * Int
        Int = Int / Int
        Int = 1 | 2
    end
    addconstraint!(grammar, Ordered(DomainRuleNode(grammar, [1, 2], [VarNode(:X), VarNode(:Y)]), [:X, :Y]))
    addconstraint!(grammar, Forbidden(DomainRuleNode(grammar, [2, 3], [VarNode(:X), RuleNode(4)])))
    
    return grammar
end

function create_length_benchmark(grammar, iterator_type, start_symbol; max_depth, max_size)
    return @benchmarkable (l[] = length(it)) setup=(it=($iterator_type)($grammar, $start_symbol; max_depth=$max_depth, max_size=$max_size); l=Ref(0)) teardown=(@assert l[] > 0)
end

function create_suite()
    suite = BenchmarkGroup()
    grammar = create_constrained_grammar()
    for it in [BFSIterator, DFSIterator]
        suite[string(it)] = create_length_benchmark(grammar, it, :Int; max_depth=4, max_size=typemax(Int))
    end

    return suite
end

const SUITE = create_suite()
