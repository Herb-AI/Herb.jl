"""
    isterminal(rule::Any, types::AbstractVector{Symbol})

Returns true if the rule is terminal, i.e., it does not contain any of the types in the provided vector.
For example, :(x) is terminal, and :(1+1) is terminal, but :(Real + Real) is typically not.
"""
function isterminal(rule::Any, types::AbstractVector{Symbol})
    if isa(rule, Expr)
        for arg ∈ rule.args
            if !isterminal(arg, types)
                return false
            end
        end
    end
    return rule ∉ types
end


"""
    iseval(rule)

Returns true if the rule is the special evaluate immediately function, i.e., _()

!!! compat
    evaluate immediately functionality is not yet supported by most of Herb.jl
"""
iseval(rule) = false
iseval(rule::Expr) = (rule.head == :call && rule.args[1] == :_)


"""
    get_childtypes(rule::Any, types::AbstractVector{Symbol})

Returns the child types/nonterminals of a production rule.
"""
function get_childtypes(rule::Any, types::AbstractVector{Symbol})
    retval = Symbol[]
    if isa(rule, Expr)
        for arg ∈ rule.args
            append!(retval, get_childtypes(arg, types))
        end
    elseif rule ∈ types
        push!(retval, rule)
    end
    return retval
end


"""
    nonterminals(grammar::AbstractGrammar)::Vector{Symbol}

Returns a list of the nonterminals or types in the [`AbstractGrammar`](@ref).
"""
nonterminals(grammar::AbstractGrammar)::Vector{Symbol} = collect(keys(grammar.bytype))


"""
    return_type(grammar::AbstractGrammar, rule_index::Int)::Symbol

Returns the type of the production rule at `rule_index`.
"""
return_type(grammar::AbstractGrammar, rule_index::Int) = grammar.types[rule_index]


"""
    child_types(grammar::AbstractGrammar, rule_index::Int)

Returns the types of the children (nonterminals) of the production rule at `rule_index`.
"""
child_types(grammar::AbstractGrammar, rule_index::Int) = grammar.childtypes[rule_index]


"""
    get_domain(g::AbstractGrammar, type::Symbol)::BitVector

Returns the domain for the hole of a certain type as a `BitVector` of the same length as the number of 
rules in the grammar. Bit `i` is set to `true` iff rule `i` is of type `type`.

!!! info
    Since this function can be intensively used when exploring a program space defined by a grammar,
    the outcomes of this function are precomputed and stored in the `domains` field in a [`AbstractGrammar`](@ref).
"""
get_domain(g::AbstractGrammar, type::Symbol)::BitVector = deepcopy(g.domains[type])


"""
    get_domain(g::AbstractGrammar, rules::Vector{Int})::BitVector

Takes a domain `rules` defined as a vector of ints and converts it to a domain defined as a `BitVector`.
"""
get_domain(g::AbstractGrammar, rules::Vector{Int})::BitVector = BitArray(r ∈ rules for r ∈ 1:length(g.rules))


"""
    isterminal(grammar::AbstractGrammar, rule_index::Int)::Bool

Returns true if the production rule at `rule_index` is terminal, i.e., does not contain any nonterminal symbols.
"""
isterminal(grammar::AbstractGrammar, rule_index::Int)::Bool = grammar.isterminal[rule_index]


"""
    iseval(grammar::AbstractGrammar)::Bool

Returns true if any production rules in grammar contain the special _() eval function.

!!! compat
    evaluate immediately functionality is not yet supported by most of Herb.jl

"""
iseval(grammar::AbstractGrammar)::Bool = any(grammar.iseval)


"""
    iseval(grammar::AbstractGrammar, index::Int)::Bool

Returns true if the production rule at rule_index contains the special _() eval function.

!!! compat
    evaluate immediately functionality is not yet supported by most of Herb.jl

"""
iseval(grammar::AbstractGrammar, index::Int)::Bool = grammar.iseval[index]



"""
    nchildren(grammar::AbstractGrammar, rule_index::Int)::Int

Returns the number of children (nonterminals) of the production rule at `rule_index`.
"""
nchildren(grammar::AbstractGrammar, rule_index::Int)::Int = length(grammar.childtypes[rule_index])


"""
    max_arity(grammar::AbstractGrammar)::Int

Returns the maximum arity (number of children) over all production rules in the [`AbstractGrammar`](@ref).
"""
max_arity(grammar::AbstractGrammar)::Int = maximum(length(cs) for cs in grammar.childtypes)


"""
    add_rule!(g::AbstractGrammar, e::Expr)

Adds a rule to the grammar and updates grammar constraints as required. 

### Usage: 
```
    add_rule!(grammar, :("Real = Real + Real"))
```
The syntax is identical to the syntax of [`@csgrammar`](@ref) and [`@cfgrammar`](@ref), but only single rules are supported.

!!! warning
    Calls to this function are ignored if a rule is already in the grammar.
"""
function add_rule!(g::AbstractGrammar, e::Expr)
    if e.head == :(=) && typeof(e.args[1]) == Symbol
        s = e.args[1]# Name of return type
        rule = e.args[2]# expression?
        rvec = Any[]
        parse_rule!(rvec, rule)
        for r ∈ rvec
            # Only add a rule if it does not exist yet. Check for existance
            # with strict equality so that true and 1 are not considered
            # equal. that means we can't use `in` or `∈` for equality checking.
            if !any(s == type && (r === rule || typeof(r) == Expr && r == rule) for (type, rule) ∈ zip(g.types, g.rules))
                push!(g.rules, r)
                push!(g.iseval, iseval(rule))
                push!(g.types, s)
                g.bytype[s] = push!(get(g.bytype, s, Int[]), length(g.rules))
            end
        end
    else
        throw(ArgumentError("Invalid rule: $e. Rules must be of the form `Symbol = Expr`"))
    end
    alltypes = collect(keys(g.bytype))

    # is_terminal and childtypes need to be recalculated from scratch, since a new type might 
    # be added that was used as a terminal symbol before.
    g.isterminal = [isterminal(rule, alltypes) for rule ∈ g.rules]
    g.childtypes = [get_childtypes(rule, alltypes) for rule ∈ g.rules]
    g.bychildtypes = [BitVector([g.childtypes[i1] == g.childtypes[i2] for i2 ∈ 1:length(g.rules)]) for i1 ∈ 1:length(g.rules)]
    g.domains = Dict(type => BitArray(r ∈ g.bytype[type] for r ∈ 1:length(g.rules)) for type ∈ keys(g.bytype))
    # update grammar constraints to enforce domain correctness
    for c in g.constraints
        HerbCore.update_rule_indices!(c, length(g.rules))
    end
    return g
end


"""
    add_rule(grammar, tree)

Extends a given grammar with an `AbstractRuleNode`. The type of the rule is inferred from the root-type.
# Arguments
- `grammar::AbstractGrammar`: the grammar to extend
- `tree::RuleNode`: the Herb tree
"""
function add_rule!(grammar::AbstractGrammar, tree::AbstractRuleNode)
    type = return_type(grammar, tree.ind)
    new_grammar_rule = rulenode2expr(tree, grammar)
    add_rule!(grammar, :($type = $new_grammar_rule))
end


"""
    add_rule!(g::AbstractGrammar, p::Real, e::Expr; normalize=true)

Add a probabilistic derivation rule.

!!! note
    By default, normalizes the grammar `g`'s probabilities after adding the rule(s).
    When constructing a grammar iteratively, it may be useful to skip normalization
    until all rules and their probabilities have been added, calling
    [`normalize!`](@ref) at the end.
"""
function add_rule!(g::AbstractGrammar, p::Real, e::Expr; normalize=true)
    isprobabilistic(g) || throw(ArgumentError("adding a probabilistic rule to a non-probabilistic grammar"))
    len₀ = length(g.rules)
    add_rule!(g, e)
    len₁ = length(g.rules)
    nnew = len₁ - len₀
    append!(g.log_probabilities, repeat([log(p / nnew)], nnew))
    if normalize
        normalize!(g)
    end
end

"""
    remove_rule!(g::AbstractGrammar, idx::Int)

Removes the rule corresponding to `idx` from the grammar. 
In order to avoid shifting indices, the rule is replaced with `nothing`,
and all other data structures are updated accordingly.
"""
function remove_rule!(g::AbstractGrammar, idx::Int)
    type = g.types[idx]
    g.rules[idx] = nothing
    g.iseval[idx] = false
    g.types[idx] = nothing
    deleteat!(g.bytype[type], findall(isequal(idx), g.bytype[type]))
    if length(g.bytype[type]) == 0
        # remove type
        delete!(g.bytype, type)
        alltypes = collect(keys(g.bytype))
        g.isterminal = [isterminal(rule, alltypes) for rule ∈ g.rules]
        g.childtypes = [get_childtypes(rule, alltypes) for rule ∈ g.rules]
        g.bychildtypes = [BitVector([g.childtypes[i1] == g.childtypes[i2] for i2 ∈ 1:length(g.rules)]) for i1 ∈ 1:length(g.rules)]
    end
    for domain ∈ values(g.domains)
        domain[idx] = 0
    end
    return g
end


"""
    cleanup_removed_rules!(g::AbstractGrammar)

Removes any placeholders for previously deleted rules. 
This means that indices get shifted.

!!! warning
    When indices are shifted, this grammar can no longer be used to interpret 
    [`AbstractRuleNode`](@ref) trees created before the call to this function.
    These trees become meaningless. 
"""
function cleanup_removed_rules!(g::AbstractGrammar)
    rules_to_cleanup = findall(isequal(nothing), g.rules)
    # highest indices are removed first, otherwise their index will have shifted
    for v ∈ [g.rules, g.types, g.isterminal, g.iseval, g.childtypes]
        deleteat!(v, rules_to_cleanup)
    end
    # update bytype
    empty!(g.bytype)

    for (idx, type) ∈ enumerate(g.types)
        g.bytype[type] = push!(get(g.bytype, type, Int[]), idx)
    end
    g.domains = Dict(type => BitArray(r ∈ g.bytype[type] for r ∈ 1:length(g.rules)) for type ∈ keys(g.bytype))
    return g
end
