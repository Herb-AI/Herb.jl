@testitem "csgrammar_annotated" begin
    using HerbGrammar # HerbSearch

    @testset "macro vs from expressions" begin
        
        direct = HerbConstraints.@csgrammar_annotated begin        
            zero::  Number = 0             
            one::  Number = 1     
            constants:: Number = |(2:4) 
            variables:: Number = x | y              
            minus::      Number = -Number           := identity("zero")
            plus::      Number = Number + Number    := (associative, commutative)
            Number = a | b | c
        end

        expr = quote        
            zero::  Number = 0             
            one::  Number = 1     
            constants:: Number = |(2:4) 
            variables:: Number = x | y              
            minus::      Number = -Number           := identity("zero")
            plus::      Number = Number + Number    := (associative, commutative)
            Number = a | b | c
        end

        from_expr = HerbConstraints.expr2csgrammar_annotated(expr)

        @test "$(direct)" == "$(from_expr)"
    end


    num =  quote
        Number = 0
        Number = 1
        Number = |(2:4)
        Number = x | y
        Number = -Number 
        Number = Number + Number
    end
    grammar = HerbGrammar.expr2csgrammar(num)
    unannotated = HerbConstraints.expr2csgrammar_annotated(num)

    num_annotated = quote        
        zero::  Number = 0             
        one::  Number = 1     
        constants:: Number = |(2:4) 
        variables:: Number = x | y              
        minus::      Number = -Number           := identity("zero")
        plus::      Number = Number + Number    := (associative, commutative)
    end
    annotated = HerbConstraints.expr2csgrammar_annotated(num_annotated)

    @testset "backwards compatible to @csgrammar w/o annotations and labels" begin
        @test length(unannotated.grammar.rules) == length(grammar.rules)

        for (r1, r2) in zip(unannotated.grammar.rules, grammar.rules)
            @test r1 == r2
        end
        @test "$(unannotated.grammar)" == "$(grammar)"
    end

    @testset "backwards compatible to @csgrammar with annotated and labeled" begin
        @test length(annotated.grammar.rules) == length(grammar.rules)

        for (r1, r2) in zip(annotated.grammar.rules, grammar.rules)
            @test r1 == r2
        end
        @test "$(annotated.grammar)" == "$(grammar)"
    end

    @testset "labels" begin
        bylabel = HerbConstraints.get_bylabel(annotated)
        rules = annotated.grammar.rules
        
        variables_rules = (bylabel["variables"])
        @test(rules[variables_rules[1]] == :(x))
        @test(rules[variables_rules[2]] == :(y))

        zero_rule = only((bylabel["zero"]))
        @test(rules[zero_rule] == :(0))

        one_rule = only((bylabel["one"]))
        @test(rules[one_rule] == :(1))

        constants_rules = (bylabel["constants"])
        for c in 2:4
            @test(rules[constants_rules[c-1]] == :($c))
        end

        minus_rule = only((bylabel["minus"]))
        @test(rules[minus_rule] == :(-Number))

        plus_rule = only((bylabel["plus"]))
        @assert(rules[plus_rule] == :(Number + Number))
    end

    @testset "label duplication" begin
        expr = quote
            zero::  Number = 0   
            zero::  Number = 1
        end
        @test_throws ErrorException HerbConstraints.expr2csgrammar_annotated(expr)
    end

    @testset "annotations" begin
        bylabel = HerbConstraints.get_bylabel(annotated)
        rule_annotations = annotated.rule_annotations
        rules = annotated.grammar.rules

        variables_rules = (bylabel["variables"])
        @test(rule_annotations[variables_rules[1]] == [])
        @test(rule_annotations[variables_rules[2]] == [])

        zero_rule = only((bylabel["zero"]))
        @test(rule_annotations[zero_rule] == [])

        one_rule = only((bylabel["one"]))
        @test(rule_annotations[one_rule] == [])

        constants_rules = (bylabel["constants"])
        for r in constants_rules
            @test(rule_annotations[r] == [])
        end

        minus_rule = only((bylabel["minus"]))
        annotations = rule_annotations[minus_rule]
        @test :(identity("zero")) in annotations

        plus_rule = only((bylabel["plus"]))
        annotations = rule_annotations[plus_rule]
        @test :associative in annotations
        @test :commutative in annotations
    end

    @testset "undefined annotation" begin
        expr = quote        
            Number = Number + Number := (unknown_annotation)
        end
        @test_throws ArgumentError HerbConstraints.expr2csgrammar_annotated(expr)
    end 

    @testset "no label in call annotation" begin
        expr = quote        
            Number = Number + Number := (unknown_annotation(arg))
        end
        @test_throws KeyError HerbConstraints.expr2csgrammar_annotated(expr)
    end

    @testset "undefined label in call annotation" begin
        expr = quote        
            plus :: Number = Number + Number := (unknown_annotation(plus))
        end
        @test_throws ArgumentError HerbConstraints.expr2csgrammar_annotated(expr)
    end


    @testset "candidates generation" begin
        @test length(grammar.constraints)==0
        @test length(annotated.grammar.constraints) == 7

        # @test length(HerbSearch.BFSIterator(grammar, :Number, max_depth=3)) == 4039
        # @test length(HerbSearch.BFSIterator(annotated.grammar, :Number, max_depth=3)) == 222
    end
end