"""
    Unique <: AbstractGrammarConstraint

This [`AbstractGrammarConstraint`] enforces that a given `rule` appears in the program tree at most once.
"""
struct Unique <: AbstractGrammarConstraint
    rule::Int
end


function on_new_node(solver::Solver, c::Unique, path::Vector{Int})
    if length(path) == 0
        #only post a local constraint at the root
        post!(solver, LocalUnique(path, c.rule))
    end
end


"""
    _count_occurrences(rulenode::AbstractRuleNode, rule::Int)::Int

Recursively counts the number of occurrences of the `rule` in the `node`.
"""
function _count_occurrences(rulenode::AbstractRuleNode, rule::Int)::Int
    @assert isfilled(rulenode)
    count = (get_rule(rulenode) == rule) ? 1 : 0
    for child ∈ get_children(rulenode)
        count += _count_occurrences(child, rule)
    end
    return count
end


"""
    function check_tree(c::Unique, tree::AbstractRuleNode)::Bool

Checks if the given [`AbstractRuleNode`](@ref) tree abides the [`Unique`](@ref) constraint.
"""
function check_tree(c::Unique, tree::AbstractRuleNode)::Bool
    return _count_occurrences(tree, c.rule) <= 1
end

"""
	update_rule_indices!(c::Unique, n_rules::Integer)

Updates a `Unique` constraint to reflect grammar changes. Errors if rule index exceeds new `n_rules`.

# Arguments
- `c`: The `Unique` constraint to be updated.
- `n_rules`: The new number of rules in the grammar.
"""
function HerbCore.update_rule_indices!(c::Unique, n_rules::Integer)
    if c.rule > n_rules
        error("Rule index $(c.rule) exceeds the number of grammar rules ($n_rules).")
    end
    # no update required
end

"""
	update_rule_indices!(c::Unique, grammar::AbstractGrammar)

Updates a `Unique` constraint to reflect grammar changes. Errors if rule index exceeds number of grammar rules.

# Arguments
- `c`: The `Unique` constraint to be updated
- `grammar`: The grammar that changed
"""
function HerbCore.update_rule_indices!(c::Unique, grammar::AbstractGrammar)
    HerbCore.update_rule_indices!(c, length(grammar.rules))
    # no update required
end

"""
    HerbCore.update_rule_indices!(c::Unique,
    n_rules::Integer,
    mapping::AbstractDict{<:Integer,<:Integer},
    constraints::Vector{<:AbstractConstraint})

Updates the `Unique` constraint to reflect grammar changes by replacing it with a new 
`Unique` constraint using the mapped rule index. Errors if rule index exceeds new `n_rules`.

# Arguments
- `c`: The `Unique` constraint to be updated
- `n_rules`: The new number of rules in the grammar  
- `mapping`: Dictionary mapping old rule indices to new rule indices
- `constraints`: Vector of grammar constraints containing the constraint to update
"""
function HerbCore.update_rule_indices!(c::Unique,
    n_rules::Integer,
    mapping::AbstractDict{<:Integer,<:Integer},
    constraints::Vector{<:AbstractConstraint})
    if c.rule > n_rules
        error("Rule index $(c.rule) exceeds the number of grammar rules ($n_rules).")
    end
    index = only(findall(x -> x == c, constraints))
    new_rule = new_rule = get(mapping, c.rule, c.rule) # keep rule index if no matching entry found in mapping
    constraints[index] = Unique(new_rule)
end

"""
    HerbCore.update_rule_indices!(c::Unique,
    grammar::AbstractGrammar,
    mapping::AbstractDict{<:Integer,<:Integer})

Updates the `Unique` constraint to reflect grammar changes by replacing it with a new 
`Unique` constraint using the mapped rule index.Errors if rule index exceeds number of grammar rules.

# Arguments
- `c`: The `Unique` constraint to be updated
- `grammar`: The grammar that changed
- `mapping`: Dictionary mapping old rule indices to new rule indices
"""
function HerbCore.update_rule_indices!(c::Unique,
    grammar::AbstractGrammar,
    mapping::AbstractDict{<:Integer,<:Integer})
    HerbCore.update_rule_indices!(c, length(grammar.rules), mapping, grammar.constraints)
end

HerbCore.is_domain_valid(c::Unique, n_rules::Integer) = c.rule <= n_rules
HerbCore.is_domain_valid(c::Unique, grammar::AbstractGrammar) = HerbCore.is_domain_valid(c, length(grammar.rules))


HerbGrammar.is_constraint_valid(c::Unique, grammar::AbstractGrammar; allow_empty_children::Bool) = (c.rule <= length(grammar.rules)) && (c.rule >= 1)