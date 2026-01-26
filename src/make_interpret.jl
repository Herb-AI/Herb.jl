using MLStyle

# Treat as input if it follows _arg_ convention OR user explicitly listed it
"""
    _is_input_tag(tag, input_set)

Checks whether a tag is an input. 
A tag is treated as an *input terminal* if:

1. it is a `Symbol` that contains the substring `"_arg_"` (the default convention), OR
2. `input_set` is provided and `tag ∈ input_set`.
"""
_is_input_tag(tag, input_set) =
    tag isa Symbol && (occursin("_arg_", String(tag)) || (input_set !== nothing && (tag in input_set)))

# Example: :(Number + 1)  ->  Expr(:call, :+, :Number, 1)   (as *code*)
_pat_atom(x) =
    x isa Symbol ? QuoteNode(x) :
    x isa Expr   ? _pat_expr(x) :
    x

"""
    _pat_expr(ex::Expr)

Internal helper that converts an `Expr` value into an MLStyle-friendly pattern AST. E.g. :(Number + 1) cannot be used directly on the left-hand-side of `@match`.
"""
function _pat_expr(ex::Expr)
    return Expr(:call, :Expr, QuoteNode(ex.head), (_pat_atom(a) for a in ex.args)...)
end


"""
    get_relevant_tags(grammar::AbstractGrammar) -> Dict{Int,Any}

Compute a "tag" for each grammar rule index on which the generated interpreter matches on .

Tagging rules:

- Literal terminals (e.g. `1`, `2`) keep their literal values as tags.
- Input terminals like `x` or `_arg_1` remain symbols (e.g. `:x`).
- For `:call` rules:
  - "Pure operator" rules whose RHS is only nonterminals (e.g. `Number = Number + Number`) are tagged by the operator symbol (e.g. `:+`, `:*`).
  - "Composite" rules that contain literals or terminals on the RHS (e.g. `Number = Number + 1`,
    `Number = x * 2`) are tagged by the full expression `Expr` (e.g. `:(Number + 1)`).
- `:if` rules are tagged as `:IF`.
- `:block` rules are tagged as `:OpSeq`.
"""
function get_relevant_tags(grammar::AbstractGrammar)
    tags = Dict{Int,Any}()
    for (ind, r) in pairs(grammar.rules)
        tags[ind] = if r isa Expr
            @match r.head begin
                :block => :OpSeq
                :if    => :IF
                :call  => begin
                    op = r.args[1]
                    args = r.args[2:end]
                    pure =
                        (op isa Symbol) &&
                        all(a -> (a isa Symbol) && (a in grammar.types), args)
                    pure ? op : r  # composites like (Number + 1) keep full Expr as tag
                end
                _ => r.head
            end
        else
            r
        end
    end
    return tags
end


"""
    build_match_cases(grammar::AbstractGrammar; interp_name=:interpret, input_symbols=nothing) -> Vector{Expr}

Generate the case list inserted into `MLStyle.@match`.

The generated cases implement a recursive interpreter of a `prog::AbstractRuleNode`:
"""
function build_match_cases(
        grammar::AbstractGrammar;
        interp_name::Symbol = :interpret,
        input_symbols::Union{Nothing,AbstractVector{Symbol}} = nothing,
    )
    tags  = get_relevant_tags(grammar)
    cases = Expr[]

    input_set = input_symbols === nothing ? nothing : Set(input_symbols)

    # Build an evaluation Expr from a rule expression, consuming `c[i]` for each nonterminal occurrence.
    function emit_eval(x, next_child::Base.RefValue{Int})
        if x isa Symbol
            if x in grammar.types
                i = next_child[]
                next_child[] += 1
                return :( $interp_name(c[$i], grammar_tags, input) )
            elseif _is_input_tag(x, input_set)
                return :( input[$(QuoteNode(x))] )
            else
                return x
            end
        elseif x isa Expr
            if x.head == :call
                f = x.args[1]
                args = [emit_eval(a, next_child) for a in x.args[2:end]]
                return Expr(:call, f, args...)
            elseif x.head == :if
                cond = emit_eval(x.args[1], next_child)
                tbr  = emit_eval(x.args[2], next_child)
                fbr  = emit_eval(x.args[3], next_child)
                return Expr(:if, cond, tbr, fbr)
            else
                return Expr(x.head, (emit_eval(a, next_child) for a in x.args)...)
            end
        else
            return x
        end
    end

    for (ind, r) in pairs(grammar.rules)
        tag = tags[ind]

        if r isa Expr && r.head == :call
            if tag isa Symbol
                # pure operator rule: match the symbol value (:+, :*, ...)
                nargs = length(r.args) - 1
                args = [:( $interp_name(c[$i], grammar_tags, input) ) for i in 1:nargs]
                rhs = Expr(:call, tag, args...)  # calls + / * / etc.
                push!(cases, :($(QuoteNode(tag)) => $rhs))  # :+ => +(args...)

            else
                # partial: match structurally on the Expr tag (avoid :(...) patterns)
                nxt = Ref(1)
                rhs = emit_eval(r, nxt)
                pat = _pat_expr(tag)  # e.g. Expr(:call, :+, :Number, 1)
                push!(cases, :($pat => $rhs))
            end
        elseif r isa Expr && r.head == :if
            push!(cases, :( :IF =>
                $interp_name(c[1], grammar_tags, input) ?
                    $interp_name(c[2], grammar_tags, input) :
                    $interp_name(c[3], grammar_tags, input)
            ))

        elseif _is_input_tag(tag, input_set)
            push!(cases, :($(QuoteNode(tag)) => input[$(QuoteNode(tag))] ))

        elseif tag isa Symbol && !(tag in grammar.types) && !_is_input_tag(tag, input_set)
            lhs = :( $interp_name(c[1], grammar_tags, input) )
            rhs = :( $interp_name(c[2], grammar_tags, input) )
            op_expr = Expr(:call, tag, lhs, rhs)
            push!(cases, :( $(QuoteNode(tag)) => $op_expr ))
        end
    end

    # Default branch: read from input if it is an input tag, otherwise return tag.
    push!(cases, :( _ =>
        begin
            tag = grammar_tags[r]
            return tag
        end
    ))

    return cases
end


"""
    make_interpreter(grammar::AbstractGrammar; name=:interpret, input_symbols=nothing) -> Expr

Return an expression defining an interpreter function `name(prog, grammar_tags, input)`.

Typical usage:

```julia
g = @cfgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
    Number = Number + 1
    Number = x * 2
end
rn = @rulenode 5{4{3,2},7}

tags = get_relevant_tags(g)
ex = make_interpreter(g; name=:interpret_sui, input_symbols=[:x])
Core.eval(Main, ex)  # or Core.eval(@__MODULE__, ex) to eval into the current module
out  = interpret_sui(rn, tags, Dict(:x => 1))
```
"""
function make_interpreter(
        grammar::AbstractGrammar;
        name::Symbol = :interpret,
        input_symbols::Union{Nothing,AbstractVector{Symbol}} = nothing,
    )
    cases = build_match_cases(grammar; interp_name=name, input_symbols=input_symbols)

    # Build the @match call as syntax first 
    match_expr = quote
        MLStyle.@match grammar_tags[r] begin
            $(cases...)
        end
    end

    match_ast = Base.macroexpand(@__MODULE__, match_expr; recursive=true)

    return quote
        function $(name)(prog::AbstractRuleNode,
                         grammar_tags::Dict{Int,Any},
                         input::Dict{Symbol,Any})
            r = get_rule(prog)
            c = get_children(prog)
            $match_ast
        end

        function $(name)(prog::AbstractRuleNode,
                         grammar_tags::Dict{Int,Any},
                         input::AbstractVector{Dict{Symbol,Any}})
            return $(name).((prog,),(grammar_tags,),input)
        end
    end
end