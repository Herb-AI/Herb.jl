@testitem "StateSparseSet" begin
    @testset "min" begin
        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        remove!(set, 1)
        remove!(set, 2)
        remove!(set, 3)
        @test findfirst(set) == 4

        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        remove!(set, 3)
        remove!(set, 2)
        remove!(set, 1)
        @test findfirst(set) == 4

        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        remove!(set, 1)
        remove!(set, 7)
        remove!(set, 3)
        @test findfirst(set) == 2

        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        remove!(set, 3)
        remove!(set, 7)
        remove!(set, 1)
        @test findfirst(set) == 2
    end

    @testset "max" begin
        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        remove!(set, 1)
        remove!(set, 2)
        remove!(set, 3)
        @test findlast(set) == 10
        
        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        remove!(set, 10)
        @test findlast(set) == 9

        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        remove!(set, 1)
        remove!(set, 2)
        remove!(set, 10)
        remove!(set, 1)
        remove!(set, 9)
        remove!(set, 3)
        @test findlast(set) == 8
    end

    @testset "in" begin
        n = 5
        for remaining_value ∈ 1:n
            set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), n)
            for i ∈ 1:n
                if i != remaining_value
                    remove!(set, i)
                end
            end
            for i ∈ 1:10
                if i == remaining_value
                    @test i ∈ set
                else
                    @test i ∉ set
                end
            end
        end
    end

    @testset "isempty" begin
        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 1)
        remove!(set, 1)
        @test isempty(set)

        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 3)
        remove!(set, 2)
        remove!(set, 3)
        remove!(set, 1)
        @test isempty(set)
    end

    @testset "size" begin
        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        @test size(set) == 10
        remove!(set, 4)
        @test size(set) == 9
        remove!(set, 2)
        @test size(set) == 8
        remove!(set, 8)
        @test size(set) == 7
        remove!(set, 5)
        @test size(set) == 6
        remove!(set, 4) #already removed
        @test size(set) == 6
        remove!(set, 1)
        @test size(set) == 5
        remove!(set, 10)
        @test size(set) == 4
    end

    @testset "remove all" begin
        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        empty!(set)
        @test size(set) == 0

        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        HerbConstraints.remove_below!(set, 11)
        @test size(set) == 0

        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        HerbConstraints.remove_above!(set, 0)
        @test size(set) == 0
    end

    @testset "remove_below!" begin
        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        HerbConstraints.remove_below!(set, 5)
        @test size(set) == 6
        for i ∈ 1:4
            @test i ∉ set
        end
        for i ∈ 5:10
            @test i ∈ set
        end
    end

    @testset "remove_above!" begin
        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 10)
        HerbConstraints.remove_above!(set, 4)
        @test size(set) == 4
        for i ∈ 1:4
            @test i ∈ set
        end
        for i ∈ 5:10
            @test i ∉ set
        end
    end

    @testset "convert BitVector to StateSparseSet" begin
        domain = BitVector((0, 0, 1, 0, 1, 0, 0))
        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), domain)
        @test 1 ∉ set
        @test 2 ∉ set
        @test 3 ∈ set
        @test 4 ∉ set
        @test 5 ∈ set
        @test 6 ∉ set
        @test 7 ∉ set
        @test size(set) == 2
        @test findfirst(set) == 3
        @test findlast(set) == 5
        @test size(set) == sum(domain) # sum(set) == sum(domain)
        @test findfirst(set) == findfirst(domain)
        @test findlast(set) == findlast(domain)
    end

    @testset "Base.iterate" begin
        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 5)
        HerbConstraints.remove!(set, 4)
        HerbConstraints.remove!(set, 1)
        vec = Vector{Int}()
        for value ∈ set
            push!(vec, value)
        end
        @test length(vec) == 3
        @test 2 ∈ vec
        @test 3 ∈ vec
        @test 5 ∈ vec
    end

    @testset "remove_all_but!" begin
        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 5)
        remove_all_but!(set, 2)
        @test length(set) == 1
        @test 2 ∈ set

        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), BitVector((1, 0, 1)))
        result = remove_all_but!(set, [1])
        @test length(set) == 1
        @test 1 ∈ set
        @test result == true

        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), BitVector((1, 0, 1)))
        @test_throws Exception remove_all_but!(set, [2])

        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), BitVector((1, 0, 1)))
        @test_throws Exception remove_all_but!(set, [2, 3])

        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), BitVector((1, 0, 1)))
        result = remove_all_but!(set, [1, 3])
        @test length(set) == 2
        @test 1 ∈ set && 3 ∈ set
        @test result == false
    end

    @testset "are_disjoint" begin
        set1 = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 5)
        set2 = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 5)
        @test are_disjoint(set1, set2) == false
        remove_all_but!(set1, 1)
        @test are_disjoint(set1, set2) == false
        remove_all_but!(set2, 2)
        @test are_disjoint(set1, set2) == true
        remove!(set1, 1)
        @test are_disjoint(set1, set2) == true
    end

    @testset "findall" begin
        set = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), BitVector((1, 0, 1)))
        @test findall(set) == [1, 3]
    end
end
