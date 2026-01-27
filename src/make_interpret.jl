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


# Resolve symbol `f` in `target_module` at compile time.
function _qualify(target_module::Module, f)
    return f isa Symbol ? GlobalRef(target_module, f) : f
end


"""
    build_match_cases(grammar; interp_name=:interpret, input_symbols=nothing, target_module=@__MODULE__) -> Vector{Expr}

Return a vector of "guarded return" branches of the form:

    r == k && return <rhs>

These branches are intended to be spliced into a block after
`r = get_rule(prog); c = get_children(prog)`.
"""
function build_match_cases(
        grammar::AbstractGrammar;
        interp_name::Symbol = :interpret,
        input_symbols::Union{Nothing,AbstractVector{Symbol}} = nothing,
        target_module::Module = @__MODULE__,
    )
    input_set = input_symbols === nothing ? nothing : Set(input_symbols)

    # Emit code to evaluate a rule RHS, consuming children c[i] for nonterminals.
    function emit_eval(x, next_child::Base.RefValue{Int})
        if x isa Symbol
            if x in grammar.types
                i = next_child[]
                next_child[] += 1
                return :( $interp_name(c[$i], input) )
            elseif _is_input_tag(x, input_set)
                return :( input[$(QuoteNode(x))] )
            else
                # Treat as a constant/function name in the target module
                return GlobalRef(target_module, x)
            end
        elseif x isa Expr
            if x.head == :call
                f = _qualify(target_module, x.args[1])
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

    branches = Expr[]

    for (ind, rhs_rule) in pairs(grammar.rules)
        rhs_code = nothing

        if rhs_rule isa Expr && rhs_rule.head == :call
            op = rhs_rule.args[1]
            args = rhs_rule.args[2:end]

            pure =
                (op isa Symbol) &&
                all(a -> (a isa Symbol) && (a in grammar.types), args)

            if pure
                nargs = length(args)
                child_vals = [:( $interp_name(c[$i], input) ) for i in 1:nargs]
                rhs_code = Expr(:call, _qualify(target_module, op), child_vals...)
            else
                nxt = Ref(1)
                rhs_code = emit_eval(rhs_rule, nxt)
            end

        elseif rhs_rule isa Expr && rhs_rule.head == :if
            nxt = Ref(1)
            rhs_code = emit_eval(rhs_rule, nxt)

        elseif rhs_rule isa Symbol
            # Symbol terminals: input if configured, else constant symbol resolved in target_module
            if _is_input_tag(rhs_rule, input_set)
                rhs_code = :( input[$(QuoteNode(rhs_rule))] )
            else
                rhs_code = GlobalRef(target_module, rhs_rule)
            end

        else
            # Literal terminals: Int, String, etc.
            rhs_code = rhs_rule
        end

        push!(branches, :( r == $(ind) && return $rhs_code ))
    end

    return branches
end



"""
    make_interpreter(grammar; name=:interpret, input_symbols=nothing, target_module=@__MODULE__)

Generate an interpreter as a simple cascade on the rule index `r`.
The generated function signature is:

    name(prog::AbstractRuleNode, input::AbstractDict{Symbol,Any})

and additionally supports:

    name(prog::AbstractRuleNode, inputs::AbstractVector{<:AbstractDict{Symbol,Any}})
"""
function make_interpreter(
        grammar::AbstractGrammar;
        name::Symbol = :interpret,
        input_symbols::Union{Nothing,AbstractVector{Symbol}} = nothing,
        target_module::Module = @__MODULE__,
    )
    branches = build_match_cases(grammar;
        interp_name=name,
        input_symbols=input_symbols,
        target_module=target_module,
    )

    cascade = Expr(:block,
        branches...,
        :( error("No matching rule index: ", r) )
    )

    return quote
        using HerbCore
        function $(name)(prog::HerbCore.AbstractRuleNode,
                         input::AbstractDict{Symbol,Any})
            r = HerbCore.get_rule(prog)
            c = HerbCore.get_children(prog)
            $cascade
        end

        function $(name)(prog::HerbCore.AbstractRuleNode,
                         inputs::AbstractVector{<:AbstractDict{Symbol,Any}})
            return $(name).((prog,), inputs)
        end
    end
end


"""
    @make_interpreter grammar [name=:interpret] [input_symbols=nothing] [module=<caller>] [target_module=<caller>]

Generate and define an interpreter function for `grammar`.

Here we return code that:
  1) evaluates `grammar_expr` at runtime,
  2) builds the interpreter definition expression via `HerbInterpret.make_interpreter`,
  3) evaluates that definition into the chosen module.
"""
macro make_interpreter(grammar_expr, args...)
    # Defaults
    name_expr   = QuoteNode(:interpret)
    input_expr  = :(nothing)
    module_expr = :(nothing)  # optional target module

    # Parse options (keyword-like)
    for a in args
        if a isa Expr && a.head == :(=) && length(a.args) == 2
            key, val = a.args[1], a.args[2]
            if key === :name
                # accept only literal symbols; if user passes a bare identifier, treat it as symbol
                name_expr = val isa Symbol ? QuoteNode(val) : val
            elseif key === :input_symbols
                input_expr = val
            elseif key === :module || key === :target_module
                module_expr = val
            else
                error("@make_interpreter: unknown option $(key). Use name=..., input_symbols=..., and optionally module=...")
            end
        else
            error("@make_interpreter: expected options like name=... and/or input_symbols=... (and optionally module=...), got: $(a)")
        end
    end

    # __module__ is the caller module. This is where we want to evaluate our expressions.
    # We capture this outside of the quote block below, so the runtime code can refer to it safely.
    caller_mod = __module__

    # Expand into runtime code (IMPORTANT!)
    # `esc` tells Julia that references inside the returned syntax should be resolved in the *caller’s scope* (where the macro is used), not in the macro’s defining module.
    return esc(quote
        # Why we use locals here:
        # - locals do not exist macro expansion time, so we force the compiler to run `grammar_expr` only when teh returned code runs.
        # - locals avoid captuing names int he caller module.
        local _caller = $(QuoteNode(caller_mod))

        # grammar_expr runs at runtime, so `g` can be local inside a  @testset or function
        local _g = $(grammar_expr)

        local _name = $(name_expr)
        _name isa Symbol || error("@make_interpreter: name must be a Symbol, got $(typeof(_name))")

        local _inputs = $(input_expr)
        (_inputs === nothing || _inputs isa AbstractVector{Symbol}) ||
            error("@make_interpreter: input_symbols must be nothing or a Vector{Symbol}, got $(typeof(_inputs))")

        # If no module was provided, install into caller module.
        local _target = $(module_expr) === nothing ? _caller : $(module_expr)
        _target isa Module || error("@make_interpreter: module/target_module must evaluate to a Module, got $(typeof(_target))")

        local _ex = HerbInterpret.make_interpreter(_g; name=_name, input_symbols=_inputs, target_module=_target)
        # Evaluate here, so it is hidden from user
        Core.eval(_target, _ex)

        # do not change this to `return nothing`! This will evaluate in the caller function and short-cut it
        nothing
    end)
end
