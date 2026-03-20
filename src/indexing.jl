"""
    update_rule_indices!(...)

Updates the rule indices of the given rule node, hole or grammar constraint when the grammar changes. 
"""
function update_rule_indices! end

"""
    is_domain_valid(x, n_rules::Integer)
    is_domain_valid(x, grammar::AbstractGrammar)

Check if the domain for the given object `x` (ex: [`RuleNode`](@ref),
[`Hole`](@ref) or [`AbstractConstraint`](@ref)) is valid given the provided
grammar or number of rules.

If [`isfilled`](@ref)`(x)` and `x` has children, it checks if all children are valid.
"""
function is_domain_valid end

"""
    issame(a, b)

!!! warning 

    This function is deprecated and should not be used. Use `==` instead.

"""
function issame(a, b)
    return a == b
end

Base.@deprecate issame Base.:(==) false
