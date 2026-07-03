module SyGuS

using HerbSpecification
using HerbCore
using HerbGrammar
using ..HerbBenchmarks.SExpressionParser

export
    parse_sygus_grammar,
    parse_sygus_problem,
    parse_synth_fun,
    parse_example_constraint


"""
    parse_sygus_grammar(filename::AbstractString)::AbstractGrammar

Parses a SyGuS file for its grammar, by looking for the keyword 'synth-fun' within the S-Expressions. Returns the grammar if found.
"""
function parse_sygus_grammar(filename::AbstractString)::AbstractGrammar
    #@TODO this parser requires the input to be named `_arg_x`. This might not be the case for all problems
    symbol_list = SExpressionParser.parsefile(filename)

    for expr in symbol_list
        if expr.car == Symbol("synth-fun")
            return parse_synth_fun(expr)
        end
    end

    throw(ArgumentError("No grammar found in '$filename'"))
end

"""
    parse_sygus_problem(filename::AbstractString)::Problem

Parses a SyGuS file for all examples and returns them, wrapped in a [`HerbSpecification.Problem`](@ref)
"""
function parse_sygus_problem(filename::AbstractString)::Problem
    symbol_list = SExpressionParser.parsefile(filename)
    examples::Vector{IOExample} = Vector{IOExample}()

    for expr in symbol_list
        if expr[1] == Symbol("constraint") && expr[2][1] == :(=)
            push!(examples, parse_example_constraint(expr))
        end
    end
    return Problem(examples)
end

"""
    parse_synth_fun(sexpr::SExpressionParser.Cons)::AbstractGrammar

Parses a SyGuS grammar that are named `synth_fun` within SyGuS. Takes the S-Expression of the grammar and returns a [`@csgrammar`](@ref).
"""
function parse_synth_fun(sexpr::SExpressionParser.Cons)::AbstractGrammar
    return_grammar = @csgrammar begin end

    if sexpr.car !== Symbol("synth-fun")
        throw(ArgumentError("'$(sexpr.car)' is not a 'synth-fun'"))
    end

    for rule in sexpr[5]
        for val in rule[3]
            if typeof(val) == SExpressionParser.Cons || false
                add_rule!(return_grammar, Meta.parse("$(rule[1]) = $(polish_function_calls(val))"))
            else
                add_rule!(return_grammar, :($(rule[1]) = $(val)))
            end
        end
    end

    return return_grammar
end


function polish_function_calls(in::SExpressionParser.Cons)
    arguments = join(in[2:length(in)], ", ")
    new_function_call = "$(in[1])($arguments)"
    return new_function_call
end


"""
    function parse_example_constraint(sexpr::SExpressionParser.Cons)
    
Parses SyGuS example of the form (constraint (= (f arg1 arg2 ...) output)).
Returns IOExample with inputs named arg1, arg2, ...
"""
function parse_example_constraint(sexpr::SExpressionParser.Cons)
   # take the X of (constraint X)
   sexpr = sexpr[2]
   # take Function call and Output of (= FunctionCall Output)
   functionCall = sexpr[2]
   output = sexpr[3]

   inputs = Dict{Symbol,Any}()

   for arg_index in 2:length(functionCall)
        inputs[Symbol("_arg_$(arg_index-1)")] = functionCall[arg_index]
   end

   return IOExample(inputs, output)
end

end # module SyGuS
