using Aqua
using Herb
using Test

include(joinpath(@__DIR__, "..", "docs", "build_notebooks.jl"))

@testset "Herb" begin
    @testset "Aqua.jl" begin
        Aqua.test_all(Herb)
    end

    @testset "Build notebooks" begin
        tutorials_dir = joinpath(dirname(@__DIR__), "docs", "src", "tutorials")
        # Smoke test to make sure building the notebooks doesn't error
        @test build(tutorials_dir) isa Any
    end
end
