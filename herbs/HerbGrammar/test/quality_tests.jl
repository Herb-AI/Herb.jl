@testitem "Quality checks" begin
    using Aqua
    @testset "Aqua.jl Checks" Aqua.test_all(HerbGrammar; piracies=(treat_as_own=[SymbolTable],))
end
