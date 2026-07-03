@testitem "Tree Manipulations (UniformSolver)" begin
    using HerbCore, HerbGrammar
    
    function create_dummy_solver(tree)
        grammar = @csgrammar begin
            Number = x | 1
            Number = Number + Number
            Number = Number - Number
        end
        return UniformSolver(grammar, tree)
    end

    @testset "remove_all_but! (vector)" begin
        tree = @rulenode UniformHole[1, 1, 0, 0]
        solver = create_dummy_solver(tree)
        remove_all_but!(solver, Int[], 1)
        node = get_tree(solver)
        @test collect(node.domain) == [1]

        solver = create_dummy_solver(tree)
        remove_all_but!(solver, Int[], [1, 2])
        node = get_tree(solver)
        @test collect(node.domain) == [1, 2]
    end
end

