@testitem "CSGs" begin
    @testset "Create empty grammar" begin
        g = @csgrammar begin end
        @test isempty(g.rules)
        @test isempty(g.types)
        @test isempty(g.isterminal)
        @test isempty(g.iseval)
        @test isempty(g.bytype)
        @test isempty(g.domains)
        @test isempty(g.childtypes)
        @test isnothing(g.log_probabilities)
    end

    @testset "Creating grammars" begin
        g₁ = @cfgrammar begin
            Real = |(1:9)
        end
        @test g₁.rules == collect(1:9)
        @test :Real ∈ g₁.types

        g₂ = @cfgrammar begin
            Real = |([1, 2, 3])
        end
        @test g₂.rules == [1, 2, 3]

        g₃ = @cfgrammar begin
            Real = 1 | 2 | 3
        end
        @test g₃.rules == [1, 2, 3]

        g₄ = @cfgrammar begin
            Real = 1 | 1
        end
        @test g₄.rules == [1]
    end


    @testset "Adding rules to grammar" begin
        g₁ = @csgrammar begin
            Real = |(1:2)
        end

        # Basic adding
        add_rule!(g₁, :(Real = 3))
        @test g₁.rules == [1, 2, 3]
        @test g₁.bytype[:Real] == [1, 2, 3]
        @test g₁.types == [:Real, :Real, :Real]
        @test g₁.isterminal == [true, true, true]
        @test g₁.iseval == [false, false, false]
        @test g₁.childtypes == [[], [], []]
        @test g₁.bychildtypes == [BitVector((1, 1, 1)) for _ in 1:3]

        # Adding multiple rules in one line
        add_rule!(g₁, :(Real = 4 | 5))
        @test g₁.rules == [1, 2, 3, 4, 5]

        # Adding already existing rules
        add_rule!(g₁, :(Real = 5))
        @test g₁.rules == [1, 2, 3, 4, 5]

        # Adding multiple already existing rules
        add_rule!(g₁, :(Real = |(1:9)))
        @test g₁.rules == collect(1:9)

        # Adding other types
        g₂ = @csgrammar begin
            Real = 1 | 2 | 3
        end

        add_rule!(g₂, :(Bool = Real ≤ Real))
        @test length(g₂.rules) == 4
        @test :Real ∈ g₂.types
        @test :Bool ∈ g₂.types
        @test g₂.rules[g₂.bytype[:Bool][1]] == :(Real ≤ Real)
        @test g₂.childtypes[g₂.bytype[:Bool][1]] == [:Real, :Real]

        @test_throws ArgumentError add_rule!(g₂, :(Real != Bool))
    end

    @testset "Merging two grammars" begin
        g₁ = @csgrammar begin
            Number = |(1:2)
            Number = x
        end

        g₂ = @csgrammar begin
            Real = Real + Real
            Real = Real * Real
        end

        merge_grammars!(g₁, g₂)

        @test length(g₁.rules) == 5
        @test :Real ∈ g₁.types
    end

    @testset "Writing and loading CSG to/from disk" begin
        g₁ = @csgrammar begin
            Real = |(1:5)
            Real = 6 | 7 | 8
        end

        store_csg(g₁, "toy_cfg.grammar")
        g₂ = read_csg("toy_cfg.grammar")
        @test :Real ∈ g₂.types
        @test g₂.rules == collect(1:8)

        # delete file afterwards
        rm("toy_cfg.grammar")
    end

    @testset "Test that strict equality is used during rule creation" begin
        g₁ = @csgrammar begin
            R = x
            R = R + R
        end

        add_rule!(g₁, :(R = 1 | 2))

        add_rule!(g₁, :(Bool = true))

        @test all(g₁.rules .== [:x, :(R + R), 1, 2, true])

        g₁ = @csgrammar begin
            R = x
            R = R + R
        end

        add_rule!(g₁, :(Bool = true))

        add_rule!(g₁, :(R = 1 | 2))

        @test all(g₁.rules .== [:x, :(R + R), true, 1, 2])
    end

    @testset "Test bychildtypes" begin
        g = @csgrammar begin
            S = 1
            S = 2 + S + A
            S = 3 + A + S
            A = 4
            S = 5 + S + S
            S = 6 + S + S
            S = 7 + S
            A = 8 + S
        end

        @test g.childtypes[1] == []
        @test g.childtypes[2] == [:S, :A]
        @test g.childtypes[3] == [:A, :S]
        @test g.childtypes[4] == []
        @test g.childtypes[5] == [:S, :S]
        @test g.childtypes[6] == [:S, :S]
        @test g.childtypes[7] == [:S]
        @test g.childtypes[8] == [:S]

        @test g.bychildtypes[1] == [1, 0, 0, 1, 0, 0, 0, 0] # 1, 4
        @test g.bychildtypes[2] == [0, 1, 0, 0, 0, 0, 0, 0] # 2
        @test g.bychildtypes[3] == [0, 0, 1, 0, 0, 0, 0, 0] # 3
        @test g.bychildtypes[4] == [1, 0, 0, 1, 0, 0, 0, 0] # 1, 4
        @test g.bychildtypes[5] == [0, 0, 0, 0, 1, 1, 0, 0] # 5, 6
        @test g.bychildtypes[6] == [0, 0, 0, 0, 1, 1, 0, 0] # 5, 6
        @test g.bychildtypes[7] == [0, 0, 0, 0, 0, 0, 1, 1] # 7, 8
        @test g.bychildtypes[8] == [0, 0, 0, 0, 0, 0, 1, 1] # 7, 8
    end

    @testset "Check that macros return an expr, not an object" begin
        @test typeof(@macroexpand @csgrammar begin
            A = 1
        end) == Expr
        @test typeof(@macroexpand @cfgrammar begin
            A = 1
        end) == Expr
        @test typeof(@macroexpand @pcsgrammar begin
            1.0:A = 1
        end) == Expr
        @test typeof(@macroexpand @pcfgrammar begin
            1.0:A = 1
        end) == Expr
    end

    @testset "Test adding duplicated rules" begin
        g = @cfgrammar begin
            S = 1 + A
            S = 2 * B
            A = 1
            B = 1
            B = 2
        end
        # All rules should be present in grammar
        @test g.rules == [:(1 + A), :(2 * B), 1, 1, 2]

        # Adding duplicated rule
        add_rule!(g, :(A = 1))
        @test g.rules == [:(1 + A), :(2 * B), 1, 1, 2]

        # Adding new rule with already existing rhs
        add_rule!(g, :(A = 2))
        @test g.rules == [:(1 + A), :(2 * B), 1, 1, 2, 2]
    end

    @testset "Add tree to grammar" begin
        g = @cfgrammar begin
            Number = |(1:2)
            Number = x
            Number = Number + Number
            Number = Number * Number
        end
        hole = Hole(get_domain(g, g.bytype[:Number]))
        test_ast = RuleNode(4, [RuleNode(1), hole])

        add_rule!(g, test_ast)
        @test g.rules[6] == :(1 + Number)
    end
end
