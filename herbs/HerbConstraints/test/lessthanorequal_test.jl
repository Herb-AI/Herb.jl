

@testitem "LessThanOrEqual" begin
    using HerbCore, HerbGrammar

    function create_dummy_solver(leftnode::AbstractRuleNode, rightnode::AbstractRuleNode)
        grammar = @csgrammar begin
            Number = x | 1
            Number = Number + Number
            Number = Number - Number
        end
        solver = GenericSolver(grammar, :Number)
        tree = RuleNode(4, [
            leftnode,
            RuleNode(3, [
                RuleNode(2), 
                rightnode
            ])
        ])
        #tree = RuleNode(4, [leftnode, rightnode]) #more trivial case
        leftpath = get_path(tree, leftnode)
        rightpath = get_path(tree, rightnode)
        new_state!(solver, tree)
        leftnode = get_node_at_location(solver, leftpath) #leftnode might have been simplified by `new_state!`
        rightnode = get_node_at_location(solver, rightpath) #rightnode might have been simplified by `new_state!`
        return solver, leftnode, rightnode
    end

    @testset "HardFail, no holes, >" begin
        left = RuleNode(2)
        right = RuleNode(1)
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualHardFail
    end

    @testset "Success, no holes, ==" begin
        left = RuleNode(1)
        right = RuleNode(1)
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
    end

    @testset "Success, no holes, <" begin
        left = RuleNode(1)
        right = RuleNode(2)
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
    end

    @testset "Success, 1 hole (left)" begin
        left = Hole(BitVector((1, 0, 1, 0)))
        right = RuleNode(2)
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
    end

    @testset "Success, 1 hole (right), expands" begin
        left = RuleNode(2)
        right = Hole(BitVector((1, 0, 1, 0)))
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
    end

    @testset "Success, 2 holes" begin
        left = Hole(BitVector((1, 1, 0, 0)))
        right = Hole(BitVector((0, 0, 1, 1)))
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
    end

    @testset "HardFail, 1 hole (left)" begin
        left = Hole(BitVector((0, 0, 1, 1)))
        right = RuleNode(2)
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualHardFail
    end

    @testset "HardFail, 1 hole (right)" begin
        left = RuleNode(3, [RuleNode(1), RuleNode(1)])
        right = Hole(BitVector((1, 1, 0, 0)))
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualHardFail
    end

    @testset "HardFail, 2 holes" begin
        left = Hole(BitVector((0, 0, 1, 1)))
        right = Hole(BitVector((1, 1, 0, 0)))
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualHardFail
    end

    @testset "SoftFail, 2 holes" begin
        left = Hole(BitVector((0, 0, 1, 1)))
        right = Hole(BitVector((1, 0, 1, 0)))
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSoftFail
    end

    @testset "SoftFail, 2 equal uniform holes" begin
        left = Hole(BitVector((1, 1, 0, 0)))
        right = Hole(BitVector((1, 1, 0, 0)))
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSoftFail
    end

    @testset "left hole softfails" begin
        left = Hole(BitVector((0, 1, 1, 0)))
        right = RuleNode(3, [RuleNode(2), RuleNode(2)])
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSoftFail
    end

    @testset "left hole softfails chemistry grammar" begin
        grammar = @csgrammar begin
            Species = "A" #1
            Species = "B" #2
        
            SpeciesList = Species #3
            SpeciesList = SpeciesList + SpeciesList #4
            Reaction = SpeciesList --> SpeciesList #5
        
            ReactionList = Reaction #6
            ReactionList = ReactionList + ReactionList #7
        end

        left = Hole(BitVector((0, 0, 0, 0, 1, 0, 0)))
        right = Hole(BitVector((0, 0, 0, 0, 1, 0, 0)))

        solver = GenericSolver(grammar, :ReactionList)
        tree = RuleNode(7, [
            RuleNode(6, [
               left 
            ]),
            RuleNode(6, [right])
        ])
        
        leftpath = get_path(tree, left)
        rightpath = get_path(tree, right)
        new_state!(solver, tree)
        left = get_node_at_location(solver, leftpath) #leftnode might have been simplified by `new_state!`
        right = get_node_at_location(solver, rightpath) #rightnode might have been simplified by `new_state!`

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSoftFail
        @test HerbConstraints.make_less_than_or_equal!(solver, right, left) isa HerbConstraints.LessThanOrEqualSoftFail
    end

    @testset "left hole gets filled once, two holes remain" begin
        left = Hole(BitVector((0, 0, 1, 1)))
        right = RuleNode(3, [RuleNode(2), RuleNode(2)])
        solver, left, right = create_dummy_solver(left, right)
        # left = 3{hole[1, 2], hole[1, 2, 3, 4]}
        # this is a softfail, because [left <= right] and [left > right] are still possible

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSoftFail
        @test number_of_holes(get_tree(solver)) == 2
    end

    @testset "left hole gets filled twice, one hole remains" begin
        left = Hole(BitVector((0, 0, 1, 1)))
        right = RuleNode(3, [RuleNode(1), RuleNode(2)])
        solver, left, right = create_dummy_solver(left, right)
        # left = 3{1, hole[1, 2]}
        # this is a success, because [left <= right] for all possible assignments

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
        @test number_of_holes(get_tree(solver)) == 1
    end

    @testset "left hole gets filled thrice, and succeeds" begin
        left = Hole(BitVector((0, 0, 1, 1)))
        right = RuleNode(3, [RuleNode(1), RuleNode(1)])
        solver, left, right = create_dummy_solver(left, right)
        # left = 3{1, 1}

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
        @test number_of_holes(get_tree(solver)) == 0
    end

    @testset "right hole softfails" begin
        left = RuleNode(3, [RuleNode(2), RuleNode(2)])
        right = Hole(BitVector((0, 0, 1, 1)))
        solver, left, right = create_dummy_solver(left, right)
        # right = hole[3, 4]{hole[1, 2, 3, 4], hole[1, 2, 3, 4]}

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSoftFail
        @test number_of_holes(get_tree(solver)) == 3
    end

    @testset "right hole gets filled once, then softfails" begin
        left = RuleNode(4, [RuleNode(2), RuleNode(2)])
        right = Hole(BitVector((0, 0, 1, 1)))
        solver, left, right = create_dummy_solver(left, right)
        # right = 4{hole[2, 3, 4], hole[1, 2, 3, 4]}

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSoftFail
        @test number_of_holes(get_tree(solver)) == 2
    end

    @testset "right hole expands to 4 holes" begin
        left = RuleNode(4, [
            RuleNode(4, [
                RuleNode(4, [
                    RuleNode(2),
                    RuleNode(2)
                ]), 
            ]),
            RuleNode(4, [
                RuleNode(2),
                RuleNode(2)
            ]), 
        ])
        right = Hole(BitVector((0, 0, 1, 1)))
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSoftFail
        @test number_of_holes(get_tree(solver)) == 4
    end

    @testset "1 guard, then succeed (no deduction)" begin
        # 1st comparison: {3, 4} <= 4           #guard1
        # 2nd comparison: {1, 2} <= 3           #success
        # 3rd comparison: {1, 2} <= 4           #success
        left = UniformHole(BitVector((0, 0, 1, 1)), [
            Hole(BitVector((1, 1, 0, 0))),
            Hole(BitVector((1, 1, 0, 0)))
        ])
        right = RuleNode(4, [
            RuleNode(3, [
                RuleNode(2)
                RuleNode(2)
            ]),
            RuleNode(4)
        ])
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
        @test number_of_holes(get_tree(solver)) == 3
    end
    
    @testset "1 guard deduction, (node, hole)" begin
        # 1st comparison: {3, 4} <= 4       #guard1
        # 2nd comparison: 2 <= 2            #success
        # 3rd comparison: 3 > {1, 2}        #hardfail
        # the hardfail on the tiebreak means that the possibility of equality on guard must be eliminated
        left = UniformHole(BitVector((0, 0, 1, 1)), [ #this hole should be set to 3
            RuleNode(2),
            RuleNode(3, [
                RuleNode(2)
                RuleNode(2)
            ]),
        ])
        right = RuleNode(4, [
            RuleNode(2),
            Hole(BitVector((1, 1, 0, 0)))
        ])
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
        @test number_of_holes(get_tree(solver)) == 1
    end

    @testset "1 guard deduction, (hole, node)" begin
        # 1st comparison: {3, 4} <= 4       #guard1
        # 2nd comparison: 2 <= 2            #success
        # 3rd comparison: {3, 4} > 2        #hardfail
        # the hardfail on the tiebreak means that the possibility of equality on guard must be eliminated
        left = UniformHole(BitVector((0, 0, 1, 1)), [ #this hole should be set to 3
            RuleNode(2),
            UniformHole(BitVector((0, 0, 1, 1)), [
                RuleNode(2)
                RuleNode(2)
            ]),
        ])
        right = RuleNode(4, [
            RuleNode(2),
            RuleNode(2)
        ])
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
        @test number_of_holes(get_tree(solver)) == 1
    end

    @testset "1 guard deduction, (hole, hole)" begin
        # 1st comparison: {3, 4} <= 4       #guard1
        # 2nd comparison: 2 <= 2            #success
        # 3rd comparison: {3, 4} > {1, 2}   #hardfail
        # the hardfail on the tiebreak means that the possibility of equality on guard must be eliminated
        left = UniformHole(BitVector((0, 0, 1, 1)), [ #this hole should be set to 3
            RuleNode(2),
            UniformHole(BitVector((0, 0, 1, 1)), [
                RuleNode(2)
                RuleNode(2)
            ]),
        ])
        right = RuleNode(4, [
            RuleNode(2),
            Hole(BitVector((1, 1, 0, 0)))
        ])
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
        @test number_of_holes(get_tree(solver)) == 2
    end

    @testset "1 guard, then softfails" begin
        # 1st comparison: {3, 4} <= 4           #guard1
        # 2nd comparison: 2 <= 2                #success
        # 3rd comparison: {1, 4} <= {2, 3}      #softfails because of the guard
        left = UniformHole(BitVector((0, 0, 1, 1)), [
            RuleNode(2),
            Hole(BitVector((1, 0, 0, 1)))
        ])
        right = RuleNode(4, [
            RuleNode(2),
            Hole(BitVector((0, 1, 1, 0)))
        ])
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSoftFail
        @test number_of_holes(get_tree(solver)) == 3
    end

    @testset "2 guards, then succeeds" begin
        # 1st comparison: {3, 4} <= 4   #guard1
        # 2nd comparison: {1, 2} <= 2   #guard2
        # 3rd comparison: {1, 2} <= 2   #success
        left = UniformHole(BitVector((0, 0, 1, 1)), [
            Hole(BitVector((1, 1, 0, 0))),
            Hole(BitVector((1, 1, 0, 0)))
        ])
        right = RuleNode(4, [
            RuleNode(2),
            RuleNode(2)
        ])
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
        @test number_of_holes(get_tree(solver)) == 3
    end

    @testset "2 guards, then softfails" begin
        # 1st comparison: {3, 4} <= 4   #guard1
        # 2nd comparison: {1, 2} <= 2   #guard2
        # 3rd comparison: {1, 2} ?? 1   #softfails
        left = UniformHole(BitVector((0, 0, 1, 1)), [
            Hole(BitVector((1, 1, 0, 0))),
            Hole(BitVector((1, 1, 0, 0)))
        ])
        right = RuleNode(4, [
            RuleNode(2),
            RuleNode(1)
        ])
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSoftFail
        @test number_of_holes(get_tree(solver)) == 3
    end

    @testset "2 guards, then hardfails (thus softfails)" begin
        # 1st comparison: {3, 4} <= 4   #guard1
        # 2nd comparison: {1, 2} <= 2   #guard2
        # 3rd comparison: 1      >  2   #hardfails
        # Since we have 2 guards, we cannot made a deduction and thus this is a softfail.
        # Either guard1 must become 3
        # Or     guard2 must become 1
        left = UniformHole(BitVector((0, 0, 1, 1)), [
            Hole(BitVector((1, 1, 0, 0))),
            RuleNode(2)
        ])
        right = RuleNode(4, [
            RuleNode(2),
            RuleNode(1)
        ])
        solver, left, right = create_dummy_solver(left, right)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSoftFail
        @test number_of_holes(get_tree(solver)) == 2
    end

    @testset "Success, large tree" begin
        grammar = @csgrammar begin
            Int = |(1:9)
            Int = x
            Int = 0
            Int = Int + Int
            Int = Int - Int
            Int = Int * Int
        end
        domain = BitVector((1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))
        left = RuleNode(13, [RuleNode(5), Hole(domain)])
        right = RuleNode(13, [RuleNode(11), RuleNode(1)])
        tree = RuleNode(14, [left, right])

        solver = GenericSolver(grammar, :Int)
        new_state!(solver, tree)

        @test HerbConstraints.make_less_than_or_equal!(solver, left, right) isa HerbConstraints.LessThanOrEqualSuccess
        @test contains_nonuniform_hole(get_tree(solver)) == true
        @test number_of_holes(get_tree(solver)) == 1
    end
end
