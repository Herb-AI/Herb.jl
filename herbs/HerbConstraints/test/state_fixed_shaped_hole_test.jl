@testitem "StateHole" begin
    using HerbCore
    
    @testset "convert, isfilled and get_rule" begin
        root_stateless = UniformHole(BitVector((1, 1, 0, 0, 0)), [  # domain size 2
            UniformHole(BitVector((1, 0, 0, 0, 0)), [               # domain size 1 (assigned)
                UniformHole(BitVector((0, 0, 0, 1, 0)), [])         # domain size 1 (assigned)
                RuleNode(4)                                             # remains a rulenode
            ]),
            RuleNode(5, [                                               # remains a rulenode
                UniformHole(BitVector((0, 0, 1, 1, 0)), [])         # domain size 2
            ])
        ])
        sm = HerbConstraints.StateManager()
        root = HerbConstraints.StateHole(sm, root_stateless)
        
        @test size(root.domain) == 2
        @test 1 ∈ root.domain
        @test 2 ∈ root.domain
        @test isfilled(root) == false

        node = root.children[1]
        @test size(node.domain) == 1
        @test 1 ∈ node.domain
        @test isfilled(node) == true
        @test get_rule(node) == 1
        
        node = root.children[1].children[1]
        @test size(node.domain) == 1
        @test 4 ∈ node.domain
        @test isfilled(node) == true
        @test get_rule(node) == 4

        node = root.children[1].children[2]
        @test node isa RuleNode
        @test node.ind == 4

        node = root.children[2]
        @test node isa RuleNode
        @test node.ind == 5

        node = root.children[2].children[1]
        @test size(node.domain) == 2
        @test 3 ∈ node.domain
        @test 4 ∈ node.domain
        @test isfilled(node) == false
    end

    @testset "contains_hole" begin
        root_stateless = UniformHole(BitVector((1, 1, 0, 0, 0)), [  # domain size 2
            UniformHole(BitVector((1, 0, 0, 0, 0)), [               # domain size 1 (assigned)
                UniformHole(BitVector((0, 0, 0, 1, 0)), [])         # domain size 1 (assigned)
                RuleNode(4)                                             # remains a rulenode
            ]),
            RuleNode(5, [                                               # remains a rulenode
                UniformHole(BitVector((0, 0, 1, 1, 0)), [])         # domain size 2
            ])
        ])
        sm = HerbConstraints.StateManager()
        root = HerbConstraints.StateHole(sm, root_stateless)

        @test contains_hole(root) == true
        @test contains_hole(root.children[1]) == false
        @test contains_hole(root.children[2]) == true
    end

    @testset "is_filled (empty domain)" begin
        hole = HerbConstraints.StateHole(HerbConstraints.StateManager(), UniformHole(BitVector((0, 0, 0)), []))
        @test isfilled(hole) == false
    end

    @testset "(==)" begin
        sm = HerbConstraints.StateManager()
        node = RuleNode(3, [
            RuleNode(2),
            RuleNode(1)
        ])
        statehole = StateHole(sm, node)
        @test node == statehole
        @test statehole == node
        @test statehole == StateHole(sm, node)

        node2 = RuleNode(3, [
            RuleNode(1),
            RuleNode(1)
        ])
        statehole2 = StateHole(sm, node2)
        @test node != statehole2
        @test statehole2 != node
        @test statehole != statehole2
    end

    @testset "Base.show" begin
        sm = HerbConstraints.StateManager()
        sh = StateHole(sm, UniformHole(BitVector((1, 1, 0)), [RuleNode(1), RuleNode(2)]))

        io = IOBuffer()
        Base.show(io, sh)
        @test String(take!(io)) == "statehole[{1, 2}]{1,2}"

        sh = StateHole(sm, UniformHole(BitVector((1, 1, 0)), [])) 
        
        Base.show(io, sh)
        @test String(take!(io)) == "statehole[{1, 2}]"
    end
end
