using HerbSpecification
using Test
using Aqua

@testset "HerbSpecification.jl" verbose=true begin
    @testset "Aqua.jl Checks" Aqua.test_all(HerbSpecification)
    include("test_ioproblem.jl") 
end
