
"""
	expr2pcsgrammar(ex::Expr)::ContextSensitiveGrammar

Function for converting an `Expr` to a [`ContextSensitiveGrammar`](@ref) with probabilities.
If the expression is hardcoded, you should use the `@pcsgrammar` macro.
Only expressions in the correct format (see [`@pcsgrammar`](@ref)) can be converted.

### Example usage:
	
```@example
grammar = expr2pcsgrammar(
	begin
		0.5 : R = x
		0.3 : R = 1 | 2
		0.2 : R = R + R
	end
)
```
"""
function expr2pcsgrammar(ex::Expr)::ContextSensitiveGrammar
	rules = Any[]
	types = Symbol[]
	probabilities = Real[]
	bytype = Dict{Symbol,Vector{Int}}()
	for e ∈ ex.args
		if e isa Expr 
			maybe_rules = parse_probabilistic_rule(e)
			isnothing(maybe_rules) && continue 	# if rules is nothing, skip
			s, prvec = maybe_rules
			
			for (p, r) ∈ prvec
				push!(rules, r)
				push!(types, s)
				push!(probabilities, p)
				bytype[s] = push!(get(bytype, s, Int[]), length(rules))
			end
		end
	end
	alltypes = collect(keys(bytype))
	log_probabilities = [log(x) for x ∈ probabilities]
	is_terminal = [isterminal(rule, alltypes) for rule in rules]
	is_eval = [iseval(rule) for rule in rules]
	childtypes = [get_childtypes(rule, alltypes) for rule in rules]
	domains = Dict(type => BitArray(r ∈ bytype[type] for r ∈ 1:length(rules)) for type ∈ alltypes)
	bychildtypes = [BitVector([childtypes[i1] == childtypes[i2] for i2 ∈ 1:length(rules)]) for i1 ∈ 1:length(rules)]

	normalize!(ContextSensitiveGrammar(rules, types, is_terminal, is_eval, bytype, domains, childtypes, bychildtypes, log_probabilities))
end

"""
	parse_probabilistic_rule(e::Expr)

Parses a single (potentially shorthand) derivation rule of a probabilistic [`ContextSensitiveGrammar`](@ref).
Returns `nothing` if the rule is not probabilistic, otherwise a `Tuple` of its type and a 
`Vector` of probability-rule pairs it expands into.
"""
function parse_probabilistic_rule(e::Expr)
	e = Base.remove_linenums!(e)
	prvec = Tuple{Real, Any}[]
	if e.head == :(=)
		left = e.args[1]		# name of return type and probability
		if left isa Expr && left.head == :call && left.args[1] == :(:)
			p = left.args[2] 			# Probability
			s = left.args[3]			# Return type
			rule = e.args[2].args[1] 	# extract rule from block expr

			rvec = Any[]
			parse_rule!(rvec, rule)
			for r ∈ rvec
				# Divide the probability of this line by the number of rules it defines.
				push!(prvec, (p / length(rvec), r))
			end

			return s, prvec
		else
			@error "Rule without probability encountered in probabilistic grammar. Rule ignored."
			return nothing
		end
	end
end


"""
	normalize!(grammar::ContextSensitiveGrammar, type::Union{Symbol, Nothing}=nothing)

A function for normalizing the probabilities of a probabilistic [`ContextSensitiveGrammar`](@ref).
If the optional `type` argument is provided, only the rules of that type are normalized. 
If the grammar is not probabilistic, i.e. `grammar.log_probabilities==nothing`, a uniform distribution is initialized.
"""
function normalize!(grammar::ContextSensitiveGrammar, type::Union{Symbol, Nothing}=nothing)
	if !isprobabilistic(grammar)
		@warn "Requesting normalization in a non-probabilistic grammar. Uniform distribution is assumed."
		init_probabilities!(grammar)
		return grammar
	end

	probabilities = map(exp, grammar.log_probabilities)
	types = isnothing(type) ? keys(grammar.bytype) : [type]

	for t ∈ types
		total_prob = sum(probabilities[i] for i ∈ grammar.bytype[t])
		if !(total_prob ≈ 1)
			for i ∈ grammar.bytype[t]
				probabilities[i] /= total_prob
			end
		end
	end
	
	grammar.log_probabilities = map(log, probabilities)
	return grammar
end


"""
    init_probabilities!(grammar::AbstractGrammar)

If the grammar is not probabilistic yet, initializes the grammar with uniform probabilities per type. If the grammar is already probabilistic, no changed are made.
"""
function init_probabilities!(grammar::AbstractGrammar) 
	if isprobabilistic(grammar) 
		@warn "Tried to init probabilities for grammar, but it is already probabilistic. No changes are made."
	else
		grammar.log_probabilities = zeros(length(grammar.rules))
		normalize!(grammar)
	end
	return grammar
end


"""
	@pcsgrammar

A macro for defining a probabilistic [`ContextSensitiveGrammar`](@ref). 

### Example usage:
```julia
grammar = @pcsgrammar begin
	0.5 : R = x
	0.3 : R = 1 | 2
	0.2 : R = R + R
end
```

### Syntax:

The syntax of rules is identical to the syntax used by [`@csgrammar`](@ref):

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

Every rule is also prefixed with a probability.
Rules and probabilities are separated using the `:` symbol.
If multiple rules are defined on a single line, the probability is equally divided between the rules.
The sum of probabilities for all rules of a certain non-terminal symbol should be equal to 1. 
The probabilities are automatically scaled if this isn't the case.


### Related:

- [`@csgrammar`](@ref) uses a similar syntax to create non-probabilistic [`ContextSensitiveGrammar`](@ref)s.
"""
macro pcsgrammar(ex)
	return :(expr2pcsgrammar($(QuoteNode(ex))))
end

macro pcfgrammar(ex)
	return :(expr2pcsgrammar($(QuoteNode(ex))))
end


"""
    log_probability(grammar::AbstractGrammar, index::Int)::Real

Returns the log probability for the rule at `index` in the grammar.
    
!!! warning
    If the grammar is not probabilistic, a warning is displayed, and a uniform probability is assumed.
"""
function log_probability(grammar::AbstractGrammar, index::Int)::Real
    if !isprobabilistic(grammar)
        @warn "Requesting probability in a non-probabilistic grammar.\nUniform distribution is assumed."
        # Assume uniform probability
        return log(1 / length(grammar.bytype[grammar.types[index]]))
    end
    return grammar.log_probabilities[index]
end

"""
    probability(grammar::AbstractGrammar, index::Int)::Real

Return the probability for a rule in the grammar.
Use [`log_probability`](@ref) whenever possible.

!!! warning
    If the grammar is not probabilistic, a warning is displayed, and a uniform probability is assumed.
"""
function probability(grammar::AbstractGrammar, index::Int)::Real
    if !isprobabilistic(grammar)
        @warn "Requesting probability in a non-probabilistic grammar.Uniform distribution is assumed."
        # Assume uniform probability
        return 1 / length(grammar.bytype[grammar.types[index]])
    end
    return ℯ^grammar.log_probabilities[index]
end

"""
    isprobabilistic(grammar::AbstractGrammar)::Bool

Function returns whether a [`AbstractGrammar`](@ref) is probabilistic.
"""
isprobabilistic(grammar::AbstractGrammar)::Bool = !(grammar.log_probabilities ≡ nothing)