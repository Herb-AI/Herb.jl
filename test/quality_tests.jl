@testitem "Quality tests" begin
    using Aqua
    @testset "Aqua.jl" begin
        Aqua.test_all(Herb)
    end
end
