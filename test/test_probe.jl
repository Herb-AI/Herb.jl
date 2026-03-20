using Test

import RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

import Garden.Probe: get_promising_programs_with_fitness, modify_grammar_probe!, probe
import Herb.HerbSearch: get_costs
import Herb: @csgrammar, CostBasedBottomUpIterator, HerbCore, IOExample, Problem,
    init_probabilities!, make_interpreter, optimal_program, suboptimal_program

@testset "Probe" begin
    @testset verbose = true "Integration tests" begin
        grammar = @csgrammar begin
            Start = Int
            Int = Int + Int
            Int = |(1:2)
            Int = x
        end

        problem = Problem([IOExample(Dict{Symbol, Any}(:x => x), x + 1) for x in 1:5])

        interp = make_interpreter(
            grammar;
            input_symbols = [:x],
            target_module = @__MODULE__,
            cache_module = @__MODULE__
        )

        program,
            num_programs = probe(
            grammar,
            :Start,
            problem;
            interpret = interp,
            max_depth = 3,
            allow_errors = false
        )

        @test !isnothing(program)
        @test num_programs > 0
        @test all(interp(program, ex.in) == ex.out for ex in problem.spec)
    end

    @testset "No exact solution returns nothing" begin
        grammar = @csgrammar begin
            Start = Int
            Int = Int + Int
            Int = |(1:5)
            Int = x
        end

        impossible_problem = Problem([IOExample(Dict{Symbol, Any}(:x => x), 0) for x in 1:5])

        interp = make_interpreter(
            grammar;
            input_symbols = [:x],
            target_module = @__MODULE__,
            cache_module = @__MODULE__
        )

        program,
            num_programs = probe(
            grammar,
            :Start,
            impossible_problem;
            interpret = interp,
            max_depth = 3,
            probe_cycles = 2
        )

        @test isnothing(program)
        @test num_programs > 0
    end

    @testset "get_promising_programs_with_fitness" begin
        grammar = @csgrammar begin
            Start = Int
            Int = Int + Int
            Int = |(1:5)
            Int = x
        end

        init_probabilities!(grammar)

        # Impossible problem, 5/6 examples are easily solvable.
        problem = Problem(
            [
                [IOExample(Dict{Symbol, Any}(:x => x), x + 1) for x in 1:5];
                IOExample(Dict{Symbol, Any}(:x => 6), 0)
            ]
        )

        interp = make_interpreter(
            grammar;
            input_symbols = [:x],
            target_module = @__MODULE__,
            cache_module = @__MODULE__
        )

        iterator = CostBasedBottomUpIterator(
            grammar, :Start; current_costs = get_costs(grammar), max_depth = 3
        )

        promising_programs, result_flag,
            num_programs = get_promising_programs_with_fitness(
            iterator,
            problem,
            interp;
            max_enumerations = 100,
            allow_errors = false
        )

        @test num_programs > 0
        @test result_flag == optimal_program || result_flag == suboptimal_program
        @test !isempty(promising_programs)
        @test all(0 < fitness <= 1 for (_, fitness) in promising_programs)
    end

    @testset "modify_grammar_probe!" begin
        grammar = @csgrammar begin
            Start = Int
            Int = Int + Int
            Int = |(1:5)
            Int = x
        end

        init_probabilities!(grammar)

        program = @rulenode 2{3, 4}
        fitness = 0.9

        orig_probs = copy(grammar.log_probabilities)

        modify_grammar_probe!(Set([(program, fitness)]), grammar)

        new_probs = grammar.log_probabilities
        touched = [2, 3, 4]
        untouched = setdiff(collect(eachindex(new_probs)), touched)

        @test orig_probs != new_probs
        @test all(new_probs[i] > orig_probs[i] for i in touched)
        @test all(new_probs[i] <= orig_probs[i] for i in untouched)
    end
end
