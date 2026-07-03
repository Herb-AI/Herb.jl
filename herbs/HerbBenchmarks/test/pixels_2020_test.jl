@testitem "Pixels" begin
    import HerbBenchmarks: Pixels_2020
    import HerbCore: @rulenode, RuleNode

    prim_moveRight = RuleNode(6)
    prim_moveLeft = RuleNode(7)
    prim_moveUp = RuleNode(8)
    prim_moveDown = RuleNode(9)
    prim_draw0 = RuleNode(10)
    prim_draw1 = RuleNode(11)
    prim_atTop = RuleNode(14)
    prim_atBottom = RuleNode(15)
    prim_atLeft = RuleNode(16)
    prim_atRight = RuleNode(17)
    prim_notAtTop = RuleNode(18)
    prim_notAtBottom = RuleNode(19)
    prim_notAtLeft = RuleNode(20)
    prim_notAtRight = RuleNode(21)

    function emptymatrix()
        return Pixels_2020.PixelState(Bool[0 0 0; 0 0 0; 0 0 0])
    end

    function emptymatrix_bottomright()
        pixel_state = Pixels_2020.PixelState(Bool[0 0 0; 0 0 0; 0 0 0])
        pixel_state.position = (3, 3)
        return pixel_state
    end

    function matrix_onepixel()
        return Pixels_2020.PixelState(Bool[1 0 0; 0 0 0; 0 0 0])
    end

    function matrix_filledtop()
        return Pixels_2020.PixelState(Bool[1 1 1; 0 0 0; 0 0 0])
    end

    @testset "Pixels_2020" begin
        @testset "Testing pixels conditions" begin
            @testset "empty matrix, pointer top left" begin
                # Test conditions => shouldn't mutate pixel state
                test_state = emptymatrix()
                @test Pixels_2020.interpret(prim_atTop, test_state) == true
                @test Pixels_2020.interpret(prim_atLeft, test_state) == true
                @test Pixels_2020.interpret(prim_notAtBottom, test_state) == true
                @test Pixels_2020.interpret(prim_notAtRight, test_state) == true
                @test Pixels_2020.interpret(prim_atBottom, test_state) == false
                @test Pixels_2020.interpret(prim_atRight, test_state) == false
                @test Pixels_2020.interpret(prim_notAtTop, test_state) == false
                @test Pixels_2020.interpret(prim_notAtLeft, test_state) == false
            end

            @testset "empty matrix, pointer bottom right" begin
                test_state = emptymatrix_bottomright()
                @test Pixels_2020.interpret(prim_atBottom, test_state) == true
                @test Pixels_2020.interpret(prim_atRight, test_state) == true
                @test Pixels_2020.interpret(prim_notAtTop, test_state) == true
                @test Pixels_2020.interpret(prim_notAtLeft, test_state) == true
                @test Pixels_2020.interpret(prim_atTop, test_state) == false
                @test Pixels_2020.interpret(prim_atLeft, test_state) == false
                @test Pixels_2020.interpret(prim_notAtBottom, test_state) == false
                @test Pixels_2020.interpret(prim_notAtRight, test_state) == false
            end
        end

        @testset "Testing pixels transformations" begin
            @testset "empty matrix, start at top left" begin
                test_state = emptymatrix() # will be modified throughout test, we reuse the same state
                Pixels_2020.interpret(prim_moveRight, test_state)
                @test test_state.position == (2, 1)
                Pixels_2020.interpret(prim_moveLeft, test_state)
                @test test_state.position == (1, 1)
                Pixels_2020.interpret(prim_moveDown, test_state)
                @test test_state.position == (1, 2)
                Pixels_2020.interpret(prim_moveUp, test_state)
                @test test_state.position == (1, 1)
            end
            @testset "moving out of bounds" begin
                # top left corner
                test_state = emptymatrix()
                Pixels_2020.interpret(prim_moveLeft, test_state)
                @test test_state.position == (1, 1)
                Pixels_2020.interpret(prim_moveUp, test_state)
                @test test_state.position == (1, 1)
                # bottom right corner
                test_state = emptymatrix_bottomright()
                Pixels_2020.interpret(prim_moveRight, test_state)
                @test test_state.position == (3, 3)
                Pixels_2020.interpret(prim_moveDown, test_state)
                @test test_state.position == (3, 3)
            end
            @testset "drawing pixels" begin
                test_state = emptymatrix()
                Pixels_2020.interpret(prim_draw1, test_state)
                @test test_state.matrix == Bool[1 0 0; 0 0 0; 0 0 0]
                Pixels_2020.interpret(prim_draw0, test_state)
                @test test_state.matrix == Bool[0 0 0; 0 0 0; 0 0 0]
                # test repeated drawing doesn't break anything
                test_state = emptymatrix()
                Pixels_2020.interpret(prim_draw0, emptymatrix())
                @test test_state.matrix == Bool[0 0 0; 0 0 0; 0 0 0]
                test_state = matrix_onepixel()
                Pixels_2020.interpret(prim_draw1, test_state)
                @test test_state.matrix == Bool[1 0 0; 0 0 0; 0 0 0]
            end
        end

        @testset "Testing IF, WHILE and nested programs" begin
            # Test IF
            test_state = matrix_filledtop()
            prog = RuleNode(12, [RuleNode(18), RuleNode(11), RuleNode(10)]) # IF(notAtTop, draw1, draw0)
            Pixels_2020.interpret(prog, test_state)
            @test test_state.matrix == Bool[0 1 1; 0 0 0; 0 0 0]
            Pixels_2020.interpret(prim_moveDown, test_state)
            Pixels_2020.interpret(prog, test_state)
            @test test_state.matrix == Bool[0 1 1; 1 0 0; 0 0 0]
            # Test WHILE
            # Test that while loop terminates correctly (even when condition is always true)
            test_state = emptymatrix()
            prog = RuleNode(13, [RuleNode(14), RuleNode(11)]) # WHILE(atTop, draw1)
            Pixels_2020.interpret(prog, test_state)
            @test test_state.matrix == Bool[1 0 0; 0 0 0; 0 0 0]
            prog = RuleNode(13, [RuleNode(19), RuleNode(9)]) # WHILE(notAtBottom, moveDown)
            Pixels_2020.interpret(prog, test_state)
            @test test_state.position == (1, 3)
            # Test nested program: turn matrix of all zeros into identity matrix
            test_state = emptymatrix()
            prog = @rulenode 3{11,3{9,3{6,3{11,3{9,3{6,11}}}}}}
            Pixels_2020.interpret(prog, test_state)
            @test test_state.matrix == Bool[1 0 0; 0 1 0; 0 0 1]
            @test test_state.position == (3, 3)
        end
    end
end
