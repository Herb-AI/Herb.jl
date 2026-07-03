@testset verbose=true "Unique" begin
    @testset "Number of candidate programs" begin
        grammar = @csgrammar begin
            Int = 1
            Int = x
            Int = - Int
            Int = Int + Int
            Int = Int * Int
        end

        unique_constraint = Unique(2)
        iter = BFSIterator(grammar, :Int, max_size=5)
        validtrees = 0
        invalid_tree_exist = false
        for p ∈ iter
            if check_tree(unique_constraint, p)
                validtrees += 1
            else
                invalid_tree_exist = true
            end
        end
        @test validtrees > 0
        @test invalid_tree_exist

        addconstraint!(grammar, unique_constraint)
        constrainted_iter = BFSIterator(grammar, :Int, max_size=5)
        @test validtrees == length(constrainted_iter)
    end
end
