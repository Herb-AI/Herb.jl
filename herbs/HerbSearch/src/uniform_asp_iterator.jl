#Branching constraint, the `StateHole` hole must be filled with rule_index `Int`.
Branch = Tuple{StateHole,Int}

#Shared reference to an empty vector to reduce memory allocations.
NOBRANCHES = Vector{Branch}()

"""
    mutable struct UniformASPIterator

Inner iterator that enumerates all candidate programs of a uniform tree.
- `solver`: the ASP solver.
- `outeriter`: outer iterator that is responsible for producing uniform trees. This field is used to dispatch on the [`derivation_heuristic`](@ref).
- `unvisited_branches`: for each search-node from the root to the current search-node, a list of unvisited branches.
- `nsolutions`: number of solutions found so far.
"""
mutable struct UniformASPIterator <: AbstractUniformIterator
    solver::ASPSolver
    outeriter::Union{ProgramIterator,Nothing}
    unvisited_branches::Stack{Vector{Branch}}
    stateholes::Vector{StateHole}
    nsolutions::Int
end

"""
    UniformASPIterator(solver::ASPSolver, outeriter::ProgramIterator)

Constructs a new UniformASPIterator that traverses solutions of the [`ASPSolver`](@ref) and is an inner iterator of an outer [`ProgramIterator`](@ref).
"""
function UniformASPIterator(solver::ASPSolver, outeriter::Union{ProgramIterator,Nothing})
    iter = UniformASPIterator(solver, outeriter, Stack{Vector{Branch}}(), Vector{StateHole}(), 0)
    if isfeasible(solver)
        # create search-branches for the root search-node
        set_stateholes!(iter, get_tree(solver))
        push!(iter.unvisited_branches, generate_branches(iter))
    end
    return iter
end


"""
    function set_stateholes!(iter::UniformASPIterator, node::Union{StateHole, RuleNode})::Vector{StateHole}

Does a dfs to retrieve all unfilled state holes in the program tree and stores them in the `stateholes` vector.
"""
function set_stateholes!(iter::UniformASPIterator, node::Union{StateHole,UniformHole,RuleNode})
    if node isa StateHole && size(node.domain) > 1
        push!(iter.stateholes, node)
    end
    for child ∈ node.children
        set_stateholes!(iter, child)
    end
end


"""
    generate_branches(iter::UniformASPIterator)::Vector{Branch}

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
function generate_branches(iter::UniformASPIterator)::Vector{Branch}
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
    next_solution!(iter::UniformASPIterator)

Searches for the next unvisited solution.
Returns nothing if all solutions have been found already.
"""
function next_solution!(iter::UniformASPIterator)
    solver = iter.solver
    if length(solver.solutions) == 0
        return nothing
    else
        sol = popfirst!(solver.solutions)
        result_tree = deepcopy(get_tree(solver))
        fill_hole!(iter, result_tree, sol, 1)
        result_tree = convert_to_rulenode!(result_tree)
        return result_tree
    end
end

"""
    fill_hole!(iter::UniformASPIterator,tree::Union{RuleNode,UniformHole,StateHole}, mapping::Dict{Int64,Int64}, current_index::Int64)

Iterates through the tree, and updates the domains of UniformHoles according to the updates given in mapping (`asp_node_index => grammar_rule_index`). 

Use `current_index` to traverse through the tree and update the correct nodes.
"""
function fill_hole!(
    iter::UniformASPIterator,
    tree::AbstractRuleNode,
    mapping::Dict{Int,Int},
    current_index::Int
)::Int
    return _fill_children!(iter, tree, mapping, current_index)
end

function fill_hole!(
    iter::UniformASPIterator,
    tree::UniformHole,
    mapping::Dict{Int,Int},
    current_index::Int
)::Int
    if haskey(mapping, current_index)
        # Check if rule to be assigned exists in grammar
        if mapping[current_index] > length(iter.solver.grammar.rules)
            error("The mapping from ASP would assign a rule index ($(mapping[current_index])) that is not a valid index in the current grammar (N rules: $(length(iter.solver.grammar.rules)))")
        end
        if mapping[current_index] ∉ findall(tree.domain)
            error("The mapping would assign a rule index ($(mapping[current_index])) that is not within the current uniform hole's domain ($(tree.domain))")
        end
        tree.domain = falses(length(tree.domain))
        tree.domain[mapping[current_index]] = 1
    end

    return _fill_children!(iter, tree, mapping, current_index)
end

function _fill_children!(iter, tree, mapping, current_index)
    for child in tree.children
        current_index = fill_hole!(iter, child, mapping, current_index + 1)
    end

    return current_index
end

"""
    convert_to_rulenode(tree::AbstractRuleNode)::AbstractRuleNode
Converts an AST and replaces each hole with a filled domain (one rule is true) to a RuleNode
"""
function convert_to_rulenode!(tree::AbstractRuleNode)::AbstractRuleNode
    children = tree.children
    new_children = Vector{AbstractRuleNode}()
    for child in children
        push!(new_children, convert_to_rulenode!(child))
    end
    if tree isa UniformHole && length(findall(tree.domain)) == 1
        if length(children) > 0
            tree = RuleNode(findfirst(tree.domain), new_children)
        else
            tree = RuleNode(findfirst(tree.domain))
        end
    else
        tree.children = new_children
    end
    return tree
end

"""
    Base.length(iter::UniformASPIterator)    

Counts and returns the number of programs without storing all the programs.
!!! warning: modifies and exhausts the iterator
"""
function Base.length(iter::UniformASPIterator)
    count = 0
    s = next_solution!(iter)
    while !isnothing(s)
        count += 1
        s = next_solution!(iter)
    end
    return count
end

Base.eltype(::UniformASPIterator) = Union{RuleNode,StateHole}

function Base.iterate(iter::UniformASPIterator)
    solution = next_solution!(iter)
    if !isnothing(solution)
        return solution, nothing
    end
    return nothing
end

Base.iterate(iter::UniformASPIterator, _) = iterate(iter)
