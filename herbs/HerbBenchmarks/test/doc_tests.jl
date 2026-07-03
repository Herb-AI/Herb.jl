@testitem "Doctests" begin
    # using Test
    using Documenter
    @testset doctest(HerbBenchmarks, manual=false)
end
