@testitem "Grammar" begin
    struct ExGrammar <: AbstractGrammar
        rules::Vector{Any}
        types::Vector{Symbol}
        bytype::Dict{Symbol, Vector{Int}}
        # ...
        # only partially implementing the AbstractGrammar interface
        # to test the Base.show
    end

    g = ExGrammar([1], [:A], Dict([:A => [1]]))

    @testset "show" begin
        io = IOBuffer()
        Base.show(io, g)
        @test String(take!(io)) == "1: A = 1\n"
    end

    @testset "get_index" begin
        @test g[:A] == [1]
    end
end
