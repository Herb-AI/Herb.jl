using Garden
using Test
using Aqua
using JET

@testset "Garden.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(Garden)
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(Garden; target_modules = (Garden,))
    end
    for (root, dirs, files) in walkdir(@__DIR__)
        for file in filter(contains(r"test_"), files)
            include(file)
        end
    end
end
