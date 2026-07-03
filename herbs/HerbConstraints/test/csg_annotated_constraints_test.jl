# """
# This test file tests that constraints in annotated grammars work as intended. 
# To make sure that constraints are tested properly:
#     * Each constraint should bad out at least one "bad" program uniquely
#     * At least one "good" program that is equivalent should pass all constraints
# Use "Run Tests with Coverage" to ensure that all constraints are covered by the tests.
# Make sure all tests have Total != 0 tests (that you did not forget to call the testing function).
# Recommended to tuRuleNode on notice_prints by default when developing tests.
# """
@testitem "csg annotated constraints" begin
    using HerbConstraints, HerbGrammar, Test
    
    function check_constraints(
        annotated_grammar::ContextSensitiveGrammar,
        good_programs::Vector{RuleNode},
        bad_programs::Vector{RuleNode};
        forgive_missing_constraints::Bool=false,
        notice_prints::Bool=true
    )
        @assert length(good_programs) >= 1
        for p ∈ good_programs
            # println("Checking good program: ", HerbGrammar.rulenode2expr(p, annotated_grammar))
            for c ∈ annotated_grammar.constraints
                if !((@test HerbConstraints.check_tree(c, p)) isa Test.Pass)
                    if notice_prints
                        println()
                        println("Fail information:")
                        println("$(HerbGrammar.rulenode2expr(p, annotated_grammar)) (good) was filtered by:")
                        println(c)
                        println()
                    end
                end
            end
        end
        tested_constraints = Set{Any}()
        for p ∈ bad_programs
            # println("Checking bad program: ", HerbGrammar.rulenode2expr(p, annotated_grammar))
            constrained_by = Vector{Any}()
            for c ∈ annotated_grammar.constraints
                if !HerbConstraints.check_tree(c, p)
                    push!(constrained_by, c)
                end
            end
            @test length(constrained_by) >= 1
            if length(constrained_by) > 1 && notice_prints
                println()
                println("Notice:")
                println("$(HerbGrammar.rulenode2expr(p, annotated_grammar)) (bad) was filtered by multiple constraints")
                [println(c) for c in constrained_by]
            elseif length(constrained_by) == 1
                push!(tested_constraints, constrained_by[1])
            elseif length(constrained_by) == 0
                println()
                println("Fail information:")
                println("$(HerbGrammar.rulenode2expr(p, annotated_grammar)) (bad) was not filtered by any constraint")
                println("The rulenode: $p")
                println("The grammar constraints:")
                [println(c) for c in annotated_grammar.constraints]
            end
        end
        if ((!forgive_missing_constraints || notice_prints) 
            && (length(tested_constraints) != length(annotated_grammar.constraints)))
            if !forgive_missing_constraints
                @test (length(tested_constraints) == length(annotated_grammar.constraints))
                println()
                println("Fail information:") 
            else
                println()
                println("Notice:")
            end
            println("Not all constraints were tested.")
            # println("Tested constraints:")
            # [println(c) for c in tested_constraints]
            println("Missing constraints:")
            [println(c) for c in setdiff(Set(annotated_grammar.constraints), tested_constraints)]
            println()
        end
    end

    @testset "identity" begin
        annotated_grammar = quote        
            zero::      Number = 0
            var::       Number = x 
            plus::      Number = Number + Number    := (identity("zero"))
            minus::     Number = -Number             := (identity("zero"))
        end
        annotated = HerbConstraints.expr2csgrammar_annotated(annotated_grammar)
        zero = only((HerbConstraints.get_bylabel(annotated)["zero"]))
        x = only((HerbConstraints.get_bylabel(annotated)["var"]))
        plus = only((HerbConstraints.get_bylabel(annotated)["plus"]))
        minus = only((HerbConstraints.get_bylabel(annotated)["minus"]))
        
        
        good = Vector{RuleNode}()
        bad = Vector{RuleNode}()

        # plus identity("zero")
        push!(good, RuleNode(x))
        push!(bad, RuleNode(plus, [
            RuleNode(x), 
            RuleNode(zero)
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(zero), 
            RuleNode(x)
        ]))

        # minus identity("zero")
        push!(good, RuleNode(x))
        push!(bad, RuleNode(minus, [RuleNode(zero)]))

        check_constraints(
            annotated.grammar,
            good,
            bad
        )
    end

    @testset "inverse" begin
        annotated_grammar = quote        
            zero::      Number = 0
            var::       Number = x | y 
            plus::      Number = Number + Number    := (inverse("minus"))
            minus::     Number = -Number            
        end
        annotated = HerbConstraints.expr2csgrammar_annotated(annotated_grammar)
        zero = only((HerbConstraints.get_bylabel(annotated)["zero"]))
        x,y = (HerbConstraints.get_bylabel(annotated)["var"])
        plus = only((HerbConstraints.get_bylabel(annotated)["plus"]))
        minus = only((HerbConstraints.get_bylabel(annotated)["minus"]))
        
        
        good = Vector{RuleNode}()
        bad = Vector{RuleNode}()

        # plus inverse("minus")
        push!(good, RuleNode(zero))
        push!(good, RuleNode(plus, [
            RuleNode(x), 
            RuleNode(minus, [RuleNode(y)])
        ]))
        push!(good, RuleNode(plus, [
            RuleNode(minus, [RuleNode(x)]),
            RuleNode(y)
        ]))

        push!(bad, RuleNode(plus, [
            RuleNode(x), 
            RuleNode(minus, [RuleNode(x)])
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(minus, [RuleNode(x)]),
            RuleNode(x)
        ]))

        push!(bad, RuleNode(minus, [
            RuleNode(minus, [
                RuleNode(y)
            ])
        ]))

        check_constraints(
            annotated.grammar,
            good,
            bad
        )
    end

    @testset "commutative" begin
        annotated_grammar = quote        
            var::       Number = x | y 
            plus::      Number = Number + Number    := (commutative)
        end
        annotated = HerbConstraints.expr2csgrammar_annotated(annotated_grammar)
        x,y = (HerbConstraints.get_bylabel(annotated)["var"])
        plus = only((HerbConstraints.get_bylabel(annotated)["plus"]))
        
        
        good = Vector{RuleNode}()
        bad = Vector{RuleNode}()

        # plus commutative
        push!(good, RuleNode(plus, [
            RuleNode(x), 
            RuleNode(y)
        ]))

        push!(bad, RuleNode(plus, [
            RuleNode(y), 
            RuleNode(x)
        ]))

        check_constraints(
            annotated.grammar,
            good,
            bad
        )
    end

    @testset "distributive_over" begin
        annotated_grammar = quote 
            var::       Number = x | y | z
            plus::      Number = Number + Number    
            times::     Number = Number * Number    := (distributive_over("plus"))
        end
        annotated = HerbConstraints.expr2csgrammar_annotated(annotated_grammar)
        x,y,z = (HerbConstraints.get_bylabel(annotated)["var"])
        plus = only((HerbConstraints.get_bylabel(annotated)["plus"]))
        times = only((HerbConstraints.get_bylabel(annotated)["times"]))
        
        
        good = Vector{RuleNode}()
        bad = Vector{RuleNode}()

        # times distributive_over("plus")
        push!(good, RuleNode(times, [
            RuleNode(plus, [
                RuleNode(x),
                RuleNode(y)
            ]),
            RuleNode(z)
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(times, [
                RuleNode(x),
                RuleNode(z)
            ]),
            RuleNode(times, [
                RuleNode(y),
                RuleNode(z)
            ])
        ]))

        push!(good, RuleNode(times, [
            RuleNode(z),
            RuleNode(plus, [
                RuleNode(x),
                RuleNode(y)
            ])
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(times, [
                RuleNode(z),
                RuleNode(x)
            ]),
            RuleNode(times, [
                RuleNode(z),
                RuleNode(y)
            ])
        ]))

        push!(good, RuleNode(plus, [
            RuleNode(times, [
                RuleNode(x),
                RuleNode(z)
            ]),
            RuleNode(times, [
                RuleNode(z),
                RuleNode(y)
            ])
        ]))
        push!(good, RuleNode(plus, [
            RuleNode(times, [
                RuleNode(z),
                RuleNode(x)
            ]),
            RuleNode(times, [
                RuleNode(y),
                RuleNode(z)
            ])
        ]))

        push!(good, RuleNode(plus, [
            RuleNode(x),
            RuleNode(x)
        ]))

        check_constraints(
            annotated.grammar,
            good,
            bad
        )
    end

    @testset "distributive_over+commutative" begin
        annotated_grammar = quote 
            var::       Number = x | y | z
            plus::      Number = Number + Number    
            times::     Number = Number * Number    := (distributive_over("plus"), commutative)
        end
        annotated = HerbConstraints.expr2csgrammar_annotated(annotated_grammar)
        x,y,z = (HerbConstraints.get_bylabel(annotated)["var"])
        plus = only((HerbConstraints.get_bylabel(annotated)["plus"]))
        times = only((HerbConstraints.get_bylabel(annotated)["times"]))
        
        good = Vector{RuleNode}()
        bad = Vector{RuleNode}()

        # times distributive_over("plus")
        push!(good, RuleNode(times, [
            RuleNode(z),
            RuleNode(plus, [
                RuleNode(x),
                RuleNode(y)
            ])
        ]))

        push!(bad, RuleNode(times, [
            RuleNode(plus, [
                RuleNode(x),
                RuleNode(y)
            ]),
            RuleNode(z)
        ]))

        push!(bad, RuleNode(plus, [
            RuleNode(times, [
                RuleNode(x),
                RuleNode(z)
            ]),
            RuleNode(times, [
                RuleNode(y),
                RuleNode(z)
            ])
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(times, [
                RuleNode(x),
                RuleNode(y)
            ]),
            RuleNode(times, [
                RuleNode(x),
                RuleNode(z)
            ])
        ]))

        push!(bad, RuleNode(plus, [
            RuleNode(times, [
                RuleNode(x),
                RuleNode(y)
            ]),
            RuleNode(times, [
                RuleNode(y),
                RuleNode(z)
            ])
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(times, [
                RuleNode(y),
                RuleNode(z)
            ]),
            RuleNode(times, [
                RuleNode(x),
                RuleNode(y)
            ])
        ]))

        push!(good, RuleNode(plus, [
            RuleNode(x),
            RuleNode(x)
        ]))

        check_constraints(
            annotated.grammar,
            good,
            bad
        )
    end

    @testset "associativeity" begin
        annotated_grammar = quote        
            constants:: Number = |(1:4) 
            smallvars:: Number = x | y 
            mult::      Number = Number * Number    := associative
            bigvars:: Number = a | b | c
        end
        annotated = HerbConstraints.expr2csgrammar_annotated(annotated_grammar)

        mult = only((HerbConstraints.get_bylabel(annotated)["mult"]))
        consts = (HerbConstraints.get_bylabel(annotated)["constants"])
        x,y = (HerbConstraints.get_bylabel(annotated)["smallvars"])
        a,b,c = (HerbConstraints.get_bylabel(annotated)["bigvars"])

        good = Vector{RuleNode}()
        bad = Vector{RuleNode}()

        mult_xy = RuleNode(mult, [
            RuleNode(x), 
            RuleNode(y)
        ])
        mult_ya = RuleNode(mult, [
            RuleNode(y), 
            RuleNode(a)
        ])

        # check for x<y<a all orders
        push!(good, RuleNode(mult, [mult_xy, RuleNode(a)]))
        push!(good, RuleNode(mult, [mult_ya, RuleNode(x)]))
        push!(bad,  RuleNode(mult, [RuleNode(x), mult_ya]))
        push!(bad,  RuleNode(mult, [RuleNode(a), mult_xy]))
        check_constraints(
            annotated.grammar,
            good,
            bad
        )
    end

    @testset "associativity+commutative" begin
        annotated_grammar = quote        
            constants:: Number = |(1:4) 
            smallvars:: Number = x | y 
            plus::      Number = Number + Number    := (associative, commutative)
            bigvars:: Number = a | b | c
        end
        annotated = HerbConstraints.expr2csgrammar_annotated(annotated_grammar)

        plus = only((HerbConstraints.get_bylabel(annotated)["plus"]))
        consts = (HerbConstraints.get_bylabel(annotated)["constants"])
        x,y = (HerbConstraints.get_bylabel(annotated)["smallvars"])
        a,b,c = (HerbConstraints.get_bylabel(annotated)["bigvars"])

        good = Vector{RuleNode}()
        bad = Vector{RuleNode}()

        # basic ordering
        push!(good, RuleNode(plus, [
            RuleNode(consts[1]),
            RuleNode(plus, [
                RuleNode(consts[2]),
                RuleNode(plus, [
                    RuleNode(consts[3]), 
                    RuleNode(consts[4])
                ])
            ])
        ]))
        push!(good, RuleNode(plus, [
            RuleNode(consts[1]),
            RuleNode(plus, [
                RuleNode(consts[1]),
                RuleNode(plus, [
                    RuleNode(consts[1]), 
                    RuleNode(consts[1])
                ])
            ])
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(consts[3]), 
            RuleNode(consts[2])
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(b), 
            RuleNode(a)
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(b), 
            RuleNode(plus, [
                RuleNode(a), 
                RuleNode(b)
            ])
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(consts[3]), 
            RuleNode(plus, [
                RuleNode(consts[2]), 
                RuleNode(consts[3])
            ])
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(plus, [
                RuleNode(a), 
                RuleNode(b)
            ]),
            RuleNode(a)
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(plus, [
                RuleNode(consts[2]), 
                RuleNode(consts[3])
            ]),
            RuleNode(consts[2])
        ]))


        # permutations of x<y<plus<a<b<c
        push!(good, RuleNode(plus, [
            RuleNode(x), 
            RuleNode(plus, [
                RuleNode(y), 
                RuleNode(plus, [
                    RuleNode(plus, [
                        RuleNode(a), 
                        RuleNode(b)
                    ]),
                    RuleNode(c)
                ])
            ])
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(x), 
            RuleNode(plus, [
                RuleNode(plus, [
                    RuleNode(plus, [
                        RuleNode(y), 
                        RuleNode(a)
                    ]),
                    RuleNode(b)
                ]),
                RuleNode(c)
            ])
        ]))
        push!(bad, RuleNode(plus, [
            RuleNode(plus, [
                RuleNode(plus, [
                    RuleNode(plus, [
                        RuleNode(x), 
                        RuleNode(y)
                    ]),
                    RuleNode(a)
                ]),
                RuleNode(b)
            ]),
            RuleNode(c)
        ]))

        check_constraints(
            annotated.grammar,
            good,
            bad,
            # parallel plus will entail infinite depth - so we want the constraint but can't test it
            forgive_missing_constraints=true,
            notice_prints=false
        )
    end

    @testset "associativity+idempotent" begin
        annotated_grammar = quote        
            smallvars:: Boolean = x | y |z
            and::  Boolean = Boolean && Boolean    := (associative, idempotent)
            bigvars:: Boolean = a | b | c
        end
        annotated = HerbConstraints.expr2csgrammar_annotated(annotated_grammar)

        and = only((HerbConstraints.get_bylabel(annotated)["and"]))
        x,y,z = (HerbConstraints.get_bylabel(annotated)["smallvars"])
        a,b,c = (HerbConstraints.get_bylabel(annotated)["bigvars"])

        good = Vector{RuleNode}()
        bad = Vector{RuleNode}()

        push!(good, RuleNode(and, [
            RuleNode(a), 
            RuleNode(b)
        ]))
        push!(good, RuleNode(and, [
            RuleNode(and, [
                RuleNode(a), 
                RuleNode(b)
            ]),
            RuleNode(c)
        ]))

        #associative
        push!(bad, RuleNode(and, [
            RuleNode(a),
            RuleNode(and, [
                RuleNode(b), 
                RuleNode(c)
            ])
        ]))
        
        # idempotent
        push!(bad, RuleNode(and, [
            RuleNode(a), 
            RuleNode(a)
        ]))
        push!(bad, RuleNode(and, [
            RuleNode(and, [
                RuleNode(a), 
                RuleNode(b)
            ])
            RuleNode(b)
        ]))
        push!(bad, RuleNode(and, [
            RuleNode(b), 
            RuleNode(and, [
                RuleNode(a), 
                RuleNode(b)
            ])
        ]))
        push!(bad, RuleNode(and, [
            RuleNode(and, [
                RuleNode(a), 
                RuleNode(b)
            ]),
            RuleNode(b)
        ]))

        check_constraints(
            annotated.grammar,
            good,
            bad
        )
    end

    @testset "associativity+commutative+idempotent" begin
        annotated_grammar = quote        
            smallvars:: Boolean = x | y |z
            and::  Boolean = Boolean && Boolean    := (associative, commutative, idempotent)
            bigvars:: Boolean = a | b | c
        end
        annotated = HerbConstraints.expr2csgrammar_annotated(annotated_grammar)

        and = only((HerbConstraints.get_bylabel(annotated)["and"]))
        x,y,z = (HerbConstraints.get_bylabel(annotated)["smallvars"])
        a,b,c = (HerbConstraints.get_bylabel(annotated)["bigvars"])

        good = Vector{RuleNode}()
        bad = Vector{RuleNode}()

        push!(good, RuleNode(and, [
            RuleNode(and, [
                RuleNode(a), 
                RuleNode(b)
            ]),
            RuleNode(c)
        ]))
        push!(good, RuleNode(and, [
                RuleNode(a), 
                RuleNode(b)
            ]))

        #associative
        push!(bad, RuleNode(and, [
            RuleNode(and, [
                RuleNode(b), 
                RuleNode(c)
            ]),
            RuleNode(a)
        ]))

        #associative+commutative
        push!(bad, RuleNode(and, [
            RuleNode(and, [
                RuleNode(a), 
                RuleNode(b)
            ]),
            RuleNode(a)
        ]))
        
        # idempotent
        push!(bad, RuleNode(and, [
            RuleNode(x), 
            RuleNode(x)
        ]))
        push!(bad, RuleNode(and, [
            RuleNode(x), 
            RuleNode(and, [
                RuleNode(x), 
                RuleNode(y)
            ])
        ]))
        push!(bad, RuleNode(and, [
            RuleNode(y), 
            RuleNode(and, [
                RuleNode(x), 
                RuleNode(y)
            ])
        ]))
        push!(bad, RuleNode(and, [
            RuleNode(and, [
                RuleNode(a), 
                RuleNode(b)
            ]),
            RuleNode(b)
        ]))

        check_constraints(
            annotated.grammar,
            good,
            bad,
            # parallel plus will entail infinite depth - so we want the constraint but can't test it
            forgive_missing_constraints=true
        )
    end

    @testset "annihilator" begin
        annotated_grammar = quote        
            zero::      Number = 0
            var::       Number = x 
            times::     Number = Number * Number    := (annihilator("zero"))
        end
        annotated = HerbConstraints.expr2csgrammar_annotated(annotated_grammar)
        zero = only((HerbConstraints.get_bylabel(annotated)["zero"]))
        x = only((HerbConstraints.get_bylabel(annotated)["var"]))
        times = only((HerbConstraints.get_bylabel(annotated)["times"]))
        
        
        good = Vector{RuleNode}()
        bad = Vector{RuleNode}()

        # times annihilator("zero")
        push!(good, RuleNode(zero))
        push!(bad, RuleNode(times, [
            RuleNode(x), 
            RuleNode(zero)
        ]))
        push!(bad, RuleNode(times, [
            RuleNode(zero), 
            RuleNode(x)
        ]))

        check_constraints(
            annotated.grammar,
            good,
            bad
        )
    end

    @testset "idempotent" begin
        annotated_grammar = quote        
            var::       Bool = x 
            and::      Bool = Bool && Bool    := (idempotent)
        end
        annotated = HerbConstraints.expr2csgrammar_annotated(annotated_grammar)
        x = only((HerbConstraints.get_bylabel(annotated)["var"]))
        and = only((HerbConstraints.get_bylabel(annotated)["and"]))
        
        
        good = Vector{RuleNode}()
        bad = Vector{RuleNode}()

        # and idempotent
        push!(good, RuleNode(x))
        push!(bad, RuleNode(and, [
            RuleNode(x), 
            RuleNode(x)
        ]))

        check_constraints(
            annotated.grammar,
            good,
            bad
        )
    end

    @testset "absorptive_over" begin
        annotated_grammar = quote        
            var::       Bool = x | y 
            and::      Bool = Bool && Bool    
            or::     Bool = Bool || Bool    := (absorptive_over("and"))
        end
        annotated = HerbConstraints.expr2csgrammar_annotated(annotated_grammar)
        x,y = (HerbConstraints.get_bylabel(annotated)["var"])
        and = only((HerbConstraints.get_bylabel(annotated)["and"]))
        or = only((HerbConstraints.get_bylabel(annotated)["or"]))
        
        
        good = Vector{RuleNode}()
        bad = Vector{RuleNode}()

        # or absorptive_over("and")
        push!(good, RuleNode(x))

        and_xy = RuleNode(and, [
            RuleNode(x), 
            RuleNode(y)
        ])
        and_yx = RuleNode(and, [
            RuleNode(y), 
            RuleNode(x)
        ])

        push!(bad, RuleNode(or, [and_xy, RuleNode(x)]))
        push!(bad, RuleNode(or, [and_yx, RuleNode(x)]))
        push!(bad, RuleNode(or, [RuleNode(x), and_xy]))
        push!(bad, RuleNode(or, [RuleNode(x), and_yx]))

        check_constraints(
            annotated.grammar,
            good,
            bad
        )
    end
end