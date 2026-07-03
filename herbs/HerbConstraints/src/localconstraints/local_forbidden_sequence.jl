"""
    LocalForbiddenSequence <: AbstractLocalConstraint

Forbids the given `sequence` of rule nodes ending at the node at the `path`.
If any of the rules in `ignore_if` appears in the sequence, the constraint is ignored.
"""
struct LocalForbiddenSequence <: AbstractLocalConstraint
    path::Vector{Int}
    sequence::Vector{Int}
    ignore_if::Vector{Int}
end

"""
    shouldschedule(::Solver, constraint::LocalForbiddenSequence, path::Vector{Int})::Bool

Return true iff the manipulation happened at or above the constraint path.
"""
function shouldschedule(::Solver, constraint::LocalForbiddenSequence, path::Vector{Int})::Bool
    return (length(constraint.path) >= length(path)) && (path== constraint.path[1:length(path)] )
end

"""
    function propagate!(solver::Solver, c::LocalForbiddenSequence)

"""
function propagate!(solver::Solver, c::LocalForbiddenSequence)
    nodes = get_nodes_on_path(get_tree(solver), c.path)
    @timeit_debug solver.statistics "LocalForbiddenSequence propagation" begin end

    # Smallest match
    forbidden_assignments = Vector{Tuple{Int, Any}}()
    i = length(c.sequence)
    for (path_idx, node) ∈ Iterators.reverse(enumerate(nodes))
        forbidden_rule = c.sequence[i]
        if (node isa RuleNode) || (node isa StateHole && isfilled(node))
            rule = get_rule(node)
            if (rule ∈ c.ignore_if)
                deactivate!(solver, c)
                @timeit_debug solver.statistics "LocalForbiddenSequence deactivate by ignore_if" begin end
                return
            elseif (rule == forbidden_rule)
                i -= 1
            end
        else
            if node.domain[forbidden_rule]
                push!(forbidden_assignments, (path_idx, forbidden_rule))
                i -= 1
            else
                for r ∈ c.ignore_if
                    if node.domain[r]
                        rules = [r for r ∈ findall(node.domain) if r ∉ c.ignore_if]
                        if !isempty(rules)
                            push!(forbidden_assignments, (path_idx, rules))
                            break
                        end
                        deactivate!(solver, c)
                        @timeit_debug solver.statistics "LocalForbiddenSequence deactivate by ignore_if" begin end
                        return
                    end
                end
            end
        end
        if i == 0
            break
        end
    end
    if i > 0
        @timeit_debug solver.statistics "LocalForbiddenSequence deactivate" begin end
        deactivate!(solver, c)
        return
    end
    if length(forbidden_assignments) == 0
        @timeit_debug solver.statistics "LocalForbiddenSequence inconsistency" begin end
        set_infeasible!(solver)
        return
    elseif length(forbidden_assignments) == 1
        path_idx, rule = forbidden_assignments[1]
        if rule isa Int
            @timeit_debug solver.statistics "LocalForbiddenSequence deduction" begin end
        else
            @timeit_debug solver.statistics "LocalForbiddenSequence deduction by ignore_if" begin end
        end
        if path_idx > length(c.path)
            deactivate!(solver, c)
        end
        remove!(solver, c.path[1:path_idx-1], rule)
        return
    end

    # Smallest match with a maximum of 1 hole (Optional, slightly stronger inference without making all possible matches) 
    i = length(c.sequence)
    forbidden_assignment = nothing
    for (path_idx, node) ∈ Iterators.reverse(enumerate(nodes))
        forbidden_rule = c.sequence[i]
        if (node isa RuleNode) || (node isa StateHole && isfilled(node))
            rule = get_rule(node)
            if (rule ∈ c.ignore_if)
                #softfail (ignore if)
                return
            elseif (rule == forbidden_rule)
                i -= 1
            end
        else
            for r ∈ c.ignore_if
                if node.domain[r]
                    #softfail (ignore if)
                    return
                end
            end
            if isnothing(forbidden_assignment)
                forbidden_assignment = (path_idx, forbidden_rule)
                i -= 1
            end
        end
        if i == 0
            break
        end
    end
    if i > 0
        return
    end
    if isnothing(forbidden_assignment)
        @timeit_debug solver.statistics "LocalForbiddenSequence inconsistency (method 2)" begin end
        set_infeasible!(solver)
        return
    end
    @timeit_debug solver.statistics "LocalForbiddenSequence deduction (method 2)" begin end
    path_idx, rule = forbidden_assignment
    if path_idx > length(c.path)
        deactivate!(solver, c)
    end
    remove!(solver, c.path[1:path_idx-1], rule)
end


"""
    function get_nodes_on_path(root::AbstractRuleNode, path::Vector{Int})::Vector{AbstractRuleNode}

Gets a list of nodes on the `path`, starting (and including) the `root`.
"""
function get_nodes_on_path(node::AbstractRuleNode, path::Vector{Int})::Vector{AbstractRuleNode}
    nodes = Vector{AbstractRuleNode}()
    push!(nodes, node)
    for i ∈ path
        node = node.children[i]
        push!(nodes, node)
    end
    return nodes
end
