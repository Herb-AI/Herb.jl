"""
    struct VarNode <: AbstractRuleNode

Matches any subtree and assigns it to a variable name.
The `LocalForbidden` constraint will not match if identical variable symbols match to different trees.
Example usage:

```julia
RuleNode(3, [VarNode(:x), VarNode(:x)])
```

This matches `RuleNode(3, [RuleNode(1), RuleNode(1)])`, `RuleNode(3, [RuleNode(2), RuleNode(2)])`, etc.
but also larger subtrees such as `RuleNode(3, [RuleNode(4, [RuleNode(1)]), RuleNode(4, [RuleNode(1)])])`
"""
struct VarNode <: AbstractRuleNode
    name::Symbol
end

function Base.show(io::IO, node::VarNode; separator=",", last_child::Bool=true)
    print(io, node.name)
    if !last_child
        print(io, separator)
    end
end

HerbCore.isuniform(::VarNode) = false

"""
    contains_varnode(rn::AbstractRuleNode, name::Symbol)

Checks if an [`AbstractRuleNode`](@ref) tree contains a [`VarNode`](@ref) with the given `name`.
"""
contains_varnode(rn::AbstractRuleNode, name::Symbol) = any(contains_varnode(c, name) for c ∈ rn.children)
contains_varnode(vn::VarNode, name::Symbol) = vn.name == name

"""
     HerbCore.update_rule_indices!(c::ContainVarNodesSubtree, n_rules::Integer)

Update the rule indices of a `VarNode`. As `VarNode`s contain no indices, this function does nothing.
"""
function HerbCore.update_rule_indices!(
    ::VarNode,
    ::Integer,
)
    # VarNode does not change
end

"""
	HerbCore.update_rule_indices!(c::VarNode, n_rules::Integer, mapping::AbstractDict{<:Integer, <:Integer})

Update the rule indices of a `VarNode`. As `VarNode`s contain no indices, this function does nothing.
"""
function HerbCore.update_rule_indices!(
    ::VarNode,
    ::Integer,
    ::AbstractDict{<:Integer,<:Integer},
)
    # VarNode does not change
end

# Always return `true` (interface only)
HerbCore.is_domain_valid(node::VarNode, n_rules::Integer) = true

HerbGrammar.is_tree_valid(vn::VarNode, grammar::AbstractGrammar; allow_empty_children::Bool)::Bool = true

HerbGrammar.is_tree_valid(vn::VarNode, grammar::AbstractGrammar, expected_type::Symbol; allow_empty_children::Bool)::Bool = true