@testitem "VarNode" begin
    using HerbCore, HerbGrammar

    @testset "number_of_varnodes" begin
        @test HerbConstraints.contains_varnode(RuleNode(1), :a) == false
        @test HerbConstraints.contains_varnode(VarNode(:a), :a) == true
        @test HerbConstraints.contains_varnode(VarNode(:b), :a) == false
        @test HerbConstraints.contains_varnode(RuleNode(2, [
                VarNode(:b),
                VarNode(:a)
            ]), :a) == true
        @test HerbConstraints.contains_varnode(RuleNode(2, [
                VarNode(:b),
                VarNode(:b)
            ]), :a) == false
    end
    @testset "update_rule_indices" begin
        n_rules = 100
        mapping = Dict(1 => 3, 5 => 99)
        node = VarNode(:b)
        HerbCore.update_rule_indices!(node, n_rules)
        @test node == VarNode(:b)
        HerbCore.update_rule_indices!(node, n_rules, mapping)
        @test node == VarNode(:b)
    end
    @testset "is_domain_valid" begin
        @test HerbCore.is_domain_valid(VarNode(:a), 99) == true
    end
    @testset "isequal" begin
        @test VarNode(:a) == VarNode(:a)
        @test VarNode(:a) != VarNode(:z)
    end
end
