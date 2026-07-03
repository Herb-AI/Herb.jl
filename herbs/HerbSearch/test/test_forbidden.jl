using HerbCore, HerbGrammar, HerbConstraints

@testset verbose=true "Forbidden" begin

    @testset "Number of candidate programs" begin
        #with constraints
        grammar = @csgrammar begin
            Number = x | 1
            Number = Number + Number
            Number = Number - Number
        end

        #without constraints
        iter = BFSIterator(grammar, :Number, max_depth=3)
        @test length(iter) == 202
        
        constraint = Forbidden(RuleNode(4, [RuleNode(1), RuleNode(1)]))
        addconstraint!(grammar, constraint)

        #with constraints
        iter = BFSIterator(grammar, :Number, max_depth=3)
        @test length(iter) == 163
    end

    @testset "Jump Start" begin
        grammar = @csgrammar begin
            Number = 1 | x
            Number = Number + Number
        end

        constraint = Forbidden(RuleNode(3, [VarNode(:x), VarNode(:x)]))
        addconstraint!(grammar, constraint)

        solver = GenericSolver(grammar, :Number, max_depth = 3)
        #jump start with new_state!
        new_state!(solver, RuleNode(3, [Hole(get_domain(grammar, :Number)), Hole(get_domain(grammar, :Number))]))
        iter = BFSIterator(solver)

        @test length(iter) == 12
        # 3{2,1}
        # 3{1,2}
        # 3{3{1,2}1}
        # 3{3{2,1}1}
        # 3{3{2,1}2}
        # 3{3{1,2}2}
        # 3{1,3{1,2}}
        # 3{2,3{1,2}}
        # 3{2,3{2,1}}
        # 3{1,3{2,1}}
        # 3{3{2,1}3{1,2}}
        # 3{3{1,2}3{2,1}}
    end

    @testset "Large Tree" begin
        grammar = @csgrammar begin
            Number = x | 1
            Number = Number + Number
            Number = Number - Number
        end

        constraint = Forbidden(RuleNode(4, [VarNode(:x), VarNode(:x)]))
        addconstraint!(grammar, constraint)

        partial_tree = RuleNode(4, [
            RuleNode(4, [
                RuleNode(3, [
                    RuleNode(1), 
                    RuleNode(1)
                ]), 
                UniformHole(BitVector((1, 1, 0, 0)), [])
            ]), 
            UniformHole(BitVector((0, 0, 1, 1)), [
                RuleNode(3, [
                    RuleNode(1), 
                    RuleNode(1)
                ]), 
                RuleNode(1)
            ]), 
        ])

        solver = GenericSolver(grammar, :Number)
        iter = BFSIterator(solver)
        new_state!(solver, partial_tree)
        @test length(iter) == 3 # 3 out of the 4 combinations to fill the UniformHole are valid
    end

    @testset "DomainRuleNode" begin
        function get_grammar1() 
            # Use 5 constraints to forbid rules 1, 2, 3, 4 and 5
            grammar = @csgrammar begin
                Int = |(1:5)
                Int = x
                Int = Int + Int
            end  
            constraint1 = Forbidden(RuleNode(1))
            constraint2 = Forbidden(RuleNode(2))
            constraint3 = Forbidden(RuleNode(3))
            constraint4 = Forbidden(RuleNode(4))
            constraint5 = Forbidden(RuleNode(5))
            addconstraint!(grammar, constraint1)
            addconstraint!(grammar, constraint2)
            addconstraint!(grammar, constraint3)
            addconstraint!(grammar, constraint4)
            addconstraint!(grammar, constraint5)
            return grammar
        end

        function get_grammar2() 
            # Use a DomainRuleNode to forbid rules 1, 2, 3, 4 and 5
            grammar = @csgrammar begin
                Int = |(1:5)
                Int = x
                Int = Int + Int
            end
            constraint_combined = Forbidden(DomainRuleNode(BitVector((1, 1, 1, 1, 1, 0, 0)), []))
            addconstraint!(grammar, constraint_combined)
            return grammar
        end
        
        iter1 = BFSIterator(get_grammar1(), :Int, max_depth=4, max_size=100)
        number_of_programs1 = length(iter1)

        iter2 = BFSIterator(get_grammar2(), :Int, max_depth=4, max_size=100)
        number_of_programs2 = length(iter2)

        @test number_of_programs1 == 26
        @test number_of_programs2 == 26
    end
end
