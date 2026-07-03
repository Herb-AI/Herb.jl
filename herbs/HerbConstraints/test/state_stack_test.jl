@testitem "StateStack" begin
    @testset "empty" begin
        sm = HerbConstraints.StateManager()
        stack = HerbConstraints.StateStack{Int}(sm)
        @test size(stack) == 0

        sm = HerbConstraints.StateManager()
        stack = HerbConstraints.StateStack{String}(sm)
        @test size(stack) == 0
    end

    @testset "membership" begin
        sm = HerbConstraints.StateManager()
        stack = HerbConstraints.StateStack{Int}(sm)
        push!(stack, 10)
        push!(stack, 20)
        push!(stack, 30)
        @test in(stack, 10)
        @test in(stack, 20)
        @test in(stack, 30)
        @test !in(stack, 40)

        sm = HerbConstraints.StateManager()
        stack = HerbConstraints.StateStack{String}(sm)
        push!(stack, "A")
        push!(stack, "B")
        push!(stack, "C")
        @test in(stack, "A")
        @test in(stack, "B")
        @test in(stack, "C")
        @test !in(stack, "D")
    end

    @testset "from vector" begin
        sm = HerbConstraints.StateManager()
        stack = HerbConstraints.StateStack{Int}(sm, [10, 20, 30])
        values = collect(stack)
        @test values[1] == 10
        @test values[2] == 20
        @test values[3] == 30

        sm = HerbConstraints.StateManager()
        stack = HerbConstraints.StateStack{String}(sm, ["A", "B", "C"])
        values = collect(stack)
        @test values[1] == "A"
        @test values[2] == "B"
        @test values[3] == "C"
    end

    @testset "restore" begin
        sm = HerbConstraints.StateManager()
        stack = HerbConstraints.StateStack{Int}(sm)

        push!(stack, 10);   @test size(stack) == 1
        push!(stack, 20);   @test size(stack) == 2

        save_state!(sm);    @test size(stack) == 2
        push!(stack, 30);   @test size(stack) == 3
        push!(stack, 40);   @test size(stack) == 4

        restore!(sm);       @test size(stack) == 2
        push!(stack, 50);   @test size(stack) == 3 #overwrites "30" with "50"

        values = collect(stack)
        @test values[1] == 10
        @test values[2] == 20
        @test values[3] == 50
    end

    @testset "restore twice" begin
        sm = HerbConstraints.StateManager()
        stack = HerbConstraints.StateStack{Int}(sm)

        push!(stack, 10);   @test size(stack) == 1 #[10]
        push!(stack, 20);   @test size(stack) == 2 #[10, 20]

        save_state!(sm);    @test size(stack) == 2 #[10, 20]
        push!(stack, 30);   @test size(stack) == 3 #[10, 20, 30]
        push!(stack, 40);   @test size(stack) == 4 #[10, 20, 30, 40]

        save_state!(sm);    @test size(stack) == 4 #[10, 20, 30, 40]
        push!(stack, 50);   @test size(stack) == 5 #[10, 20, 30, 40, 50]
        push!(stack, 60);   @test size(stack) == 6 #[10, 20, 30, 40, 50, 60]

        restore!(sm);       @test size(stack) == 4 #[10, 20, 30, 40]
        push!(stack, 70);   @test size(stack) == 5 #[10, 20, 30, 40, 70]

        restore!(sm);       @test size(stack) == 2 #[10, 20]
        push!(stack, 80);   @test size(stack) == 3 #[10, 20, 80]

        values = collect(stack)
        @test values[1] == 10
        @test values[2] == 20
        @test values[3] == 80
    end
end
