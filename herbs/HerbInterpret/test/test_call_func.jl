module TestModule
    export add, mul, greet, no_arg

    add(x, y) = x + y

    mul(x, y, z) = x * y * z

    greet(name, age) = "Hello, $name ! You are $age years old."

    no_arg() = "No arguments!"
end

@testset "Testing call_func" begin
    @testset "No argument function" begin
        @test call_func(TestModule, :no_arg) == "No arguments!"
    end

    @testset "Two-argument function" begin
        @test call_func(TestModule, :add, 2, 3) == 5
    end

    @testset "Three-argument function" begin
        @test call_func(TestModule, :mul, 2, 3, 4) == 24
    end

    @testset "Function with mixed types" begin
        @test call_func(TestModule, :greet, "Alice", 25) == "Hello, Alice ! You are 25 years old."
    end

    @testset "Error cases" begin
        @testset "Not enough arguments" begin 
            @test_throws Exception call_func(TestModule, :add, 2)
        end
        @testset "Too many arguments" begin
            @test_throws Exception call_func(TestModule, :mul, 2, 3)
        end
        @testset "Function does not exist" begin
            @test_throws Exception call_func(TestModule, :nonexistent)
        end
    end
end