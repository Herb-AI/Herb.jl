using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__) 

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
    _qualify(target_module::Module, f)

Resolve symbol `f` in `target_module` at compile time.
"""
function _qualify(target_module::Module, f)
    return f isa Symbol ? GlobalRef(target_module, f) : f
end


"""
    build_match_cases(grammar; target_module=@__MODULE__, input_symbols=nothing)

Return a vector of "guarded return" branches of the form:

    r == k && return <rhs>

These branches are intended to be spliced into a block after
`r = get_rule(prog); c = get_children(prog)`.

Returns a vector of branching expressions.
"""
function build_match_cases(
    grammar::AbstractGrammar;
    target_module::Module = @__MODULE__,
    input_symbols::Union{Nothing,AbstractVector{Symbol}} = nothing,
)
    input_set = input_symbols === nothing ? nothing : Set(input_symbols)

    # recurse on child i as: self(self, c[i], input)
    recur(i) = :( self(self, c[$i], input) )

    # Emit code to evaluate a rule RHS, consuming children c[i] for nonterminals.
    function emit_eval(x, next_child::Base.RefValue{Int})
        if x isa Symbol
            if x in grammar.types
                i = next_child[]
                next_child[] += 1
                return recur(i)
            elseif _is_input_tag(x, input_set)
                return :( input[$(QuoteNode(x))] )
            else
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
            op   = rhs_rule.args[1]
            args = rhs_rule.args[2:end]

            pure =
                (op isa Symbol) &&
                all(a -> (a isa Symbol) && (a in grammar.types), args)

            if pure
                nargs = length(args)
                child_vals = [recur(i) for i in 1:nargs]
                rhs_code = Expr(:call, _qualify(target_module, op), child_vals...)
            else
                nxt = Ref(1)
                rhs_code = emit_eval(rhs_rule, nxt)
            end

        elseif rhs_rule isa Expr && rhs_rule.head == :if
            nxt = Ref(1)
            rhs_code = emit_eval(rhs_rule, nxt)

        elseif rhs_rule isa Symbol
            if rhs_rule in grammar.types
                rhs_code = recur(1)  # Start = Number  etc.
            elseif _is_input_tag(rhs_rule, input_set)
                rhs_code = :( input[$(QuoteNode(rhs_rule))] )
            else
                rhs_code = GlobalRef(target_module, rhs_rule)
            end

        else
            rhs_code = rhs_rule
        end

        push!(branches, :( r == $(ind) && return $rhs_code ))
    end

    return branches
end


struct GeneratedInterpreter{F}
    core::F
end

# Single input
function (gi::GeneratedInterpreter)(prog::HerbCore.AbstractRuleNode,
                                   input::AbstractDict{Symbol,Any})
    return gi.core(gi.core, prog, input)
end

# Vector of inputs
function (gi::GeneratedInterpreter)(prog::HerbCore.AbstractRuleNode,
                                   inputs::AbstractVector{<:AbstractDict{Symbol,Any}})
    return (gi.core).((gi.core,), (prog,), inputs)   # broadcasts (self, prog, input)
end

function (gi::GeneratedInterpreter)(prog::HerbCore.AbstractRuleNode,
                                   ex::HerbSpecification.IOExample)
    return gi(prog, ex.in)
end

function (gi::GeneratedInterpreter)(prog::HerbCore.AbstractRuleNode,
                                   exs::AbstractVector{<:HerbSpecification.IOExample})
    return [gi(prog, ex) for ex in exs]
end


"""
    make_interpreter(grammar::AbstractGrammar; input_symbols::Union{Nothing,AbstractVector{Symbol}} = nothing, target_module::Module = @__MODULE__, cache_module::Module = HerbInterpret)


Construct a fast, *runtime-generated* interpreter for programs represented as
`HerbCore.AbstractRuleNode`s.

The returned value is a callable `GeneratedInterpreter` (a small wrapper around a
`RuntimeGeneratedFunctions.RuntimeGeneratedFunction`) that can be applied to:

- a single input dictionary:
  `interp(prog, input::AbstractDict{Symbol,Any})`
- a vector of input dictionaries:
  `interp(prog, inputs::AbstractVector{<:AbstractDict{Symbol,Any}})`
- a single `HerbSpecification.IOExample`:
  `interp(prog, ex::IOExample)` (uses `ex.in`)
- a vector of `IOExample`s:
  `interp(prog, exs::AbstractVector{<:IOExample})`

## Arguments

- `grammar`: The grammar whose rule indices define the operational semantics.
  The interpreter dispatches by `r = HerbCore.get_rule(prog)`.

## Keyword arguments

- `input_symbols`: Optional list of symbols that should be interpreted as *inputs*.  If provided, terminals matching these symbols (and any symbol following the `_arg_` convention) are read from the `input` dict.

- `target_module`: Module in which operator/function symbols appearing in the grammar are resolved. This is important when the grammar uses domain-specific primitives (e.g. `concat_cvc`, `substr_cvc`) that are defined in a benchmark module rather than in the caller’s module.

- `cache_module`: Module used by `RuntimeGeneratedFunctions.jl` to store its internal cache. 
"""
function make_interpreter(grammar::AbstractGrammar;
    input_symbols::Union{Nothing,AbstractVector{Symbol}} = nothing,
    target_module::Module = @__MODULE__,
    cache_module::Module = HerbInterpret
)
    # ensure the cache exists in the chosen cache module
    RuntimeGeneratedFunctions.init(cache_module)

    # build if-then-else statements to evaluate the expressions
    branches = build_match_cases(grammar;
        target_module = target_module,
        input_symbols = input_symbols
    )

    # Add error for non-existent indices
    cascade = Expr(:block, branches..., :(error("No matching rule index: ", r)))

    # Bit of meta-programming magic:
    # Constructs an anonymous function with an extra self arg for recursion.
    ex = :(function (self, prog, input)
        r = HerbCore.get_rule(prog)
        c = HerbCore.get_children(prog)
        $cascade
    end)
    Base.remove_linenums!(ex)

    # Call RuntimeGeneratedFunction on this, so we can directly use it
    core = RuntimeGeneratedFunctions.RuntimeGeneratedFunction(cache_module, target_module, ex)
    return GeneratedInterpreter(core)
end


"""
    build_match_cases_stateful_rgf(grammar; target_module=@__MODULE__, state_name=:state, max_steps=1000)

Like `build_match_cases_stateful`, but emits code for a RuntimeGeneratedFunction body:
- recursion is expressed as `self(self, child, state)`
- `WHILE` is inlined (bounded by `max_steps`) to avoid needing external helpers
"""
function build_match_cases_stateful(
        grammar::AbstractGrammar;
        target_module::Module = @__MODULE__,
        state_name::Symbol = :state,
    )
    branches = Expr[]
    max_steps=1000

    # recurse into i-th child with threaded state
    child_call(i) = :( self(self, c[$i], $(state_name)) )

    for (ind, rhs_rule) in pairs(grammar.rules)
        rhs_code = nothing

        if rhs_rule isa Expr
            if rhs_rule.head == :block
                # (A; B) sequencing
                rhs_code = :( self(self, c[2], self(self, c[1], $(state_name))) )

            elseif rhs_rule.head == :call && rhs_rule.args[1] == :(;)
                # alternative encoding of sequencing
                rhs_code = :( self(self, c[2], self(self, c[1], $(state_name))) )

            elseif rhs_rule.head == :call && rhs_rule.args[1] == :IF
                rhs_code = :( self(self, c[1], $(state_name)) ?
                              self(self, c[2], $(state_name)) :
                              self(self, c[3], $(state_name)) )

            elseif rhs_rule.head == :call && rhs_rule.args[1] == :WHILE
                # Inline a bounded while-loop:
                # WHILE(cond, body)
                rhs_code = quote
                    local st  = $(state_name)
                    local ctr = $(max_steps)
                    while ctr > 0 && self(self, c[1], st)
                        st = self(self, c[2], st)
                        ctr -= 1
                    end
                    st
                end

            elseif rhs_rule.head == :call
                f    = rhs_rule.args[1]
                args = rhs_rule.args[2:end]

                # Most stateful primitives are 0-arg: inc(), moveRight(), etc.
                if isempty(args)
                    rhs_code = Expr(:call, _qualify(target_module, f), state_name)
                else
                    # For calls with nonterminals, interpret children and pass results
                    nargs      = length(args)
                    child_vals = [child_call(i) for i in 1:nargs]
                    rhs_code   = Expr(:call, _qualify(target_module, f), child_vals...)
                end
            else
                # fallback: forward to first child
                rhs_code = :( self(self, c[1], $(state_name)) )
            end

        elseif rhs_rule isa Symbol
            if rhs_rule in grammar.types
                # Alias: Start = Sequence, etc.
                rhs_code = :( self(self, c[1], $(state_name)) )
            else
                # Rare: terminal symbol treated as primitive on state
                rhs_code = Expr(:call, _qualify(target_module, rhs_rule), state_name)
            end

        else
            # literal terminal
            rhs_code = rhs_rule
        end

        push!(branches, :( r == $(ind) && return $rhs_code ))
    end

    return branches
end


struct GeneratedStatefulInterpreter{F}
    core::F  # RuntimeGeneratedFunction
end

# single state
function (gi::GeneratedStatefulInterpreter)(prog::HerbCore.AbstractRuleNode, state)
    return gi.core(gi.core, prog, state)
end

# vector of states
function (gi::GeneratedStatefulInterpreter)(prog::HerbCore.AbstractRuleNode, states::AbstractVector)
    core = gi.core
    return core.((core,), (prog,), states)
end

# IOExample (state in :_arg_1)
function (gi::GeneratedStatefulInterpreter)(prog::HerbCore.AbstractRuleNode, ex::HerbSpecification.IOExample)
    return gi(prog, ex.in[:_arg_1])
end

# vector of IOExamples
function (gi::GeneratedStatefulInterpreter)(prog::HerbCore.AbstractRuleNode, exs::AbstractVector{<:HerbSpecification.IOExample})
    return [gi(prog, ex) for ex in exs]
end


"""
    make_stateful_interpreter_rgf(grammar; target_module=@__MODULE__, cache_module=HerbInterpret, max_steps=1000)

Build a RuntimeGeneratedFunctions-backed state-threading interpreter.

- `target_module` controls where primitives (inc, moveRight, etc.) are resolved.
- `cache_module` controls where RGF stores its cache. **This module must have**
  `RuntimeGeneratedFunctions.init(@__MODULE__)` executed at module top level.
- `max_steps` bounds generated WHILE loops.
"""
function make_stateful_interpreter(
        grammar::AbstractGrammar;
        target_module::Module = @__MODULE__,
        cache_module::Module  = HerbInterpret,
    )
    # IMPORTANT: cache_module must be initialized at module top-level.
    RuntimeGeneratedFunctions.init(cache_module)

    branches = build_match_cases_stateful(grammar;
        target_module = target_module,
        state_name    = :state
    )

    cascade = Expr(:block, branches..., :(error("No matching rule index: ", r)))

    # RGF body is an anonymous function. We add `self` for recursion.
    ex = :(function (self, prog, state)
        r = HerbCore.get_rule(prog)
        c = HerbCore.get_children(prog)
        $cascade
    end)
    Base.remove_linenums!(ex)

    core = RuntimeGeneratedFunctions.RuntimeGeneratedFunction(cache_module, target_module, ex)
    return GeneratedStatefulInterpreter(core)
end
