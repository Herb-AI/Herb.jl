@testitem "General tests on all submodules" begin
    import HerbCore: AbstractGrammar
    import HerbSpecification
    import HerbBenchmarks: Abstract_Reasoning_2019, DeepCoder_2016,
        Pixels_2020, Robots_2020, String_transformations_2020,
        PBE_BV_Track_2018, PBE_SLIA_Track_2019

    input_rules(grammar::AbstractGrammar) =
        findall(rule -> occursin("_arg_", string(rule)), grammar.rules)
    modules = [
        Abstract_Reasoning_2019,
        DeepCoder_2016,
        Pixels_2020,
        Robots_2020,
        String_transformations_2020,
        PBE_BV_Track_2018,
        PBE_SLIA_Track_2019
    ]
    @testset "Module $mod" for mod in modules
        begin
            problems = get_all_problems(mod)
            if length(problems) == 0
                continue
            end
            @testset "Inputs are well-typed" begin
                @test problems[1] isa HerbSpecification.Problem
                @test problems[1].spec[1] isa HerbSpecification.IOExample
            end

            if mod ∉ [HerbBenchmarks.String_transformations_2020,
                HerbBenchmarks.Pixels_2020,
                HerbBenchmarks.Robots_2020]

                @testset "Inputs align in grammar and problem" begin
                    pairs = get_all_problem_grammar_pairs(mod)
                    for pair in pairs
                        p, g = pair.problem, pair.grammar
                        p_args = length(p.spec[1].in)
                        g_args = length(input_rules(g))
                        # test whether 
                        @test p_args == g_args
                    end
                end
            end
        end
    end
end

