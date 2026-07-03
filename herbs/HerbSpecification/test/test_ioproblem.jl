# Tests for IOExample
@testset "IOExample Tests" begin
    input_dict = Dict(:var1 => 42, :var2 => "value")
    output_value = "test output"
    io_example = IOExample(input_dict, output_value)

    @test io_example.in == input_dict
    @test io_example.out == output_value
    @testset "Test Equality" begin
        e₁ = IOExample(Dict(:x => 1), 1)
        e₂ = IOExample(Dict(:x => 1), 1)
        @test e₁ == e₂
    end
end

@testset "Trace Tests" begin
    t₁ = Trace([:x => 1, :x => 2, :x => 3])
    t₂ = Trace([:x => 1, :x => 2, :x => 3])
    @test t₁ == t₂
end

@testset "SMTSpecification Tests" begin
    example_formula = identity
    smt₁ = SMTSpecification(example_formula)
    smt₂ = SMTSpecification(example_formula)
    @test smt₁ == smt₂
end

@testset "AgdaSpecification Tests" begin
    example_formula = identity
    agda₁ = AgdaSpecification(example_formula)
    agda₂ = AgdaSpecification(example_formula)
    @test agda₁ == agda₂
end

@testset "Problem Tests" begin
    # Example specs to use in the below tests.
    specs = [
        [
            IOExample(Dict(:var1 => 1, :var2 => 2), 3),
            IOExample(Dict(:var1 => 4, :var2 => 5), 6),
            IOExample(Dict(:var1 => 7, :var2 => 8), 9),
        ],
        AgdaSpecification(x -> 23),
        SMTSpecification(x -> 23),
        [Trace(["some", "exec", "path"]), Trace(["another", "path"])],
    ]

    @testset "$(typeof(spec))" for spec in specs
        # Test constructor without a name
        problem1 = Problem(spec)
        @test problem1.name == ""
        @test problem1.spec === spec

        if spec isa Vector{<:IOExample}
            # Test getindex
            subproblem = problem1[1:2]
            @test isa(subproblem, Problem)
            @test subproblem.spec == spec[1:2]
            @test subproblem.name == ""
        end

        # Test constructor with a name
        problem_name = "Test Problem"
        problem2 = Problem(problem_name, spec)
        @test problem2.name == problem_name
        @test problem2.spec === spec

        if spec isa Vector{<:IOExample}
            # Test getindex
            subproblem = problem2[1:2]
            @test isa(subproblem, Problem)
            @test subproblem.spec == spec[1:2]
            @test subproblem.name == problem_name
        end
    end

    @testset "Test Equality" begin
        p₁ = Problem([IOExample(Dict(:x => 1), 1)])
        p₂ = Problem([IOExample(Dict(:x => 1), 1)])
        @test p₁ == p₂
    end
end

# Tests for MetricProblem
@testset "MetricProblem Tests" begin
    # Create a vector of IOExample instances as specification
    spec = [
        IOExample(Dict(:var1 => 1, :var2 => 2), 3),
        IOExample(Dict(:var1 => 4, :var2 => 5), 6),
        IOExample(Dict(:var1 => 7, :var2 => 8), 9),
    ]
    cost_function(x) = 23

    # Test constructor without a name
    metric1 = MetricProblem(cost_function, spec)
    @test metric1.name == ""
    @test metric1.spec === spec
    @test metric1.cost_function === cost_function

    # Test constructor with a name
    name = "Test Metric"
    metric2 = MetricProblem(name, cost_function, spec)
    @test metric2.name == name
    @test metric2.spec === spec
    @test metric2.cost_function === cost_function

    # Test getindex without name
    submetric1 = metric1[1:2]
    @test isa(submetric1, MetricProblem)
    @test submetric1.spec == spec[1:2]
    @test submetric1.name == ""
    @test submetric1.cost_function === cost_function

    # Test getindex with name
    submetric2 = metric2[2:3]
    @test isa(submetric2, MetricProblem)
    @test submetric2.spec == spec[2:3]
    @test submetric2.name == name
    @test submetric2.cost_function === cost_function

    @testset "Test Equality" begin
        cost_function = () -> 1
        mp₁ = MetricProblem(cost_function , [IOExample(Dict(:x => 1), 1)])
        mp₂ = MetricProblem(cost_function , [IOExample(Dict(:x => 1), 1)])
        @test mp₁ == mp₂
    end
end
