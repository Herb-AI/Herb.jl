@testitem "Tree Manipulations (GenericSolver)" begin
    using HerbCore, HerbGrammar

    function create_dummy_solver()
        grammar = @csgrammar begin
            Number = x | 1
            Number = Number + Number
            Number = Number - Number
        end
        return GenericSolver(grammar, :Number)
    end

    @testset "simplify_hole! Hole -> UniformHole" begin
        solver = create_dummy_solver()
        new_state!(solver, Hole(BitVector((0, 0, 1, 1))))
        #HerbConstraints.simplify_hole!(solver, Vector{Int}()) this will be done inside `new_state!`
        
        tree = get_tree(solver)
        @test tree isa UniformHole
        @test tree.domain == BitVector((0, 0, 1, 1))
        @test length(tree.children) == 2
        for child ∈ tree.children
            @test child isa Hole
            @test child.domain == BitVector((1, 1, 1, 1))
        end
    end

    @testset "simplify_hole! Hole -> RuleNode" begin
        solver = create_dummy_solver()
        new_state!(solver, Hole(BitVector((0, 0, 0, 1))))
        #HerbConstraints.simplify_hole!(solver, Vector{Int}()) this will be done inside `new_state!`
        
        tree = get_tree(solver)
        @test tree isa RuleNode
        @test tree.ind == 4
        @test length(tree.children) == 2
        for child ∈ tree.children
            @test child isa Hole
            @test child.domain == BitVector((1, 1, 1, 1))
        end
    end

    @testset "simplify_hole! UniformHole -> RuleNode" begin
        solver = create_dummy_solver()
        new_state!(solver, UniformHole(BitVector((0, 0, 0, 1)), [RuleNode(1), RuleNode(1)]))
        #HerbConstraints.simplify_hole!(solver, Vector{Int}()) this will be done inside `new_state!`
        
        tree = get_tree(solver)
        @test tree isa RuleNode
        @test tree.ind == 4
        @test length(tree.children) == 2
        for child ∈ tree.children
            @test child isa RuleNode
            @test child.ind == 1
        end
    end

    @testset "remove_node!" begin
        solver = create_dummy_solver()
        new_state!(solver, RuleNode(1, [
            RuleNode(1, [     #  | This node will be 'removed'. It will be replaced with a hole
                RuleNode(3),  #  |
                RuleNode(3)   #  |
            ]),               # _|
            RuleNode(2)
        ]))
        remove_node!(solver, [1])
        tree = get_tree(solver)
        @test tree.children[1] isa Hole
        @test tree.children[1].domain[1] == true
        @test tree.children[1].domain[2] == true
        @test tree.children[1].domain[3] == true
        @test tree.children[1].domain[4] == true
        @test tree.children[2] == RuleNode(2)
    end


    @testset "remove_all_but! (vector)" begin
        solver = create_dummy_solver()
        new_state!(solver, @rulenode Hole[1, 1, 1, 1])
        remove_all_but!(solver, Int[], [2, 3])
        node = get_tree(solver)
        @test node.domain == BitVector((0, 1, 1, 0))
    
        new_state!(solver, @rulenode Hole[1, 1, 1, 1])
        remove_all_but!(solver, Int[], [1, 2])
        node = get_tree(solver)
        @test node.domain == BitVector((1, 1, 0, 0))
    
        new_state!(solver, @rulenode Hole[1, 1, 0, 1])
        remove_all_but!(solver, Int[], [3, 4])
        node = get_tree(solver)
        @test node.ind == 4
    
        new_state!(solver, @rulenode Hole[0, 1, 0, 1])
        remove_all_but!(solver, Int[], [2, 4])
        node = get_tree(solver)
        @test node.domain == BitVector((0, 1, 0, 1))
    end
end

