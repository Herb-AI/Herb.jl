#Branching constraint, the `StateHole` hole must be filled with rule_index `Int`.
Branch = Tuple{StateHole, Int}

#Shared reference to an empty vector to reduce memory allocations.
NOBRANCHES = Vector{Branch}()

abstract type AbstractUniformIterator <: ProgramIterator end

"""
    mutable struct UniformIterator

Inner iterator that enumerates all candidate programs of a uniform tree.
- `solver`: the uniform solver.
- `outeriter`: outer iterator that is responsible for producing uniform trees. This field is used to dispatch on the [`derivation_heuristic`](@ref).
- `unvisited_branches`: for each search-node from the root to the current search-node, a list of unvisited branches.
- `nsolutions`: number of solutions found so far.
"""
mutable struct UniformIterator <: AbstractUniformIterator
    solver::UniformSolver
    outeriter::Union{ProgramIterator, Nothing}
    unvisited_branches::Stack{Vector{Branch}}
    stateholes::Vector{StateHole}
    nsolutions::Int
end

get_solver(iter::UniformIterator) = iter.solver

"""
    UniformIterator(solver::UniformSolver, outeriter::ProgramIterator)

Constructs a new UniformIterator that traverses solutions of the [`UniformSolver`](@ref) and is an inner iterator of an outer [`ProgramIterator`](@ref).
"""
function UniformIterator(solver::UniformSolver, outeriter::Union{ProgramIterator, Nothing})
    iter = UniformIterator(solver, outeriter, Stack{Vector{Branch}}(), Vector{StateHole}(), 0)
    if isfeasible(solver)
        # create search-branches for the root search-node
        save_state!(solver)
        set_stateholes!(iter, get_tree(solver))
        push!(iter.unvisited_branches, generate_branches(iter))
    end
    return iter
end


"""
    function set_stateholes!(iter::UniformIterator, node::Union{StateHole, RuleNode})::Vector{StateHole}

Does a dfs to retrieve all unfilled state holes in the program tree and stores them in the `stateholes` vector.
"""
function set_stateholes!(iter::UniformIterator, node::Union{StateHole, RuleNode})
    if node isa StateHole && size(node.domain) > 1
        push!(iter.stateholes, node)
    end
    for child ∈ node.children
        set_stateholes!(iter, child)
    end
end


"""
Returns a vector of disjoint branches to expand the search tree at its current state.
Example:
```
# pseudo code
Hole(domain=[2, 4, 5], children=[
    Hole(domain=[1, 6]), 
    Hole(domain=[1, 6])
])
```
If we split on the first hole, this function will create three branches.
- `(firsthole, 2)`
- `(firsthole, 4)`
- `(firsthole, 5)`
"""
function generate_branches(iter::UniformIterator)::Vector{Branch}
    #iterate over all the state holes in the tree
    for hole ∈ iter.stateholes
        #pick an unfilled state hole
        if size(hole.domain) > 1
            #skip the derivation_heuristic if the parent_iterator is not set up
            if isnothing(iter.outeriter)
                return [(hole, rule) for rule ∈ hole.domain]
            end
            #reversing is needed because we pop and consider the rightmost branch first
            return reverse!([(hole, rule) for rule ∈ derivation_heuristic(iter.outeriter, findall(hole.domain))])
        end
    end
    return NOBRANCHES
end


"""
    next_solution!(iter::UniformIterator)::Union{RuleNode, StateHole, Nothing}

Searches for the next unvisited solution.
Returns nothing if all solutions have been found already.
"""
function next_solution!(iter::UniformIterator)::Union{RuleNode, StateHole, Nothing}
    solver = get_solver(iter)
    if iter.nsolutions == 1000000 @warn "UniformSolver is iterating over more than 1000000 solutions..." end
    if iter.nsolutions > 0
        # backtrack from the previous solution
        restore!(solver)
    end
    while length(iter.unvisited_branches) > 0
        branches = first(iter.unvisited_branches)
        if length(branches) > 0
            # current depth has unvisited branches, pick a branch to explore
            (hole, rule) = pop!(branches)
            save_state!(solver)
            remove_all_but!(solver, solver.node_to_path[hole], rule)
            if isfeasible(solver)
                # generate new branches for the new search node
                branches = generate_branches(iter)
                if length(branches) == 0
                    # search node is a solution leaf node, return the solution
                    iter.nsolutions += 1
                    @timeit_debug get_solver(iter).statistics "#CompleteTrees" begin end
                    return solver.tree
                else
                    # search node is an (non-root) internal node, store the branches to visit
                    @timeit_debug get_solver(iter).statistics "#InternalSearchNodes" begin end
                    push!(iter.unvisited_branches, branches)
                end
            else
                # search node is an infeasible leaf node, backtrack
                @timeit_debug get_solver(iter).statistics "#InfeasibleTrees" begin end
                restore!(solver)
            end
        else
            # search node is an exhausted internal node, backtrack
            restore!(solver)
            pop!(iter.unvisited_branches)
        end
    end
    if iter.nsolutions == 0 && isfeasible(solver)
        _isfilledrecursive(node) = isfilled(node) && all(_isfilledrecursive(c) for c ∈ node.children)
        if _isfilledrecursive(solver.tree)
            # search node is the root and the only solution, return the solution.
            iter.nsolutions += 1
            @timeit_debug get_solver(iter).statistics "#CompleteTrees" begin end
            return solver.tree
        end
    end
    return nothing
end


"""
    Base.length(iter::UniformIterator)    

Counts and returns the number of programs without storing all the programs.
!!! warning: modifies and exhausts the iterator
"""
function Base.length(iter::UniformIterator)
    count = 0
    s = next_solution!(iter)
    while !isnothing(s)
        count += 1
        s = next_solution!(iter)
    end
    return count
end

Base.eltype(::UniformIterator) = Union{RuleNode, StateHole}

function Base.iterate(iter::UniformIterator)
    solution = next_solution!(iter)
    if !isnothing(solution)
        return solution, nothing
    end
    return nothing 
end

Base.iterate(iter::UniformIterator, _) = iterate(iter)
