function create_dummy_grammar()
    g = @cfgrammar begin
       Number = |(1:2)
       Number = x
       Number = Number + Number
       Number = Number * Number
    end
    return g
end

function create_dummy_rulenode()
    return @rulenode 4{3,1}
end


@testset verbose=true "Execute on input" begin
    @testset verbose=true "With SymbolTable and Expr" begin
        @testset "(tab, expr, dict)" begin
            @testset "Simple execute_on_input (x + 2)" begin
                tab = Dict{Symbol,Any}(:+ => +)
                input_dict = Dict(:x => 3)
                @test execute_on_input(tab, :(x + 2), input_dict) == 5
            end

            @testset "Simple execute_on_input (x * x + 2)" begin
                tab = Dict{Symbol,Any}(:+ => +, :* => *)
                input = 3
                f(x) = x * x + 2
                input_dict = Dict(:x => input,:f => f)
                @test execute_on_input(tab, :(f(x)), input_dict) == f(input)
            end
        end

        @testset "(tab, expr, Vector{Dict})" begin
            @testset "Execute_on_input with multiple inputs" begin
                tab = Dict{Symbol,Any}(:+ => +, :* => *)
                expr = :(x * 2 + y)
                inputs = [
                    Dict(:x => 1, :y => 2),
                    Dict(:x => 2, :y => 3),
                    Dict(:x => 3, :y => 4)
                ]
                expected_outputs = [4, 7, 10]
                @test execute_on_input(tab, expr, inputs) == expected_outputs
            end
        end
    end

    @testset "With grammar and RuleNode" begin
        grammar = create_dummy_grammar() # integer arithmetic
        program = create_dummy_rulenode() # :(1+x)

        @testset "(grammar, rulenode, Dict)" begin
            input_dict = Dict(:x => 5, :y => 3)
            @test execute_on_input(grammar, program, input_dict) == 6
        end

        @testset "(grammar, rulenode, Vector{Dict})" begin
            inputs = [
                Dict(:x => 2, :y => 3),
                Dict(:x => 4, :y => 1)
            ]
            expected_outputs = [3, 5]
            @test execute_on_input(grammar, program, inputs) == expected_outputs
        end
    end

    @testset "Error handling" begin
        @testset "Invalid expression" begin
            tab = Dict{Symbol,Any}(:+ => +)
            input_dict = Dict(:x => "a")
            @test_throws Exception execute_on_input(tab, :(x + 2), input_dict)
        end
    end
end


