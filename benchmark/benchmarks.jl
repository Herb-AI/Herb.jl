using BenchmarkTools, Herb

function create_dfs_benchmark()
    suite = BenchmarkGroup()

    suite["enumerate unconstrained up to depth=3"] = @benchmarkable(
        length(DFSIterator(g, :Int; max_depth=3)),
        setup = (
            g = @csgrammar begin
                Int = Int + Int
                Int = 1
            end
        )
    )

    suite["enumerate with ordered up to depth=3"] = @benchmarkable(
        length(DFSIterator(g, :Int; max_depth=3)),
        setup = (
            g = let g = @csgrammar begin
                    Int = Int + Int
                    Int = 1
                end
                addconstraint!(g, Ordered(DomainRuleNode(g, [1], [VarNode(:a), VarNode(:b)]), [:a, :b]))
                g
            end
        )
    )

    suite["enumerate with unique up to depth=3"] = @benchmarkable(
        length(DFSIterator(g, :Int; max_depth=3)),
        setup = (
            g = let g = @csgrammar begin
                    Int = Int + Int
                    Int = 1 | 2 | 3
                end
                addconstraint!.((g,), Unique.([2, 3, 4]))
                g
            end
        )
    )
    return suite
end

function create_benchmark()
    suite = BenchmarkGroup()
    suite["dfs"] = create_dfs_benchmark()

    return suite
end

const SUITE = create_benchmark()
