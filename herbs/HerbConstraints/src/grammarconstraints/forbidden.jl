"""
    Forbidden <: AbstractGrammarConstraint

This [`AbstractGrammarConstraint`] forbids any subtree that matches the pattern given by `tree` to be generated.
A pattern is a tree of [`AbstractRuleNode`](@ref)s. 

# Example

A node in the tree can be of any type `<:AbstractRuleNode`. For example, a [`RuleNode`](@ref), which contains a rule index corresponding to the 
rule index in the [`AbstractGrammar`](@ref) and the appropriate number of children, or a [`VarNode`](@ref), which contains a single identifier symbol.

Let's consider the tree `1(a, 2(b, 3(c, 4))))`:

- `Forbidden(RuleNode(3, [RuleNode(5), RuleNode(4)]))` forbids `c` to be filled with `5`.
- `Forbidden(RuleNode(3, [VarNode(:v), RuleNode(4)]))` forbids `c` to be filled, since a [`VarNode`] can 
    match any rule, thus making the match attempt successful for the entire domain of `c`. 
    Therefore, this tree invalid.
- `Forbidden(RuleNode(3, [VarNode(:v), VarNode(:v)]))` forbids `c` to be filled with `4`, since that would 
    make both assignments to `v` equal, which causes a successful match.

A [`VarNode`](@ref) can match any subtree, but if there are multiple instances of the same
variable in the pattern, the matched subtrees must be identical.
Any rule in the domain that makes the match attempt successful is removed.

"""
struct Forbidden <: AbstractGrammarConstraint
    tree::AbstractRuleNode
end

function on_new_node(solver::Solver, c::Forbidden, path::Vector{Int})
    #minor optimization: prevent the first hardfail (https://github.com/orgs/Herb-AI/projects/6/views/1?pane=issue&itemId=55570518)
    if c.tree isa RuleNode
        @match get_node_at_location(solver, path) begin
            hole::AbstractHole => if !hole.domain[c.tree.ind]
                return
            end
            node::RuleNode => if node.ind != c.tree.ind
                return
            end
        end
    end
    post!(solver, LocalForbidden(path, c.tree))
end

"""
    check_tree(c::Forbidden, tree::AbstractRuleNode)::Bool

Checks if the given [`AbstractRuleNode`](@ref) tree abides the [`Forbidden`](@ref) constraint.
"""
function check_tree(c::Forbidden, tree::AbstractRuleNode)::Bool
    @match pattern_match(tree, c.tree) begin
        ::PatternMatchHardFail => ()
        ::PatternMatchSoftFail => ()
        ::PatternMatchSuccess => return false
        ::PatternMatchSuccessWhenHoleAssignedTo => ()
    end
    return all(check_tree(c, child) for child ∈ tree.children)
end

"""
    update_rule_indices!(c::Forbidden, n_rules::Integer)

Updates the `Forbidden` constraint to reflect grammar changes by calling `HerbCore.update_rule_indices!` on its `tree` field.

# Arguments
- `c`: The `Forbidden` constraint to be updated.
- `n_rules`: The new number of rules in the grammar.
"""
function HerbCore.update_rule_indices!(
    c::Forbidden,
    n_rules::Integer,
)
    HerbCore.update_rule_indices!(c.tree, n_rules)
end

"""
    update_rule_indices!(c::Forbidden, grammar::AbstractGrammar)

Updates the `Forbidden` constraint to reflect grammar changes by calling `HerbCore.update_rule_indices!` on its `tree` field.

# Arguments
- `c`: The `Forbidden` constraint to be updated.
- `grammar`: The new number of rules in the grammar.
"""
function HerbCore.update_rule_indices!(
    c::Forbidden,
    grammar::AbstractGrammar,
)
    HerbCore.update_rule_indices!(c.tree, length(grammar.rules))
end

"""
	update_rule_indices!(c::Forbidden, n_rules::Integer, mapping::AbstractDict{<:Integer, <:Integer}, ::Vector{<:AbstractConstraint})

Updates the `Forbidden` constraint to reflect grammar changes by calling `HerbCore.update_rule_indices!` on its `tree` field.

# Arguments
- `c`: The `Forbidden` constraint to be updated
- `n_rules`: The new number of rules in the grammar  
- `mapping`: Dictionary mapping old rule indices to new rule indices
"""
function HerbCore.update_rule_indices!(
    c::Forbidden,
    n_rules::Integer,
    mapping::AbstractDict{<:Integer,<:Integer},
    ::Vector{<:AbstractConstraint}
)
    HerbCore.update_rule_indices!(c.tree, n_rules, mapping)
end

"""
	update_rule_indices!(c::Forbidden, grammar::AbstractGrammar, mapping::AbstractDict{<:Integer, <:Integer})

Updates the `Forbidden` constraint to reflect grammar changes by calling `HerbCore.update_rule_indices!` on its `tree` field.

# Arguments
- `c`: The `Forbidden` constraint to be updated
- `grammar`: The grammar that changed
- `mapping`: Dictionary mapping old rule indices to new rule indices
"""
function HerbCore.update_rule_indices!(
    c::Forbidden,
    grammar::AbstractGrammar,
    mapping::AbstractDict{<:Integer,<:Integer},
)
    HerbCore.update_rule_indices!(c, length(grammar.rules), mapping, grammar.constraints)
end

HerbCore.is_domain_valid(c::Forbidden, n_rules::Integer) = HerbCore.is_domain_valid(c.tree, n_rules)
HerbCore.is_domain_valid(c::Forbidden, grammar::AbstractGrammar) = HerbCore.is_domain_valid(c.tree, length(grammar.rules))

Base.:(==)(c1::Forbidden, c2::Forbidden) = (c1.tree == c2.tree)

function HerbGrammar.is_constraint_valid(c::Forbidden, grammar::AbstractGrammar; allow_empty_children::Bool)
    return HerbGrammar.is_tree_valid(c.tree, grammar; allow_empty_children=allow_empty_children)
end