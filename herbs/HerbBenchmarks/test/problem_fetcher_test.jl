@testitem "Problem fetcher" begin
    module Test_benchmark_default_grammar
    using HerbGrammar, HerbSpecification

    problem_1 = Problem([IOExample(Dict(:x => x), x) for x in 1:2])
    problem_2 = Problem([IOExample(Dict(:x => x), -x) for x in 1:5])

    grammar_default = @cfgrammar begin
        Real = Real + Real
        Real = -Real
        Real = x
        Real = 1
    end
    end

    module Test_benchmark_different_grammars
    using HerbGrammar, HerbSpecification

    problem_1 = Problem([IOExample(Dict(:x => x), 2x + 1) for x in 1:5])
    problem_2 = Problem([IOExample(Dict(:x => x), 2x - 1) for x in 1:1])

    grammar_1 = @cfgrammar begin
        Real = Real + Real
        Real = x
        Real = 1
    end

    grammar_2 = @cfgrammar begin
        Real = Real - Real
        Real = -Real
        Real = x
        Real = 0.5
    end
    end

    module Test_benchmark_no_grammar
    end

    @testset "Problem fetcher" begin

        @testset "Get default grammar" begin
            # Default grammar
            result1 = get_default_grammar(Test_benchmark_default_grammar)
            @test result1 == Test_benchmark_default_grammar.grammar_default

            # No grammar
            @test_throws KeyError get_default_grammar(Test_benchmark_no_grammar)
        end

        @testset "Get grammar" begin
            # Default grammar
            result1 = get_grammar(Test_benchmark_default_grammar, "1")
            @test result1 == Test_benchmark_default_grammar.grammar_default

            result2 = get_grammar(Test_benchmark_default_grammar, "2")
            @test result2 == Test_benchmark_default_grammar.grammar_default

            # Specific grammar
            result3 = get_grammar(Test_benchmark_different_grammars, "1")
            @test result3 == Test_benchmark_different_grammars.grammar_1

            result4 = get_grammar(Test_benchmark_different_grammars, "2")
            @test result4 == Test_benchmark_different_grammars.grammar_2
        end

        @testset "Get problem" begin
            result1 = get_problem(Test_benchmark_different_grammars, "1")
            @test result1 == Test_benchmark_different_grammars.problem_1

            result2 = get_problem(Test_benchmark_different_grammars, "2")
            @test result2 == Test_benchmark_different_grammars.problem_2
        end

        @testset "Get problem grammar pair" begin
            result1 = get_problem_grammar_pair(Test_benchmark_different_grammars, "1")
            @test result1.problem == Test_benchmark_different_grammars.problem_1
            @test result1.grammar == Test_benchmark_different_grammars.grammar_1
            @test result1.benchmark_name == Test_benchmark_different_grammars
            @test result1.identifier == "1"

            result2 = get_problem_grammar_pair(Test_benchmark_different_grammars, "2")
            @test result2.problem == Test_benchmark_different_grammars.problem_2
            @test result2.grammar == Test_benchmark_different_grammars.grammar_2
            @test result2.benchmark_name == Test_benchmark_different_grammars
            @test result2.identifier == "2"

            result3 = get_problem_grammar_pair(Test_benchmark_default_grammar, "1")
            @test result3.problem == Test_benchmark_default_grammar.problem_1
            @test result3.grammar == Test_benchmark_default_grammar.grammar_default
            @test result3.benchmark_name == Test_benchmark_default_grammar
            @test result3.identifier == "1"

            result4 = get_problem_grammar_pair(Test_benchmark_default_grammar, "2")
            @test result4.problem == Test_benchmark_default_grammar.problem_2
            @test result4.grammar == Test_benchmark_default_grammar.grammar_default
            @test result4.benchmark_name == Test_benchmark_default_grammar
            @test result4.identifier == "2"
        end

        @testset "Get all identifiers" begin
            result1 = get_all_identifiers(Test_benchmark_different_grammars)
            @test result1 == ["1", "2"]

            result2 = get_all_identifiers(Test_benchmark_default_grammar)
            @test result2 == ["1", "2"]
        end

        @testset "Get problem grammar pair" begin
            result1 = get_all_problem_grammar_pairs(Test_benchmark_different_grammars)
            @test result1[1].problem == Test_benchmark_different_grammars.problem_1
            @test result1[1].grammar == Test_benchmark_different_grammars.grammar_1
            @test result1[2].problem == Test_benchmark_different_grammars.problem_2
            @test result1[2].grammar == Test_benchmark_different_grammars.grammar_2

            result2 = get_all_problem_grammar_pairs(Test_benchmark_default_grammar)

            @test result2[1].problem == Test_benchmark_default_grammar.problem_1
            @test result2[1].grammar == Test_benchmark_default_grammar.grammar_default
            @test result2[2].problem == Test_benchmark_default_grammar.problem_2
            @test result2[2].grammar == Test_benchmark_default_grammar.grammar_default
        end

        @testset "Get benchmark" begin
            result1 = get_benchmark(Test_benchmark_different_grammars)
            @test result1.module_name == Test_benchmark_different_grammars
            @test result1.problem_grammar_pairs[1].problem == Test_benchmark_different_grammars.problem_1
            @test result1.problem_grammar_pairs[1].grammar == Test_benchmark_different_grammars.grammar_1
            @test result1.problem_grammar_pairs[2].problem == Test_benchmark_different_grammars.problem_2
            @test result1.problem_grammar_pairs[2].grammar == Test_benchmark_different_grammars.grammar_2

            result2 = get_benchmark(Test_benchmark_default_grammar)
            @test result2.module_name == Test_benchmark_default_grammar
            @test result2.problem_grammar_pairs[1].problem == Test_benchmark_default_grammar.problem_1
            @test result2.problem_grammar_pairs[1].grammar == Test_benchmark_default_grammar.grammar_default
            @test result2.problem_grammar_pairs[2].problem == Test_benchmark_default_grammar.problem_2
            @test result2.problem_grammar_pairs[2].grammar == Test_benchmark_default_grammar.grammar_default
        end

    end
end
