using Logging
disable_logging(LogLevel(1))


grammar = @csgrammar begin
    X = |(1:5)
    X = X * X
    X = X + X
    X = X - X
    X = x
end

"""
Expression is an expression like x * x + x * x * x - 5 and max_depth is the max depth
"""
macro testmh(expression::String, max_depth=6)
    return :(
        @testset "mh $($expression)" begin
        e = Meta.parse("x -> $($expression)")
        f = eval(e)
        problem, examples = create_problem(f)
        iterator = MHSearchIterator(grammar, :X, examples, mean_squared_error, max_depth=$max_depth)
        solution, flag = synth(problem, iterator, max_time=MAX_RUNNING_TIME)
        @test flag == optimal_program
    end
    )
end

const global MAX_RUNNING_TIME = 10
macro testsa(expression::String,max_depth=6,init_temp = 2)
    return :(
        @testset "sa $($expression)" begin
        e = Meta.parse("x -> $($expression)")
        f = eval(e)
        problem, examples = create_problem(f)
        iterator = SASearchIterator(grammar, :X, examples, mean_squared_error, initial_temperature=$init_temp, max_depth=$max_depth)

        solution, flag = synth(problem, iterator, max_time=MAX_RUNNING_TIME)
        @test flag == optimal_program
    end
    )
end

macro testvlsn(expression::String, max_depth = 6, neighbourhood_depth = 2)
    return :(
        @testset "vl $($expression)" begin
        e = Meta.parse("x -> $($expression)")
        f = eval(e)
        problem, examples = create_problem(f)
        iterator = VLSNSearchIterator(grammar, :X, examples, mean_squared_error, vlsn_neighbourhood_depth=$neighbourhood_depth, max_depth=$max_depth)

        #@TODO overwrite evaluate function within synth to showcase how you may use that

        solution, flag = synth(problem, iterator, max_time=MAX_RUNNING_TIME)
        @test flag == optimal_program
    end
    )
end

@testset verbose = true "Algorithms" begin
    @testset verbose = true "MH" begin
        @testmh "x * x + 4" 3
        @testmh "x * (x + 5)" 4


        @testset verbose = true "factorization" begin
            @testmh  "5 * 5 * 5"         3  # 125 = 5 * 5 * 5 (depth 3)
            # @testmh  "5 * 5 * 5 * 5"     3  # 625 = 5 * 5 * 5 * 5 (depth 3)
            @testmh  "2 * 3 * 5 * 5"     3  # 150 = 2 * 3 * 5 * 5 (depth 3)
            @testmh  "2 * 2 * 3 * 4 * 5" 4  # 240 = ((2 * 2) * (3 * 4)) * 5 (depth 4)

        end
    end

    @testset verbose = true "Very Large Scale Neighbourhood" begin
        @testvlsn "x"  1
        @testvlsn "2"  1
        @testvlsn "4"  1
        @testvlsn "10" 2

    end

    @testset verbose = true "Simulated Annealing" begin
        @testsa "x * x + 4" 3
        @testsa "x * (x + 5)" 3 2

        @testset verbose = true "factorization" begin
            @testsa  "5 * 5"             2  # 25 = 5 * 5 (depth 2)
            @testsa  "2 * 3 * 4"         3  # (depth 3)
        end
    end
end
