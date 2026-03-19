module Probe

using DocStringExtensions
using Garden: SynthResult, optimal_program, suboptimal_program
using Herb.HerbCore: AbstractRuleNode, AbstractGrammar, rulesoftype
using Herb.HerbGrammar: normalize!, init_probabilities!, ContextSensitiveGrammar,
    rulenode2expr, grammar2symboltable
using Herb.HerbSpecification: AbstractSpecification, Problem
using Herb.HerbInterpret: SymbolTable
using Herb.HerbConstraints: freeze_state, get_grammar
using Herb.HerbSearch: CostBasedBottomUpIterator, evaluate, ProgramIterator,
    log_probability, get_costs

"""
    $(TYPEDSIGNATURES)

Synthesize a program for `problem` from `grammar` using Probe
([Barke, Peleg, and Polikarpova, OOPSLA 2020](https://doi.org/10.1145/3428295)).

Probe alternates between bottom-up enumeration and grammar reweighting:

1. candidate programs are enumerated from `grammar`,
2. each candidate is evaluated on all examples in `problem`,
3. candidates with non-zero fitness are kept as *promising programs*,
4. rule probabilities are updated based on the best fitness of any promising
   program containing that rule.

This process is repeated for at most `probe_cycles` rounds.

If an exact solution is found, it is returned immediately. If no exact solution
is found within the given budgets, `nothing` is returned.

An `intrepret` function is required and must be a callable of the form

    interpret(program, input) -> output

`HerbInterpret.make_interpret` and `HerbInterpret.make_stateful_interpret` provide a standard way to generate this for a given grammar.

# Keyword Arguments
- `interpret`: callable used to execute candidate programs.
- `probe_cycles::Int=3`: maximum number of Probe reweighting rounds.
- `max_iterations::Int=typemax(Int)`: maximum number of enumerated programs
  per Probe round.
- `max_iteration_time::Int=typemax(Int)`: time budget in seconds per Probe
  round.
- `eq::Function=_outputs_match`: predicate used to compare interpreter outputs
  to expected outputs.
- `allow_errors::Bool=true`: if `true`, interpreter errors are treated as
  failed examples; otherwise they are rethrown.
- `kwargs...`: forwarded to `CostBasedBottomUpIterator`.

# Returns
A tuple `(program, total_enumerated)` where:
- `program` is the first program that satisfies all examples, or `nothing`
  if no exact solution was found;
- `num_enumerated` is the total number of candidate programs enumerated across
  all Probe rounds.
"""
function probe(
        grammar::AbstractGrammar,
        starting_sym::Symbol,
        problem::Problem;
        interpret::F,
        probe_cycles::Int = 3,
        max_iterations::Int = typemax(Int),
        max_iteration_time::Int = typemax(Int),
        eq::Function = _outputs_match,
        allow_errors::Bool = true,
        kwargs...
    ) where {F}
    if isnothing(grammar.log_probabilities)
        init_probabilities!(grammar)
    end

    total_enumerated = 0

    for _ in 1:probe_cycles
        iterator = CostBasedBottomUpIterator(
            grammar, starting_sym; current_costs = get_costs(grammar), kwargs...
        )

        promising_programs, result_flag,
            programs_enumerated = get_promising_programs_with_fitness(
            iterator, problem, interpret;
            max_time = max_iteration_time,
            max_enumerations = max_iterations,
            eq = eq,
            allow_errors = allow_errors
        )

        total_enumerated += programs_enumerated

        if result_flag == optimal_program
            program, _ = only(promising_programs)
            return program, total_enumerated
        end

        if isempty(promising_programs)
            return nothing, total_enumerated
        end

        modify_grammar_probe!(promising_programs, grammar)
    end

    @warn "No solution found within $probe_cycles Probe iterations."
    return nothing, total_enumerated
end

_outputs_match(x, y) = (x == y)

"""
    $(TYPEDSIGNATURES)

Decide whether to keep a program, or discard it, based on the specification. 
Returns the portion of solved examples.
"""
function decide_probe(
        program::AbstractRuleNode,
        problem::Problem,
        interp::F;
        eq::Function = _outputs_match,
        allow_errors::Bool = true
    ) where {F}
    solved = 0
    for ex in problem.spec
        ok = false
        if allow_errors
            try
                y = interp(program, ex.in)
                ok = eq(y, ex.out)
            catch err
                ok = false
            end
        else
            y = interp(program, ex.in)
            ok = eq(y, ex.out)
        end

        solved += ok ? 1 : 0
    end

    return solved / length(problem.spec)
end

"""
    $(TYPEDSIGNATURES)

Modify the grammar based on the programs kept during the `decide` step.
Takes a set of programs and their fitnesses, which describe how useful the respective program is.
Updates a rules probability based on the highest program fitness the rule occurred in. 
The update function is taken from the Probe paper. Instead of introducing a normalization value, we just call `normalize!` instead.
"""
function modify_grammar_probe!(
        saved_program_fitness::AbstractSet{<:Tuple{<:AbstractRuleNode, <:Real}},
        grammar::AbstractGrammar
    )
    if isnothing(grammar.log_probabilities)
        init_probabilities!(grammar)
    end

    for i in eachindex(grammar.log_probabilities)
        max_fitness = 0.0
        for (program, fitness) in saved_program_fitness
            if !isempty(rulesoftype(program, Set([i]))) && fitness > max_fitness
                max_fitness = fitness
            end
        end

        lp = log_probability(grammar, i)
        grammar.log_probabilities[i] = (1 - max_fitness) * lp
    end

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
        problem::Problem,
        interpret::F;
        max_time = typemax(Int),
        max_enumerations = typemax(Int),
        eq::Function = _outputs_match,
        allow_errors::Bool = true
    ) where {F}
    start_time = time()
    promising_programs = Set{Tuple{AbstractRuleNode, Real}}()
    programs_enumerated = 0

    for (i, candidate_program) in enumerate(iterator)
        programs_enumerated = i

        fitness = decide_probe(
            candidate_program,
            problem,
            interpret;
            eq = eq,
            allow_errors = allow_errors
        )

        if fitness == 1
            empty!(promising_programs)
            push!(promising_programs, (freeze_state(candidate_program), fitness))
            return (promising_programs, optimal_program, programs_enumerated)
        elseif fitness > 0
            push!(promising_programs, (freeze_state(candidate_program), fitness))
        end

        if i >= max_enumerations || (time() - start_time) > max_time
            break
        end
    end

    return (promising_programs, suboptimal_program, programs_enumerated)
end

end
