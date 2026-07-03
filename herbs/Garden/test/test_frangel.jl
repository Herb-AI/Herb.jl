using Herb.HerbGrammar: @cfgrammar, rulenode2expr
using Herb.HerbSearch: BFSIterator
using Herb.HerbSpecification: IOExample, Problem
using Herb.HerbCore: RuleNode, Hole, @rulenode
using Garden: FrAngel
using .FrAngel: frangel, mine_fragments, select_shallowest_fragments,
    select_smallest_fragments, modify_grammar_frangel!, decide_frangel,
    NoProgramFoundError

@testset verbose = true "FrAngel" begin
    @testset "Integration tests" begin
        # Define extra grammar as FrAngel will change it.
        grammar = @cfgrammar begin
            Start = Int
            Int = Int + Int
            Int = 1 | 2
        end
        problem = Problem(
            [IOExample{Symbol, Any}(Dict(), 2)]
        )
        result = frangel(
            BFSIterator,
            grammar,
            :Start,
            problem;
            max_depth = 4
        )

        @test rulenode2expr(result, grammar) == 2

        imp_problem = Problem(
            [IOExample{Symbol, Any}(Dict(), 0)]
        )

        # A program yielding 0 is impossible to derive from the grammar.
        @test_throws NoProgramFoundError frangel(
            BFSIterator, grammar, :Start, imp_problem; max_depth = 4
        )
    end

    grammar = @cfgrammar begin
        Start = Int
        Int = Int + Int
        Int = 1 | 2
    end

    @testset "mine_fragments" begin
        rn = @rulenode 2{2{3, 4}, 3}

        fragments = mine_fragments(grammar, rn)
        @test rn in fragments
        @test !((@rulenode 3) in fragments)
        @test !((@rulenode 3) in fragments)
        @test (@rulenode 2{3, 4}) in fragments

        complete = @rulenode 2{3, 4}
        rn_hole = RuleNode(
            2, [
                complete, Hole([0, 0, 1, 1]),
            ]
        )
        fragments_hole = mine_fragments(grammar, rn_hole)
        @test !(rn_hole in fragments_hole)
        @test complete in fragments_hole
    end

    @testset "select_shallowest_fragments" begin
        rn = @rulenode 2{2{2{2{3, 4}, 3}, 4}, 3}

        fragments = mine_fragments(grammar, rn)

        selected_fragments = select_shallowest_fragments(fragments; num_programs = 3)

        @test selected_fragments[1] == @rulenode 2{3, 4}
        @test selected_fragments[2] == @rulenode 2{2{3, 4}, 3}
        @test selected_fragments[3] == @rulenode 2{2{2{3, 4}, 3}, 4}
    end

    @testset "modify_grammar_frangel" begin
        fragment = @rulenode 2{3, 4}

        modify_grammar_frangel!([fragment], grammar)
        # "Int = Fragment_Int" rule exists
        @test :Fragment_Int in grammar.rules

        # "Fragment_Int" type added to grammar
        @test haskey(grammar.bytype, :Fragment_Int)
        fragment_rule_index = first(grammar.bytype[:Fragment_Int])
        # added fragment exists in a rule
        expr = rulenode2expr(fragment, grammar)
        @test grammar.rules[fragment_rule_index] == expr
    end
end
