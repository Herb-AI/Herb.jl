using BenchmarkTools, Herb
using Pkg

if PACKAGE_VERSION < v"0.4.1"
    if PACKAGE_VERSION == v"0.3.0"
        pkg"add HerbGrammar#bug/upper-compat-core HerbSearch"
    else
        pkg"add HerbGrammar HerbSearch"
    end
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

