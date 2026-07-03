module FrAngel

using DocStringExtensions
using Herb.HerbCore: AbstractRuleNode, AbstractGrammar, get_rule, isfilled, depth
using Herb.HerbSpecification: AbstractSpecification, Problem
using Herb.HerbSearch: ProgramIterator, evaluate
using Herb.HerbInterpret: SymbolTable
using Herb.HerbConstraints: get_grammar, freeze_state
using Herb.HerbGrammar: ContextSensitiveGrammar, grammar2symboltable, rulenode2expr,
    isterminal, iscomplete, add_rule!

@enum SynthResult optimal_program = 1 suboptimal_program = 2

struct NoProgramFoundError <: Exception
    message::String
end

"""
    $(TYPEDSIGNATURES)

Synthesize a program using the `grammar` that follows the `spec` following the method from 
["FrAngel: component-based synthesis with control structures"](https://doi.org/10.1145/3290386).

!!! note

    This implementation includes fragment mining but *excludes angelic conditions*!

Constructs an iterator of type `iterator_type`. Iteratively, collects promising programs, mines fragments from them and adds them to the grammar. 
This is then re-started with the updated grammar.

- `frangel_iterations` determines how many iterations of search are run
- `max_iterations` puts a bound on how many programs should be enumerated within one search procedure.
- `max_iteration_time` limits the time the iterator has for each search. Note that this time is only checked whenever a program is iterated and thus may take slightly longer than the given time.
```
"""
function frangel(
        iterator_type::Type{T},
        grammar::AbstractGrammar,
        starting_sym::Symbol,
        problem::Problem;
        max_iterations::Int = typemax(Int),
        frangel_iterations::Int = 3,
        max_iteration_time::Int = typemax(Int),
        kwargs...
    )::Union{AbstractRuleNode, Nothing} where {T <: ProgramIterator}
    # FrAngel config arguments

    for _ in 1:frangel_iterations
        # Gets an iterator with some limit (the low-level budget)
        iterator = iterator_type(grammar, starting_sym; kwargs...)

        # Run a budgeted search
        promising_programs,
            result_flag = get_promising_programs(
            iterator, problem; max_time = max_iteration_time,
            max_enumerations = max_iterations
        )

        if result_flag == optimal_program
            return only(promising_programs) # returns the only element
        end

        # Throw an error if no programs were found.
        if length(promising_programs) == 0
            throw(NoProgramFoundError("No promising program found for the given specification. Try exploring more programs."))
        end

        # Extract fragments
        fragments = mine_fragments(grammar, promising_programs)

        # Select fragments that should be added to the gramamr
        selected_fragments = select_fragments(fragments)

        # Modify grammar
        modify_grammar_frangel!(selected_fragments, grammar)
    end

    @warn "No solution found. Within $frangel_iterations iterations."
    return nothing
end

"""
    $(TYPEDSIGNATURES)

Decide whether to keep a program, or discard it, based on the specification.
Returns a score where score=1 yields the program immediately.
"""
function decide_frangel(
        program::AbstractRuleNode,
        problem::Problem,
        grammar::ContextSensitiveGrammar,
        symboltable::SymbolTable
    )
    expr = rulenode2expr(program, grammar)
    score = evaluate(problem, expr, symboltable, shortcircuit = false)
    return score
end

"""
    $(TYPEDSIGNATURES)

Modify the grammar based on the fragments mined from the programs kept during the `decide` step.
This function adds "Fragment_{type}" to the grammar to denote added fragments.
"""
function modify_grammar_frangel!(
        fragments::AbstractVector{<:AbstractRuleNode},
        grammar::AbstractGrammar;
        max_fragment_rules::Int = typemax(Int)
    )
    for f in fragments
        ind = get_rule(f)
        type = grammar.types[ind]
        frag_type = Symbol("Fragment_", type)

        # Add fragment_{type} to the grammar if not present yet
        if !haskey(grammar.bytype, frag_type)
            #@TODO substitute fragment rules
            add_rule!(grammar, Meta.parse("$type = $frag_type"))
        end

        expr = rulenode2expr(f, grammar)
        add_rule!(grammar, Meta.parse("$frag_type = $expr"))
    end
    return
end

"""
    $(TYPEDSIGNATURES)

Selects the smallest (fewest number of nodes) fragments from the set of mined fragments. 
`num_programs` determines how many programs should be selected.
"""
function select_smallest_fragments(
        fragments::Set{AbstractRuleNode};
        num_programs::Int = 3
    )::AbstractVector{<:AbstractRuleNode}
    sorted_nodes = sort(collect(fragments), by = x -> length(x))

    # Select the top 3 elements
    return sorted_nodes[1:min(num_programs, length(sorted_nodes))]
end

"""
    $(TYPEDSIGNATURES)

Selects the shallowest (smallest depth) fragments from the set of mined fragments. 
`num_programs` determines how many programs should be selected.
"""
function select_shallowest_fragments(
        fragments::Set{AbstractRuleNode};
        num_programs::Int = 3
    )::AbstractVector{<:AbstractRuleNode}
    sorted_nodes = sort(collect(fragments), by = x -> depth(x))

    # Select the top 3 elements
    return sorted_nodes[1:min(num_programs, length(sorted_nodes))]
end

function select_fragments(fragments::Set{AbstractRuleNode})
    return select_smallest_fragments(fragments; num_programs = 3)
end

"""
    $(TYPEDSIGNATURES)

Iterates over the solutions to find partial or full solutions.
Takes an iterator to enumerate programs. Quits when `max_time` or `max_enumerations` is reached.
If the program solves the problem, it is returned with the `optimal_program` flag.
If a program solves some of the problem (e.g. some but not all examples) it is added to the list of `promising_programs`.
The set of promising programs is returned eventually.
"""
function get_promising_programs(
        iterator::ProgramIterator,
        problem::Problem;
        max_time = typemax(Int),
        max_enumerations = typemax(Int),
        mod::Module = Main
    )::Tuple{Set{AbstractRuleNode}, SynthResult}
    start_time = time()
    grammar = get_grammar(iterator.solver)
    symboltable::SymbolTable = grammar2symboltable(grammar, mod)

    promising_programs = Set{AbstractRuleNode}()

    for (i, candidate_program) in enumerate(iterator)
        score = decide_frangel(candidate_program, problem, grammar, symboltable)

        if score == 1
            push!(promising_programs, freeze_state(candidate_program))
            return (promising_programs, optimal_program)
        elseif score > 0
            push!(promising_programs, freeze_state(candidate_program))
        end

        # Check stopping criteria
        if i > max_enumerations || time() - start_time > max_time
            break
        end
    end

    return (promising_programs, suboptimal_program)
end

"""
    $(TYPEDSIGNATURES)

Finds all the fragments from the `program` defined over the `grammar`.

The result is a set of the distinct program fragments, generated recursively by iterating over all children. A fragment is any complete subprogram of the original program.

"""
function mine_fragments(
        grammar::AbstractGrammar, program::AbstractRuleNode
    )::Set{AbstractRuleNode}
    fragments = Set{AbstractRuleNode}()
    # Push terminals as they are
    if isfilled(program) && !isterminal(grammar, program)
        # Only complete programs count are considered
        if iscomplete(grammar, program)
            push!(fragments, program)
        end
        for child in program.children
            fragments = union(fragments, mine_fragments(grammar, child))
        end
    end

    return fragments
end

"""
    $(TYPEDSIGNATURES)

Finds fragments (subprograms) of each program in `programs`.
"""
function mine_fragments(
        grammar::AbstractGrammar, programs::Set{<:AbstractRuleNode}
    )::Set{AbstractRuleNode}
    fragments = reduce(union, mine_fragments(grammar, p) for p in programs)
    fragments = setdiff(fragments, programs) # Don't include the programs themselves in the set of fragments

    return fragments
end

export
    frangel,
    decide_frangel,
    modify_grammar_frangel!,
    get_promising_programs

end
