using Garden.Probe
using Herb

using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

grammar = @cfgrammar begin
    Start = Int
    Int = Int + Int
    Int = |(1:2)
    Int = x
end
# problem = Problem( [IOExample{Symbol, Any}(Dict(), 2)])
problem = Problem([IOExample(Dict{Symbol, Any}(:x => x), x + 1) for x in 1:5])

interp = HerbInterpret.make_interpreter(
    grammar;
    input_symbols = [:x],
    target_module = @__MODULE__,
    cache_module = @__MODULE__
)

@show grammar
@show grammar.log_probabilities

program,
    num_programs = probe(
    grammar,
    :Start,
    problem;
    interpret = interp,
    max_depth = 3,
    allow_errors = false
)

@show program, num_programs
