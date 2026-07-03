"""
    remove!(solver::Solver, path::Vector{Int}, rule_index::Int)

Remove `rule_index` from the domain of the hole located at the `path`.
It is assumed the path points to a hole, otherwise an exception will be thrown.
"""
function remove!(solver::UniformSolver, path::Vector{Int}, rule_index::Int)
    #remove the rule_index from the state sparse set of the hole
    hole = get_hole_at_location(solver, path)
    if remove!(hole.domain, rule_index)
        if isempty(hole.domain)
            set_infeasible!(solver)
        end
        notify_tree_manipulation(solver, path)
        fix_point!(solver)
    end
end

"""
    remove!(solver::UniformSolver, path::Vector{Int}, rules::Vector{Int})

Remove all `rules` from the domain of the hole located at the `path`.
It is assumed the path points to a hole, otherwise an exception will be thrown.
"""
function remove!(solver::UniformSolver, path::Vector{Int}, rules::Vector{Int})
    #remove the rule_index from the state sparse set of the hole
    hole = get_hole_at_location(solver, path)
    domain_updated = false
    for rule_index ∈ rules
        if remove!(hole.domain, rule_index)
            domain_updated = true
        end
    end
    if domain_updated
        if isempty(hole.domain)
            set_infeasible!(solver)
        end
        notify_tree_manipulation(solver, path)
        fix_point!(solver)
    end
end

"""
    remove_above!(solver::UniformSolver, path::Vector{Int}, rule_index::Int)

Reduce the domain of the hole located at the `path` by removing all rules indices above `rule_index`
Example:
`rule_index` = 2. 
`hole` with domain {1, 2, 4} gets reduced to {1}
"""
function remove_above!(solver::UniformSolver, path::Vector{Int}, rule_index::Int)
    hole = get_hole_at_location(solver, path)
    if remove_above!(hole.domain, rule_index)
        if isempty(hole.domain)
            set_infeasible!(solver)
        end
        notify_tree_manipulation(solver, path)
        fix_point!(solver)
    end
end

"""
    remove_below!(solver::UniformSolver, path::Vector{Int}, rule_index::Int)

Reduce the domain of the hole located at the `path` by removing all rules indices below `rule_index`
Example:
`rule_index` = 2. 
`hole` with domain {1, 2, 4} gets reduced to {2, 4}
"""
function remove_below!(solver::UniformSolver, path::Vector{Int}, rule_index::Int)
    hole = get_hole_at_location(solver, path)
    if remove_below!(hole.domain, rule_index)
        if isempty(hole.domain)
            set_infeasible!(solver)
        end
        notify_tree_manipulation(solver, path)
        fix_point!(solver)
    end
end

"""
    remove_all_but!(solver::UniformSolver, path::Vector{Int}, rule_index::Int)

Fill in the hole located at the `path` with rule `rule_index`.
"""
function remove_all_but!(solver::UniformSolver, path::Vector{Int}, rule_index::Union{Int, Vector{Int}})
    hole = get_hole_at_location(solver, path)
    if remove_all_but!(hole.domain, rule_index)
        if isempty(hole.domain)
            set_infeasible!(solver)
        end
        notify_tree_manipulation(solver, path)
        fix_point!(solver)
    end
end
