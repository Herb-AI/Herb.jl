"""
Contains <: AbstractGrammarConstraint
This [`AbstractGrammarConstraint`] enforces that a given `rule` appears in the program tree at least once.
"""
struct Contains <: AbstractGrammarConstraint
    rule::Int
end

function on_new_node(solver::Solver, c::Contains, path::Vector{Int})
    if length(path) == 0
        #only post a local constraint at the root
        post!(solver, LocalContains(path, c.rule))
    end
end

"""
    check_tree(c::Contains, tree::AbstractRuleNode)::Bool

Checks if the given [`AbstractRuleNode`](@ref) tree abides the [`Contains`](@ref) constraint.
"""
function check_tree(c::Contains, tree::AbstractRuleNode)::Bool
    if get_rule(tree) == c.rule
        return true
    end
    return any(check_tree(c, child) for child ∈ get_children(tree))
end


"""
	update_rule_indices!(c::Contains, n_rules::Integer)

Updates a `Contains` constraint to reflect grammar changes. Errors if rule index exceeds new `n_rules`.

# Arguments
- `c`: The `Contains` constraint to be updated
- `n_rules`: The new number of rules in the grammar
"""
function HerbCore.update_rule_indices!(c::Contains, n_rules::Integer)
    if c.rule > n_rules
        error("Rule index $(c.rule) exceeds the number of grammar rules ($n_rules).")
    end
    # no update required
end

"""
	update_rule_indices!(c::Contains, grammar::AbstractGrammar)

Updates the `Contains` constraint as required when grammar size changes. Errors if the rule index exceeds number of grammar rules.

# Arguments
- `c`: The `Contains` constraint to be updated
- `grammar`: The grammar that changed
"""
function HerbCore.update_rule_indices!(c::Contains, grammar::AbstractGrammar)
    n_rules = length(grammar.rules)
    if c.rule > n_rules
        error("Rule index $(c.rule) exceeds the number of grammar rules ($n_rules).")
    end
    # no update required
end

"""
    update_rule_indices!(c::Contains, n_rules::Integer, mapping::AbstractDict{<:Integer,<:Integer}, constraints::Vector{<:AbstractConstraint})

Updates the `Contains` constraint to reflect grammar changes by replacing it with a new 
`Contains` constraint using the mapped rule index.

# Arguments
- `c`: The `Contains` constraint to be updated
- `n_rules`: The new number of rules in the grammar  
- `mapping`: Dictionary mapping old rule indices to new rule indices
- `constraints`: Vector of grammar constraints containing the constraint to update
"""
function HerbCore.update_rule_indices!(
    c::Contains,
    n_rules::Integer,
    mapping::AbstractDict{<:Integer,<:Integer},
    constraints::Vector{<:AbstractConstraint}
)
    if c.rule > n_rules
        error("Rule index $(c.rule) exceeds the number of grammar rules ($n_rules).")
    end
    index = only(findall(x -> x == c, constraints))
    new_rule = get(mapping, c.rule, c.rule) # keep rule index if no matching entry found in mapping
    constraints[index] = Contains(new_rule)
end

"""
    update_rule_indices!(c::Contains, grammar::AbstractGrammar, mapping::AbstractDict{<:Integer,<:Integer})

Updates the `Contains` constraint to reflect grammar changes by replacing it with a new 
`Contains` constraint using the mapped rule index.

# Arguments
- `c`: The `Contains` constraint to be updated
- `grammar`: The grammar that changed  
- `mapping`: Dictionary mapping old rule indices to new rule indices
"""
function HerbCore.update_rule_indices!(c::Contains,
    grammar::AbstractGrammar,
    mapping::AbstractDict{<:Integer,<:Integer})
    HerbCore.update_rule_indices!(c, length(grammar.rules), mapping, grammar.constraints)
end

HerbCore.is_domain_valid(c::Contains, n_rules::Integer) = c.rule <= n_rules
HerbCore.is_domain_valid(c::Contains, grammar::AbstractGrammar) = HerbCore.is_domain_valid(c, length(grammar.rules))

HerbGrammar.is_constraint_valid(c::Contains, grammar::AbstractGrammar; allow_empty_children::Bool) = (c.rule <= length(grammar.rules)) && (c.rule >= 1)