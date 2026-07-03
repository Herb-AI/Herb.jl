@testitem "expr2rulenode" begin
    using HerbCore

    g1 = @cfgrammar begin
        Number = |(1:2)
        Number = x
        Number = Number + Number
        Number = Number * Number
        Number = DiffNumber
        DiffNumber = |(3:4)
    end

    expr1 = :(1 + 2)
    expr2 = :((x * (1 + 3)) + (4 * x))
    @test expr2rulenode(expr1, g1) == RuleNode(4, [RuleNode(1, []), RuleNode(2, [])])
    @test expr2rulenode(expr2, g1) == RuleNode(4, [RuleNode(5, [RuleNode(3, []), RuleNode(4, [RuleNode(1, []), RuleNode(6, [RuleNode(7, [])])])]), RuleNode(5, [RuleNode(6, [RuleNode(8, [])]), RuleNode(3, [])])])


    g2 = @csgrammar begin
        Start = Sequence                   #1

        Sequence = Operation                #2
        Sequence = (Operation; Sequence)    #3
        Operation = Transformation          #4
        Operation = ControlStatement        #5

        Transformation = moveRight() | moveDown() | moveLeft() | moveUp() | drop() | grab()     #6
        ControlStatement = IF(Condition, Sequence, Sequence)        #12
        ControlStatement = WHILE(Condition, Sequence)               #13

        Condition = atTop() | atBottom() | atLeft() | atRight() | notAtTop() | notAtBottom() | notAtLeft() | notAtRight()      #14
    end

    expr3 = :(moveUp())
    expr4 = :(moveUp(); (moveRight()))
    expr5 = :(IF(atTop(), ((moveUp(); (moveRight()))), moveRight()))

    @test expr2rulenode(expr3, g2) == RuleNode(9, [])
    @test expr2rulenode(expr3, g2, :Start) == RuleNode(1, [RuleNode(2, [RuleNode(4, [RuleNode(9, [])])])])

    @test expr2rulenode(expr4, g2) == RuleNode(3, [RuleNode(4, [RuleNode(9, [])]), RuleNode(2, [RuleNode(4, [RuleNode(6, [])])])])
    @test expr2rulenode(expr4, g2, :Start) == RuleNode(1, [RuleNode(3, [RuleNode(4, [RuleNode(9, [])]), RuleNode(2, [RuleNode(4, [RuleNode(6, [])])])])])

    @test expr2rulenode(expr5, g2) == RuleNode(12, [RuleNode(14, []), RuleNode(3, [RuleNode(4, [RuleNode(9, [])]), RuleNode(2, [RuleNode(4, [RuleNode(6, [])])])]), RuleNode(2, [RuleNode(4, [RuleNode(6, [])])])])
    @test expr2rulenode(expr5, g2, :Start) == RuleNode(1, [RuleNode(2, [RuleNode(5, [RuleNode(12, [RuleNode(14, []), RuleNode(3, [RuleNode(4, [RuleNode(9, [])]), RuleNode(2, [RuleNode(4, [RuleNode(6, [])])])]), RuleNode(2, [RuleNode(4, [RuleNode(6, [])])])])])])])

    int_grammar = @csgrammar begin
        Val = 0 | 1 | 2
    end

    int_expr = :(2)
    @test expr2rulenode(int_expr, int_grammar) == RuleNode(3)
    @test rulenode2expr(expr2rulenode(int_expr, int_grammar), int_grammar) == int_expr

    float_grammar = @csgrammar begin
        Val = 0.0 | 1.0 | 2.0 | 3.14
    end

    float_expr = :(3.14)
    @test expr2rulenode(float_expr, float_grammar) == RuleNode(4)
    @test rulenode2expr(expr2rulenode(float_expr, float_grammar), float_grammar) == float_expr

    sym_grammar = @csgrammar begin
        Val = x
    end

    sym = :(x)
    @test expr2rulenode(sym, sym_grammar) == RuleNode(1)
    @test rulenode2expr(expr2rulenode(sym, sym_grammar), sym_grammar) == sym
end

@testitem "expr2rulenode cvc grammar bug" begin
    import HerbCore: @rulenode

    grammar_11440431 = @cfgrammar begin
        Start = ntString
        ntString = _arg_1
        ntString = ""
        ntString = " "
        ntString = "US"
        ntString = "CAN"
        ntString = concat_cvc(ntString, ntString)
        ntString = replace_cvc(ntString, ntString, ntString)
        ntString = at_cvc(ntString, ntInt)
        ntString = int_to_str_cvc(ntInt)
        ntString = ntBool ? ntString : ntString
        ntString = substr_cvc(ntString, ntInt, ntInt)
        ntInt = 1
        ntInt = 0
        ntInt = -1
        ntInt = ntInt + ntInt
        ntInt = ntInt - ntInt
        ntInt = len_cvc(ntString)
        ntInt = str_to_int_cvc(ntString)
        ntInt = ntBool ? ntInt : ntInt
        ntInt = indexof_cvc(ntString, ntString, ntInt)
        ntBool = true
        ntBool = false
        ntBool = ntInt == ntInt
        ntBool = prefixof_cvc(ntString, ntString)
        ntBool = suffixof_cvc(ntString, ntString)
        ntBool = contains_cvc(ntString, ntString)
    end
    @test expr2rulenode(:(at_cvc(_arg_1, 1)), grammar_11440431) == @rulenode 9{2,13}
end


@testitem "convert expr with multiple intermediate rules and multiple same types on rhs." begin
    using HerbCore: @rulenode
    @testset "Multiple similar types on RHS" begin
    g = @csgrammar begin
            S = A - B
            S = A + B
            S = f(A, B)
            A = V
            B = V
            V = 1
            V = 2
        end
        e1 = :(1-1)
        @test expr2rulenode(e1, g) == @rulenode 1{4{6}, 5{6}}
        @test rulenode2expr(expr2rulenode(e1, g), g) == e1
        e2 = :(1+1)
        @test expr2rulenode(e2, g) == @rulenode 2{4{6}, 5{6}}
        @test rulenode2expr(expr2rulenode(e2, g), g) == e2
        e3 = :(f(1, 1))
        @test expr2rulenode(e3, g) == @rulenode 3{4{6}, 5{6}}
        @test rulenode2expr(expr2rulenode(e3, g), g) == e3

        @test_throws ErrorException expr2rulenode(:((1 + 1) + 1), g)
    end
    @testset "Nested types" begin
        g = @csgrammar begin
            S = A - D
            A = B
            B = C
            C = 1
            D = 3
        end
        @test expr2rulenode(:(1-3), g) == @rulenode 1{2{3{4}}, 5}
        @test rulenode2expr(expr2rulenode(:((1)-3), g), g) == :(1 - 3)
    end

end