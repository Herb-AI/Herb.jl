@testitem "Build notebooks" begin
    include(joinpath(@__DIR__, "..", "docs", "build_notebooks.jl"))
    tutorials_dir = joinpath(dirname(@__DIR__), "docs", "src", "tutorials")
    # Smoke test to make sure building the notebooks doesn't error
    @test build(tutorials_dir) isa Any
end
