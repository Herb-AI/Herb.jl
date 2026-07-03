@testset verbose=true "Forbidden Sequence" begin
    @testset "Number of candidate programs (without ignore_if)" begin

        grammar = @csgrammar begin
            S = (S, 1) | (S, 2) | (S, 3)
            S = 4
        end
        
        forbidden_sequence_constraint = ForbiddenSequence([1, 2, 3])
        iter = BFSIterator(grammar, :S, max_size=5)
        validtrees = 0
        invalid_tree_exist = false
        for p ∈ iter
            if check_tree(forbidden_sequence_constraint, p)
                validtrees += 1
            else
                invalid_tree_exist = true
            end
        end
        @test validtrees > 0
        @test invalid_tree_exist

        addconstraint!(grammar, forbidden_sequence_constraint)
        constrainted_iter = BFSIterator(grammar, :S, max_size=5)
        @test validtrees == length(constrainted_iter)
    end
end
