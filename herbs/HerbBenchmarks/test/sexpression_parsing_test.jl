@testitem "SExpressionParser" begin
    using HerbBenchmarks.SExpressionParser: parsefile, car

    @testset "S-Expression Parsing" begin
        files = readdir(joinpath(@__DIR__, "example_sygus_files"); join=true)
        
        for f in files
            @testset "Parsing $f" begin
                res = parsefile(f)
                @test !isnothing(res)
                @test car(res[end]) == Symbol("check-synth")
            end
        end
    end
end
