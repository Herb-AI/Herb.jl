import HerbInterpret: make_interpreter
using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

# Small module for testing state-less make_interpret
module LocalStringDSL
    using HerbCore
    using RuntimeGeneratedFunctions
    RuntimeGeneratedFunctions.init(LocalStringDSL)
    concat_cvc(a::String, b::String) = a * b
end

# Simplest stateful grammar
module LocalStateDSL
    using HerbCore
    using RuntimeGeneratedFunctions
    RuntimeGeneratedFunctions.init(LocalStateDSL)
 
    struct St
        x::Int
    end

    inc(st::St) = St(st.x + 1)
    iseven(st::St) = Base.iseven(st.x)
end

# Stateful grammar with if-then-else
module LocalStateDSL2
    using HerbCore
    using HerbGrammar
    using RuntimeGeneratedFunctions
    RuntimeGeneratedFunctions.init(LocalStateDSL2)
 
    struct St
        x::Int
    end

    inc(st::St) = St(st.x + 1)
    dec(st::St) = St(st.x - 1)
    iseven(st::St) = Base.iseven(st.x)

    g2 = @cfgrammar begin
        Start = Step
        Step  = IF(Cond, Step, Step)
        Step  = inc()
        Step  = dec()
        Cond  = iseven()
    end
end

# Stateful grammar with WHILE 
module LocalStateDSL3
    using HerbCore
    using HerbGrammar
    using RuntimeGeneratedFunctions
    RuntimeGeneratedFunctions.init(LocalStateDSL3)
 
    struct St
        x::Int
    end

    inc(st::St) = St(st.x + 1)
    lt3(st::St) = st.x < 3

    g3 = @cfgrammar begin
        Start = Step
        Step  = WHILE(Cond, Step)
        Step  = inc()
        Cond  = lt3()
    end
end


@testset verbose=true "Test make_interpreter" begin
    @testset "Test base functionality" begin
        g = @cfgrammar begin
            Number = |(1:2)
            Number = x
            Number = Number + Number
            Number = Number * Number
            Number = Number + 1
            Number = x * 2
        end

        # Compile once
        interpret_custom = HerbInterpret.make_interpreter(g; input_symbols=[:x])

        rn = @rulenode(5{4{3,2},7})  # (x + 2) * (x * 2)
        input = Dict{Symbol,Any}(:x => 1)

        @testset "Single input dict" begin
            # Leaves
            @test interpret_custom(@rulenode(1), input) == 1
            @test interpret_custom(@rulenode(2), input) == 2
            @test interpret_custom(@rulenode(3), input) == 1

            # Pure operators
            @test interpret_custom(@rulenode(4{1,2}), input) == 3   # 1 + 2
            @test interpret_custom(@rulenode(5{1,2}), input) == 2   # 1 * 2

            # Partial rules
            @test interpret_custom(@rulenode(6{3}), input) == 2     # x + 1
            @test interpret_custom(@rulenode(7), input) == 2        # x * 2

            # Composite example
            @test interpret_custom(rn, input) == 6
        end

        @testset "Vector of input dicts" begin
            inputs = [
                Dict{Symbol,Any}(:x => 1),
                Dict{Symbol,Any}(:x => 3),
            ]
            outs = interpret_custom(rn, inputs)
            @test outs == [6, 30]  # x=1 => 6, x=3 => 30
        end

        @testset "Single IOExample" begin
            ex = HerbSpecification.IOExample(Dict{Symbol,Any}(:x => 1), nothing)
            @test interpret_custom(rn, ex) == 6
        end

        @testset "Vector of IOExamples" begin
            exs = [
                HerbSpecification.IOExample(Dict{Symbol,Any}(:x => 1), nothing),
                HerbSpecification.IOExample(Dict{Symbol,Any}(:x => 3), nothing),
            ]
            outs = interpret_custom(rn, exs)
            @test outs == [6, 30]
        end
    end

    @testset "Interpreter uses correct operators from target module" begin
        # Conflicting operator in caller module: must NOT be used
        concat_cvc(a::String, b::String) = a * "|" * b

        g = @cfgrammar begin
            Str = s
            Str = "A"
            Str = concat_cvc(Str, Str)
        end

        rn = @rulenode(3{1,2})
        input = Dict{Symbol,Any}(:s => "X")

        # Compile once, but resolve operators in LocalStringDSL
        interpret_string = HerbInterpret.make_interpreter(
            g;
            input_symbols=[:s],
            target_module=LocalStringDSL,
        )

        # Dict form
        @test interpret_string(rn, input) == "XA"

        # IOExample form (optional extra check)
        ex = HerbSpecification.IOExample(Dict{Symbol,Any}(:s => "X"), nothing)
        @test interpret_string(rn, ex) == "XA"

        # Prove caller's concat differs (and is not used)
        @test concat_cvc("X", "A") == "X|A"
    end

    @testset "Stateful interpreter generation" begin
        @testset "Test basic usage in external module" begin
            # Rule indices:
            # 1 Start    = Sequence
            # 2 Sequence = Step
            # 3 Sequence = (Step; Sequence)
            # 4 Step     = inc()
            # 5 Step     = IF(Cond, Step, Step)
            # 6 Cond     = iseven()
            g = @cfgrammar begin
                Start    = Sequence
                Sequence = Step
                Sequence = (Step; Sequence)
                Step     = inc()
                Step     = IF(Cond, Step, Step)
                Cond     = iseven()
            end

            # Build the interpreter object (RGF-backed)
            interp = HerbInterpret.make_stateful_interpreter(
                g;
                target_module = LocalStateDSL,
                cache_module  = @__MODULE__,
            )

            # Program: (inc(); inc()) starting from x=0 => x=2
            # Start=Sequence -> Sequence=(Step;Sequence) -> Step=inc(); Sequence=Step -> Step=inc()
            prog_two_incs = @rulenode(1{3{4,2{4}}})

            st0 = LocalStateDSL.St(0)
            out = interp(prog_two_incs, st0)
            @test out == LocalStateDSL.St(2)

            # Vector-of-states overload
            outs = interp(prog_two_incs, [LocalStateDSL.St(0), LocalStateDSL.St(10)])
            @test outs == [LocalStateDSL.St(2), LocalStateDSL.St(12)]
        end

        @testset "IF semantics in external target module" begin
            # Build interpreter from grammar that lives in LocalStateDSL2
            interp2 = HerbInterpret.make_stateful_interpreter(
                LocalStateDSL2.g2;
                target_module = LocalStateDSL2,
                cache_module  = @__MODULE__,
            )

            # Rule indices in LocalStateDSL2.g2:
            # 1 Start=Step
            # 2 Step=IF(Cond,Step,Step)
            # 3 Step=inc()
            # 4 Step=dec()
            # 5 Cond=iseven()

            # IF(iseven(), inc(), dec())
            prog_if = @rulenode(2{5,3,4})

            @test interp2(prog_if, LocalStateDSL2.St(2)) == LocalStateDSL2.St(3)  # even -> inc
            @test interp2(prog_if, LocalStateDSL2.St(3)) == LocalStateDSL2.St(2)  # odd  -> dec

            # IOExample support (state is in :_arg_1)
            exs = [
                HerbSpecification.IOExample(Dict{Symbol,Any}(:_arg_1 => LocalStateDSL2.St(2)), nothing),
                HerbSpecification.IOExample(Dict{Symbol,Any}(:_arg_1 => LocalStateDSL2.St(3)), nothing),
            ]

            outs_ex = interp2(prog_if, exs)
            @test outs_ex == [LocalStateDSL2.St(3), LocalStateDSL2.St(2)]
        end

        @testset "WHILE operator (bounded loop) " begin
            # Grammar lives in LocalStateDSL3.g3:
            # 1 Start=Step
            # 2 Step=WHILE(Cond, Step)
            # 3 Step=inc()
            # 4 Cond=lt3()

            interp3 = HerbInterpret.make_stateful_interpreter(
                LocalStateDSL3.g3;
                target_module = LocalStateDSL3,
                cache_module  = @__MODULE__,
            )

            # WHILE(lt3(), inc())
            prog_while = @rulenode(2{4,3})

            @test interp3(prog_while, LocalStateDSL3.St(0)) == LocalStateDSL3.St(3)
            @test interp3(prog_while, LocalStateDSL3.St(2)) == LocalStateDSL3.St(3)

            # Vector-of-states
            outs = interp3(prog_while, [LocalStateDSL3.St(0), LocalStateDSL3.St(1), LocalStateDSL3.St(3)])
            @test outs == [LocalStateDSL3.St(3), LocalStateDSL3.St(3), LocalStateDSL3.St(3)]
        end
    end
end