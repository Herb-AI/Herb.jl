@testitem "RuleNode Operators" begin
    module SomeDefinitions
    a_variable_that_is_defined = 7
    end
    @testset "Check if a symbol is a variable" begin
        g₁ = @cfgrammar begin
            Real = |(1:5)
            Real = a_variable
            Real = a_variable_that_is_defined
        end

        @test !isvariable(g₁, RuleNode(5, g₁), SomeDefinitions)
        @test isvariable(g₁, RuleNode(6, g₁), SomeDefinitions)
        @test !isvariable(g₁, RuleNode(7, g₁), SomeDefinitions)
        @test isvariable(g₁, RuleNode(7, g₁))
    end
end
