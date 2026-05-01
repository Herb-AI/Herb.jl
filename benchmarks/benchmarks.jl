using BenchmarkTools: @benchmarkable, BenchmarkGroup, load, loadparams!, params, save, tune!
using Herb: @csgrammar, BFSIterator, Contains, ContainsSubtree, Forbidden,
    ForbiddenSequence, Ordered, RuleNode, Unique, VarNode, addconstraint!

function many_constraints()
    grammar = @csgrammar begin
        Int = 1
        Int = x
        Int = -Int
        Int = Int + Int
        Int = Int * Int
    end

    contains_subtree = ContainsSubtree(RuleNode(4, [
        RuleNode(1),
        RuleNode(1)
    ]))

    contains_subtree2 = ContainsSubtree(RuleNode(4, [
        RuleNode(4, [
            VarNode(:a),
            RuleNode(2)
        ]),
        VarNode(:a)
    ]))

    contains = Contains(2)

    forbidden_sequence = ForbiddenSequence([4, 5])

    forbidden_sequence2 = ForbiddenSequence([4, 5], ignore_if=[3])

    forbidden_sequence3 = ForbiddenSequence([4, 1], ignore_if=[5])

    forbidden = Forbidden(RuleNode(3, [RuleNode(3, [VarNode(:a)])]))

    forbidden2 = Forbidden(RuleNode(4, [
        VarNode(:a),
        VarNode(:a)
    ]))

    ordered = Ordered(RuleNode(5, [
            VarNode(:a),
            VarNode(:b)
        ]), [:a, :b])

    unique = Unique(2)

    all_constraints = [
        ("ContainsSubtree", contains_subtree),
        ("ContainsSubtree2", contains_subtree2),
        ("Contains", contains),
        ("ForbiddenSequence", forbidden_sequence),
        ("ForbiddenSequence2", forbidden_sequence2),
        ("ForbiddenSequence3", forbidden_sequence3),
        ("Forbidden", forbidden),
        ("Forbidden2", forbidden2),
        ("Ordered", ordered),
        ("Unique", unique)
    ]
    for (_, constraint) ∈ all_constraints
        addconstraint!(grammar, constraint)
    end
    return grammar
end


function create_suite()
    suite = BenchmarkGroup()

    suite["grammar with many constraints BFSIterator"] = @benchmarkable length(it) setup = (it = BFSIterator(many_constraints(), :Int; max_size=10))
    params_path = joinpath(@__DIR__, "params.json")
    if isfile(params_path)
        loadparams!(suite, load(params_path)[1], :evals, :samples)
    else
        tune!(suite)
        save(params_path, params(suite))
    end

    return suite
end

const SUITE = create_suite()
