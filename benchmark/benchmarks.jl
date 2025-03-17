using BenchmarkTools, Herb

const SUITE = BenchmarkGroup()

SUITE["search"] = BenchmarkGroup()

g = @csgrammar begin
    Int = 1 | 2
    Int = 3 + Int
end

iter = BFSIterator(g, :Int; max_depth=5)

SUITE["search"]["BFS over small addition grammar"] = @benchmarkable(
    collect($iter)
)