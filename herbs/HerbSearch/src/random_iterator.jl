function rand_with_constraints!(solver::Solver,path::Vector{Int})
    skeleton = get_node_at_location(solver,path)
    grammar = get_grammar(solver)
    @info "The maximum depth is $(get_max_depth(solver) - length(path)). $(get_max_depth(solver))"
    return _rand_with_constraints!(skeleton,solver, path, mindepth_map(grammar), get_max_depth(solver))
end

function _rand_with_constraints!(skeleton::RuleNode,solver::Solver,path::Vector{Int},dmap::AbstractVector{Int}, remaining_depth::Int=10) 
    @info "The depth RuleNode left: $remaining_depth"

    for (i,child) ∈ enumerate(skeleton.children)
        push!(path,i)
        _rand_with_constraints!(child,solver,path, dmap, remaining_depth - 1)
        pop!(path)
    end
    return get_tree(solver)
end

function _rand_with_constraints!(hole::AbstractHole,solver::Solver,path::Vector{Int},dmap::AbstractVector{Int}, remaining_depth::Int=10) 
    @info "The depth hole left: $remaining_depth"

    hole = get_hole_at_location(solver, path)

    # TODO : probabilistic grammars support
    filtered_rules = filter(r->dmap[r] ≤ remaining_depth, findall(hole.domain))
    state = save_state!(solver)
    @assert !isfilled(hole)

    shuffle!(filtered_rules)
    found_feasable = false
    for rule_index ∈ filtered_rules
        remove_all_but!(solver,path,rule_index)
        if isfeasible(solver)
            found_feasable = true
            break
        end
        load_state!(solver,state)
        state = save_state!(solver)
    end

    if !found_feasable
        error("rand with constraints failed because there are no feasible rules to use")
    end

    subtree = get_node_at_location(solver, path)
    for (i,child) ∈ enumerate(subtree.children)
        push!(path,i)
        _rand_with_constraints!(child,solver,path, dmap, remaining_depth - 1)
        pop!(path)
    end
    return get_tree(solver)
end


@programiterator RandomSearchIterator(
    path::Vector{Int} = Vector{Int}()
    # TODO: Maybe limit number of iterations
)

Base.IteratorSize(::RandomSearchIterator) = Base.SizeUnknown()
Base.eltype(::RandomSearchIterator) = RuleNode

function Base.iterate(iter::RandomSearchIterator)
    solver_state = save_state!(get_solver(iter)) #TODO: if this is the last iteration, don't save the state
    return rand_with_constraints!(get_solver(iter), iter.path), solver_state
end

function Base.iterate(iter::RandomSearchIterator, solver_state::SolverState)
    load_state!(get_solver(iter), solver_state)
    solver_state = save_state!(get_solver(iter)) #TODO: if this is the last iteration, don't save the state
    return rand_with_constraints!(get_solver(iter), iter.path), solver_state
end
