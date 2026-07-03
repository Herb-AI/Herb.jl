"""
    remove!(solver::GenericSolver, path::Vector{Int}, rule_index::Int)

Remove `rule_index` from the domain of the hole located at the `path`.
It is assumed the path points to a hole, otherwise an exception will be thrown.
"""
function remove!(solver::GenericSolver, path::Vector{Int}, rule_index::Int)
    hole = get_hole_at_location(solver, path)
    if !hole.domain[rule_index]
        # The rule is not present in the domain, ignore the tree manipulation
        return
    end
    hole.domain[rule_index] = false
    simplify_hole!(solver, path)
    notify_tree_manipulation(solver, path)
    fix_point!(solver)
end

"""
    remove!(solver::GenericSolver, path::Vector{Int}, rules::Vector{Int})

Remove all `rules` from the domain of the hole located at the `path`.
It is assumed the path points to a hole, otherwise an exception will be thrown.
"""
function remove!(solver::GenericSolver, path::Vector{Int}, rules::Vector{Int})
    hole = get_hole_at_location(solver, path)
    domain_updated = false
    for rule_index ∈ rules
        if hole.domain[rule_index]
            domain_updated = true
            hole.domain[rule_index] = false
        end
    end
    if domain_updated
        simplify_hole!(solver, path)
        notify_tree_manipulation(solver, path)
        fix_point!(solver)
    end
end

"""
    remove_all_but!(solver::GenericSolver, path::Vector{Int}, new_domain::BitVector)

Reduce the domain of the hole located at the `path`, to the `new_domain`.
It is assumed the path points to a hole, otherwise an exception will be thrown.
It is assumed new_domain ⊆ domain. For example: [1, 0, 1, 0] ⊆ [1, 0, 1, 1]
"""
function remove_all_but!(solver::GenericSolver, path::Vector{Int}, new_domain::BitVector)
    hole = get_hole_at_location(solver, path)
    if hole.domain == new_domain @warn "'remove_all_but' was called with trivial arguments" return end
    @assert is_subdomain(new_domain, hole.domain) "($new_domain) ⊈ ($(hole.domain)) The remaining rules are required to be a subdomain of the hole to remove from"
    hole.domain = new_domain
    simplify_hole!(solver, path)
    notify_tree_manipulation(solver, path)
    fix_point!(solver)
end

"""
    remove_all_but!(solver::GenericSolver, path::Vector{Int}, rules_to_keep::Vector{Int})

Remove all rules from the domain of the hole located at the `path` except for the rules in `rules_to_keep`.
"""
function remove_all_but!(solver::GenericSolver, path::Vector{Int}, rules_indices::Vector{Int})
    hole = get_hole_at_location(solver, path)

    bit_to_keep = BitVector(falses(length(hole.domain)))
    bit_to_keep[rules_indices] .= true

    updated_domain = hole.domain .& bit_to_keep
    if hole.domain != updated_domain
        hole.domain = updated_domain
        simplify_hole!(solver, path)
        notify_tree_manipulation(solver, path)
        fix_point!(solver)
    end
end

"""
    remove_above!(solver::GenericSolver, path::Vector{Int}, rule_index::Int)

Reduce the domain of the hole located at the `path` by removing all rules indices above `rule_index`
Example:
`rule_index` = 2. 
`hole` with domain [1, 1, 0, 1] gets reduced to [1, 0, 0, 0] and gets simplified to a `RuleNode`
"""
function remove_above!(solver::GenericSolver, path::Vector{Int}, rule_index::Int)
    hole = get_hole_at_location(solver, path)
    highest_ind = findlast(hole.domain)
    if highest_ind <= rule_index
        # e.g. domain: [0, 1, 1, 1, 0, 0] rule_index: 4
        # The tree manipulation won't have any effect, ignore the tree manipulation
        return
    end
    for r ∈ rule_index+1:length(hole.domain)
        hole.domain[r] = false
    end
    simplify_hole!(solver, path)
    notify_tree_manipulation(solver, path)
    fix_point!(solver)
end

"""
    remove_below!(solver::GenericSolver, path::Vector{Int}, rule_index::Int)

Reduce the domain of the hole located at the `path` by removing all rules indices below `rule_index`
Example:
`rule_index` = 2. 
`hole` with domain [1, 1, 0, 1] gets reduced to [0, 1, 0, 1]
"""
function remove_below!(solver::GenericSolver, path::Vector{Int}, rule_index::Int)
    hole = get_hole_at_location(solver, path)
    lowest_ind = findfirst(hole.domain)
    if lowest_ind >= rule_index
        # e.g. domain: [0, 1, 0, 1, 1, 0] rule_index: 2
        # The tree manipulation won't have any effect, ignore the tree manipulation
        return
    end
    for r ∈ 1:rule_index-1
        hole.domain[r] = false
    end
    simplify_hole!(solver, path)
    notify_tree_manipulation(solver, path)
    fix_point!(solver)
end

"""
    remove_all_but!(solver::GenericSolver, path::Vector{Int}, rule_index::Int)

Fill in the hole located at the `path` with rule `rule_index`.
It is assumed the path points to a hole, otherwise an exception will be thrown.
It is assumed rule_index ∈ hole.domain.

!!! warning: If the `hole` is known to be in the current tree, the hole can be passed directly.
    The caller has to make sure that the hole instance is actually present at the provided `path`.
"""
function remove_all_but!(solver::GenericSolver, path::Vector{Int}, rule_index::Int; hole::Union{Hole, Nothing}=nothing)
    if isnothing(hole)
        hole = get_hole_at_location(solver, path)
    end
    @assert hole.domain[rule_index] "Hole $hole cannot be filled with rule $rule_index"
    if isuniform(hole)
        # no new children appear underneath
        new_node = RuleNode(rule_index, get_children(hole))
        substitute!(solver, path, new_node, is_domain_increasing=false)
    else
        # reduce the domain of the non-uniform hole and let `simplify_hole!` take care of instantiating the children correctly
        # throw("WARNING: attempted to fill a non-uniform hole (untested behavior).")
        # If you encountered this error, it means you are trying to fill a non-uniform hole, this can cause new holes to appear underneath.
        # Usually, constraints should behave differently on uniform holes and non-uniform holes.
        # If this is also the case for a newly added constraint, make sure to add an `if isuniform(hole) end` check to your propagator.
        # Before you delete this error, make sure that the caller, typically a `propagate!` function, is actually working as intended.
        # If you are sure that filling in a non-uniform hole is fine, this error can safely be deleted."
        for r ∈ 1:length(hole.domain)
            hole.domain[r] = false
        end
        hole.domain[rule_index] = true
        simplify_hole!(solver, path)
    end
end


"""
    substitute!(solver::GenericSolver, path::Vector{Int}, new_node::AbstractRuleNode; is_domain_increasing::Union{Nothing, Bool}=nothing)

Substitute the node at the `path`, with a `new_node`.
* `is_domain_increasing`: indicates if all grammar constraints should be repropagated from the ground up.
Domain increasing substitutions are substitutions that cannot be achieved by repeatedly removing values from domains.
Example of an domain increasing event: `hole[{3, 4, 5}] -> hole[{1, 2}]`.
Example of an domain decreasing event: `hole[{3, 4, 5}] -> rulenode(4, [hole[{1, 2}], rulenode(1)])`.
"""
function substitute!(solver::GenericSolver, path::Vector{Int}, new_node::AbstractRuleNode; is_domain_increasing::Union{Nothing, Bool}=nothing)
    if isempty(path)
        #replace the root
        old_node = solver.state.tree
        solver.state.tree = new_node
    else
        #replace a node in the middle of the tree
        parent = get_tree(solver)
        for i ∈ path[1:end-1]
            parent = parent.children[i]
        end
        old_node = parent.children[path[end]]
        parent.children[path[end]] = new_node
    end
    
    if (get_tree_size(solver) > get_max_size(solver)) || (length(path)+depth(new_node) > get_max_depth(solver))
        #if the tree is too large, mark it as infeasible
        set_infeasible!(solver)
        return
    end
    
    if isnothing(is_domain_increasing)
        #automatically decide if the event is domain increasing
        @timeit_debug solver.statistics "substitute! checks is_domain_increasing" begin end
        is_domain_increasing = !is_subdomain(new_node, old_node)
    end
    if is_domain_increasing
        #propagate all constraints from the ground up
        @timeit_debug solver.statistics "substitute! (domain increasing)" begin end
        new_state!(solver, get_tree(solver))
    else
        if !have_same_shape(new_node, old_node)
            #unknown locations have been added to the tree
            #let the grammar constraint post new local constraints at these new paths
            @timeit_debug solver.statistics "substitute! (domain decreasing, different shape)" begin end
            notify_new_nodes(solver, new_node, path)
        else
            @timeit_debug solver.statistics "substitute! (domain decreasing, same shape)" begin end
        end
        notify_tree_manipulation(solver, path)
        fix_point!(solver)
    end
end


"""
    function remove_node!(solver::GenericSolver, path::Vector{Int})

Remove the node at the given `path` by substituting it with a hole of the same symbol.
"""
function remove_node!(solver::GenericSolver, path::Vector{Int})
    @timeit_debug solver.statistics "remove_node!" begin end
    node = get_node_at_location(solver, path)
    @assert !(node isa Hole)
    grammar = get_grammar(solver)
    type = grammar.types[get_rule(node)]
    domain = copy(grammar.domains[type]) #must be copied, otherwise we are mutating the grammar
    substitute!(solver, path, Hole(domain), is_domain_increasing=true)
end


"""
    simplify_hole!(solver::GenericSolver, path::Vector{Int})

Takes a [Hole](@ref) and tries to simplify it to a [UniformHole](@ref) or [RuleNode](@ref).
If the domain of the hole is empty, the state will be marked as infeasible
"""
function simplify_hole!(solver::GenericSolver, path::Vector{Int})
    if !isfeasible(solver) return end
    hole = get_hole_at_location(solver, path)
    grammar = get_grammar(solver)
    new_node = nothing
    domain_size = sum(hole.domain)
    if domain_size == 0
        set_infeasible!(solver)
        return
    elseif hole isa UniformHole
        if domain_size == 1
            new_node = RuleNode(findfirst(hole.domain), hole.children)
        end
    elseif hole isa Hole
        if domain_size == 1
            child_types = grammar.childtypes[findfirst(hole.domain)]
            domains = [get_domain(grammar, type) for type ∈ child_types]
            new_children = [Hole(d) for d ∈ domains]
            new_node = RuleNode(findfirst(hole.domain), new_children)
        elseif is_subdomain(hole.domain, grammar.bychildtypes[findfirst(hole.domain)])
            child_types = grammar.childtypes[findfirst(hole.domain)]
            domains = [get_domain(grammar, type) for type ∈ child_types]
            new_children = [Hole(d) for d ∈ domains]
            new_node = UniformHole(hole.domain, new_children)
        end
    else
        @assert !isnothing(hole) "No node exists at path $path in the current state"
        @warn "Attempted to simplify node type: $(typeof(hole))"
    end

    #the hole will be simplified and replaced with a `new_node`
    if !isnothing(new_node)
        # Ideally, we should try to simplify holes with domain size of 1 here
        # before substituting. This would remove some duplicated logic when calling
        # pattern_match and lessthanorequal
        substitute!(solver, path, new_node, is_domain_increasing=false)
        for i ∈ 1:length(new_node.children)
            # try to simplify the new children
            child_path = push!(copy(path), i)
            if (new_node.children[i] isa AbstractHole)
                simplify_hole!(solver, child_path)
            end
        end
    end
end
