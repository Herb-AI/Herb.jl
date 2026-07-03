
"""
    LocalUnique <: AbstractLocalConstraint

Enforces that a given `rule` appears at or below the given `path` at most once.
In case of the UniformSolver, cache the list of `holes`, since no new holes can appear.
"""
struct LocalUnique <: AbstractLocalConstraint
	path::Vector{Int}
    rule::Int
    holes::Vector{AbstractHole}
end

LocalUnique(path::Vector{Int}, rule::Int) = LocalUnique(path, rule, Vector{AbstractHole}())

"""
    function propagate!(solver::Solver, c::LocalUnique)

Enforce that the `rule` appears at or below the `path` at least once.
Uses a helper function to retrieve a list of holes that can potentially hold the target rule.
If there is only a single hole that can potentially hold the target rule, that hole will be filled with that rule.
"""
function propagate!(solver::Solver, c::LocalUnique)
    @timeit_debug solver.statistics "LocalUnique propagation" begin end
    if (solver isa GenericSolver) | isempty(c.holes)
        empty!(c.holes)
        node = get_node_at_location(solver, c.path)
        count = _count_occurrences!(node, c.rule, c.holes)
    else
        #only search for the target rule in the cached list of holes
        count = _count_occurrences(c.holes, c.rule)
    end
    if count >= 2
        set_infeasible!(solver)
        @timeit_debug solver.statistics "LocalUnique inconsistency" begin end
    elseif count == 1
        if all(isuniform(hole) for hole ∈ c.holes)
            @timeit_debug solver.statistics "LocalUnique deactivate" begin end
            deactivate!(solver, c)
        end 
        for hole ∈ c.holes
            deductions = 0
            if (hole.domain[c.rule] == true) && !isfilled(hole)
                path = get_path(solver, hole)
                remove!(solver, path, c.rule)
                deductions += 1
                @timeit_debug solver.statistics "LocalUnique deduction" begin end
            end
        end
    end
end

"""
    function _count_occurrences!(node::AbstractRuleNode, rule::Int, holes::Vector{AbstractHole})::Int

Recursive helper function for the LocalUnique constraint.
Returns the number of certain occurrences of the rule in the tree.
All holes that potentially can hold the target rule are stored in the `holes` vector.

!!! warning: 
    Stops counting if the rule occurs more than once. 
    Counting beyond 2 is not needed for LocalUnique. 
"""
function _count_occurrences!(node::AbstractRuleNode, rule::Int, holes::Vector{AbstractHole})::Int
    count = 0
    if isfilled(node)
        # if the rulenode is the second occurence of the rule, hardfail
        if get_rule(node) == rule
            count += 1
            if count > 1
                return count
            end
        end
    else
        # if the hole contains the target rule, add the hole to the candidate list
        if !isuniform(node) || node.domain[rule] == true
            push!(holes, node)
        end
    end
    for child ∈ get_children(node)
        count += _count_occurrences!(child, rule, holes)
        if count > 1
            return count
        end
    end
    return count
end

"""
    function _count_occurrences(holes::Vector{AbstractHole}, rule::Int)

Counts the occurences of the `rule` in the cached list of `holes`.

!!! warning: 
    Stops counting if the rule occurs more than once. 
    Counting beyond 2 is not needed for LocalUnique. 
"""
function _count_occurrences(holes::Vector{AbstractHole}, rule::Int)
    count = 0
    for hole ∈ holes
        if isfilled(hole) && get_rule(hole) == rule
            count += 1
            if count >= 2
                break
            end
        end
    end
    count
end
