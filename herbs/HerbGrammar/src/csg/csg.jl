"""
	ContextSensitiveGrammar <: AbstractGrammar

Represents a context-sensitive grammar.
Extends [`AbstractGrammar`](@ref) with constraints.

Consists of:

- `rules::Vector{Any}`: A list of RHS of rules (subexpressions).
- `types::Vector{Symbol}`: A list of LHS of rules (types, all symbols).
- `isterminal::BitVector`: A bitvector where bit `i` represents whether rule `i` is terminal.
- `iseval::BitVector`: A bitvector where bit `i` represents whether rule i is an eval rule.
- `bytype::Dict{Symbol,Vector{Int}}`: A dictionary that maps a type to all rules of said type.
- `domains::Dict{Symbol, BitVector}`: A dictionary that maps a type to a domain bitvector. 
  The domain bitvector has bit `i` set to true iff the `i`th rule is of this type.
- `childtypes::Vector{Vector{Symbol}}`: A list of types of the children for each rule. 
  If a rule is terminal, the corresponding list is empty.
- `bychildtypes::Vector{BitVector}`: A bitvector of rules that share the same childtypes for each rule
- `log_probabilities::Union{Vector{Real}, Nothing}`: A list of probabilities for each rule. 
  If the grammar is non-probabilistic, the list can be `nothing`.
- `constraints::Vector{AbstractConstraint}`: A list of constraints that programs in this grammar have to abide.

Use the [`@csgrammar`](@ref) macro to create a [`ContextSensitiveGrammar`](@ref) object.
Use the [`@pcsgrammar`](@ref) macro to create a [`ContextSensitiveGrammar`](@ref) object with probabilities.
"""
mutable struct ContextSensitiveGrammar <: AbstractGrammar
    rules::Vector{Any}
    types::Vector{Union{Symbol,Nothing}}
    isterminal::BitVector
    iseval::BitVector
    bytype::Dict{Symbol,Vector{Int}}
    domains::Dict{Symbol,BitVector}
    childtypes::Vector{Vector{Symbol}}
    bychildtypes::Vector{BitVector}
    log_probabilities::Union{Vector{Real},Nothing}
    constraints::Vector{AbstractConstraint}
end

ContextSensitiveGrammar(
    rules::Vector{<:Any},
    types::Vector{<:Union{Symbol,Nothing}},
    isterminal::Union{BitVector,Vector{Bool}},
    iseval::Union{BitVector,Vector{Bool}},
    bytype::Dict{Symbol,Vector{Int}},
    domains::Dict{Symbol,BitVector},
    childtypes::Vector{Vector{Symbol}},
    bychildtypes::Vector{BitVector},
    log_probabilities::Union{Vector{<:Real},Nothing}
) = ContextSensitiveGrammar(rules, types, isterminal, iseval, bytype, domains, childtypes, bychildtypes, log_probabilities, AbstractConstraint[])

ContextSensitiveGrammar() = ContextSensitiveGrammar([], [], BitVector[], BitVector[], Dict{Symbol,Vector{Int}}(), Dict{Symbol,BitVector}(), Vector{Vector{Symbol}}(), Vector{BitVector}(), nothing, AbstractConstraint[])

"""
	expr2csgrammar(ex::Expr)::ContextSensitiveGrammar

A function for converting an `Expr` to a [`ContextSensitiveGrammar`](@ref).
If the expression is hardcoded, you should use the [`@csgrammar`](@ref) macro.
Only expressions in the correct format (see [`@csgrammar`](@ref)) can be converted.

### Example usage:

```@example
grammar = expr2csgrammar(
	begin
		R = x
		R = 1 | 2
		R = R + R
	end
)
```
"""
function expr2csgrammar(ex::Expr)::ContextSensitiveGrammar
    grammar = ContextSensitiveGrammar()

    for e ∈ ex.args
        if isa(e, Expr)
            add_rule!(grammar, e)
        end
    end

    return grammar
end



"""
	@csgrammar

A macro for defining a [`ContextSensitiveGrammar`](@ref). 
AbstractConstraints can be added afterwards using the [`addconstraint!`](@ref) function.

### Example usage:
```julia
grammar = @csgrammar begin
	R = x
	R = 1 | 2
	R = R + R
end
```

### Syntax:

- Literals: Symbols that are already defined in Julia are considered literals, such as `1`, `2`, or `π`.
  For example: `R = 1`.
- Variables: A variable is a symbol that is not a nonterminal symbol and not already defined in Julia.
  For example: `R = x`.
- Functions: Functions and infix operators that are defined in Julia or the `Main` module can be used 
  with the default evaluator. For example: `R = R + R`, `R = f(a, b)`.
- Combinations: Multiple rules can be defined on a single line in the grammar definition using the `|` symbol.
  For example: `R = 1 | 2 | 3`.
- Iterators: Another way to define multiple rules is by providing a Julia iterator after a `|` symbol.
  For example: `R = |(1:9)`.

### Related:

- [`@pcsgrammar`](@ref) uses a similar syntax to create probabilistic [`ContextSensitiveGrammar`](@ref)s.
"""
macro csgrammar(ex)
    return :(expr2csgrammar($(QuoteNode(ex))))
end


"""
	@cfgrammar

This macro is deprecated and will be removed in future versions. Use [`@csgrammar`](@ref) instead.
"""
macro cfgrammar(ex)
    return :(expr2csgrammar($(QuoteNode(ex))))
end

parse_rule!(v::Vector{Any}, r) = push!(v, r)

function parse_rule!(v::Vector{Any}, ex::Expr)
    # Strips `LineNumberNode`s from the expression
    Base.remove_linenums!(ex)

    if ex.head == :call && ex.args[1] == :|
        terms = _expand_shorthand(ex.args)

        for t in terms
            parse_rule!(v, t)
        end
    else
        push!(v, ex)
    end
end

function _expand_shorthand(args::Vector{Any})
    # expand a rule using the `|` symbol:
    # `X = |(1:3)`, `X = 1|2|3`, `X = |([1,2,3])`
    # these should all be equivalent and should expand to
    # the following 3 rules: `X = 1`, `X = 2`, and `X = 3`
    if args[1] != :|
        throw(ArgumentError("Tried to parse: $ex as a shorthand rule, but it is not a shorthand rule."))
    end

    if length(args) == 2
        to_expand = args[2]
        if to_expand.args[1] == :(:)
            expanded = collect(to_expand.args[2]:to_expand.args[3])# (1:3) case
        else
            expanded = to_expand.args# ([1,2,3]) case
        end
    elseif length(args) == 3
        expanded = args[2:end]# 1|2|3 case
    else
        throw(ArgumentError("Failed to parse shorthand for rule: $ex"))
    end
end

"""
	addconstraint!(grammar::ContextSensitiveGrammar, c::AbstractConstraint)

Adds a [`AbstractConstraint`](@ref) to a [`ContextSensitiveGrammar`](@ref). 

!!! warning
    - Errors if the constraint's domain is invalid.
    - Errors if the constraint's tree is impossible to construct with the given grammar.
    - Calls to this function are ignored if the constraint already exists in the grammar.
"""
function addconstraint!(grammar::ContextSensitiveGrammar, c::AbstractConstraint; allow_empty_children::Bool=false)
    if !HerbCore.is_domain_valid(c, grammar)
        error("The domain of $(typeof(c)) is not valid for the provided grammar. Rule index or domain size does not match the number of grammar rule: $(length(grammar.rules))")
    end
    if !is_constraint_valid(c, grammar; allow_empty_children=allow_empty_children)
        error("The constraint $(typeof(c)) \n$c\n contains a tree that is not possible with the grammar\n$grammar")
    end
    if isempty(grammar.constraints) || !any(x -> (x == c), grammar.constraints) # only add constraint if it doesn't exist yet
        push!(grammar.constraints, c)
    end
    # Note: Tests for adding constraints to a grammar can be found in HerbConstraints.
end

"""
Clear all constraints from the grammar
"""
clearconstraints!(grammar::ContextSensitiveGrammar) = empty!(grammar.constraints)

function Base.display(rulenode::RuleNode, grammar::ContextSensitiveGrammar)
    return rulenode2expr(rulenode, grammar)
end

"""
	merge_grammars!(merge_to::AbstractGrammar, merge_from::AbstractGrammar)

Adds all rules and constraints from `merge_from` to `merge_to`. Duplicate rules are ignored.
"""
function merge_grammars!(merge_to::AbstractGrammar, merge_from::AbstractGrammar)
    mapping = Dict{Integer,Integer}() # keep track of new rule indices for merge_from grammar
    # Dict for easy lookup of duplicate rules 
    rule_to_index = Dict{Tuple,Int}()
    for (idx, (type, rule)) in enumerate(zip(merge_to.types, merge_to.rules))
        rule_to_index[(type, rule)] = idx
    end

    # add rules
    for i in eachindex(merge_from.rules)
        n_rules_before = length(merge_to.rules)
        expression = :($(merge_from.types[i]) = $(merge_from.rules[i]))
        add_rule!(merge_to, expression)
        n_rules_after = length(merge_to.rules)
        if n_rules_before < n_rules_after
            mapping[i] = n_rules_after
        else
            # If rule already exists, rule index from merge_to grammar is used for mapping.  
            idx = rule_to_index[(merge_from.types[i], merge_from.rules[i])]
            mapping[i] = idx
        end
    end
    # update constraints of ...
    # ... `merge_to` grammar
    for i in eachindex(merge_to.constraints)
        HerbCore.update_rule_indices!(merge_to.constraints[i], length(merge_to.rules))
    end

    # ... `merge_from` grammar (mapping required)
    from_constraints = deepcopy(merge_from.constraints) # we don't want to modify `merge_from` 
    for i in eachindex(from_constraints)
        HerbCore.update_rule_indices!(from_constraints[i], length(merge_to.rules), mapping, from_constraints)
        addconstraint!(merge_to, from_constraints[i]; allow_empty_children=true)
    end
    # Note: Tests for merging two grammars with constraints can be found in HerbConstraints.
end

"""
    is_constraint_valid(c::AbstractConstraint, grammar::AbstractGrammar; allow_empty_children)

Checks if the structure of constraint `c` is sound with the given grammar.
E.g. if `c` is `Forbidden(tree)`, this funciton will check if `tree` is possible to construct with the given grammar.
"""
function is_constraint_valid end

"""
    is_tree_valid(rn::AbstractRuleNode, grammar::AbstractGrammar; allow_empty_children)

Checks if the tree `rn` is possible to construct with the given grammar.

If `allow_empty_children` is set to true, the check will not error when no children are given for a rule that has children in the grammar.
"""
function is_tree_valid(rn::AbstractRuleNode, grammar::AbstractGrammar; allow_empty_children=false)
    return is_tree_valid(rn, grammar, return_type(grammar, rn); allow_empty_children=allow_empty_children)
end

"""
    is_tree_valid(rn::AbstractRuleNode, grammar::AbstractGrammar; allow_empty_children)

Checks if the tree `rn` is possible to construct with the given grammar. The root of the tree should be `expected_type`.
If `allow_empty_children` is set to true, the check will not error when no children are given for a rule that has children in the grammar.
"""
function is_tree_valid(rn::RuleNode, grammar::AbstractGrammar, expected_type::Symbol; allow_empty_children)
    # not valid if the rule node type does not match the expected type
    (return_type(grammar, rn) == expected_type) || return false
    expected_child_types = child_types(grammar, rn)
    return _are_children_valid(rn, grammar, [expected_child_types]; allow_empty_children=allow_empty_children)
end

"""
    is_tree_valid(rn::AbstractRuleNode, grammar::AbstractGrammar; allow_empty_children)

Checks if the tree `hole` is possible to construct with the given grammar.

If `allow_empty_children` is set to true, the check will not error when no children are given for a rule that has children in the grammar.
"""
function is_tree_valid(hole::UniformHole, grammar::AbstractGrammar, _expected_type::Symbol; allow_empty_children)
    # ignoring "expected_type" here because a hole can have multiple types.
    # not valid if domain of the hole is not the same length as the grammar
    (length(grammar.rules) == length(hole.domain)) || return false
    child_types = grammar.childtypes[hole.domain]
    return _are_children_valid(hole, grammar, child_types; allow_empty_children=allow_empty_children)
end

function _are_children_valid(rn::AbstractRuleNode, grammar::AbstractGrammar, expected_types::Vector{Vector{Symbol}}; allow_empty_children)
    children = get_children(rn)
    # in some cases we can allow not including children as a way of saying "any children are allowed"
    (isempty(children) && allow_empty_children) && return true
    for expected_child_types in expected_types
        (length(children) == length(expected_child_types)) || return false
        for (i, child) in enumerate(children)
            is_tree_valid(child, grammar, expected_child_types[i]; allow_empty_children=allow_empty_children) || return false
        end
    end
    return true
end