"""
	AbstractGrammar

Abstract type representing all grammars.
It is assumed that all grammar structs have at least the following attributes:

- `rules::Vector{Any}`: A list of RHS of rules (subexpressions).
- `types::Vector{Symbol}`: A list of LHS of rules (types, all symbols).
- `isterminal::BitVector`: A bitvector where bit `i` represents whether rule `i` is terminal.
- `iseval::BitVector`: A bitvector where bit `i` represents whether rule i is an eval rule.
- `bytype::Dict{Symbol,Vector{Int}}`: A dictionary that maps a type to all rules of said type.
- `domains::Dict{Symbol, BitVector}`: A dictionary that maps a type to a domain bitvector. 
  The domain bitvector has bit `i` set to true iff the `i`th rule is of this type.
- `childtypes::Vector{Vector{Symbol}}`: A list of types of the children for each rule. 
If a rule is terminal, the corresponding list is empty.
- `log_probabilities::Union{Vector{Real}, Nothing}`: A list of probabilities for each rule. 
If the grammar is non-probabilistic, the list can be `nothing`.

For concrete types, see `ContextSensitiveGrammar` within the `HerbGrammar` module.
"""
abstract type AbstractGrammar end

function Base.show(io::IO, grammar::AbstractGrammar)
    for i in eachindex(grammar.rules)
        println(io, i, ": ", grammar.types[i], " = ", grammar.rules[i])
    end
    return
end

Base.getindex(grammar::AbstractGrammar, typ::Symbol) = grammar.bytype[typ]
