using HerbCore, HerbGrammar, HerbConstraints

@testset verbose=true "ContainsSubtree" begin
    @testset "Minimal Example" begin
        grammar = @csgrammar begin
            Int = x
            Int = Int + Int
            Int = Int + Int
            Int = 1
        end
        
        constraint = ContainsSubtree(
            RuleNode(2, [
                RuleNode(1),
                RuleNode(2, [
                    RuleNode(1),
                    RuleNode(1)
                ])
            ])
        )
        
        test_constraint!(grammar, constraint, max_size=6)
    end

    @testset "1 VarNode" begin
        grammar = @csgrammar begin
            Int = x
            Int = Int + Int
            Int = Int + Int
            Int = 1
        end
        
        constraint = ContainsSubtree(
            RuleNode(2, [
                RuleNode(1),
                VarNode(:x)
            ])
        )
        
        test_constraint!(grammar, constraint, max_size=6)
    end

    @testset "2 VarNodes" begin
        grammar = @csgrammar begin
            Int = x
            Int = Int + Int
            Int = Int + Int
            Int = 1
        end
        
        constraint = ContainsSubtree(
            RuleNode(2, [
                VarNode(:x),
                VarNode(:x)
            ])
        )
        
        test_constraint!(grammar, constraint, max_size=6)
    end

    
    @testset "No StateHoles" begin
        grammar = @csgrammar begin
            Int = x
            Int = Int + Int
        end
        
        constraint = ContainsSubtree(
            RuleNode(2, [
                RuleNode(1),
                RuleNode(2, [
                    RuleNode(1),
                    RuleNode(1)
                ])
            ])
        )
        
        test_constraint!(grammar, constraint, max_size=6)
    end

    @testset "Permutations" begin
        # A grammar that represents all permutations of (1, 2, 3, 4, 5)
        grammar = @csgrammar begin
            N = |(1:5)
            Permutation = (N, N, N, N, N)
        end
        addconstraint!(grammar, ContainsSubtree(RuleNode(1)))
        addconstraint!(grammar, ContainsSubtree(RuleNode(2)))
        addconstraint!(grammar, ContainsSubtree(RuleNode(3)))
        addconstraint!(grammar, ContainsSubtree(RuleNode(4)))
        addconstraint!(grammar, ContainsSubtree(RuleNode(5)))

        # There are 5! = 120 permutations of 5 distinct elements
        iter = BFSIterator(grammar, :Permutation)
        @test length(iter) == 120
    end
end
