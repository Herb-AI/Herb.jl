@testitem "MakeEqual (UniformSolver)" begin
    using HerbCore, HerbGrammar

    function create_dummy_solver(leftnode::AbstractRuleNode, rightnode::AbstractRuleNode)
        grammar = @csgrammar begin
            Number = x | 1
            Number = Number + Number
            Number = Number - Number
        end

        uniform_tree = RuleNode(4, [
            leftnode,
            RuleNode(3, [
                RuleNode(2), 
                rightnode
            ])
        ])
        solver = UniformSolver(grammar, uniform_tree)
        leftnode = get_node_at_location(solver, [1])
        rightnode = get_node_at_location(solver, [2, 2])
        return solver, leftnode, rightnode
    end

    @testset "MakeEqualSuccess" begin
        left = RuleNode(4, [RuleNode(1), RuleNode(2)])
        right = RuleNode(4, [RuleNode(1), RuleNode(2)])
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_equal!(solver, left, right) isa HerbConstraints.MakeEqualSuccess
        @test left == right
    end

    @testset "MakeEqualSuccess, with holes" begin
        left = RuleNode(4, [
            UniformHole(BitVector((1, 1, 0, 0)), []), 
            RuleNode(2)
        ])
        right = UniformHole(BitVector((0, 0, 1, 1)), [
            RuleNode(1), 
            UniformHole(BitVector((1, 1, 0, 0)), [])]
        )
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_equal!(solver, left, right) isa HerbConstraints.MakeEqualSuccess
        @test left == RuleNode(4, [RuleNode(1), RuleNode(2)])
        @test left == right
    end

    @testset "MakeEqualHardFail" begin
        left = RuleNode(4, [RuleNode(1), RuleNode(2)])
        right = RuleNode(4, [RuleNode(1), RuleNode(1)])
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_equal!(solver, left, right) isa HerbConstraints.MakeEqualHardFail
        @test left != right
    end

    @testset "MakeEqualHardFail, with holes" begin
        left = RuleNode(4, [
            UniformHole(BitVector((1, 1, 0, 0)), []), 
            RuleNode(2)
        ])
        right = RuleNode(4, [
            RuleNode(1), 
            RuleNode(1)
        ])
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_equal!(solver, left, right) isa HerbConstraints.MakeEqualHardFail
        @test left != right
    end

    @testset "MakeEqualSuccess, 1 VarNode" begin
        node = RuleNode(4, [
            UniformHole(BitVector((1, 1, 0, 0)), []), 
            RuleNode(1)
        ])
        varnode = RuleNode(4, [
            VarNode(:a), 
            RuleNode(1)
        ])
        solver, node, _ = create_dummy_solver(node, RuleNode(1))

        @test HerbConstraints.make_equal!(solver, node, varnode) isa HerbConstraints.MakeEqualSuccess
    end

    @testset "MakeEqualSuccess, 2 VarNodes" begin
        node = RuleNode(4, [
            UniformHole(BitVector((1, 1, 0, 0)), []), 
            RuleNode(1)
        ])
        varnode = RuleNode(4, [
            VarNode(:a), 
            VarNode(:a)
        ])
        solver, node, _ = create_dummy_solver(node, RuleNode(1))

        @test HerbConstraints.make_equal!(solver, node, varnode) isa HerbConstraints.MakeEqualSuccess
        @test node == RuleNode(4, [RuleNode(1), RuleNode(1)])
    end

    @testset "MakeEqualSoftFail, 2 VarNodes" begin
        node = RuleNode(4, [
            UniformHole(BitVector((1, 1, 0, 0)), []), 
            UniformHole(BitVector((1, 1, 0, 0)), [])
        ])
        varnode = RuleNode(4, [
            VarNode(:a), 
            VarNode(:a)
        ])
        solver, node, _ = create_dummy_solver(node, RuleNode(1))

        @test HerbConstraints.make_equal!(solver, node, varnode) isa HerbConstraints.MakeEqualSoftFail
    end

    @testset "MakeEqualSuccess, 1 VarNode and a hole" begin
        node = RuleNode(4, [
            UniformHole(BitVector((1, 0, 0, 0)), []), 
            UniformHole(BitVector((1, 1, 0, 0)), [])
        ])
        varnode = RuleNode(4, [
            VarNode(:a), 
            RuleNode(1)
        ])
        solver, node, _ = create_dummy_solver(node, RuleNode(1))

        @test HerbConstraints.make_equal!(solver, node, varnode) isa HerbConstraints.MakeEqualSuccess
        @test node == RuleNode(4, [RuleNode(1), RuleNode(1)])
    end

    @testset "MakeEqualSuccess, 1 RuleNode and a DomainRuleNode" begin
        node = RuleNode(4, [
            RuleNode(1), 
            RuleNode(2)
        ])
        domainrulenode = DomainRuleNode(BitVector([0, 0, 1, 1]), [
            RuleNode(1), 
            RuleNode(2)
        ])
        solver, node, _ = create_dummy_solver(node, RuleNode(1))
        
        @test HerbConstraints.make_equal!(solver, node, domainrulenode) isa HerbConstraints.MakeEqualSuccess
        @test node == RuleNode(4, [RuleNode(1), RuleNode(2)])
    end

    @testset "MakeEqualHardFail, 1 RuleNode and a DomainRuleNode" begin
        node = RuleNode(4, [
            RuleNode(1), 
            RuleNode(2)
        ])
        domainrulenode = DomainRuleNode(BitVector([0, 1, 0, 0]), [
            RuleNode(1), 
            RuleNode(1)
        ])
        solver, node, _ = create_dummy_solver(node, RuleNode(1))
        
        @test HerbConstraints.make_equal!(solver, node, domainrulenode) isa HerbConstraints.MakeEqualHardFail
        @test node != domainrulenode
    end

    @testset "MakeEqualHardFail, 1 AbstractHole and a DomainRuleNode" begin
        hole = UniformHole(BitVector([1, 0, 0, 0]), [])
        domainrulenode = DomainRuleNode(BitVector([0, 1, 0, 0]), [
            RuleNode(1), 
            RuleNode(1)
        ])

        solver, hole, _ = create_dummy_solver(hole, RuleNode(1))

        @test HerbConstraints.make_equal!(solver, hole, domainrulenode) isa HerbConstraints.MakeEqualHardFail
        @test hole != domainrulenode
    end

    @testset "MakeEqualSoftFail, DomainRuleNode's with VarNodes" begin
        node = RuleNode(4, [
            UniformHole(BitVector([1, 1, 0, 0]), []),
            UniformHole(BitVector([1, 1, 0, 0]), [])
        ])
        vardomainrulenode = DomainRuleNode(BitVector([0, 0, 0, 1]), [
            VarNode(:a), 
            VarNode(:a)
        ])

        solver, node, _ = create_dummy_solver(node, RuleNode(1))

        @test HerbConstraints.make_equal!(solver, node, vardomainrulenode) isa HerbConstraints.MakeEqualSoftFail
        @test node != vardomainrulenode
    end
end
