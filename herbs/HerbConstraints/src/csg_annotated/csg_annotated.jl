"""
   AnnotatedGrammar

Represents an annotated context-sensitive grammar.
Fields:
- grammar: The underlying ContextSensitiveGrammar
- bylabel: A dictionary mapping labels to their corresponding rules
- rule_annotations: A dictionary mapping rule indices to their corresponding annotations
"""
mutable struct AnnotatedGrammar
   grammar::ContextSensitiveGrammar
   bylabel::Dict{String, Vector{Int}}
   rule_annotations::Dict{Int,Vector{Any}}

    function AnnotatedGrammar(grammar::ContextSensitiveGrammar, bylabel::Dict{String, Vector{Int}}, rule_annotations::Dict{Int,Vector{Any}})
        annotated_grammar = new(grammar, bylabel, rule_annotations)
        for rule_index in keys(rule_annotations)
            for annotation in rule_annotations[rule_index]
                _annotation2constraints!(annotated_grammar, rule_index, annotation)
            end
        end
        return annotated_grammar
    end
end

"""
    expr2csgrammar(expression::Expr)::AnnotatedGrammar  

A function for converting an `Expr` to a [`AnnotatedGrammar`](@ref).
If the expression is hardcoded, you should use the [`@csgrammar_annotated`](@ref) macro.
Only expressions in the correct format (see [`csgrammar_annotated`](@ref)) can be converted.

# Examples
```julia-repl
    num_annotated = quote        
        zero::  Number = 0             
        one::  Number = 1     
        constants:: Number = |(2:4) 
        variables:: Number = x | y              
        minus::      Number = -Number           := (identity("zero"))
        plus::      Number = Number + Number    := (associative, commutative, identity("zero"), inverse("minus"))
        times::     Number = Number * Number    := (associative, commutative, identity("one"), distributive_over("plus"))
    end
    annotated_grammar = HerbConstraints.expr2csgrammar_annotated(num_annotated)
```
"""
function expr2csgrammar_annotated(expr::Expr)::AnnotatedGrammar
    grammar, bylabel, rule_annotations = _process_expression(expr)
    return AnnotatedGrammar(grammar, bylabel, rule_annotations)
end

"""    
    @csgrammar_annotated ex

Construct an [`AnnotatedGammar`](@ref).
Define an annotated grammar and return it as a ContextSensitiveGrammar.
Allows for adding optional annotations per rule.
As well as that, allows for adding optional labels per rule, which can be referenced in annotations. 
Syntax is backwards-compatible with @csgrammar.Converts an annotation to constraints.

Supported annotations:
- commutative: creates an Ordered constraint on the (two) children of the rule
- associative: creates Forbidden constraints, such that rule can only be applied in a path formation (no sub trees of the rule r{r,r} allowed)
- identity(label): creates Forbidden constraints for applying the rule on an identity element from the specified domain
- inverse(label1): creates Forbidden constraints for applying the rule on an an element and its inverse from the specified domain (assumes inverses a single child)
- distributive_over(label): creates Forbidden constraints for applying the specified domain on (two) children of the rule with a common child (in same position, unless commutative)

# Examples

```julia-repl
g₁ = @csgrammar_annotated begin
    Element = 1
    Element = x
    Element = Element + Element := commutative
    Element = Element * Element := (commutative, associativity)
end
```

```julia-repl
g₁ = @csgrammar_annotated begin
    zero::           Element = 0
    one::            Element = 1
    variable::       Element = x
    addition::       Element = Element + Element := (
                                                       commutative,
                                                       associativity,
                                                       identity("zero"),
                                                    )
    multiplication:: Element = Element * Element := (commutative, associativity, identity("one"), distributive_over("addition"))
end
```
"""
macro csgrammar_annotated(ex)
    return :(expr2csgrammar_annotated($(QuoteNode(ex))))
end

"""
    get_grammar(annotated_grammar::AnnotatedGrammar)::ContextSensitiveGrammar

Returns the underlying ContextSensitiveGrammar.
"""
function get_grammar(annotated_grammar::AnnotatedGrammar)::ContextSensitiveGrammar
    return annotated_grammar.grammar
end

"""
    get_bylabel(annotated_grammar::AnnotatedGrammar)::Dict{String, Vector{Int}}

Returns a dictionary of the rules associated with each label.
"""
function get_bylabel(annotated_grammar::AnnotatedGrammar)::Dict{String, Vector{Int}}
    return annotated_grammar.bylabel
end


"""
    get_labeldomain(annotated_grammar::AnnotatedGrammar)::Dict{String, BitVector}

Returns a dictionary with the domain BitVector of each label.
"""
function get_labeldomain(annotated_grammar::AnnotatedGrammar)::Dict{String, BitVector}
    return Dict(
        label => BitArray(r ∈ rules for r ∈ 1:length(get_grammar(annotated_grammar).rules))
        for (label, rules) in get_bylabel(annotated_grammar)
    )
end

"""
    get_rule_annotations(annotated_grammar::AnnotatedGrammar)::Dict{Int,Vector{Any}}

Returns the rule annotations dictionary.
"""
function get_rule_annotations(annotated_grammar::AnnotatedGrammar)::Dict{Int,Vector{Any}}
    return annotated_grammar.rule_annotations
end

"""
    addconstraint!(annotated_grammar::AnnotatedGrammar, constraint::Constraint)
Adds a constraint to the underlying ContextSensitiveGrammar.
"""
function HerbGrammar.addconstraint!(annotated_grammar::AnnotatedGrammar, constraint::HerbCore.AbstractConstraint)
    addconstraint!(get_grammar(annotated_grammar), constraint)
end

