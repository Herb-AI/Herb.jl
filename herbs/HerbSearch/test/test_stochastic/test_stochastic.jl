@testset "Stochastic" verbose=true begin
    include("test_stochastic_functions.jl")
    include("test_stochastic_algorithms.jl")
    include("test_stochastic_with_constraints.jl")
end
