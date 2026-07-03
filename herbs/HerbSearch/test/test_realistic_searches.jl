@testset verbose=true "Somewhat larger domains" begin
    @testset "Small domain, small operators" begin
        """Expects to return a program equivalent to 1 + (1 - x) = 2 - x"""

        g₁ = @csgrammar begin
            Element = |(1 : 3)          # 1 - 3
            Element = Element + Element # 4
            Element = 1 - Element       # 5
            Element = x                 # 6
        end

        addconstraint!(g₁, ComesAfter(6, [5]))
        
        examples = [
            IOExample(Dict(:x => 0), 2),
            IOExample(Dict(:x => 1), 1),
            IOExample(Dict(:x => 2), 0)
        ]
        problem = Problem(examples)
        solution = search(g₁, problem, :Element, max_depth=3)

        @test execute_on_input(grammar2symboltable(g₁), solution, Dict(:x => -2)) == 4
    end

    @testset "Small domain, large operators" begin
        """Expects to return a program equivalent to 4 + x * (x + 3 + 3) = x^2 + 6x + 4"""

        g₂ = @csgrammar begin
            Element = Element + Element + Element # 1
            Element = Element + Element * Element # 2
            Element = x                           # 3
            Element = |(3 : 5)                    # 4
        end

        # Restrict .. + x * x
        addconstraint!(g₂, Forbidden(MatchNode(2, [MatchVar(:x), MatchNode(3), MatchNode(3)])))
        # Restrict 4 and 5 in lower level
        addconstraint!(g₂, ForbiddenPath([2, 1, 5]))
        addconstraint!(g₂, ForbiddenPath([2, 1, 6]))

        examples = [
            IOExample(Dict(:x => 1), 11)
            IOExample(Dict(:x => 2), 20)
            IOExample(Dict(:x => -1), -1)
        ]
        problem = Problem(examples)
        solution = search(g₂, problem, :Element)

        @test execute_on_input(grammar2symboltable(g₂), solution, Dict(:x => 0)) == 4
    end

    @testset "Large domain, small operators" begin
        """Expects to return a program equivalent to (1 - (((1 - x) - 1) - 1)) - 1 = x + 1"""

        g₃ = @csgrammar begin
            Element = |(1 : 20)   # 1 - 20
            Element = Element - 1 # 21
            Element = 1 - Element # 22
            Element = x           # 23
        end

        addconstraint!(g₃, ComesAfter(23, [22, 21]))
        addconstraint!(g₃, ComesAfter(22, [21]))

        examples = [
            IOExample(Dict(:x => 1), 2)
            IOExample(Dict(:x => 10), 11)
        ]
        problem = Problem(examples)
        solution = search(g₃, problem, :Element)

        @test execute_on_input(grammar2symboltable(g₃), solution, Dict(:x => 0)) == 1
        @test execute_on_input(grammar2symboltable(g₃), solution, Dict(:x => 100)) == 101
    end

    @testset "Large domain, large operators" begin
        """Expects to return a program equivalent to 18 + 4x"""

        g₄ = @csgrammar begin
            Element = |(0 : 20)                   # 1 - 20
            Element = Element + Element + Element # 21
            Element = Element + Element * Element # 22
            Element = x                           # 23
        end

        # Enforce ordering on + +
        addconstraint!(g₄, Ordered(
            MatchNode(21, [MatchVar(:x), MatchVar(:y), MatchVar(:z)]),
            [:x, :y, :z]
        ))

        examples = [
            IOExample(Dict(:x => 1), 22),
            IOExample(Dict(:x => 0), 18),
            IOExample(Dict(:x => -1), 14)
        ]
        problem = Problem(examples)
        solution = search(g₄, problem, :Element)

        @test execute_on_input(grammar2symboltable(g₄), solution, Dict(:x => 100)) == 418
    end

    @testset "Large domain with if-statements" begin
        """Expects to return a program equivalent to (x == 2) ? 1 : (x + 2)"""

        g₅ = @csgrammar begin
            Element = Number # 1
            Element = Bool # 2
        
            Number = |(1 : 3) # 3-5
            
            Number = Number + Number # 6
            Bool = Number ≡ Number # 7
            Number = x # 8
            
            Number = Bool ? Number : Number # 9
            Bool = Bool ? Bool : Bool # 10
        end

        # Forbid ? = ?
        addconstraint!(g₅, Forbidden(MatchNode(7, [MatchVar(:x), MatchVar(:x)])))
        # Order =
        addconstraint!(g₅, Ordered(MatchNode(7, [MatchVar(:x), MatchVar(:y)]), [:x, :y]))
        # Order +
        addconstraint!(g₅, Ordered(MatchNode(6, [MatchVar(:x), MatchVar(:y)]), [:x, :y]))

        examples = [
            IOExample(Dict(:x => 0), 2)
            IOExample(Dict(:x => 1), 3)
            IOExample(Dict(:x => 2), 1)
        ]
        problem = Problem(examples)
        solution = search(g₅, problem, :Element)

        @test execute_on_input(grammar2symboltable(g₅), solution, Dict(:x => 3)) == 5
    end    
end
