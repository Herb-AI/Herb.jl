using Logging
disable_logging(LogLevel(1))

function parametrized_test(argument_list, test_function::Function)
    method = methods(test_function)[begin]
    argument_names = [String(arg) for arg ∈ Base.method_argnames(method)[2:end]]
    function_name_string = String(Symbol(test_function))
    @testset "parameterized test: $function_name_string" verbose = true begin
        for arguments ∈ argument_list
            if length(arguments) != length(argument_names)
                error("""The length of the input arguments needs to match the length of the function params.
                       args given:      $arguments
                       function params: $argument_names""")
            end
            argument_pairs = ["$arg_name = $arg_value" for (arg_name,arg_value) in zip(argument_names, arguments)] 
            joined_names = join(argument_pairs,", ")
            @testset "$function_name_string($joined_names)" begin
                test_function(arguments...) 
            end
        end           
    end
end

function create_problem(f, range=20)
    examples = [IOExample(Dict(:x => x), f(x)) for x ∈ 1:range]
    return Problem(examples), examples
end

"""
    function test_constraints!(grammar::AbstractGrammar, constraints::Vector{AbstractGrammarConstraint}; max_size=typemax(Int), max_depth=typemax(Int), allow_trivial=false)

Tests if propagating the constraints during a top-down iteration yields the correct number of programs.

Does two searches and tests if they have the same amount of programs:
- without the constraints and retrospectively applying the constraints
- propagating the constraints during search

If `allow_trivial = false`, it is tested that:
-  at least 1 program satisfies the constraint
-  at least 1 program violates the constraint
"""
function test_constraints!(grammar::AbstractGrammar, constraints::Vector{<:AbstractGrammarConstraint}; max_size=typemax(Int), max_depth=typemax(Int), allow_trivial=false)
    starting_symbol = grammar.types[1]
    iter = BFSIterator(grammar, starting_symbol, max_size = max_size, max_depth = max_depth)
    alltrees = 0
    validtrees = 0
    for p ∈ iter
        if all(check_tree(constraint, p) for constraint ∈ constraints)
            validtrees += 1
        end
        alltrees += 1
    end

    for constraint ∈ constraints
        addconstraint!(grammar, constraint)
    end
    constraint_iter = BFSIterator(grammar, starting_symbol, max_size = max_size, max_depth = max_depth)
    
    @test length(constraint_iter) == validtrees
    if !allow_trivial
        @test validtrees > 0
        @test validtrees < alltrees
    end
end

"""
    test_constraint!(grammar::AbstractGrammar, constraint::AbstractGrammarConstraint; max_size=typemax(Int), max_depth=typemax(Int))

Tests if propagating the constraint during a top-down iteration yields the correct number of programs.

Does two searches and tests if they have the same amount of programs:
- without the constraint and retrospectively applying the constraint
- propagating the constraint during search

If `allow_trivial = false`, it is tested that:
-  at least 1 program satisfies the constraint
-  at least 1 program violates the constraint
"""
function test_constraint!(grammar::AbstractGrammar, constraint::AbstractGrammarConstraint; max_size=typemax(Int), max_depth=typemax(Int), allow_trivial=false)
    test_constraints!(grammar, [constraint], max_size = max_size, max_depth = max_depth, allow_trivial=allow_trivial)
end
