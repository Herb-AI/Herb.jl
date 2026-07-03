@testset verbose = true "Interpret Function Tests" begin
    @testset "Basic Interpretations on Arithmetic Operators" begin
        tab = Dict{Symbol,Any}(:x => 5, :y => 3, :+ => +, :* => *)
        @testset "Interpreting a single variable" begin
            @test interpret(tab, :x) == 5
            @test interpret(tab, :y) == 3
        end

        @testset "Interpreting a basic expression (x + y)" begin
            @test interpret(tab, :(x + y)) == 8
        end
        @testset "Interpreting a basic expression (x * y)" begin
            @test interpret(tab, :(x * y)) == 15
        end

    end

    @testset "Advanced Interpretations" begin
        tab = Dict{Symbol,Any}(
            :x => 2, :y => 4, :+ => +, :- => -, :* => *, :/ => /
)
        @testset "Interpreting compound expression (x * y) + y" begin
            @test interpret(tab, :(x * y + y)) == 12    
        end
        @testset "Interpreting compound expression x / y + (y * x)" begin
            @test interpret(tab, :(( x / y ) + y * x)) == 8.5  
        end
    end

    @testset "Boolean and Logical Operations" begin
        tab = Dict{Symbol,Any}(:x => true, :y => false, :and => (x, y) -> x && y, :or => (x, y) -> x || y)

        @testset "Interpreting logical expression x && y" begin
            @test interpret(tab, :(x && y)) == false
        end
        @testset "Interpreting logical expression x || y" begin
            @test interpret(tab, :(x || y)) == true
        end
    end

    @testset "Error Handling" begin
        tab = Dict{Symbol,Any}(:x => "hello", :+ => +)

        @testset "Interpreting invalid expressions" begin
            @test_throws Exception interpret(tab, :(x + 2)) 
        end
    end
end
