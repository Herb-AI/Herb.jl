module Robots_2020
using HerbCore
using HerbSpecification
using HerbGrammar
using HerbInterpret

using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

include("robots_primitives.jl")
include("data.jl")
include("data_generation.jl")
include("grammar.jl")

interpret = make_stateful_interpreter(grammar_robots; target_module=Robots_2020, cache_module=Robots_2020)

generated_data_path = "generated_data.jl"
if isfile(generated_data_path)
    include(generated_data_path)
end

export
    parseline_robots


"""
    parseline_robots(line::AbstractString)::IOExample

Parses a line from a file in the `robots` dataset
"""
function parseline_robots(line::AbstractString)::IOExample
    # Helper function that converts a string to a list of integers 
    # consisting of the characters
    # Example: "1,2,3" → [1, 2, 3]
    parseintlist(x) = map(y -> parse(Int, y), split(x, ","))

    # Remove unnecessary parts and split the input and output
    split_line = split(replace(line, "pos(w(" => "", "))." => ""), "),w(")

    robot_x, robot_y, ball_x, ball_y, holds_ball, size = parseintlist(split_line[1])
    input = Dict(:robot_x => robot_x,
        :robot_y => robot_y,
        :ball_x => ball_x,
        :ball_y => ball_y,
        :holds_ball => holds_ball,
        :size => size
    )
    robot_x, robot_y, ball_x, ball_y, holds_ball, size = parseintlist(split_line[2])
    output = Dict(:robot_x => robot_x,
        :robot_y => robot_y,
        :ball_x => ball_x,
        :ball_y => ball_y,
        :holds_ball => holds_ball,
        :size => size
    )
    return IOExample(input, output)
end

end # module Robots_2020
