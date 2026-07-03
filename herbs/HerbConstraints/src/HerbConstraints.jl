module HerbConstraints

using HerbCore
using HerbGrammar
using DataStructures
using DocStringExtensions
using MLStyle
using TimerOutputs


"""
    abstract type AbstractGrammarConstraint <: AbstractConstraint

Abstract type representing all user-defined constraints.
Each grammar constraint has a related [AbstractLocalConstraint](@ref) that is responsible for propagating the constraint at a specific location in the tree.
Grammar constraints should implement `on_new_node` to post a [`AbstractLocalConstraint`](@ref) at that new node
"""
abstract type AbstractGrammarConstraint <: AbstractConstraint end

"""
    abstract type AbstractLocalConstraint <: AbstractConstraint

Abstract type representing all local constraints.
Each local constraint contains a `path` that points to a specific location in the tree at which the constraint applies.

Each local constraint should implement a [`propagate!`](@ref)-function.
Inside the [`propagate!`](@ref) function, the constraint can use the following solver functions:
- `remove!`: Elementary tree manipulation. Removes a value from a domain. (other tree manipulations are: `remove_above!`, `remove_below!`, `remove_all_but!`)
- `deactivate!`: Prevent repropagation. Call this as soon as the constraint is satisfied.
- `set_infeasible!`: Report a non-trivial inconsistency. Call this if the constraint can never be satisfied. An empty domain is considered a trivial inconsistency, such inconsistencies are already handled by tree manipulations.
- `isfeasible`: Check if the current tree is still feasible. Return from the propagate function, as soon as infeasibility is detected.
"""
abstract type AbstractLocalConstraint <: AbstractConstraint end


"""
    function get_priority(::AbstractLocalConstraint)

Used to determine which constraint to propagate first in [`fix_point!`](@ref).
Constraints with fast propagators and/or strong inference should be propagated first.
"""
function get_priority(::AbstractLocalConstraint)
    return 0
end

include("varnode.jl")
include("domainrulenode.jl")

include("solver/solver.jl")
include("solver/generic_solver/state.jl")
include("solver/generic_solver/generic_solver.jl")
include("solver/generic_solver/treemanipulations.jl")

include("solver/uniform_solver/state_manager.jl")
include("solver/uniform_solver/state_stack.jl")
include("solver/uniform_solver/state_sparse_set.jl")
include("solver/uniform_solver/state_hole.jl")
include("solver/uniform_solver/uniform_solver.jl")
include("solver/uniform_solver/uniform_treemanipulations.jl")
include("solver/domainutils.jl")

include("patternmatch.jl")
include("lessthanorequal.jl")
include("makeequal.jl")

include("localconstraints/local_forbidden.jl")
include("localconstraints/local_ordered.jl")
include("localconstraints/local_contains.jl")
include("localconstraints/local_contains_subtree.jl")
include("localconstraints/local_forbidden_sequence.jl")
include("localconstraints/local_unique.jl")

include("grammarconstraints/forbidden.jl")
include("grammarconstraints/ordered.jl")
include("grammarconstraints/contains.jl")
include("grammarconstraints/contains_subtree.jl")
include("grammarconstraints/forbidden_sequence.jl")
include("grammarconstraints/unique.jl")

# Implemented in ASPExt
function rulenode_to_ASP end
function constraint_rulenode_to_ASP end
function map_varnodes_to_asp_indices end
function enforce_varnode_equality end
function grammar_to_ASP end
function constraint_to_ASP end
function rulenode_comparisons_asp end

include("solver/asp.jl")
include("csg_annotated/csg_annotated.jl")
include("csg_annotated/process_annotated_rules.jl")
include("csg_annotated/algebraic_annotations.jl")

export
    AbstractGrammarConstraint,
    AbstractLocalConstraint, DomainRuleNode,
    VarNode,
    pattern_match,
    check_tree,

    #anotated csg grammar
    AnnotatedGrammar,

    #grammar constraints
    Forbidden,
    Ordered,
    Contains,
    ContainsSubtree,
    ForbiddenSequence,
    Unique,

    #local constraints
    LocalForbidden,
    LocalOrdered,
    LocalContains,
    LocalContainsSubtree,
    LocalForbiddenSequence,
    LocalUnique,

    #public solver functions
    GenericSolver,
    Solver,
    SolverState,
    new_state!,
    save_state!,
    load_state!,
    isfeasible,
    get_state,
    get_tree,
    get_grammar,
    get_starting_symbol,
    get_state,
    get_node_at_location,
    get_hole_at_location,
    get_max_depth,
    get_max_size,
    get_tree_size,

    #tree manipulations
    remove!,
    remove_all_but!,
    substitute!,
    remove_node!,

    #domainutils
    is_subdomain,
    partition,
    are_disjoint,
    get_intersection,

    #functions related to stateful objects
    restore!,
    StateInt,
    get_value,
    set_value!,
    increment!,
    decrement!,

    #uniform solver
    UniformSolver,

    #state fixed shaped hole
    StateHole,
    freeze_state,
    update_rule_indices!,
    ASPSolver

end # module HerbConstraints
