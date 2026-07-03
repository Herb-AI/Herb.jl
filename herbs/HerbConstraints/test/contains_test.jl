@testitem "Contains" begin
    using HerbGrammar, HerbCore

    contains = Contains(2)
   
    @testset "check_tree true" begin
        tree1 = RuleNode(2)
        tree2 = RuleNode(2, [
            RuleNode(3, [
                RuleNode(2),
                RuleNode(1)
            ]),
            RuleNode(2)
        ])

        @test check_tree(contains, tree1) == true
        @test check_tree(contains, tree2) == true
    end

    @testset "check_tree false" begin
        tree1 = RuleNode(4)
        tree2 = RuleNode(4, [
            RuleNode(3, [
                RuleNode(4),
                RuleNode(1)
            ]),
            RuleNode(4)
        ])

        @test check_tree(contains, tree1) == false
        @test check_tree(contains, tree2) == false
    end

    @testset "update_rule_indices!" begin
        grammar = @csgrammar begin
            Int = 1
            Int = x
            Int = -Int
            Int = Int + Int
            Int = Int * Int
        end
        c = Contains(2)
        @testset "interface without grammar" begin
            addconstraint!(grammar, Contains(2))
            addconstraint!(grammar, Contains(3))
            n_rules = 5
            HerbCore.update_rule_indices!(c, n_rules)
            @test Contains(2) in grammar.constraints
            mapping = Dict(1 => 5, 2 => 6)
            HerbCore.update_rule_indices!(c, n_rules,
                mapping, grammar.constraints)
            @test Contains(6) in grammar.constraints
            @test !(Contains(2) in grammar.constraints)
        end

        @testset "interface with grammar" begin
            clearconstraints!(grammar)
            addconstraint!(grammar, Contains(2))
            addconstraint!(grammar, Contains(3))
            HerbCore.update_rule_indices!(c, grammar)
            @test grammar.constraints[1] == Contains(2)
            mapping = Dict(1 => 5, 2 => 6)
            HerbCore.update_rule_indices!(c, grammar, mapping)
            @test Contains(6) in grammar.constraints
        end
        @testset "error" begin
            c = Contains(23)
            n_rules = 10
            @test_throws ErrorException HerbCore.update_rule_indices!(c, n_rules)
        end
    end
    @testset "is_domain_valid" begin
        grammar = @csgrammar begin
            Int = 1
            Int = x
            Int = -Int
            Int = Int + Int
            Int = Int * Int
        end
        @test HerbCore.is_domain_valid(Contains(8), grammar) == false
        @test HerbCore.is_domain_valid(Contains(3), grammar) == true
    end
    @testset "isequal" begin
        @test Contains(12) == Contains(12)
        @test Contains(12) != Contains(12222)
    end
end
