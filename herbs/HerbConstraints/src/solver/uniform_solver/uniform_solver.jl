"""
A DFS-based solver that uses `StateHole`s that support backtracking.
"""
mutable struct UniformSolver <: Solver
    grammar::AbstractGrammar
    sm::StateManager
    tree::Union{RuleNode, StateHole}
    path_to_node::Dict{Vector{Int}, AbstractRuleNode}
    node_to_path::Dict{AbstractRuleNode, Vector{Int}}
    isactive::Dict{AbstractLocalConstraint, StateInt}
    canceledconstraints::Set{AbstractLocalConstraint}
    isfeasible::Bool
    schedule::PriorityQueue{AbstractLocalConstraint, Int}
    fix_point_running::Bool
    statistics::Union{TimerOutput, Nothing}
end


"""
    UniformSolver(grammar::AbstractGrammar, fixed_shaped_tree::AbstractRuleNode)
"""
function UniformSolver(grammar::AbstractGrammar, fixed_shaped_tree::AbstractRuleNode; with_statistics=false)
    @assert !contains_nonuniform_hole(fixed_shaped_tree) "$(fixed_shaped_tree) contains non-uniform holes"
    sm = StateManager()
    tree = StateHole(sm, fixed_shaped_tree)
    path_to_node = Dict{Vector{Int}, AbstractRuleNode}()
    node_to_path = Dict{AbstractRuleNode, Vector{Int}}()
    isactive = Dict{AbstractLocalConstraint, StateInt}()
    canceledconstraints = Set{AbstractLocalConstraint}()
    schedule = PriorityQueue{AbstractLocalConstraint, Int}()
    fix_point_running = false
    statistics = @match with_statistics begin
        ::TimerOutput => with_statistics
        ::Bool => with_statistics ? TimerOutput("Uniform Solver") : nothing
        ::Nothing => nothing
    end
    solver = UniformSolver(grammar, sm, tree, path_to_node, node_to_path, isactive, canceledconstraints, true, schedule, fix_point_running, statistics)
    notify_new_nodes(solver, tree, Vector{Int}())
    fix_point!(solver)
    return solver
end


get_name(::UniformSolver) = "UniformSolver"


"""
    notify_new_nodes(solver::UniformSolver, node::AbstractRuleNode, path::Vector{Int})

Notify all grammar constraints about the new `node` and its (grand)children
"""
function notify_new_nodes(solver::UniformSolver, node::AbstractRuleNode, path::Vector{Int})
    solver.path_to_node[path] = node
    solver.node_to_path[node] = path
    for (i, childnode) ∈ enumerate(get_children(node))
        notify_new_nodes(solver, childnode, push!(copy(path), i))
    end
    for c ∈ get_grammar(solver).constraints
        on_new_node(solver, c, path)
    end
end


"""
    get_path(solver::UniformSolver, node::AbstractRuleNode)

Get the path at which the `node` is located.
"""
function HerbCore.get_path(solver::UniformSolver, node::AbstractRuleNode)::Vector{Int}
    return solver.node_to_path[node]
end


"""
    get_node_at_location(solver::UniformSolver, path::Vector{Int})

Get the node that is located at the provided `path`.
"""
function HerbCore.get_node_at_location(solver::UniformSolver, path::Vector{Int})
    return solver.path_to_node[path]
end


"""
    get_hole_at_location(solver::UniformSolver, path::Vector{Int})

Get the hole that is located at the provided `path`.
"""
function get_hole_at_location(solver::UniformSolver, path::Vector{Int})
    hole = solver.path_to_node[path]
    @assert hole isa StateHole
    return hole
end


"""
    get_nodes(solver)

Return an iterator over all nodes in the tree
"""
function get_nodes(solver)
    return keys(solver.node_to_path)
end


"""
    function get_grammar(solver::UniformSolver)::AbstractGrammar

Get the grammar.
"""
function get_grammar(solver::UniformSolver)::AbstractGrammar
    return solver.grammar
end


"""
    function get_tree(solver::UniformSolver)::AbstractRuleNode

Get the root of the tree. This remains the same instance throughout the entire search.
"""
function get_tree(solver::UniformSolver)::AbstractRuleNode
    return solver.tree
end


"""
    deactivate!(solver::UniformSolver, constraint::AbstractLocalConstraint)

Function that should be called whenever the constraint is already satisfied and never has to be repropagated.
"""
function deactivate!(solver::UniformSolver, constraint::AbstractLocalConstraint)
    if constraint ∈ keys(solver.schedule)
        # remove the constraint from the schedule
        @timeit_debug solver.statistics "deactivate! removed from schedule" begin end
        delete!(solver.schedule, constraint)
    end
    if constraint ∈ keys(solver.isactive)
        # the constraint was posted earlier and should be deactivated
        @timeit_debug solver.statistics "deactivate!" begin end
        set_value!(solver.isactive[constraint], 0)
        return
    end
    # the constraint is satisfied during its initial propagation
    # the constraint was not posted yet, the post should be canceled
    @timeit_debug solver.statistics "cancel post (1/2)" begin end
    push!(solver.canceledconstraints, constraint)
end


"""
    post!(solver::UniformSolver, constraint::AbstractLocalConstraint)

Post a new local constraint.
Converts the constraint to a state constraint and schedules it for propagation.
"""
function post!(solver::UniformSolver, constraint::AbstractLocalConstraint)
    if !isfeasible(solver) return end
    # initial propagation of the new constraint
    temp = solver.fix_point_running
    solver.fix_point_running = true
    propagate!(solver, constraint)
    solver.fix_point_running = temp
    if constraint ∈ solver.canceledconstraints
        # the constraint was deactivated during the initial propagation, cancel posting the constraint
        @timeit_debug solver.statistics "cancel post (2/2)" begin end
        delete!(solver.canceledconstraints, constraint)
        return
    end
    #if the was not deactivated after initial propagation, it can be added to the list of constraints
    if (constraint ∈ keys(solver.isactive))
        @assert solver.isactive[constraint] == 0 "Attempted to post a constraint that is already active: $(constraint). Please verify that the grammar does not contain duplicate constraints."
    else
        solver.isactive[constraint] = StateInt(solver.sm, 0) #initializing the state int as 0 will deactivate it on backtrack
    end
    set_value!(solver.isactive[constraint], 1)
end


"""
    notify_tree_manipulation(solver::UniformSolver, event_path::Vector{Int})

Notify subscribed constraints that a tree manipulation has occured at the `event_path` by scheduling them for propagation
"""
function notify_tree_manipulation(solver::UniformSolver, event_path::Vector{Int})
    if !isfeasible(solver) return end
    for (constraint, isactive) ∈ solver.isactive
        if get_value(isactive) == 1
            if shouldschedule(solver, constraint, event_path)
                schedule!(solver, constraint)
            end
        end
    end
end


"""
    isfeasible(solver::UniformSolver)

Returns true if no inconsistency has been detected.
"""
function isfeasible(solver::UniformSolver)
    return solver.isfeasible
end


"""
    set_infeasible!(solver::Solver)

Function to be called if any inconsistency has been detected
"""
function set_infeasible!(solver::UniformSolver)
    solver.isfeasible = false
end


"""
Save the current state of the solver, can restored using `restore!`
"""
function save_state!(solver::UniformSolver)
    @assert isfeasible(solver)
    @timeit_debug solver.statistics "save_state!" begin end
    save_state!(solver.sm)
end


"""
Restore state of the solver until the last `save_state!`
"""
function restore!(solver::UniformSolver)
    @timeit_debug solver.statistics "restore!" begin end
    restore!(solver.sm)
    solver.isfeasible = true
end

