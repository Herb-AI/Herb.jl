@testitem "Robots 2020" begin
    import HerbCore: @rulenode, RuleNode
    import HerbBenchmarks.Robots_2020: RobotState, grammar_robots, interpret

    test_state_1 = RobotState(0, 1, 1, 1, 1, 5)
    test_state_2 = RobotState(1, 5, 5, 5, 5, 5)
    test_state_3 = RobotState(0, 5, 1, 1, 1, 5)

    prim_moveRight = RuleNode(6)
    prim_moveDown = RuleNode(7)
    prim_moveLeft = RuleNode(8)
    prim_moveUp = RuleNode(9)
    prim_drop = RuleNode(10)
    prim_grab = RuleNode(11)
    prim_atTop = RuleNode(14)
    prim_atBottom = RuleNode(15)
    prim_atLeft = RuleNode(16)
    prim_atRight = RuleNode(17)
    prim_notAtTop = RuleNode(18)
    prim_notAtBottom = RuleNode(19)
    prim_notAtLeft = RuleNode(20)
    prim_notAtRight = RuleNode(21)
    prim_if = @rulenode 12{18,9,7} # IF(notAtTop, moveUp, moveDown)
    prim_while = @rulenode 13{14,6} # WHILE(atTop, moveRight)

    @testset "Robots_2020" begin
        @testset "Testing robot transformations" begin
            @testset "Robot in top left corner" begin
                @test interpret(prim_moveRight, test_state_1) ==
                      RobotState(0, 2, 1, 1, 1, 5)
                @test interpret(prim_moveDown, test_state_1) ==
                      RobotState(0, 1, 2, 1, 1, 5)
                @test interpret(prim_moveLeft, test_state_1) ==
                      RobotState(0, 1, 1, 1, 1, 5)
                @test interpret(prim_moveUp, test_state_1) ==
                      RobotState(0, 1, 1, 1, 1, 5)
                @test interpret(prim_drop, test_state_1) ==
                      RobotState(0, 1, 1, 1, 1, 5)
                @test interpret(prim_grab, test_state_1) ==
                      RobotState(1, 1, 1, 1, 1, 5)
            end
            # Test case: robot in bottom right corner
            @testset "Robot in bottom right corner" begin
                @test interpret(prim_moveRight, test_state_2) ==
                      RobotState(1, 5, 5, 5, 5, 5)
                @test interpret(prim_moveDown, test_state_2) ==
                      RobotState(1, 5, 5, 5, 5, 5)
                @test interpret(prim_moveLeft, test_state_2) ==
                      RobotState(1, 4, 5, 4, 5, 5)
                @test interpret(prim_moveUp, test_state_2) ==
                      RobotState(1, 5, 4, 5, 4, 5)
                @test interpret(prim_drop, test_state_2) ==
                      RobotState(0, 5, 5, 5, 5, 5)
                @test interpret(prim_grab, test_state_2) ==
                      RobotState(1, 5, 5, 5, 5, 5)
            end
        end

        @testset "Testing robot conditions" begin
            @testset "Robot in top left corner" begin
                @test interpret(prim_atTop, test_state_1) == true
                @test interpret(prim_atLeft, test_state_1) == true
                @test interpret(prim_notAtBottom, test_state_1) == true
                @test interpret(prim_notAtRight, test_state_1) == true
                @test interpret(prim_atBottom, test_state_1) == false
                @test interpret(prim_atRight, test_state_1) == false
                @test interpret(prim_notAtTop, test_state_1) == false
                @test interpret(prim_notAtLeft, test_state_1) == false
            end

            @testset "Robot in bottom right corner" begin
                @test interpret(prim_atBottom, test_state_2) == true
                @test interpret(prim_atRight, test_state_2) == true
                @test interpret(prim_notAtTop, test_state_2) == true
                @test interpret(prim_notAtLeft, test_state_2) == true
                @test interpret(prim_atTop, test_state_2) == false
                @test interpret(prim_atLeft, test_state_2) == false
                @test interpret(prim_notAtBottom, test_state_2) == false
                @test interpret(prim_notAtRight, test_state_2) == false
            end


        end

        @testset "Testing IF, WHILE and nested programs" begin
            @test interpret(prim_if, test_state_2) == RobotState(1, 5, 4, 5, 4, 5)
            # Nested program: while not at bottom move down and left
            condition = RuleNode(19)
            body = RuleNode(3, [RuleNode(7), RuleNode(8)]) # (moveDown; moveLeft)
            prog = RuleNode(13, [condition, body])
            @test interpret(prog, test_state_3) == RobotState(0, 1, 5, 1, 1, 5)
            @test interpret(prim_if, test_state_1) == RobotState(0, 1, 2, 1, 1, 5)
            # WHILE loop
            @test interpret(prim_while.children[1], test_state_1) == true # test that condition is true
            @test interpret(prim_while, test_state_1) == RobotState(0, 5, 1, 1, 1, 5)
        end
    end
end
