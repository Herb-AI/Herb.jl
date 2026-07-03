using HerbCore, HerbGrammar, HerbConstraints

@testset verbose=true "Ordered" begin

    @testset "Number of candidate programs" begin
        grammar = @csgrammar begin
            Number = 1
            Number = x
            Number = Number + Number
        end
        constraint = Ordered(RuleNode(3, [
            VarNode(:a),
            VarNode(:b)
        ]), [:a, :b])
        test_constraint!(grammar, constraint, max_size=6)

        grammar = @csgrammar begin
            Number = Number + Number
            Number = 1
            Number = -Number
            Number = x
        end
        constraint = Ordered(RuleNode(1, [
            RuleNode(3, [VarNode(:a)]) ,
            RuleNode(3, [VarNode(:b)])
        ]), [:a, :b])
        test_constraint!(grammar, constraint, max_size=6)
    end

    @testset "DomainRuleNode" begin
        #Expressing commutativity of + and * in 2 constraints
        grammar = @csgrammar begin
            Number = 1
            Number = x
            Number = Number + Number
            Number = Number * Number
        end
        constraint1 = Ordered(RuleNode(3, [
            VarNode(:a),
            VarNode(:b)
        ]), [:a, :b])
        constraint2 = Ordered(RuleNode(4, [
            VarNode(:a),
            VarNode(:b)
        ]), [:a, :b])
        addconstraint!(grammar, constraint1)
        addconstraint!(grammar, constraint2)
        
        #Expressing commutativity of + and * using a single constraint (with a DomainRuleNode)
        grammar_domainrulenode = @csgrammar begin
            Number = 1
            Number = x
            Number = Number + Number
            Number = Number - Number
        end
        constraint_domainrulenode = Ordered(DomainRuleNode(BitVector((0, 0, 1, 1)), [
            VarNode(:a),
            VarNode(:b)
        ]), [:a, :b])
        addconstraint!(grammar_domainrulenode, constraint_domainrulenode)
        
        #The number of solutions should be equal in both approaches
        iter = BFSIterator(grammar, :Number, max_size=6)
        iter_domainrulenode = BFSIterator(grammar_domainrulenode, :Number, max_size=6)
        @test length(iter) == length(iter_domainrulenode)
    end

    @testset "4 symbols" begin
        grammar = @csgrammar begin
            V = |(1:2)
            S = (V, V, V, V)
        end
        
        constraint = Ordered(
            RuleNode(3, [
                VarNode(:a),
                VarNode(:b),
                VarNode(:c),
                VarNode(:d)
            ]),
            [:a, :b, :c, :d]
        )
        
        addconstraint!(grammar, constraint)
        
        solver = GenericSolver(grammar, :S)
        iter = BFSIterator(solver)

        # (1, 1, 1, 1)
        # (1, 1, 1, 2)
        # (1, 1, 2, 2)
        # (1, 2, 2, 2)
        # (2, 2, 2, 2)
        @test length(iter) == 5
    end

    @testset "(a, b) and (b, a)" begin
        grammar = @csgrammar begin
            S = (S, S)
            S = |(1:2)
        end
        
        constraint1 = Ordered(
            RuleNode(1, [
                VarNode(:a),
                VarNode(:b),
            ]),
            [:a, :b]
        )
        
        constraint2 = Ordered(
            RuleNode(1, [
                VarNode(:a),
                VarNode(:b),
            ]),
            [:b, :a]
        )
        
        addconstraint!(grammar, constraint1)
        addconstraint!(grammar, constraint2)
        iter = BFSIterator(grammar, :S, max_depth=5)
        
        # 2x a
        # 2x (a, a)
        # 2x ((a, a), (a, a))
        # 2x (((a, a), (a, a)), ((a, a), (a, a)))
        # 2x ((((a, a), (a, a)), ((a, a), (a, a))), (((a, a), (a, a)), ((a, a), (a, a))))
        @test length(iter)  == 10
    end
end
