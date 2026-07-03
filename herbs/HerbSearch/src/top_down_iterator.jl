"""
    mutable struct TopDownIterator <: ProgramIterator 

Enumerates a context-free grammar starting at [`Symbol`](@ref) `sym` with respect to the grammar up to a given depth and a given size. 
The exploration is done using the given priority function for derivations, and the expand function for discovered nodes.
Concrete iterators may overload the following methods:
- priority_function
- derivation_heuristic
- hole_heuristic
"""
abstract type TopDownIterator <: ProgramIterator end

"""
    ConstraintStyle

Abstract type representing the family of constraint styles present in Herb.

There are currently two styles, namely:

- [`HerbStyle`](@ref): The default, this corresponds to iterators that enforce
    constraints using the propagation implemented in `HerbConstraints`. 
- [`ASPStyle`](@ref): Corresponds to iterators that enforce constraints using ASP via Clingo.

See [`constraint_style`](@ref).
"""
abstract type ConstraintStyle end
struct ASPStyle <: ConstraintStyle end
struct HerbStyle <: ConstraintStyle end

"""
    constraint_style(it)

Get the constraint style of an iterator.
"""
constraint_style(::ProgramIterator) = HerbStyle()

"""
    priority_function(::TopDownIterator, g::AbstractGrammar, tree::AbstractRuleNode, parent_value::Union{Real, Tuple{Vararg{Real}}}, isrequeued::Bool)

Assigns a priority value to a `tree` that needs to be considered later in the search. Trees with the lowest priority value are considered first.

- ``: The first argument is a dispatch argument and is only used to dispatch to the correct priority function
- `g`: The grammar used for enumeration
- `tree`: The tree that is about to be stored in the priority queue
- `parent_value`: The priority value of the parent [`SolverState`](@ref)
- `isrequeued`: The same tree shape will be requeued. The next time this tree shape is considered, the `UniformSolver` will produce the next complete program deriving from this shape.
"""
function priority_function(
    ::TopDownIterator,
    g::AbstractGrammar,
    tree::AbstractRuleNode,
    parent_value::Union{Real,Tuple{Vararg{Real}}},
    isrequeued::Bool
)
    #the default priority function is the bfs priority function
    if isrequeued
        return parent_value
    end
    return parent_value + 1
end

"""
    function derivation_heuristic(::TopDownIterator, indices::Vector{Int})

Returns a sorted sublist of the `indices`, based on which rules are most promising to fill a hole.
The underlying solver can change the order within a Hole's domain. We sort the domain to make the enumeration order explicit and more predictable. 
"""
function derivation_heuristic(::TopDownIterator, indices::Vector{Int})
    return sort(indices)
end

"""
    hole_heuristic(::TopDownIterator, node::AbstractRuleNode, max_depth::Int)::Union{ExpandFailureReason, HoleReference}

Defines a heuristic over variable shaped holes. Returns a [`HoleReference`](@ref) once a hole is found.
"""
function hole_heuristic(::TopDownIterator, node::AbstractRuleNode, max_depth::Int)::Union{ExpandFailureReason,HoleReference}
    return heuristic_leftmost(node, max_depth)
end

Base.@doc """
    @programiterator RandomIterator() <: TopDownIterator

Iterates trees in the grammar in a random order.
""" RandomIterator
@programiterator RandomIterator() <: TopDownIterator

"""
    priority_function(::RandomIterator, g::AbstractGrammar, tree::AbstractRuleNode, parent_value::Union{Real, Tuple{Vararg{Real}}}, isrequeued::Bool)

Assigns a random priority to each state.
"""
function priority_function(
    ::RandomIterator,
    ::AbstractGrammar,
    ::AbstractRuleNode,
    ::Union{Real,Tuple{Vararg{Real}}},
    ::Bool
)
    Random.rand()
end

"""
    function derivation_heuristic(::RandomIterator, indices::Vector{Int})

Randomly shuffles the rules.
"""
function derivation_heuristic(::RandomIterator, indices::Vector{Int})
    return Random.shuffle!(indices)
end

"""
    AbstractBFSIterator <: TopDownIterator

This is the supertype for all breadth-first search iterators. It inherits all stop-criteria and traversal mechanisms from [`TopDownIterator`](@ref).
"""
abstract type AbstractBFSIterator <: TopDownIterator end


Base.@doc """
    @programiterator BFSIterator() <: TopDownIterator

Creates a breadth-first search iterator for traversing given a grammar, starting from the given symbol. The iterator returns trees in the grammar in increasing order of size.
""" BFSIterator
@programiterator BFSIterator() <: AbstractBFSIterator

Base.@doc """
    @programiterator BFSASPIterator() <: AbstractBFSIterator

Creates a breadth-first search iterator for traversing given a grammar,
starting from the given symbol. The iterator returns trees in the grammar in
increasing order of size.

Constraints on uniform trees are enforced in ASP, making use of Clingo.
Behavior should otherwise match that of [`AbstractBFSIterator`](@ref)s.
""" BFSASPIterator
@programiterator BFSASPIterator() <: AbstractBFSIterator
constraint_style(::BFSASPIterator) = ASPStyle()

"""
    AbstractDFSIterator <: TopDownIterator

This is the supertype for all depth-first search iterators. It inherits all stop-criteria and from [`TopDownIterator`](@ref), but the traversal mechanism is 
implemented to perform a depth-first search.
"""
abstract type AbstractDFSIterator <: TopDownIterator end


"""
    priority_function(::AbstractDFSIterator, g::AbstractGrammar, tree::AbstractRuleNode, parent_value::Union{Real, Tuple{Vararg{Real}}}, isrequeued::Bool)

Assigns priority such that the search tree is traversed like in a DFS manner. 
"""
function priority_function(
    ::AbstractDFSIterator,
    ::AbstractGrammar,
    ::AbstractRuleNode,
    parent_value::Union{Real,Tuple{Vararg{Real}}},
    isrequeued::Bool
)
    if isrequeued
        return parent_value
    end
    return parent_value - 1
end

Base.@doc """
    @programiterator DFSIterator() <: AbstractDFSIterator

Creates a depth-first search iterator for traversing a given a grammar, starting from a given symbol. The iterator returns trees in the grammar in decreasing order of size. 
""" DFSIterator
@programiterator DFSIterator() <: AbstractDFSIterator

Base.@doc """
    @programiterator DFSASPIterator() <: AbstractDFSIterator

Creates a depth-first search iterator for traversing given a grammar,
starting from the given symbol. The iterator returns trees in the grammar in
decreasing order of size.

Constraints on uniform trees are enforced in ASP, making use of Clingo.
Behavior should otherwise match that of [`AbstractDFSIterator`](@ref)s.
""" DFSASPIterator
@programiterator DFSASPIterator() <: AbstractDFSIterator
constraint_style(::DFSASPIterator) = ASPStyle()

Base.@doc """
    @programiterator MLFSIterator() <: TopDownIterator

Iterator that enumerates expressions in the grammar in decreasing order of probability (Only use this iterator with probabilistic grammars). Inherits all stop-criteria from TopDownIterator.
""" MLFSIterator
@programiterator MLFSIterator() <: TopDownIterator

"""
    priority_function(::MLFSIterator, grammar::AbstractGrammar, current_program::AbstractRuleNode, parent_value::Union{Real, Tuple{Vararg{Real}}}, isrequeued::Bool)

Calculates the priority function of the `MLFSIterator`. The priority value of a tree is then the max_rulenode_log_probability within the represented uniform tree.
The value is negated as lower priority values are popped earlier.
"""
function priority_function(
    ::MLFSIterator,
    grammar::AbstractGrammar,
    current_program::AbstractRuleNode,
    parent_value::Union{Real,Tuple{Vararg{Real}}},
    isrequeued::Bool
)
    -max_rulenode_log_probability(current_program, grammar)
end

"""
    derivation_heuristic(iter::MLFSIterator, domain::Vector{Int})

Defines `derivation_heuristic` for the iterator type `MLFSIterator`. 
Sorts the indices within a domain, that is grammar rules, by decreasing log_probabilities. 
    
This will invert the enumeration order if probabilities are equal.
"""
function derivation_heuristic(iter::MLFSIterator, domain::Vector{Int})
    log_probs = get_grammar(iter).log_probabilities
    return sort(domain, by=i -> log_probs[i], rev=true) # have highest log_probability first
end

"""
    ExpandFailureReason

Abstract type representing the different reasons why expanding a partial tree failed. 

Currently, there are two possible causes of the expansion failing:

- [`LimitReached`](@ref): The depth limit or the size limit of the partial tree would 
   be violated by the expansion
- [`AlreadyComplete`](@ref): There is no hole left in the tree, so nothing can be 
   expanded.
"""
abstract type ExpandFailureReason end
struct LimitReached <: ExpandFailureReason end
struct AlreadyComplete <: ExpandFailureReason end


"""
    function Base.collect(iter::TopDownIterator)

Return an array of all programs in the TopDownIterator. 
!!! warning
    This requires deepcopying programs from type StateHole to type RuleNode.
    If it is not needed to save all programs, iterate over the iterator manually.
"""
function Base.collect(iter::TopDownIterator)
    @warn "Collecting all programs of a TopDownIterator requires freeze_state"
    programs = Vector{RuleNode}()
    for program ∈ iter
        push!(programs, freeze_state(program))
    end
    return programs
end

"""
    Base.iterate(iter::TopDownIterator)

Describes the iteration for a given [`TopDownIterator`](@ref) over the grammar. The iteration constructs a [`PriorityQueue`](@ref) first and then prunes it propagating the active constraints. Recursively returns the result for the priority queue.
"""
function Base.iterate(iter::TopDownIterator)
    # Priority queue with `SolverState`s (for variable shaped trees) and `UniformIterator`s (for fixed shaped trees)
    pq = _init_pq(iter)

    solver = get_solver(iter)

    if isfeasible(solver)
        push!(pq, get_state(solver) => priority_function(iter, get_grammar(solver), get_tree(solver), 0, false))
    end
    return _find_next_complete_tree(get_solver(iter), pq, iter)
end

function _init_pq(iter::TopDownIterator)
    _init_pq(constraint_style(iter))
end

function _init_pq(::HerbStyle)
    return PriorityQueue{
        Union{SolverState,UniformIterator},
        Union{Real,Tuple{Vararg{Real}}}
    }()
end

function _init_pq(::ASPStyle)
    return PriorityQueue{
        Union{SolverState,UniformASPIterator},
        Union{Real,Tuple{Vararg{Real}}}
    }()
end

"""
    Base.iterate(iter::TopDownIterator, pq::DataStructures.PriorityQueue)

Describes the iteration for a given [`TopDownIterator`](@ref) and a [`PriorityQueue`](@ref) over the grammar without enqueueing new items to the priority queue. Recursively returns the result for the priority queue.
"""
function Base.iterate(iter::TopDownIterator, tup::Tuple{Vector{<:AbstractRuleNode},DataStructures.PriorityQueue})
    @timeit_debug get_solver(iter).statistics "#CompleteTrees (by FixedShapedIterator)" begin end
    # iterating over fixed shaped trees using the FixedShapedIterator
    if !isempty(tup[1])
        return (pop!(tup[1]), tup)
    end

    return _find_next_complete_tree(get_solver(iter), tup[2], iter)
end


function Base.iterate(iter::TopDownIterator, pq::DataStructures.PriorityQueue)
    @timeit_debug get_solver(iter).statistics "#CompleteTrees (by UniformSolver)" begin end
    return _find_next_complete_tree(get_solver(iter), pq, iter)
end

"""
    _find_next_complete_tree(solver::Solver, pq::PriorityQueue, iter::TopDownIterator)::Union{Tuple{RuleNode, Tuple{Vector{AbstractRuleNode}, PriorityQueue}}, Nothing}

Takes a priority queue and returns the smallest AST from the grammar it can obtain from the queue or by (repeatedly) expanding trees that are in the queue.
Returns `nothing` if there are no trees left within the depth limit.
"""
function _find_next_complete_tree(
    solver::Solver,
    pq::PriorityQueue,
    iter::TopDownIterator
)
    while length(pq) ≠ 0
        (item, priority_value) = popfirst!(pq)
        solution_or_nothing = _find_next_complete_tree(solver, pq, iter, item, priority_value)
        if !isnothing(solution_or_nothing)
            return solution_or_nothing
        end
    end
    return nothing
end

function _find_next_complete_tree(
    solver::Solver,
    pq::PriorityQueue,
    iter::TopDownIterator,
    item::AbstractUniformIterator,
    priority_value
)
    #the item is a fixed shaped solver, we should get the next solution and re-enqueue it with a new priority value
    uniform_iterator = item
    solution = next_solution!(uniform_iterator)
    if !isnothing(solution)
        push!(pq, uniform_iterator => priority_function(iter, get_grammar(solver), solution, priority_value, true))
        return (solution, pq)
    end
end

function _find_next_complete_tree(
    solver::Solver,
    pq::PriorityQueue,
    iter::TopDownIterator,
    item::SolverState,
    priority_value
)
    #the item is a solver state, we should find a variable shaped hole to branch on
    state = item
    load_state!(solver, state)

    hole_res = hole_heuristic(iter, get_tree(solver), get_max_depth(solver))
    return _decide_hole(solver, pq, iter, item, priority_value, hole_res)
end

function _decide_hole(
    solver::Solver,
    pq::PriorityQueue,
    iter::TopDownIterator,
    ::SolverState,
    priority_value,
    ::AlreadyComplete
)
    @timeit_debug get_solver(iter).statistics "#FixedShapedTrees" begin end
    # Always use the Uniform Solver
    uniform_iterator = _make_uniform_iterator(solver, iter)
    solution = next_solution!(uniform_iterator)
    if !isnothing(solution)
        push!(pq, uniform_iterator => priority_function(iter, get_grammar(solver), solution, priority_value, true))
        return (solution, pq)
    end
end

function _make_uniform_iterator(solver::Solver, iter::TopDownIterator)
    return _make_uniform_iterator(constraint_style(iter), solver, iter)
end

function _make_uniform_iterator(::HerbStyle, solver::Solver, iter::TopDownIterator)
    uniform_solver = UniformSolver(get_grammar(solver), get_tree(solver), with_statistics=solver.statistics)
    return UniformIterator(uniform_solver, iter)
end

function _make_uniform_iterator(::ASPStyle, solver::Solver, iter::TopDownIterator)
    uniform_solver = HerbConstraints.ASPSolver(get_grammar(solver), get_tree(solver), with_statistics=solver.statistics)
    return UniformASPIterator(uniform_solver, iter)
end

function _decide_hole(
    ::Solver,
    ::PriorityQueue,
    ::TopDownIterator,
    ::SolverState,
    ::Any,
    ::LimitReached
)
    # The maximum depth is reached
    return nothing
end

function _decide_hole(
    solver::Solver,
    pq::PriorityQueue,
    iter::TopDownIterator,
    ::SolverState,
    priority_value,
    hole_res::HoleReference
)
    # Variable Shaped Hole was found
    (; hole, path) = hole_res

    partitioned_domains = partition(hole, get_grammar(solver))
    number_of_domains = length(partitioned_domains)
    for (i, domain) ∈ enumerate(partitioned_domains)
        if i < number_of_domains
            state = save_state!(solver)
        end
        @assert isfeasible(solver) "Attempting to expand an infeasible tree: $(get_tree(solver))"
        remove_all_but!(solver, path, domain)
        if isfeasible(solver)
            push!(pq, get_state(solver) => priority_function(iter, get_grammar(solver), get_tree(solver), priority_value, false))
        end
        if i < number_of_domains
            load_state!(solver, state)
        end
    end
end
