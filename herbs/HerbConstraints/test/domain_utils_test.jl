@testitem "Domain Utils" begin
    using HerbCore, HerbGrammar

    @testset "is_subdomain (BitVector and StateSparseSet)" begin
        #The domain represents a set of rules. In this case the domain represents the set {1, 3, 4, 5, 8}.
        #is_subdomain checks if the two provided domains form a subset relation.
        domain = BitVector((1, 0, 1, 1, 1, 0, 0, 1))

        #(BitVector, BitVector)
        @test is_subdomain(BitVector((0, 0, 0, 0, 0, 0, 0, 0)), domain) == true
        @test is_subdomain(BitVector((0, 0, 0, 1, 0, 0, 0, 0)), domain) == true
        @test is_subdomain(BitVector((1, 0, 0, 1, 0, 0, 0, 0)), domain) == true
        @test is_subdomain(BitVector((1, 0, 1, 1, 1, 0, 0, 1)), domain) == true
        @test is_subdomain(BitVector((0, 1, 0, 0, 0, 0, 0, 0)), domain) == false
        @test is_subdomain(BitVector((0, 1, 1, 0, 1, 0, 0, 1)), domain) == false
        @test is_subdomain(BitVector((1, 1, 1, 1, 1, 1, 1, 1)), domain) == false

        #(StateSparseSet, BitVector)
        @test is_subdomain(HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), BitVector((0, 0, 0, 0, 0, 0, 0, 0))), domain) == true
        @test is_subdomain(HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), BitVector((0, 0, 0, 1, 0, 0, 0, 0))), domain) == true
        @test is_subdomain(HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), BitVector((1, 0, 0, 1, 0, 0, 0, 0))), domain) == true
        @test is_subdomain(HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), BitVector((1, 0, 1, 1, 1, 0, 0, 1))), domain) == true
        @test is_subdomain(HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), BitVector((0, 1, 0, 0, 0, 0, 0, 0))), domain) == false
        @test is_subdomain(HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), BitVector((0, 1, 1, 0, 1, 0, 0, 1))), domain) == false
        @test is_subdomain(HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), BitVector((1, 1, 1, 1, 1, 1, 1, 1))), domain) == false
    end

    @testset "is_subdomain true (AbstractRuleNode)" begin
        #is_subdomain for rulenodes checks if a specific tree can be obtained by repeatedly filling in holes from the general_tree
        @test is_subdomain(RuleNode(1), Hole(BitVector((1, 1, 1))))
        @test is_subdomain(UniformHole(BitVector((1, 1, 0)), []), Hole(BitVector((1, 1, 1))))
        @test is_subdomain(UniformHole(BitVector((1, 1, 1)), []), Hole(BitVector((1, 1, 1))))
        @test is_subdomain(Hole(BitVector((1, 1, 1))), Hole(BitVector((1, 1, 1))))

        specific_tree = RuleNode(3, [
            UniformHole(BitVector((1, 1, 0)), []),
            RuleNode(3, [
                Hole(BitVector((1, 1, 1))),
                RuleNode(1)
            ])
        ])
        general_tree = UniformHole(BitVector((0, 1, 1)), [
            Hole(BitVector((1, 1, 1))),
            Hole(BitVector((1, 0, 1)))
        ])
        @test is_subdomain(specific_tree, general_tree)
    end

    @testset "is_subdomain false (AbstractRuleNode)" begin
        @test is_subdomain(RuleNode(1), Hole(BitVector((0, 1, 1)))) == false
        @test is_subdomain(UniformHole(BitVector((1, 1, 0)), []), Hole(BitVector((0, 1, 1)))) == false
        @test is_subdomain(UniformHole(BitVector((1, 1, 1)), []), Hole(BitVector((0, 1, 1)))) == false
        @test is_subdomain(Hole(BitVector((1, 1, 1))), Hole(BitVector((0, 1, 1)))) == false

        specific_tree = RuleNode(3, [
            UniformHole(BitVector((1, 1, 0)), []),
            RuleNode(2, [ # The specific_tree has a RuleNode(2) at the second child
                Hole(BitVector((1, 1, 1))),
                RuleNode(1)
            ])
        ])
        general_tree = UniformHole(BitVector((0, 1, 1)), [
            Hole(BitVector((1, 1, 1))),
            Hole(BitVector((1, 0, 1))) # RuleNode(2) is not part of this domain
        ])
        @test is_subdomain(specific_tree, general_tree) == false
    end

    @testset "is_subdomain false (AbstractRuleNode, no holes)" begin
        #the specific_tree is larger than the general_tree
        specific_tree = RuleNode(
            8,
            [
                RuleNode(5)
                RuleNode(7, [
                    RuleNode(4),
                    RuleNode(5)
                ])
            ]
        )
        general_tree = RuleNode(9)
        @test is_subdomain(specific_tree, general_tree) == false
    end

    @testset "partition" begin
        #partion groups the rules by childtypes
        g = @csgrammar begin
            A = (1)
            A = (2)
            A = (3, A)
            A = (4, A)
            A = (5, A, A)
            A = (6, A, A)
            A = (7, A, B)
            A = (8, A, B)
            B = (9)
            B = (10)
            B = (11, A, B)
            B = (12, A, B)
        end
        domains = partition(Hole(get_domain(g, :A)), g)
        @test length(domains) == 4
        @test domains[1] == BitVector((1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        @test domains[2] == BitVector((0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0))
        @test domains[3] == BitVector((0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0))
        @test domains[4] == BitVector((0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0))

        g = @cfgrammar begin
            Number = x | 1
            Number = Number + Number
            Bool = Number - Number
        end

        domains = partition(Hole(BitVector((1, 1, 1, 1))), g)
        @test length(domains) == 3
        @test domains[1] == BitVector((1, 1, 0, 0))
        @test domains[2] == BitVector((0, 0, 1, 0))
        @test domains[3] == BitVector((0, 0, 0, 1))
    end

    @testset "are_disjoint" begin
        #(BitVector, BitVector)
        @test are_disjoint(BitVector((1, 1, 1, 1)), BitVector((0, 0, 0, 0))) == true
        @test are_disjoint(BitVector((0, 1, 0, 0)), BitVector((0, 0, 1, 0))) == true
        @test are_disjoint(BitVector((1, 0, 0, 1)), BitVector((0, 0, 1, 0))) == true
        @test are_disjoint(BitVector((1, 1, 1, 1)), BitVector((0, 0, 1, 0))) == false
        @test are_disjoint(BitVector((0, 1, 0, 0)), BitVector((0, 1, 0, 0))) == false
        @test are_disjoint(BitVector((1, 0, 0, 1)), BitVector((1, 1, 0, 1))) == false

        #(BitVector, StateSparseSet)
        sss = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 4)
        remove!(sss, 1)
        @test are_disjoint(BitVector((1, 0, 0, 1)), sss) == false # [1, 0, 0, 1] and [0, 1, 1, 1] overlap
        @test are_disjoint(sss, BitVector((1, 0, 0, 1))) == false
        remove!(sss, 4)
        @test are_disjoint(BitVector((1, 0, 0, 1)), sss) == true  # [1, 0, 0, 1] and [0, 1, 1, 0] are disjoint
        @test are_disjoint(sss, BitVector((1, 0, 0, 1))) == true
    end

    @testset "get_intersection" begin
        #(BitVector, BitVector)
        @test get_intersection(BitVector((1, 1, 1, 1)), BitVector((1, 1, 1, 1))) == [1, 2, 3, 4]
        @test get_intersection(BitVector((1, 0, 0, 0)), BitVector((0, 1, 1, 1))) == Vector{Int}()
        @test get_intersection(BitVector((1, 1, 1, 0)), BitVector((0, 0, 1, 1))) == [3]
        @test get_intersection(BitVector((1, 1, 1, 1)), BitVector((0, 0, 0, 1))) == [4]
        @test get_intersection(BitVector((1, 1, 1, 1)), BitVector((0, 0, 0, 0))) == Vector{Int}()

        #(BitVector, StateSparseSet). same cases, but now one of the domains is implemented with a StateSparseSet
        sss = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 4)
        @test get_intersection(BitVector((1, 1, 1, 1)), sss) == [1, 2, 3, 4]
        @test get_intersection(sss, BitVector((1, 1, 1, 1))) == [1, 2, 3, 4]
        remove!(sss, 1)
        @test get_intersection(BitVector((1, 0, 0, 0)), sss) == Vector{Int}()
        @test get_intersection(sss, BitVector((1, 0, 0, 0))) == Vector{Int}()
        remove!(sss, 2)
        @test get_intersection(BitVector((1, 1, 1, 0)), sss) == [3]
        @test get_intersection(sss, BitVector((1, 1, 1, 0))) == [3]
        remove!(sss, 3)
        @test get_intersection(BitVector((1, 1, 1, 1)), sss) == [4]
        @test get_intersection(sss, BitVector((1, 1, 1, 1))) == [4]
        remove!(sss, 4)
        @test get_intersection(BitVector((1, 1, 1, 1)), sss) == Vector{Int}()
        @test get_intersection(sss, BitVector((1, 1, 1, 1))) == Vector{Int}()

        #(StateSparseSet, StateSparseSet)
        sss1 = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 4)
        remove!(sss1, 1)
        sss2 = HerbConstraints.StateSparseSet(HerbConstraints.StateManager(), 4)
        remove!(sss1, 3)
        intersection = get_intersection(sss1, sss2)
        @test length(intersection) == 2
        @test 2 ∈ intersection
        @test 4 ∈ intersection
    end
end
