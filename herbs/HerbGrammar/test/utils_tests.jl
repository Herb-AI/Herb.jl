@testitem "SymbolTable Tests" begin
    module DefiningAVariable
    x = 1
    end
    g = @cfgrammar begin
        Real = |(1:9)
        Real = x
    end

    st = grammar2symboltable(g, DefiningAVariable)
    @test st[:x] == 1

    @test_deprecated st = SymbolTable(g, DefiningAVariable)
    @test st[:x] == 1
end
