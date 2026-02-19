module Probe

using DocStringExtensions
using Garden: SynthResult, optimal_program, suboptimal_program
using Herb.HerbCore: AbstractRuleNode, AbstractGrammar, rulesoftype
using Herb.HerbGrammar: normalize!, init_probabilities!, ContextSensitiveGrammar, rulenode2expr, grammar2symboltable
using Herb.HerbSpecification: AbstractSpecification, Problem
using Herb.HerbInterpret: SymbolTable
using Herb.HerbConstraints: freeze_state, get_grammar
using Herb.HerbSearch: MLFSIterator, evaluate, ProgramIterator, log_probability


"""
    $(TYPEDSIGNATURES)

Synthesize a program using the `grammar` that follows the `spec` following the method from 
["Just-in-time learning for bottom-up enumerative synthesis"](https://doi.org/10.1145/3428295).
```
"""
function probe(
        grammar::AbstractGrammar,
        starting_sym::Symbol,
        problem::Problem;
        probe_cycles::Int = 3,
        max_iterations::Int = typemax(Int),
        max_iteration_time::Int = typemax(Int),
        kwargs...
)#::Union{AbstractRuleNode, Nothing}
    if isnothing(grammar.log_probabilities)
        init_probabilities!(grammar)
    end

    counter = 0
    for _ in 1:probe_cycles
        # Gets an iterator with some limit (the low-level budget)
        iterator = MLFSIterator(grammar, starting_sym; kwargs...)

        # Run a budgeted search
        promising_programs, result_flag, num_programs = get_promising_programs_with_fitness(
            iterator, problem; max_time = max_iteration_time,
            max_enumerations = max_iterations)
        counter += num_programs

        if result_flag == optimal_program
            @show promising_programs
            program, score = only(promising_programs) # returns the only element
            return (program, counter)
        end

        # Throw an error if no programs were found.
        if length(promising_programs) == 0
            # throw(NoProgramFoundError("No promising program found for the given specification. Try exploring more programs."))
            println("No program found.")
            return (nothing, counter)
        end

        # Update grammar probabilities 
        modify_grammar_probe!(promising_programs, grammar)
    end

    @warn "No solution found within $probe_cycles Probe iterations."
    return (nothing, counter)
end


"""
    $(TYPEDSIGNATURES)

Decide whether to keep a program, or discard it, based on the specification. 
Returns the portion of solved examples.
"""
function decide_probe(
        program::AbstractRuleNode,
        problem::Problem,
        grammar::ContextSensitiveGrammar,
        symboltable::SymbolTable)::Real
    expr = rulenode2expr(program, grammar)
    fitness = evaluate(problem, expr, symboltable, shortcircuit = false, allow_evaluation_errors=true)
    return fitness
end

"""
    $(TYPEDSIGNATURES)

Modify the grammar based on the programs kept during the `decide` step.
Takes a set of programs and their fitnesses, which describe how useful the respective program is.
Updates a rules probability based on the highest program fitness the rule occurred in. 
The update function is taken from the Probe paper. Instead of introducing a normalization value, we just call `normalize!` instead.
"""
function modify_grammar_probe!(
        saved_program_fitness::Set{Tuple{<:AbstractRuleNode, Real}},
        grammar::AbstractGrammar
)::AbstractGrammar 
    orig_probs = exp.(grammar.log_probabilities)
    
    for i in 1:length(grammar.log_probabilities)
        max_fitness = 0

        # Find maximum fitness for programs with that rule among saved programs
        for (program, fitness) in saved_program_fitness
            if !isempty(rulesoftype(program, Set(i))) && fitness > max_fitness
                max_fitness = fitness                
            end
        end

        # Update the probability according to Probe's formula
        prob = log_probability(grammar, i)
        orig_probs[i] = log(exp(prob)^(1-max_fitness))
    end
    # Normalize probabilities after the update
    normalize!(grammar)

    return grammar
end


"""
    $(TYPEDSIGNATURES)

Iterates over the solutions to find partial or full solutions.
Takes an iterator to enumerate programs. Quits when `max_time` or `max_enumerations` is reached.
If the program solves the problem, it is returned with the `optimal_program` flag.
If a program solves some of the problem (e.g. some but not all examples) it is added to the list of `promising_programs`.
The set of promising programs is returned eventually.
"""
function get_promising_programs_with_fitness(
        iterator::ProgramIterator,
        problem::Problem;
        max_time = typemax(Int),
        max_enumerations = typemax(Int),
        mod::Module = Main
)
    start_time = time()
    grammar = get_grammar(iterator.solver)
    symboltable::SymbolTable = grammar2symboltable(grammar, mod)

    promising_programs = Set{Tuple{AbstractRuleNode, Real}}()

    counter = 0
    for (i, candidate_program) in enumerate(iterator)
        counter = i
        fitness = decide_probe(candidate_program, problem, grammar, symboltable)

        if fitness == 1
            empty!(promising_programs)
            push!(promising_programs, (freeze_state(candidate_program), fitness))
            return (promising_programs, optimal_program, counter)
        elseif fitness > 0
            push!(promising_programs, (freeze_state(candidate_program), fitness))
        end

        # Check stopping criteria
        if i > max_enumerations || time() - start_time > max_time
            break
        end
    end

    return (promising_programs, suboptimal_program, counter)
end

export 
    probe, 
    decide_probe, 
    modify_grammar_probe!,
    get_promising_programs_with_fitness

end
