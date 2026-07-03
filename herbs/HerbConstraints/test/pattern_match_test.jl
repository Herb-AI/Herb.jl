@testitem "PatternMatch" begin
    using HerbCore, HerbGrammar

    #the grammar is not needed in the current implementation
    g = @csgrammar begin
        Real = 1
        Real = :x
        Real = -Real
        Real = Real + Real
        Real = Real * Real
        Real = Real / Real
    end

    @testset "PatternMatchSuccess, no holes" begin
        rn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        mn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        @test pattern_match(rn, mn) isa HerbConstraints.PatternMatchSuccess
    end

    @testset "PatternMatchSuccess, holes underneath a VarNode" begin
        hole = Hole(BitVector((1, 1, 1, 1, 1, 1)))
        node_1hole = RuleNode(4, [
            Hole(BitVector((1, 1, 1, 1, 1, 1))), 
            RuleNode(1)]
        )
        node_2holes = RuleNode(4, [
            Hole(BitVector((1, 1, 1, 1, 1, 1))), 
            Hole(BitVector((1, 1, 1, 1, 1, 1)))]
        )
        @test pattern_match(hole, VarNode(:x)) isa HerbConstraints.PatternMatchSuccess
        @test pattern_match(node_1hole, VarNode(:x)) isa HerbConstraints.PatternMatchSuccess
        @test pattern_match(node_2holes, VarNode(:x)) isa HerbConstraints.PatternMatchSuccess
    end

    @testset "PatternMatchSuccess, holes underneath different VarNodes" begin
        varnodes = RuleNode(4, [VarNode(:x), VarNode(:y)])
        node_2holes = RuleNode(4, [
            Hole(BitVector((1, 1, 1, 1, 1, 1))), 
            Hole(BitVector((1, 1, 1, 1, 1, 1)))
        ])
        node_3holes = RuleNode(4, [
            Hole(BitVector((1, 1, 1, 1, 1, 1))), 
            RuleNode(4, [
                Hole(BitVector((1, 1, 1, 1, 1, 1))), 
                Hole(BitVector((1, 1, 1, 1, 1, 1)))
            ])
        ])
        node_4holes = RuleNode(4, [
            RuleNode(4, [
                Hole(BitVector((1, 1, 1, 1, 1, 1))), 
                Hole(BitVector((1, 1, 1, 1, 1, 1)))
            ]), 
            RuleNode(5, [
                Hole(BitVector((1, 1, 1, 1, 1, 1))), 
                Hole(BitVector((1, 1, 1, 1, 1, 1)))
            ])
        ])
        @test pattern_match(node_2holes, VarNode(:x)) isa HerbConstraints.PatternMatchSuccess
        @test pattern_match(node_3holes, VarNode(:x)) isa HerbConstraints.PatternMatchSuccess
        @test pattern_match(node_4holes, VarNode(:x)) isa HerbConstraints.PatternMatchSuccess
    end
    
    @testset "PatternMatchSuccessWhenHoleAssignedTo, 1 hole with a valid domain" begin
        rn_variable_shaped_hole = RuleNode(4, [RuleNode(1), Hole(BitVector((1, 1, 1, 1, 1, 1)))])
        rn_fixed_shaped_hole = RuleNode(4, [RuleNode(1), Hole(BitVector((1, 1, 0, 0, 0, 0)))])
        rn_single_value_hole = RuleNode(4, [RuleNode(1), Hole(BitVector((1, 0, 0, 0, 0, 0)))])
        mn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        @test pattern_match(rn_variable_shaped_hole, mn) isa HerbConstraints.PatternMatchSuccessWhenHoleAssignedTo
        @test pattern_match(rn_fixed_shaped_hole, mn) isa HerbConstraints.PatternMatchSuccessWhenHoleAssignedTo
        
        # the convention for this test changed. holes of domain size 1 are considered to be filled.
        # `rn_single_value_hole` and `mn` match successfully, as `rn_single_value_hole` is considered to be filled.
        @test pattern_match(rn_single_value_hole, mn) isa HerbConstraints.PatternMatchSuccess
        
        @test pattern_match(rn_fixed_shaped_hole, mn).ind == 1
    end

    @testset "PatternMatchSuccessWhenHoleAssignedTo, path" begin
        mn = RuleNode(4, [
            RuleNode(1), 
            RuleNode(4, [
                RuleNode(4, [
                    RuleNode(1), 
                    RuleNode(4, [
                        RuleNode(4, [
                            RuleNode(1), 
                            RuleNode(1)
                        ]), 
                        RuleNode(1)
                    ]),
                ]), 
                RuleNode(1)
            ])
        ])
        rn = RuleNode(4, [
            RuleNode(1), 
            RuleNode(4, [
                RuleNode(4, [
                    RuleNode(1), 
                    RuleNode(4, [
                        RuleNode(4, [
                            Hole(BitVector((1, 1, 0, 0, 0, 0))), 
                            RuleNode(1)
                        ]), 
                        RuleNode(1)
                    ]),
                ]), 
                RuleNode(1)
            ])
        ])
        match = pattern_match(rn, mn)
        @test match.ind == 1
        @test get_path(rn, match.hole) == [2, 1, 2, 1, 1]
    end

    @testset "PatternMatchSuccessWhenHoleAssignedTo, 1 uniform hole with children" begin
        rn = UniformHole(BitVector((0, 0, 0, 1, 1, 1)), [RuleNode(1), RuleNode(1)])
        mn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        result = pattern_match(rn, mn)
        @test result isa HerbConstraints.PatternMatchSuccessWhenHoleAssignedTo
        @test result.ind == 4
    end

    @testset "PatternMatchHardFail, same shape, no holes" begin
        rn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        mn1 = RuleNode(4, [RuleNode(2), RuleNode(1)])
        mn2 = RuleNode(4, [RuleNode(1), RuleNode(2)])
        mn3 = RuleNode(4, [RuleNode(2), RuleNode(2)])
        @test pattern_match(rn, mn1) isa HerbConstraints.PatternMatchHardFail
        @test pattern_match(rn, mn2) isa HerbConstraints.PatternMatchHardFail
        @test pattern_match(rn, mn3) isa HerbConstraints.PatternMatchHardFail
    end

    @testset "PatternMatchHardFail, different shapes, no holes" begin
        rn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        mn_small = RuleNode(1)
        mn_large = RuleNode(4, [
            RuleNode(1), 
            RuleNode(4, [
                RuleNode(1), 
                RuleNode(1)
            ])
        ])
        @test pattern_match(rn, mn_small) isa HerbConstraints.PatternMatchHardFail
        @test pattern_match(rn, mn_large) isa HerbConstraints.PatternMatchHardFail
    end

    @testset "PatternMatchHardFail, 1 hole with an invalid domain" begin
        rn_variable_shaped_hole = RuleNode(4, [RuleNode(1), Hole(BitVector((0, 1, 1, 1, 1, 1)))])
        rn_fixed_shaped_hole = RuleNode(4, [RuleNode(1), Hole(BitVector((0, 0, 0, 1, 1, 1)))])
        rn_single_value_hole = RuleNode(4, [RuleNode(1), Hole(BitVector((0, 0, 0, 0, 1, 1)))])
        mn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        @test pattern_match(rn_variable_shaped_hole, mn) isa HerbConstraints.PatternMatchHardFail
        @test pattern_match(rn_fixed_shaped_hole, mn) isa HerbConstraints.PatternMatchHardFail
        @test pattern_match(rn_single_value_hole, mn) isa HerbConstraints.PatternMatchHardFail
    end

    @testset "PatternMatchHardFail, 1 hole with a valid domain, 1 hole with an invalid domain" begin
        rn1 = RuleNode(4, [Hole(BitVector((1, 1, 1, 1, 1, 1))), Hole(BitVector((0, 1, 1, 1, 1, 1)))])
        rn2 = RuleNode(4, [Hole(BitVector((0, 1, 1, 1, 1, 1))), Hole(BitVector((1, 1, 1, 1, 1, 1)))])
        mn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        @test pattern_match(rn1, mn) isa HerbConstraints.PatternMatchHardFail
        @test pattern_match(rn2, mn) isa HerbConstraints.PatternMatchHardFail
    end

    @testset "PatternMatchHardFail, 1 uniform hole with an invalid domain" begin
        rn = UniformHole(BitVector((0, 0, 0, 0, 1, 1)), [RuleNode(1), RuleNode(1)])
        mn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        @test pattern_match(rn, mn) isa HerbConstraints.PatternMatchHardFail
    end

    @testset "PatternMatchHardFail, 2 holes with invalid domains" begin
        rn = UniformHole(BitVector((0, 0, 0, 0, 1, 1)), [Hole(BitVector((0, 0, 1, 1, 1, 1))), RuleNode(1)])
        mn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        @test pattern_match(rn, mn) isa HerbConstraints.PatternMatchHardFail
    end

    @testset "PatternMatchHardFail, 1 uniform hole with a valid domain, 1 hole with an invalid domain" begin
        rn = UniformHole(BitVector((0, 0, 0, 1, 1, 1)), [Hole(BitVector((0, 0, 1, 1, 1, 1))), RuleNode(1)])
        mn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        @test pattern_match(rn, mn) isa HerbConstraints.PatternMatchHardFail
    end

    @testset "PatternMatchHardFail, 1 uniform hole with an invalid domain, 1 hole with a valid domain" begin
        rn1 = UniformHole(BitVector((0, 0, 0, 0, 1, 1)), [Hole(BitVector((1, 1, 1, 1, 1, 1))), RuleNode(1)])
        rn2 = UniformHole(BitVector((0, 0, 0, 0, 1, 1)), [RuleNode(1), Hole(BitVector((1, 1, 1, 1, 1, 1)))])
        mn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        @test pattern_match(rn1, mn) isa HerbConstraints.PatternMatchHardFail
        @test pattern_match(rn2, mn) isa HerbConstraints.PatternMatchHardFail
    end

    @testset "PatternMatchHardFail, 2 holes with valid domains, but rule node mismatch" begin
        rn = RuleNode(4, [
            RuleNode(4, [
                Hole(BitVector((1, 1, 1, 1, 1, 1))), 
                Hole(BitVector((1, 1, 1, 1, 1, 1)))
            ]),
            RuleNode(1)
        ])

        mn = RuleNode(4, [
            RuleNode(4, [
                RuleNode(2), 
                RuleNode(2)
            ]),
            RuleNode(2)
        ])

        @test pattern_match(rn, mn) isa HerbConstraints.PatternMatchHardFail
    end

    @testset "PatternMatchSoftFail, 1 uniform hole with an valid domain, 1 hole with a valid domain" begin
        rn1 = UniformHole(BitVector((0, 0, 0, 1, 1, 1)), [Hole(BitVector((1, 1, 1, 1, 1, 1))), RuleNode(1)])
        rn2 = UniformHole(BitVector((0, 0, 0, 1, 1, 1)), [RuleNode(1), Hole(BitVector((1, 1, 1, 1, 1, 1)))])
        mn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        @test pattern_match(rn1, mn) isa HerbConstraints.PatternMatchSoftFail
        @test pattern_match(rn2, mn) isa HerbConstraints.PatternMatchSoftFail
    end

    @testset "PatternMatchSoftFail, 1 hole with a domain of 1, matching rulenode" begin
        rn = Hole([0, 0, 0, 1])
        mn = RuleNode(4, [VarNode(:a), VarNode(:a)])
        @test pattern_match(rn, mn) isa HerbConstraints.PatternMatchSoftFail
        @test pattern_match(mn, rn) isa HerbConstraints.PatternMatchSoftFail
    end

    @testset "PatternMatchSoftFail, 2 holes with valid domains" begin
        rn = RuleNode(4, [Hole(BitVector((1, 1, 1, 1, 1, 1))), Hole(BitVector((1, 1, 1, 1, 1, 1)))])
        mn = RuleNode(4, [RuleNode(1), RuleNode(1)])
        @test pattern_match(rn, mn) isa HerbConstraints.PatternMatchSoftFail
    end

    @testset "PatternMatchSoftFail, large hole" begin
        rn = RuleNode(4, [RuleNode(1), Hole(BitVector((1, 1, 1, 1, 1, 1)))])
        mn = RuleNode(4, [RuleNode(1), RuleNode(4, [RuleNode(1), RuleNode(1)])])
        @test pattern_match(rn, mn) isa HerbConstraints.PatternMatchSoftFail
    end

    @testset "PatternMatchSoftFail, UniformHole vs Hole" begin
        h1 = UniformHole(BitVector((1, 1, 0)), [RuleNode(3)])
        h2 = Hole(BitVector((1, 1, 1)))
        @test pattern_match(h1, h2) isa HerbConstraints.PatternMatchSoftFail
    end

    @testset "Hole vs UniformHoleShapedHole" begin
        h1 = UniformHole(BitVector((1, 1, 0, 0, 0, 0)), [])
        h2_softfail = Hole(BitVector((1, 0, 0, 0, 0, 1)))
        h2_hardfail = Hole(BitVector((0, 0, 0, 0, 1, 1)))
        @test pattern_match(h1, h2_softfail) isa HerbConstraints.PatternMatchSoftFail
        @test pattern_match(h1, h2_hardfail) isa HerbConstraints.PatternMatchHardFail
    end

    @testset "StateHole" begin
        @testset "Success" begin
            sm = HerbConstraints.StateManager()
            h1 = StateHole(sm, UniformHole(BitVector((1, 0, 0)), [RuleNode(3)]))
            h2 = StateHole(sm, UniformHole(BitVector((1, 0, 0)), [RuleNode(3)]))
            @test pattern_match(h1, h2) isa HerbConstraints.PatternMatchSuccess
        end

        @testset "SuccessWhenHoleAssignedTo" begin
            sm = HerbConstraints.StateManager()
            h1 = StateHole(sm, UniformHole(BitVector((1, 0, 0)), [RuleNode(3)]))
            h2 = StateHole(sm, UniformHole(BitVector((1, 1, 0)), [RuleNode(3)]))
            @test pattern_match(h1, h2) isa HerbConstraints.PatternMatchSuccessWhenHoleAssignedTo
        end

        @testset "Softfail" begin
            sm = HerbConstraints.StateManager()
            h1 = StateHole(sm, UniformHole(BitVector((1, 1, 0)), [RuleNode(3)]))
            h2 = StateHole(sm, UniformHole(BitVector((1, 1, 0)), [RuleNode(3)]))
            @test pattern_match(h1, h2) isa HerbConstraints.PatternMatchSoftFail
        end

        @testset "Hardfail" begin
            sm = HerbConstraints.StateManager()
            h1 = StateHole(sm, UniformHole(BitVector((1, 0, 0)), [RuleNode(3)]))
            h2 = StateHole(sm, UniformHole(BitVector((0, 1, 0)), [RuleNode(3)]))
            @test pattern_match(h1, h2) isa HerbConstraints.PatternMatchHardFail
        end
    end

    @testset "VarNode assigned to a RuleNode" begin
        mn = RuleNode(4, [VarNode(:x), VarNode(:x)])
        @testset "Depth1" begin
            node_success = RuleNode(4, [RuleNode(1), RuleNode(1)])
            node_fail = RuleNode(4, [RuleNode(1), RuleNode(2)])
            @test pattern_match(node_success, mn) isa HerbConstraints.PatternMatchSuccess
            @test pattern_match(node_fail, mn) isa HerbConstraints.PatternMatchHardFail
        end
        @testset "Depth2" begin
            node_success = RuleNode(4, [RuleNode(4, [RuleNode(1), RuleNode(1)]), RuleNode(4, [RuleNode(1), RuleNode(1)])])
            node_fail = RuleNode(4, [RuleNode(4, [RuleNode(1), RuleNode(1)]), RuleNode(4, [RuleNode(2), RuleNode(1)])])
            mn = RuleNode(4, [VarNode(:x), VarNode(:x)])
            @test pattern_match(node_success, mn) isa HerbConstraints.PatternMatchSuccess
            @test pattern_match(node_fail, mn) isa HerbConstraints.PatternMatchHardFail
        end
    end

    @testset "VarNode assigned to a Hole" begin
        mn = RuleNode(4, [VarNode(:x), VarNode(:x)])
        @testset "Hole in the left VarNode, depth 1" begin
            n1 = RuleNode(4, [Hole(BitVector((1, 1, 0, 0, 0, 0))), RuleNode(1)])
            match = pattern_match(n1, mn)
            @test match isa HerbConstraints.PatternMatchSuccessWhenHoleAssignedTo
            @test match.ind == 1
        end
        @testset "Hole in the right VarNode, depth 1" begin
            n1 = RuleNode(4, [RuleNode(1), Hole(BitVector((1, 1, 0, 0, 0, 0)))])
            match = pattern_match(n1, mn)
            @test match isa HerbConstraints.PatternMatchSuccessWhenHoleAssignedTo
            @test match.ind == 1
        end
        @testset "Hole in the left VarNode, depth 2" begin
            n1 = RuleNode(4, [
                RuleNode(4, [Hole(BitVector((1, 1, 0, 0, 0, 0))), RuleNode(1)]), 
                RuleNode(4, [RuleNode(2), RuleNode(1)])
            ])
            n2 = RuleNode(4, [
                RuleNode(4, [RuleNode(1), Hole(BitVector((1, 1, 0, 0, 0, 0)))]), 
                RuleNode(4, [RuleNode(1), RuleNode(2)])
            ])
            match1 = pattern_match(n1, mn)
            match2 = pattern_match(n2, mn)
            @test match1 isa HerbConstraints.PatternMatchSuccessWhenHoleAssignedTo
            @test match1.ind == 2
            @test match2 isa HerbConstraints.PatternMatchSuccessWhenHoleAssignedTo
            @test match2.ind == 2
        end
        @testset "Hole in the right VarNode, depth 2" begin
            n1 = RuleNode(4, [
                RuleNode(4, [RuleNode(2), RuleNode(1)]),
                RuleNode(4, [Hole(BitVector((1, 1, 0, 0, 0, 0))), RuleNode(1)])
            ])
            n2 = RuleNode(4, [
                RuleNode(4, [RuleNode(1), RuleNode(2)]),
                RuleNode(4, [RuleNode(1), Hole(BitVector((1, 1, 0, 0, 0, 0)))])
            ])
            match1 = pattern_match(n1, mn)
            match2 = pattern_match(n2, mn)
            @test match1 isa HerbConstraints.PatternMatchSuccessWhenHoleAssignedTo
            @test match1.ind == 2
            @test match2 isa HerbConstraints.PatternMatchSuccessWhenHoleAssignedTo
            @test match2.ind == 2
        end
    end

    @testset "VarNode HardFails with holes" begin
        mn = RuleNode(4, [VarNode(:x), VarNode(:x)])
        @testset "Disjoint Holes, after RuleNode Success" begin
            n1 = RuleNode(4, [
                RuleNode(4, [
                    Hole(BitVector((1, 1, 0, 0, 0, 0))), 
                    Hole(BitVector((1, 1, 0, 0, 0, 0)))
                ]),
                RuleNode(4, [
                    Hole(BitVector((1, 1, 0, 0, 0, 0))), 
                    Hole(BitVector((0, 0, 1, 1, 0, 0)))
                ])
            ])
            @test pattern_match(n1, mn) isa HerbConstraints.PatternMatchHardFail
        end
        @testset "Disjoint Holes, after UniformHole SoftFail" begin
            n1 = RuleNode(4, [
                UniformHole(BitVector((0, 0, 0, 0, 1, 1)), [
                    Hole(BitVector((1, 1, 0, 0, 0, 0))), 
                    Hole(BitVector((1, 1, 0, 0, 0, 0)))
                ]),
                UniformHole(BitVector((0, 0, 0, 1, 1, 0)), [
                    Hole(BitVector((1, 1, 0, 0, 0, 0))), 
                    Hole(BitVector((0, 0, 1, 1, 0, 0)))
                ]),
            ])
            @test pattern_match(n1, mn) isa HerbConstraints.PatternMatchHardFail
        end
        @testset "Disjoint UniformHoles" begin
            n1 = RuleNode(4, [
                UniformHole(BitVector((0, 0, 0, 0, 1, 1)), [
                    Hole(BitVector((1, 1, 0, 0, 0, 0))), 
                    Hole(BitVector((1, 1, 0, 0, 0, 0)))
                ]),
                UniformHole(BitVector((0, 0, 0, 1, 0, 0)), [
                    Hole(BitVector((1, 1, 0, 0, 0, 0))), 
                    Hole(BitVector((1, 1, 0, 0, 0, 0)))
                ]),
            ])
            @test pattern_match(n1, mn) isa HerbConstraints.PatternMatchHardFail
        end
    end
end