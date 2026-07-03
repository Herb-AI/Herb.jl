@testset verbose = true "Context-free iterators" begin
    @testset "getters for ProgramIterators" begin
        g1 = @csgrammar begin
            Real = |(1:9)
        end

        bfs = BFSIterator(g1, :Real, max_depth=1, max_size=1)
        @test get_grammar(bfs) == g1
        @test get_solver(bfs) isa HerbConstraints.Solver
        @test get_max_depth(bfs) == 1
        @test get_max_size(bfs) == 1
        @test get_starting_symbol(bfs) == :Real
    end
    @testset "length on single Real grammar" begin
        g1 = @csgrammar begin
            Real = |(1:9)
        end

        @test length(BFSIterator(g1, :Real, max_depth=1)) == 9
        @test length(DFSIterator(g1, :Real, max_depth=1)) == 9

        # Tree depth is equal to 1, so the max depth of 3 does not change the expression count
        @test length(BFSIterator(g1, :Real, max_depth=3)) == 9
        @test length(DFSIterator(g1, :Real, max_depth=3)) == 9
    end

    @testset "length on grammar with multiplication" begin
        g1 = @csgrammar begin
            Real = 1 | 2
            Real = Real * Real
        end
        # Expressions: [1, 2]  
        @test length(BFSIterator(g1, :Real, max_depth=1)) == 2
        @test length(DFSIterator(g1, :Real, max_depth=1)) == 2

        # Expressions: [1, 2, 1 * 1, 1 * 2, 2 * 1, 2 * 2] 
        @test length(BFSIterator(g1, :Real, max_depth=2)) == 6
        @test length(DFSIterator(g1, :Real, max_depth=2)) == 6
    end

    @testset "length on different arithmetic operators" begin
        g1 = @csgrammar begin
            Real = 1
            Real = Real * Real
        end

        g2 = @csgrammar begin
            Real = 1
            Real = Real / Real
        end

        g3 = @csgrammar begin
            Real = 1
            Real = Real + Real
        end

        g4 = @csgrammar begin
            Real = 1
            Real = Real - Real
        end

        g5 = @csgrammar begin
            Real = 1
            Real = Real % Real
        end

        g6 = @csgrammar begin
            Real = 1
            Real = Real \ Real
        end

        g7 = @csgrammar begin
            Real = 1
            Real = Real^Real
        end

        g8 = @csgrammar begin
            Real = 1
            Real = -Real * Real
        end

        # E.q for multiplication: [1, 1 * 1, 1 * (1 * 1), (1 * 1) * 1, (1 * 1) * (1 * 1)] 
        @test length(BFSIterator(g1, :Real, max_depth=3)) == 5
        @test length(BFSIterator(g2, :Real, max_depth=3)) == 5
        @test length(BFSIterator(g3, :Real, max_depth=3)) == 5
        @test length(BFSIterator(g4, :Real, max_depth=3)) == 5
        @test length(BFSIterator(g5, :Real, max_depth=3)) == 5
        @test length(BFSIterator(g6, :Real, max_depth=3)) == 5
        @test length(BFSIterator(g7, :Real, max_depth=3)) == 5
        @test length(BFSIterator(g8, :Real, max_depth=3)) == 5

        @test length(DFSIterator(g1, :Real, max_depth=3)) == 5
        @test length(DFSIterator(g2, :Real, max_depth=3)) == 5
        @test length(DFSIterator(g3, :Real, max_depth=3)) == 5
        @test length(DFSIterator(g4, :Real, max_depth=3)) == 5
        @test length(DFSIterator(g5, :Real, max_depth=3)) == 5
        @test length(DFSIterator(g6, :Real, max_depth=3)) == 5
        @test length(DFSIterator(g7, :Real, max_depth=3)) == 5
        @test length(DFSIterator(g8, :Real, max_depth=3)) == 5

    end

    @testset "length on grammar with functions" begin
        g1 = @csgrammar begin
            Real = 1 | 2
            Real = f(Real)                # function call
        end

        # Expressions: [1, 2, f(1), f(2)]
        @test length(BFSIterator(g1, :Real, max_depth=2)) == 4
        @test length(DFSIterator(g1, :Real, max_depth=2)) == 4

        # Expressions: [1, 2, f(1), f(2), f(f(1)), f(f(2))]
        @test length(BFSIterator(g1, :Real, max_depth=3)) == 6
        @test length(DFSIterator(g1, :Real, max_depth=3)) == 6
    end

    answer_programs = [
        RuleNode(1),
        RuleNode(2),
        RuleNode(3, [RuleNode(1), RuleNode(1)]),
        RuleNode(3, [RuleNode(1), RuleNode(2)]),
        RuleNode(3, [RuleNode(2), RuleNode(1)]),
        RuleNode(3, [RuleNode(2), RuleNode(2)])
    ]

    @testset "BFSIterator test" begin
        g1 = @csgrammar begin
            Real = 1 | 2
            Real = Real * Real
        end
        bfs_programs = [freeze_state(p) for p ∈ BFSIterator(g1, :Real, max_depth=2)]
        # Test for increasing program depth
        @test all(map(t -> depth(t[1]) ≤ depth(t[2]), zip(bfs_programs[begin:end-1], bfs_programs[begin+1:end])))

        @test length(bfs_programs) == 6
        @test all(p ∈ bfs_programs for p ∈ answer_programs)
    end

    @testset "DFSIterator test" begin
        g1 = @csgrammar begin
            Real = 1 | 2
            Real = Real * Real
        end

        dfs_programs = [freeze_state(p) for p ∈ DFSIterator(g1, :Real, max_depth=2)]

        @test length(dfs_programs) == 6
        @test all(p ∈ dfs_programs for p ∈ answer_programs)
    end

    @testset verbose = true "MLFSIterator tests" begin
        g = @pcsgrammar begin
            0.2:Real = 1
            0.3:Real = 2
            0.5:Real = Real * Real
        end

        log_p(p) = rulenode_log_probability(p, g)

        iter = MLFSIterator(g, :Real, max_depth=2)

        mlfs_programs = [freeze_state(p) for p ∈ iter]

        # Test for drecreasing program probability
        @test all(map(t -> log_p(t[1]) >= log_p(t[2]), zip(mlfs_programs[begin:end-1], mlfs_programs[begin+1:end])))
        @test length(mlfs_programs) == 6
        @test all(p ∈ mlfs_programs for p ∈ answer_programs)
    end
end
