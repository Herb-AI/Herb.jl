@testitem "Ordered" begin
    using HerbCore, HerbGrammar
    
    @testset "check_tree true, length(order)=2" begin
        ordered = Ordered(RuleNode(4, [
                VarNode(:a),
                VarNode(:b)
            ]), [:a, :b])
        tree11 = RuleNode(4, [
            RuleNode(1),
            RuleNode(1)
        ])
        tree12 = RuleNode(4, [
            RuleNode(1),
            RuleNode(2)
        ])
        tree22 = RuleNode(4, [
            RuleNode(2),
            RuleNode(2)
        ])
        tree22_mismatchedroot = RuleNode(3, [
            RuleNode(2),
            RuleNode(2)
        ])
        tree_large_true = RuleNode(3, [
            RuleNode(4, [
                RuleNode(2),
                RuleNode(3, [
                    RuleNode(2),
                    RuleNode(2)
                ])
            ]),
            RuleNode(2)
        ])
        @test check_tree(ordered, tree11) == true
        @test check_tree(ordered, tree12) == true
        @test check_tree(ordered, tree22) == true
        @test check_tree(ordered, tree22_mismatchedroot) == true
        @test check_tree(ordered, tree_large_true) == true
    end

    @testset "check_tree false, length(order)=2" begin
        ordered = Ordered(RuleNode(4, [
                VarNode(:a),
                VarNode(:b)
            ]), [:a, :b])
        tree21 = RuleNode(4, [
            RuleNode(2),
            RuleNode(1)
        ])
        tree_large_false = RuleNode(3, [
            RuleNode(4, [
                RuleNode(3, [
                    RuleNode(2),
                    RuleNode(2)
                ]),
                RuleNode(2)
            ]),
            RuleNode(2)
        ])
        @test check_tree(ordered, tree21) == false
        @test check_tree(ordered, tree_large_false) == false
    end

    @testset "check_tree true, length(order)=3" begin
        ordered = Ordered(RuleNode(4, [
                VarNode(:a),
                VarNode(:b),
                VarNode(:c)
            ]), [:a, :b, :c])
        tree111 = RuleNode(4, [
            RuleNode(1),
            RuleNode(1),
            RuleNode(1)
        ])
        tree112 = RuleNode(4, [
            RuleNode(1),
            RuleNode(1),
            RuleNode(2)
        ])
        tree122 = RuleNode(4, [
            RuleNode(1),
            RuleNode(2),
            RuleNode(2)
        ])
        tree111_mismatchedroot = RuleNode(5, [
            RuleNode(1),
            RuleNode(1),
            RuleNode(1)
        ])
        tree123 = RuleNode(4, [
            RuleNode(1),
            RuleNode(2),
            RuleNode(3, [
                RuleNode(1),
                RuleNode(1),
            ])
        ])
        tree133 = RuleNode(4, [
            RuleNode(1),
            RuleNode(3, [
                RuleNode(1),
                RuleNode(1),
            ]),
            RuleNode(3, [
                RuleNode(1),
                RuleNode(1),
            ])
        ])
        @test check_tree(ordered, tree111) == true
        @test check_tree(ordered, tree112) == true
        @test check_tree(ordered, tree122) == true
        @test check_tree(ordered, tree111_mismatchedroot) == true
        @test check_tree(ordered, tree123) == true
        @test check_tree(ordered, tree133) == true
    end

    @testset "check_tree false, length(order)=3" begin
        ordered = Ordered(RuleNode(4, [
                VarNode(:a),
                VarNode(:b),
                VarNode(:c)
            ]), [:a, :b, :c])
        tree121 = RuleNode(4, [
            RuleNode(1),
            RuleNode(2),
            RuleNode(1)
        ])
        tree133_leftchild_false = RuleNode(4, [
            RuleNode(1),
            RuleNode(3, [
                RuleNode(2),
                RuleNode(1),
            ]),
            RuleNode(3, [
                RuleNode(1),
                RuleNode(1),
            ])
        ])
        tree133_rightchild_false = RuleNode(4, [
            RuleNode(1),
            RuleNode(3, [
                RuleNode(1),
                RuleNode(2),
            ]),
            RuleNode(3, [
                RuleNode(1),
                RuleNode(1),
            ])
        ])
        @test check_tree(ordered, tree121) == false
        @test check_tree(ordered, tree133_leftchild_false) == false
        @test check_tree(ordered, tree133_rightchild_false) == false
    end
    @testset "update_rule_indices" begin
        @testset "interface without grammar" begin
            ordered = Ordered(RuleNode(4, [
                    VarNode(:a),
                    VarNode(:b),
                    VarNode(:c)
                ]), [:a, :c, :b])

            tree = @rulenode 10{1,5,6}
            n_rules = 10
            HerbCore.update_rule_indices!(ordered, n_rules)
            @test ordered.tree == RuleNode(4, [
                VarNode(:a),
                VarNode(:b),
                VarNode(:c)])
            @test check_tree(ordered, tree) == true # constraint pattern not found in tree

            mapping = Dict(4 => 10, 2 => 22)
            constraints = [ordered]
            HerbCore.update_rule_indices!(ordered, n_rules, mapping, constraints)
            @test check_tree(ordered, tree) == false # tree now violates constraint
            @test ordered.tree == RuleNode(10, [
                VarNode(:a),
                VarNode(:b),
                VarNode(:c)])
        end
        @testset "interface with grammar" begin
            grammar = @csgrammar begin
                Int = |(1:9)
                Int = x
                Int = -Int
                Int = Int + Int
                Int = Int * Int
            end
            ordered = Ordered(RuleNode(12, [
                    VarNode(:a),
                    VarNode(:b)
                ]), [:a, :b])
            addconstraint!(grammar, ordered)
            tree = @rulenode 13{5,1}
            HerbCore.update_rule_indices!(ordered, grammar)
            @test ordered.tree == RuleNode(12, [
                VarNode(:a),
                VarNode(:b)])
            @test check_tree(ordered, tree) == true # constraint pattern not found in tree

            mapping = Dict(12 => 13, 2 => 22)

            HerbCore.update_rule_indices!(ordered, grammar, mapping)
            @test check_tree(ordered, tree) == false # tree now violates constraint
            @test ordered.tree == RuleNode(13, [
                VarNode(:a),
                VarNode(:b)])
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
        ordered1 = Ordered(RuleNode(4, [
                VarNode(:a),
                VarNode(:b)
            ]), [:a, :b])
        ordered2 = Ordered(RuleNode(31, [
                VarNode(:a),
                VarNode(:b)
            ]), [:a, :b])
        @test HerbCore.is_domain_valid(ordered1, grammar) == true
        @test HerbCore.is_domain_valid(ordered2, grammar) == false

    end
    @testset "isequal" begin
        ordered1 = Ordered(RuleNode(4, [
                VarNode(:a),
                VarNode(:b)
            ]), [:a, :b])
        ordered2 = Ordered(RuleNode(4, [
                VarNode(:a),
                VarNode(:b)
            ]), [:a, :b])
        ordered3 = Ordered(RuleNode(4, [
                VarNode(:a),
                VarNode(:c)
            ]), [:a, :c])
        @test ordered1 == ordered2
        @test ordered1 != ordered3

    end
end
