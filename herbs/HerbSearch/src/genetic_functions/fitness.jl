"""
    default_fitness(program, results)

Defines the default fitness function taking the program and its results. Results are a vector of tuples, where each tuple is in the form `Tuple{expected_output, actual_output}`. As we are looking for individuals with the highest fitness function, the error is inverted. 
"""
function default_fitness(program, results)
    results = convert(Vector{Tuple{Number, Number}}, results)
    1 / mean_squared_error(results)
end
