using BenchmarkTools, Herb

if PACKAGE_VERSION < v"0.4.1"
    import Pkg
    Pkg.add(["HerbGrammar", "HerbSearch"])
    using HerbGrammar, HerbSearch
end

const SUITE = BenchmarkGroup()

SUITE["search"] = BenchmarkGroup()

g = @csgrammar begin
    Int = 1 | 2
    Int = 3 + Int
end

max_depth = 5
max_size = typemax(Int)

if PACKAGE_VERSION == v"0.1.0"
    SUITE["search"]["BFS over small addition grammar"] = @benchmarkable(
        count_expressions($g, $max_depth, $max_size, :Int)
    )
else
    iter = BFSIterator(g, :Int; max_depth=max_depth)
    SUITE["search"]["BFS over small addition grammar"] = @benchmarkable(
        collect($iter)
    )
end

