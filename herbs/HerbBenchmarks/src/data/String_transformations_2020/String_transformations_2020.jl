module String_transformations_2020
using HerbCore
using HerbSpecification
using HerbGrammar
using HerbInterpret

using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

include("string_primitives.jl")
include("data.jl")
include("grammar.jl")

interpret = make_stateful_interpreter(grammar_string; target_module=String_transformations_2020, cache_module=String_transformations_2020)

export
    parseline_string_transformations

"""
    parseline_strings(line::AbstractString)::IOExample

Parses a line from a file in the `strings` dataset
"""
function parseline_string_transformations(line::AbstractString)::IOExample
    # Helper function that converts a character list string to a string
    # consisting of the characters
    # Example: "['A','B','C']" → "ABC"
    parsecharlist(x) = join([x[i] for i ∈ 3:4:length(x)])

    # Extract input and output lists using the RegEx
    matches = match(r"^[^\[\]]+(\[[^\[\]]*\])[^\[\]]+(\[[^\[\]]*\])", line)

    input = Dict(:_arg_1 => parsecharlist(matches[1]))
    output = parsecharlist(matches[2])
    return IOExample(input, output)
end

end # module String_transformations_2020
