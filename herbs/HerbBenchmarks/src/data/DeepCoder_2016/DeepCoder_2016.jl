module DeepCoder_2016
using HerbCore
using HerbSpecification
using HerbGrammar
using HerbInterpret

using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

using JSON

include("data.jl")
include("base_grammar.jl")
include("grammars.jl")

include("list_functions.jl")


function set_base_grammar!(grammar_with_spec::AbstractGrammar)
    global base_grammar_deepcoder = grammar_with_spec
end

function make_deepcoder_interpreter(g)
    return make_interpreter(g; target_module=DeepCoder_2016, cache_module=DeepCoder_2016)
end

"""
    parse_deepcoder_problem(filename::AbstractString, base_grammar::AbstractGrammar)::Problem

Parses a DeepCoder problem from a file given a base grammar.
"""
function parse_deepcoder_problem_and_grammar(filename::AbstractString,
    base_grammar::AbstractGrammar)
    raw = JSON.parsefile(filename)

    examples = IOExample[]
    for ex in raw["examples"]
        args = split_inputs(ex["input"])
        out = normalize_value(ex["output"])
        push!(examples, IOExample(args, out))
    end

    number = match(r"\d+", raw["name"])
    number === nothing && error("Could not extract problem number from: $filename")
    problem_name = "problem_" * lpad(number.match, 3, '0')
    problem = Problem(problem_name, examples)

    # infer from first example (DeepCoder tasks are consistent)
    sig = infer_signature(examples[1].in)
    start_nt = infer_output_nt(examples[1].out)

    # combine base + extras
    g = deepcopy(base_grammar)
    add_extras!(g, sig, start_nt)

    return problem, g
end

function split_inputs(raw_in)::Dict{Symbol,Any}
    @assert raw_in isa Vector "DeepCoder 'input' must be an array"
    n = length(raw_in)
    @assert 1 <= n <= 2 "Expected 1 or 2 inputs, got $n"

    tojl(v) = v isa Vector ? map(Int, v) : Int(v)

    args = Dict{Symbol,Any}()
    args[:_arg_1] = tojl(raw_in[1])
    if n == 2
        args[:_arg_2] = tojl(raw_in[2])
    end
    return args
end

function infer_signature(args::Dict{Symbol,Any})::Dict{Symbol,Symbol}
    sig = Dict{Symbol,Symbol}()
    for (k, v) in args
        if v isa AbstractVector{<:Integer}
            sig[k] = :ExprArr
        elseif v isa Integer
            sig[k] = :ExprNum
        else
            error("Unsupported input type for $(k): $(typeof(v))")
        end
    end
    sig
end

function add_extras!(g::AbstractGrammar, sig::Dict{Symbol,Symbol}, start_nt::String)
    add_rule!(g, make_sym_rule(:Start, start_nt))
    for (arg, nt) in sig
        add_rule!(g, make_sym_rule(nt, arg))
    end
    g
end

infer_output_nt(out)::String = out isa AbstractVector{<:Any} ? "ExprArr" :
                               out isa Integer ? "ExprNum" :
                               error("Unsupported output type: $(typeof(out)): $out")

normalize_value(x) = x isa Vector ? map(v -> Int(v), x) : Int(x)

make_sym_rule(lhs::Symbol, rhs::Symbol)::Expr = Expr(:(=), lhs, rhs)

end # module DeepCoder_2016
