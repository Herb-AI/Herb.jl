import HerbInterpret: make_interpreter

module LocalStringDSL
    concat_cvc(a::String, b::String) = a * b
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

        # Build and define the interpreter once for the next sub-testsets
        ex = HerbInterpret.make_interpreter(g; input_symbols=[:x], name=:interpret_custom)
        Core.eval(@__MODULE__, ex)

        @testset "Test make_interpreter on single input" begin
            input = Dict{Symbol,Any}(:x => 1)

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

            # Composite example: (x + 2) * (x * 2) with x=1 => 6
            rn = @rulenode(5{4{3,2},7})
            @test interpret_custom(rn, input) == 6
        end

        @testset "Test make_interpreter on multiple inputs" begin
            rn = @rulenode(5{4{3,2},7})

            inputs = [
                Dict{Symbol,Any}(:x => 1),
                Dict{Symbol,Any}(:x => 3),
            ]

            outs = interpret_custom(rn, inputs)

            # x=1 => (1+2)*(2)=6
            # x=3 => (3+2)*(6)=30
            @test outs == [6, 30]
        end
    end

    @testset "Test @make_interpreter macro forms" begin
        g = @cfgrammar begin
            Number = |(1:2)
            Number = x
            Number = Number + Number
            Number = Number * Number
            Number = Number + 1
            Number = x * 2
        end

        rn = @rulenode(5{4{3,2},7})               # (x + 2) * (x * 2)
        rn_without_input = @rulenode(5{4{1,2},2}) # (1 + 2) * 2
        input = Dict{Symbol,Any}(:x => 1)

        # We have to run all tests in a separate module to avoid overwriting existing functions and those warnings.
        # We have to use Base.invokelatest to avoid world age issues here,a s the freshly generated binding is too new.
        function run_in_fresh_module(expr_to_eval::Expr, fname::Symbol)
            M = Module(gensym(:InterpTest))

            # Make packages visible inside M
            Core.eval(M, :(using HerbInterpret, HerbCore, HerbGrammar))

            # Bind grammar inside M (so macro can reference `g`)
            Core.eval(M, :(const g = $g))

            # Run the macro call inside M
            Core.eval(M, expr_to_eval)

            # Return module and function name; we'll access/call via invokelatest
            return M, fname
        end

        # @make_interpreter g  -> defines interpret
        M, fname = run_in_fresh_module(:(@make_interpreter g), :interpret)
        @test isdefined(M, :interpret)
        f = getfield(M, :interpret)
        @test Base.invokelatest(f, rn_without_input, Dict{Symbol,Any}()) == 6

        # @make_interpreter g name=:interpret_sui
        M, fname = run_in_fresh_module(:(@make_interpreter g name=:interpret_sui), :interpret_sui)
        @test isdefined(M, :interpret_sui)
        f = getfield(M, :interpret_sui)
        @test Base.invokelatest(f, rn_without_input, Dict{Symbol,Any}()) == 6

        # @make_interpreter g input_symbols=[:x]
        M, fname = run_in_fresh_module(:(@make_interpreter g input_symbols=[:x]), :interpret)
        @test isdefined(M, :interpret)
        f = getfield(M, :interpret)
        @test Base.invokelatest(f, rn, input) == 6

        # @make_interpreter g name=:interpret_sui input_symbols=[:x]
        M, fname = run_in_fresh_module(:(@make_interpreter g name=:interpret_sui input_symbols=[:x]), :interpret_sui)
        @test isdefined(M, :interpret_sui)
        f = getfield(M, :interpret_sui)
        @test Base.invokelatest(f, rn, input) == 6

        # Test the second function definition over multiple inputs
        outs = Base.invokelatest(f, rn, [Dict{Symbol,Any}(:x => 1), Dict{Symbol,Any}(:x => 3)])
        @test outs == [6, 30]
    end

    @testset "Interpreter uses correct operators from target module" begin
        # Conflicting operator in caller module
        concat_cvc(a::String, b::String) = a * "|" * b

        g = @cfgrammar begin
            Str = s
            Str = "A"
            Str = concat_cvc(Str, Str)
        end

        rn = @rulenode(3{1,2})
        input = Dict{Symbol,Any}(:s => "X")

        @make_interpreter g name=:interpret_string input_symbols=[:s] target_module=LocalStringDSL

        @test isdefined(LocalStringDSL, :interpret_string)
        @test !isdefined(@__MODULE__, :interpret_string)

        @test LocalStringDSL.interpret_string(rn, input) == "XA"
        @test concat_cvc("X", "A") == "X|A"
    end
end
