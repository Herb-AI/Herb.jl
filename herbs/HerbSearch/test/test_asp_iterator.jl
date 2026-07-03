@testset "ASP Iterators" begin
    using HerbCore
    using HerbSearch: BFSASPIterator, DFSASPIterator
    using Clingo_jll

    answer_programs = [
        @rulenode(1),
        @rulenode(2),
        @rulenode(3{1,1}),
        @rulenode(3{1,2}),
        @rulenode(3{2,1}),
        @rulenode(3{2,2}),
    ]

    @testset "BFS ASP Iterator" begin
        g1 = @csgrammar begin
            Real = 1 | 2
            Real = Real * Real
        end
        bfs_programs = [freeze_state(p) for p ∈ BFSASPIterator(g1, :Real, max_depth=2)]
        # Test for increasing program depth
        @test all(map(t -> depth(t[1]) ≤ depth(t[2]), zip(bfs_programs[begin:end-1], bfs_programs[begin+1:end])))

        @test length(bfs_programs) == 6
        @test all(p ∈ bfs_programs for p ∈ answer_programs)
    end

    @testset "DFS ASP Iterator" begin
        g1 = @csgrammar begin
            Real = 1 | 2
            Real = Real * Real
        end

        dfs_programs = [freeze_state(p) for p ∈ DFSASPIterator(g1, :Real, max_depth=2)]

        @test length(dfs_programs) == 6
        @test all(p ∈ dfs_programs for p ∈ answer_programs)
    end

    @testset "Issue 175: Invalid mapping" begin
        g = @csgrammar begin
            Int = Int + Int
            Int = 1 | 2
        end
        iter = BFSASPIterator(g, :Int, max_depth=3)
        @test length(collect(iter)) > 0
    end
end
