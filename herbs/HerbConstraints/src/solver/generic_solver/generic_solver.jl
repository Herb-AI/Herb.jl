"""
    GenericSolver

Maintains a feasible partial program in a [`SolverState`](@ref). A [`ProgramIterator`](@ref) may manipulate the partial tree with the following tree manipulations:
- `substitute!`
- `remove!`
- `remove_below!`
- `remove_above!`
- `remove_all_but!`

Each [`SolverState`](@ref) holds an independent propagation program. Program iterators can freely move back and forth between states using:
- `new_state!`
- `save_state!`
- `load_state!`
"""
mutable struct GenericSolver <: Solver
    grammar::AbstractGrammar
    state::Union{SolverState, Nothing}
    schedule::PriorityQueue{AbstractLocalConstraint, Int}
    statistics::Union{TimerOutput, Nothing}
    fix_point_running::Bool
    max_size::Int
    max_depth::Int
end


"""
    GenericSolver(grammar::AbstractGrammar, sym::Symbol)

Constructs a new solver, with an initial state using starting symbol `sym`
"""
function GenericSolver(grammar::AbstractGrammar, sym::Symbol; with_statistics=false, max_size = typemax(Int), max_depth = typemax(Int))
    init_node = Hole(get_domain(grammar, sym))
    GenericSolver(grammar, init_node, with_statistics=with_statistics, max_size = max_size, max_depth = max_depth)
end


"""
    GenericSolver(grammar::AbstractGrammar, init_node::AbstractRuleNode)

Constructs a new solver, with an initial state of the provided [`AbstractRuleNode`](@ref).
"""
function GenericSolver(grammar::AbstractGrammar, init_node::AbstractRuleNode; with_statistics=false, max_size = typemax(Int), max_depth = typemax(Int))
    stats = with_statistics ? TimerOutput("Generic Solver") : nothing
    solver = GenericSolver(grammar, nothing, PriorityQueue{AbstractLocalConstraint, Int}(), stats, false, max_size, max_depth)
    new_state!(solver, init_node)
    return solver
end


get_name(::GenericSolver) = "GenericSolver"


"""
    deactivate!(solver::GenericSolver, constraint::AbstractLocalConstraint)

Function that should be called whenever the constraint is already satisfied and never has to be repropagated.
"""
function deactivate!(solver::GenericSolver, constraint::AbstractLocalConstraint)
    if constraint ∈ keys(solver.schedule)
        # remove the constraint from the schedule
        @timeit_debug solver.statistics "deactivate! removed from schedule" begin end
        delete!(solver.schedule, constraint)
    end
    if constraint ∉ get_state(solver).active_constraints
        @timeit_debug solver.statistics "deactivate! (unnecessary)" begin end
        @assert constraint ∈ get_state(solver).active_constraints "Attempted to deactivate a deactivated constraint $(constraint)"
        # This assertion error can occur if a `propagate!` function is called outside `fix_point!`
        # For example, assume that `propagate!` function is called from `post!`
        # Consider the following call stack:
        # -----------------------------------------
        #   | post!                                 # a new constraint is posted
        #       | propagate!                        # the new constraint is propagated
        #           | remove!                       # the new constraint caused the removal of rule
        #               | notify_tree_manipulation  # the new constraint is scheduled for propagation
        #               | fix_point!                # scheduled constraints are propagated
        #                   | propagate!            # the new constraint is propagated
        #                       | deactivate!       # the new constraint is satisfied and deactivated itself
        #           | deactivate!                   # the new constraint is satisfied and deactivated itself (again)
        # -----------------------------------------
        # To prevent this scenario, initial propagations are scheduled, not propagated.
        # The expected behavior is as follows:
        # -----------------------------------------
        #   | post!                                 # a new constraint is posted
        #       | schedule!                         # the new constraint is scheduled for propagation
        #   | fix_point!                            # scheduled constraints are propagated
        #       | propagate!                        # the new constraint is propagated
        #           | remove!                       # the new constraint caused the removal of rule
        #               | notify_tree_manipulation  # the new constraint is scheduled for propagation
        #               | fix_point!                # nested fix point calls are ignored (see: `fix_point_running`)
        #           | deactivate!                   # the new constraint is satisfied, deactivated itself and removed itself from the schedule
        # -----------------------------------------
    end
    delete!(get_state(solver).active_constraints, constraint)
end


"""
    post!(solver::GenericSolver, constraint::AbstractLocalConstraint)

Imposes the `constraint` to the current state.
By default, the constraint will be scheduled for its initial propagation.
Constraints can overload this method to add themselves to notify lists or triggers.
"""
function post!(solver::GenericSolver, constraint::AbstractLocalConstraint)
    if !isfeasible(solver) return end
    @timeit_debug solver.statistics "post! $(typeof(constraint))" begin end
    # add to the list of active constraints
    push!(get_state(solver).active_constraints, constraint)
    # initial propagation of the new constraint
    temp = solver.fix_point_running
    solver.fix_point_running = true
    propagate!(solver, constraint)
    solver.fix_point_running = temp
end


"""
    new_state!(solver::GenericSolver, tree::AbstractRuleNode)

Overwrites the current state and propagates constraints on the `tree` from the ground up
"""
function new_state!(solver::GenericSolver, tree::AbstractRuleNode)
    @timeit_debug solver.statistics "new_state!" begin end
    empty!(solver.schedule)
    solver.state = SolverState(tree)
    function _dfs_simplify(node::AbstractRuleNode, path::Vector{Int})
        if (node isa AbstractHole)
            simplify_hole!(solver, path)
        end
        for (i, childnode) ∈ enumerate(get_children(node))
            _dfs_simplify(childnode, push!(copy(path), i))
        end
    end
    _dfs_simplify(tree, Vector{Int}()) #try to simplify all holes in the new state. 
    tree = get_tree(solver) #the tree might have been replaced by the previous function, so we need to get the updated tree
    notify_new_nodes(solver, tree, Vector{Int}()) #notify the grammar constraints about all nodes in the new state
    fix_point!(solver)
end


"""
    save_state!(solver::GenericSolver)

Returns a copy of the current state that can be restored by calling `load_state!(solver, state)`
"""
function save_state!(solver::GenericSolver)::SolverState
    @timeit_debug solver.statistics "save_state!" begin end
    return copy(get_state(solver))
end


"""
    load_state!(solver::GenericSolver, state::SolverState)

Overwrites the current state with the given `state`
"""
function load_state!(solver::GenericSolver, state::SolverState)
    empty!(solver.schedule)
    solver.state = state
end


"""
    function get_tree_size(solver::GenericSolver)::Int

Returns the number of [`AbstractRuleNode`](@ref)s in the tree.
"""
function get_tree_size(solver::GenericSolver)::Int
    return length(get_tree(solver))
end


"""
    function get_tree(solver::GenericSolver)::AbstractRuleNode

Returns the number of [`AbstractRuleNode`](@ref)s in the tree.
"""
function get_tree(solver::GenericSolver)::AbstractRuleNode
    return solver.state.tree
end


"""
    function get_grammar(solver::GenericSolver)::AbstractGrammar

Get the grammar.
"""
function get_grammar(solver::GenericSolver)::AbstractGrammar
    return solver.grammar
end

"""
    function get_starting_symbol(solver::GenericSolver)::Symbol

Get the symbol from the solver.
"""
function get_starting_symbol(solver::GenericSolver)::Symbol
    root = get_tree(solver)
    rule = isfilled(root) ?  get_rule(root) : findfirst(root.domain)
    grammar = get_grammar(solver)
    return grammar.types[rule]
end


"""
    function get_state(solver::GenericSolver)::SolverState

Get the current [`SolverState`]@(ref) of the solver.
"""
function get_state(solver::GenericSolver)::SolverState
    return solver.state
end


"""
    function get_max_depth(solver::GenericSolver)::SolverState

Get the maximum depth of the tree.
"""
function get_max_depth(solver::GenericSolver)
    return solver.max_depth
end


"""
    function get_max_size(solver::GenericSolver)::SolverState

Get the maximum number of [`AbstractRuleNode`](@ref)s allowed inside the tree.
"""
function get_max_size(solver::GenericSolver)
    return solver.max_size
end


"""
    set_infeasible!(solver::GenericSolver)

Function to be called if any inconsistency has been detected
"""
function set_infeasible!(solver::GenericSolver)
    solver.state.isfeasible = false
end

"""
    isfeasible(solver::GenericSolver)

Returns true if no inconsistency has been detected. Used in several ways:
- Iterators should check for infeasibility to discard infeasible states
- After any tree manipulation with the possibility of an inconsistency (e.g. `remove_below!`, `remove_above!`, `remove!`)
- `fix_point!` should check for infeasibility to clear its schedule and return
- Some `GenericSolver` functions assert a feasible state for debugging purposes `@assert isfeasible(solver)`
- Some `GenericSolver` functions have a guard that skip the function on an infeasible state: `if !isfeasible(solver) return end`
"""
function isfeasible(solver::GenericSolver)
    return get_state(solver).isfeasible
end


"""
    get_path(solver::GenericSolver, node::AbstractRuleNode)

Get the path at which the `node` is located.
"""
function HerbCore.get_path(solver::GenericSolver, node::AbstractRuleNode)::Vector{Int}
    return get_path(get_tree(solver), node)
end

"""
    HerbCore.get_node_at_location(solver::GenericSolver, location::Vector{Int})::AbstractRuleNode

Get the node at path `location`.
"""
function HerbCore.get_node_at_location(solver::GenericSolver, location::Vector{Int})::AbstractRuleNode
    # dispatches the function on type `AbstractRuleNode` (defined in rulenode_operator.jl in HerbGrammar.jl)
    node = get_node_at_location(get_tree(solver), location)
    @assert !isnothing(node) "No node exists at location $location in the current state of the solver"
    return node
end

"""
    get_hole_at_location(solver::GenericSolver, location::Vector{Int})::AbstractHole

Get the node at path `location` and assert it is a [`AbstractHole`](@ref).
"""
function get_hole_at_location(solver::GenericSolver, location::Vector{Int})::AbstractHole
    hole = get_node_at_location(get_tree(solver), location)
    @assert hole isa AbstractHole "AbstractHole $hole is of non-AbstractHole type $(typeof(hole)). Tree: $(get_tree(solver)), location: $(location)"
    return hole
end


"""
    notify_tree_manipulation(solver::GenericSolver, event_path::Vector{Int})

Notify subscribed constraints that a tree manipulation has occured at the `event_path` by scheduling them for propagation
"""
function notify_tree_manipulation(solver::GenericSolver, event_path::Vector{Int})
    if !isfeasible(solver) return end
    active_constraints = get_state(solver).active_constraints
    for c ∈ active_constraints
        if shouldschedule(solver, c, event_path)
            schedule!(solver, c)
        end
    end
end


"""
    notify_new_node(solver::GenericSolver, event_path::Vector{Int})

Notify all constraints that a new node has appeared at the `event_path` by calling their respective `on_new_node` function.
!!! warning
    This does not notify the solver about nodes below the `event_path`. In that case, call [`notify_new_nodes`](@ref) instead.
"""
function notify_new_node(solver::GenericSolver, event_path::Vector{Int})
    if !isfeasible(solver) return end
    for c ∈ get_grammar(solver).constraints
        on_new_node(solver, c, event_path)
    end
end


"""
    notify_new_nodes(solver::GenericSolver, node::AbstractRuleNode, path::Vector{Int})

Notify all grammar constraints about the new `node` and its (grand)children
"""
function notify_new_nodes(solver::GenericSolver, node::AbstractRuleNode, path::Vector{Int})
    notify_new_node(solver, path)
    for (i, childnode) ∈ enumerate(get_children(node))
        notify_new_nodes(solver, childnode, push!(copy(path), i))
    end
end
