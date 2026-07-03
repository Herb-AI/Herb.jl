@testitem "String Transformations 2020" begin
    import HerbBenchmarks.String_transformations_2020
    import .String_transformations_2020: StringState, grammar_string
    import HerbCore: @rulenode, RuleNode

    test_state_1 = StringState("abc", 1)
    test_state_2 = StringState("abc", 3)
    test_state_3 = StringState("Abc", 1)
    test_state_4 = StringState("abc", 2)
    test_state_5 = StringState("ab!c", 3)
    test_state_6 = StringState("a1?", 2)
    test_state_7 = StringState("   ", 2)
    test_state_8 = StringState("a", 1)
    test_state_9 = StringState("", 0)
    test_state_10 = StringState("a1?odP[&*8wdcE]b!", 1)


    prim_moveRight = RuleNode(6, [])
    prim_moveLeft = RuleNode(7, [])
    prim_makeUppercase = RuleNode(8, [])
    prim_makeLowercase = RuleNode(9, [])
    prim_drop = RuleNode(10, [])
    prim_atEnd = RuleNode(13, [])
    prim_notAtEnd = RuleNode(14, [])
    prim_atStart = RuleNode(15, [])
    prim_notAtStart = RuleNode(16, [])
    prim_isLetter = RuleNode(17, [])
    prim_isNotLetter = RuleNode(18, [])
    prim_isUppercase = RuleNode(19, [])
    prim_isNotUppercase = RuleNode(20, [])
    prim_isLowercase = RuleNode(21, [])
    prim_isNotLowercase = RuleNode(22, [])
    prim_isNumber = RuleNode(23, [])
    prim_isNotNumber = RuleNode(24, [])
    prim_isSpace = RuleNode(25, [])
    prim_isNotSpace = RuleNode(26, [])

    @testset "String_transformations_2020" begin
        @testset "General tests" begin
            problems = get_all_problems(String_transformations_2020)
            @testset "Inputs/Outputs are StringStates" begin
                for problem in problems
                    @test all(
                        typeof(state) == StringState for ex in problem.spec for state in values(ex.in)
                    )
                    @test all(typeof(ex.out) == StringState for ex in problem.spec)
                end
            end
        end

        @testset "Testing string transformations" begin
            @testset "multiple character string" begin
                @test String_transformations_2020.interpret(prim_moveRight, test_state_1) ==
                      StringState("abc", 2)
                @test String_transformations_2020.interpret(prim_moveLeft, test_state_2) ==
                      StringState("abc", 2)
                @test String_transformations_2020.interpret(prim_makeUppercase, test_state_2) ==
                      StringState("abC", 3)
                @test String_transformations_2020.interpret(prim_makeLowercase, test_state_3) ==
                      StringState("abc", 1)
                @test String_transformations_2020.interpret(prim_drop, test_state_1) ==
                      StringState("bc", 1)
            end

            @testset "single character string" begin
                @test String_transformations_2020.interpret(prim_moveRight, test_state_8) ==
                      StringState("a", 1)
                @test String_transformations_2020.interpret(prim_moveLeft, test_state_8) ==
                      StringState("a", 1)
                @test String_transformations_2020.interpret(prim_drop, test_state_8) ==
                      StringState("", 0) # TODO: is that how we want this to behave?
            end

            @testset "empty string" begin
                # pointer at 0
                @test String_transformations_2020.interpret(prim_moveRight, test_state_9) ==
                      StringState("", 0)
                @test String_transformations_2020.interpret(prim_moveLeft, test_state_9) ==
                      StringState("", 1) # TODO: shouldn't change string state -> == StringState("", 0)
                @test_throws BoundsError String_transformations_2020.interpret(
                    prim_makeUppercase,
                    test_state_9,
                )
                @test_throws BoundsError String_transformations_2020.interpret(
                    prim_makeLowercase,
                    test_state_9,
                )
                @test String_transformations_2020.interpret(prim_drop, test_state_9) ==
                      StringState("", -1) # TODO: pointer shouldn't be -1
            end
        end

        @testset "Testing string conditions" begin
            @testset "multiple character string" begin
                @test String_transformations_2020.interpret(prim_atEnd, test_state_2) == true
                @test String_transformations_2020.interpret(prim_atEnd, test_state_1) == false &&
                      String_transformations_2020.interpret(prim_notAtEnd, test_state_1) == true
                @test String_transformations_2020.interpret(prim_atStart, test_state_1) == true
                @test String_transformations_2020.interpret(prim_notAtStart, test_state_1) ==
                      false
                @test String_transformations_2020.interpret(prim_notAtStart, test_state_4) ==
                      true &&
                      String_transformations_2020.interpret(prim_notAtEnd, test_state_4) == true
                @test String_transformations_2020.interpret(prim_isLetter, test_state_1) == true
                @test String_transformations_2020.interpret(prim_isLetter, test_state_5) ==
                      false &&
                      String_transformations_2020.interpret(prim_isNotLetter, test_state_5) ==
                      true
                @test String_transformations_2020.interpret(prim_isUppercase, test_state_3) ==
                      true &&
                      String_transformations_2020.interpret(prim_isNotUppercase, test_state_3) ==
                      false
                @test String_transformations_2020.interpret(prim_isLowercase, test_state_1) ==
                      true &&
                      String_transformations_2020.interpret(prim_isNotLowercase, test_state_1) ==
                      false
                @test String_transformations_2020.interpret(prim_isNumber, test_state_6) == true
                @test String_transformations_2020.interpret(prim_isNotNumber, test_state_1) ==
                      true
                @test String_transformations_2020.interpret(prim_isSpace, test_state_6) ==
                      false &&
                      String_transformations_2020.interpret(prim_isNotSpace, test_state_6) == true
            end

            # Test case: single character string
            @test String_transformations_2020.interpret(prim_atEnd, test_state_8) == true &&
                  String_transformations_2020.interpret(prim_atStart, test_state_8) == true

            @testset "empty string" begin
                @test String_transformations_2020.interpret(prim_atEnd, test_state_9) == true
                # @test String_transformations_2020.interpret(prim_atStart, test_state_9) == true # TODO: should evaluate to true
                @test String_transformations_2020.interpret(prim_notAtEnd, test_state_9) == false
                # @test String_transformations_2020.interpret(prim_notAtStart, test_state_9) == true # TODO
                @test_throws BoundsError String_transformations_2020.interpret(
                    prim_isLetter,
                    test_state_9,
                )
                @test_throws BoundsError String_transformations_2020.interpret(
                    prim_isNotLetter,
                    test_state_9,
                )
                @test_throws BoundsError String_transformations_2020.interpret(
                    prim_isUppercase,
                    test_state_9,
                )
                @test_throws BoundsError String_transformations_2020.interpret(
                    prim_isNotUppercase,
                    test_state_9,
                )
                @test_throws BoundsError String_transformations_2020.interpret(
                    prim_isLowercase,
                    test_state_9,
                )
                @test_throws BoundsError String_transformations_2020.interpret(
                    prim_isNotLowercase,
                    test_state_9,
                )
                @test_throws BoundsError String_transformations_2020.interpret(
                    prim_isNumber,
                    test_state_9,
                )
                @test_throws BoundsError String_transformations_2020.interpret(
                    prim_isNotNumber,
                    test_state_9,
                )
                @test_throws BoundsError String_transformations_2020.interpret(
                    prim_isSpace,
                    test_state_9,
                )
                @test_throws BoundsError String_transformations_2020.interpret(
                    prim_isNotSpace,
                    test_state_9,
                )
            end
        end

        @testset "Testing WHILE, IF, and nested programs" begin
            # Test while loop terminates correctly (even when condition is always true)
            prog = RuleNode(12, [RuleNode(14), RuleNode(8)]) # WHILE(notAtEnd, makeUppercase)
            @test String_transformations_2020.interpret(prog, test_state_1) ==
                  StringState("Abc", 1)

            # Test nested program (IF inside WHILE)
            condition = RuleNode(14) # notAtEnd
            body = RuleNode(11, [RuleNode(17), RuleNode(3, [RuleNode(8), RuleNode(6)]), RuleNode(10)]) # IF(isLetter, makeUppercase; moveRight, drop)
            prog = RuleNode(12, [condition, body])   # WHILE(notAtEnd, IF(isLetter, makeUppercase; moveRight, drop))
            @test String_transformations_2020.interpret(prog, test_state_10) ==
                  StringState("AODPWDCEB!", 10)
        end
    end
end
