"""
    ContainsSubtree <: AbstractGrammarConstraint

This [`AbstractGrammarConstraint`] enforces that a given `subtree` appears in the program tree at least once.

!!! warning:
    This constraint can only be propagated by the UniformSolver
"""
struct ContainsSubtree <: AbstractGrammarConstraint
    tree::AbstractRuleNode
end

function on_new_node(solver::UniformSolver, c::ContainsSubtree, path::Vector{Int})
    if length(path) == 0
        post!(solver, LocalContainsSubtree(path, c.tree, nothing, nothing))
    end
end

function on_new_node(::GenericSolver, ::ContainsSubtree, ::Vector{Int}) end

"""
    check_tree(c::ContainsSubtree, tree::AbstractRuleNode)::Bool

Checks if the given [`AbstractRuleNode`](@ref) tree abides the [`ContainsSubtree`](@ref) constraint.
"""
function check_tree(c::ContainsSubtree, tree::AbstractRuleNode)::Bool
    if pattern_match(c.tree, tree) isa PatternMatchSuccess
        return true
    end
    return any(check_tree(c, child) for child ∈ get_children(tree))
end

"""
	update_rule_indices!(c::ContainsSubtree, n_rules::Integer)

Updates the `ContainsSubtree` constraint to reflect grammar changes by calling `HerbCore.update_rule_indices!` on its `tree` field.

# Arguments
- `c`: The `ContainsSubtree` constraint to be updated
- `n_rules`: The new number of rules in the grammar
"""
function HerbCore.update_rule_indices!(
    c::ContainsSubtree,
    n_rules::Integer,
)
    HerbCore.update_rule_indices!(c.tree, n_rules)
end

"""
	update_rule_indices!(c::ContainsSubtree, grammar::AbstractGrammar)

Updates the `ContainsSubtree` constraint to reflect grammar changes by calling `HerbCore.update_rule_indices!` on its `tree` field.

# Arguments
- `c`: The `ContainsSubtree` constraint to be updated
- `grammar`: The grammar that changed
"""
function HerbCore.update_rule_indices!(
    c::ContainsSubtree,
    grammar::AbstractGrammar,
)
    HerbCore.update_rule_indices!(c, length(grammar.rules))
end

"""
	update_rule_indices!(c::ContainsSubtree, n_rules::Integer, mapping::AbstractDict{<:Integer, <:Integer}, ::Vector{<:AbstractConstraint})

Updates the `ContainsSubtree` constraint to reflect grammar changes by calling `HerbCore.update_rule_indices!` on its `tree` field.

# Arguments
- `c`: The `ContainsSubtree` to be updated
- `n_rules`: The new number of rules in the grammar
- `mapping`: Dictionary mapping old rule indices to new rule indices
"""
function HerbCore.update_rule_indices!(
    c::ContainsSubtree,
    n_rules::Integer,
    mapping::AbstractDict{<:Integer,<:Integer},
    ::Vector{<:AbstractConstraint}
)
    HerbCore.update_rule_indices!(c.tree, n_rules, mapping)
end

"""
    update_rule_indices!(c::ContainsSubtree, grammar::AbstractGrammar, mapping::AbstractDict{<:Integer, <:Integer})

Updates the `ContainsSubtree` constraint to reflect grammar changes by calling `HerbCore.update_rule_indices!` on its `tree` field.

# Arguments
- `c`: The `ContainsSubtree` to be updated
- `grammar`: The grammar that changed
- `mapping`: Dictionary mapping old rule indices to new rule indices
"""
function HerbCore.update_rule_indices!(
    c::ContainsSubtree,
    grammar::AbstractGrammar,
    mapping::AbstractDict{<:Integer,<:Integer},
)
    HerbCore.update_rule_indices!(c, length(grammar.rules), mapping, grammar.constraints)
end

HerbCore.is_domain_valid(c::ContainsSubtree, n_rules::Integer) = HerbCore.is_domain_valid(c.tree, n_rules)
HerbCore.is_domain_valid(c::ContainsSubtree, grammar::AbstractGrammar) = HerbCore.is_domain_valid(c.tree, length(grammar.rules))

Base.:(==)(c1::ContainsSubtree, c2::ContainsSubtree) = (c1.tree == c2.tree)

function HerbGrammar.is_constraint_valid(c::ContainsSubtree, grammar::AbstractGrammar; allow_empty_children::Bool)
    return HerbGrammar.is_tree_valid(c.tree, grammar; allow_empty_children=allow_empty_children)
end