using Random

 """
     abstract type StochasticSearchIterator <: ProgramIterator

A unified abstract type for the stochastic search algorithms Metropolis Hastings, Very Large Scale Neighbourhood and Simulated Annealing. 
Iterators are customisable by overloading the followign functions:
 - `neighbourhood`
 - `propose`
 - `temperature`
 - `accept`. 
 ----
 # Fields
 -   `examples::Vector{IOExample}` example used to check the program
 -   `cost_function::Function`. Returns the cost of the current program. It receives a list of tuples for (expected, found) and gives back a cost. 
 -   `initial_temperature::Real` = 1 
 -   `evaluation_function`::Function that evaluates the julia expressions
 An iterator over all possible expressions of a grammar up to max_depth with start symbol sym. Also inherits all stop criteria like `max_depth` from `ProgramIterator`.
 """
abstract type StochasticSearchIterator <: ProgramIterator end

"""
    neighbourhood(iter::StochasticSearchIterator, current_program::RuleNode) 

Returns a node location from the neighbourhood of the current program. 
"""
neighbourhood(iter::StochasticSearchIterator, current_program::RuleNode) = constructNeighbourhood(current_program, get_grammar(iter))


"""
    propose(iter::StochasticSearchIterator, path::Vector{Int}, dict::Union{Nothing,Dict{String,Any}})

Proposes a list of programs to fill in the location provided by `path` and the `dict`.
"""
propose(iter::StochasticSearchIterator, path::Vector{Int}, dict::Union{Nothing,Dict{String,Any}}) = random_fill_propose(get_solver(iter), path, dict)

"""
    temperature(::StochasticSearchIterator, current_temperature::Real)

Returns the new temperature based on the current temperature. A higher temperature means that the algorithm will explore more.
"""
temperature(::StochasticSearchIterator, current_temperature::Real) = const_temperature(current_temperature)

"""
    accept(::StochasticSearchIterator, current_cost::Real, next_cost::Real, temperature::Real)

Based on the current program and possible cost and temperature a program is accepted or not. Usually we would always want to accept
better programs but we might get stuck if we do so. That is why some implementations of the `accept` function accept with a probability 
costs that are worse. 
`cost` means how different are the outcomes of the program compared to the correct outcomes.
The lower the `cost` the better the program performs on the examples. The `cost` is provided by the `cost_function`
"""
accept(::StochasticSearchIterator, current_cost::Real, next_cost::Real, temperature::Real) = probabilistic_accept(current_cost, next_cost, temperature)

struct IteratorState
    current_program::RuleNode
    current_temperature::Real
    dmap::AbstractVector{Int} # depth map of each rule
end

Base.IteratorSize(::StochasticSearchIterator) = Base.SizeUnknown()
Base.eltype(::StochasticSearchIterator) = RuleNode

function Base.iterate(iter::StochasticSearchIterator)
    solver = get_solver(iter)
    grammar, max_depth = get_grammar(solver), get_max_depth(solver)

    # sample a random node using start symbol and grammar
    dmap = mindepth_map(grammar)
    start_symbol = get_starting_symbol(solver)
    sampled_program = rand(RuleNode, grammar, start_symbol , max_depth) #TODO: replace iter.sym with a domain of valid rules
    substitute!(solver, Vector{Int}(), sampled_program)
    while !isfeasible(solver)
        #TODO: prevent infinite loops here. Check max_time and/or max_enumerations.
        sampled_program = rand(RuleNode, grammar, start_symbol, max_depth) #TODO: replace iter.sym with a domain of valid rules
        substitute!(solver, Vector{Int}(), sampled_program)
    end

    return (sampled_program, IteratorState(sampled_program, iter.initial_temperature,dmap))  
end


"""
    Base.iterate(iter::StochasticSearchIterator, current_state::IteratorState)

The algorithm that constructs the iterator of StochasticSearchIterator. It has the following structure:

1. get a random node location -> location,dict = neighbourhood(current_program)
2. call propose on the current program getting a list of full programs
3. iterate through all the proposals and check if the proposed program is "better" than the previous one
4. "accept" the new program by calling the `accept`
5. return the new next_program
"""
function Base.iterate(iter::StochasticSearchIterator, iterator_state::IteratorState)
    grammar, solver = get_grammar(iter), get_solver(iter)
    current_program = get_tree(solver)#iterator_state.current_program
    
    current_cost = calculate_cost(iter, current_program)

    new_temperature = temperature(iter, iterator_state.current_temperature)

    # get the neighbour node location 
    neighbourhood_node_location, dict = neighbourhood(iter, current_program)

    # get the subprogram pointed by node-location
    subprogram = get(current_program, neighbourhood_node_location)


    @info "Start: $(rulenode2expr(current_program, grammar)), subexpr: $(rulenode2expr(subprogram, grammar)), cost: $current_cost
            temp $new_temperature"

    # remove the rule node by substituting it with a hole of the same symbol
    original_node = get(current_program, neighbourhood_node_location)
    path = get_path(current_program, original_node)
    original_state = save_state!(solver)

    remove_node!(solver, path)
    
    # propose new programs to consider. They are programs to put in the place of the nodelocation
    # propose should give full programs
    possible_programs = propose(iter, path, dict)
    
    # try to improve the program using any of the possible replacements
    improved_program = try_improve_program!(iter, possible_programs, neighbourhood_node_location, new_temperature, current_cost)
    
    if isnothing(improved_program)
        load_state!(solver, original_state)
    else 
        new_state!(solver, improved_program)
    end

    @assert isfeasible(solver)
    @assert !contains_hole(get_tree(solver))
    
    next_state = IteratorState(get_tree(solver), new_temperature,iterator_state.dmap)
    return (get_tree(solver), next_state)
end


function try_improve_program!(iter::StochasticSearchIterator, possible_programs, neighbourhood_node_location::NodeLoc, new_temperature, current_cost)
    best_program = nothing
    for possible_program in possible_programs
        program_cost = calculate_cost(iter, possible_program)
        if accept(iter, current_cost, program_cost, new_temperature)
            best_program = freeze_state(possible_program)
            current_cost = program_cost
        end
    end
    return best_program
end

"""
    _calculate_cost(program::RuleNode, cost_function::Function, spec::AbstractVector{IOExample}, grammar::AbstractGrammar, evaluation_function::Function)

Returns the cost of the `program` using the examples and the `cost_function`. It first convert the program to an expression and evaluates it on all the examples.
"""
function _calculate_cost(program::Union{RuleNode, StateHole}, cost_function::Function, spec::AbstractVector{<:IOExample}, grammar::AbstractGrammar, evaluation_function::Function)
    results = Tuple{<:Number,<:Number}[]

    expression = rulenode2expr(program, grammar)
    symbol_table = grammar2symboltable(grammar)

    for example ∈ filter(e -> e isa IOExample, spec)
        outcome = evaluation_function(symbol_table, expression, example.in)
        push!(results, (example.out, outcome))
    end

    return cost_function(results)
end

"""
    calculate_cost(iter::T, program::Union{RuleNode, StateHole}) where T <: StochasticSearchIterator

Wrapper around [`_calculate_cost`](@ref).
"""
calculate_cost(iter::T, program::Union{RuleNode, StateHole}) where T <: StochasticSearchIterator = _calculate_cost(program, iter.cost_function, iter.spec, get_grammar(iter), iter.evaluation_function)


"""
    AbstractMHSearchIterator <: StochasticSearchIterator

This is the supertype for all Metropolis Hastings (MH) search iterators. It inherits all behaviour from [`StochasticSearchIterator`](@ref).
"""
abstract type AbstractMHSearchIterator <: StochasticSearchIterator end

Base.@doc """
    MHSearchIterator(examples::AbstractArray{<:IOExample}, cost_function::Function, evaluation_function::Function=HerbInterpret.execute_on_input)

The `MHSearchIterator` generates programs using the Metropolis-Hastings algorithm. 
The search behaviour has the following characteristics:
- It uses `random_fill_propose` for the `propose` function.
- The `accept function is `probabilistic`. 
- The `temperature` of the algorithm remains constant over time, ensuring a stable acceptance probability.

# Arguments
- `examples::AbstractArray{<:IOExample}`: An array of input-output examples used to guide the search.
- `cost_function::Function`: A function to evaluate the cost of the proposed programs.
- `evaluation_function::Function=HerbInterpret.execute_on_input`: A function that evaluates the generated program generated and produces an output. Defaults to `HerbInterpret.execute_on_input`.

# Returns 
An iterator to generate programs according to the Metropolis Hastings algorithm.
""" MHSearchIterator

@programiterator MHSearchIterator(
    spec::Vector{<:IOExample},
    cost_function::Function,
    initial_temperature::Real = 1,
    evaluation_function::Function = execute_on_input, 
) <: AbstractMHSearchIterator

"""
    AbstractVLSNSearchIterator <: StochasticSearchIterator

This is the supertype for all VLSN search iterators. 
"""
abstract type AbstractVLSNSearchIterator <: StochasticSearchIterator end

propose(iter::AbstractVLSNSearchIterator, path::Vector{Int}, dict::Union{Nothing,Dict{String,Any}}) = enumerate_neighbours_propose(iter.vlsn_neighbourhood_depth)(get_solver(iter), path, dict)
temperature(::AbstractVLSNSearchIterator, current_temperature::Real) = const_temperature(current_temperature)
accept(::AbstractVLSNSearchIterator, current_cost::Real, next_cost::Real, temperature::Real) = best_accept(current_cost, next_cost, temperature)

Base.@doc """
    VLSNSearchIterator(spec, cost_function, enumeration_depth = 2, evaluation_function::Function=HerbInterpret.execute_on_input) = StochasticSearchIterator(

Returns an iterator that runs according to the Very Large Scale Neighbourhood Search algorithm.
- `spec` : array of examples
- `cost_function` : cost function to evaluate the proposed programs
- `vlsn_neighbourhood_depth` : the enumeration depth to search for a best program at a time
- `evaluation_function` : evaluation function that evaluates the program generated and produces an output
The propose function consists of all possible programs of the given `enumeration_depth`. The accept function accepts the program
with the lowest cost according to the `cost_function`.
The temperature value of the algorithm remains constant over time.
""" VLSNSearchIterator
@programiterator VLSNSearchIterator(
    spec::Vector{<:IOExample},
    cost_function::Function,
    vlsn_neighbourhood_depth::Int = 2,
    initial_temperature::Real = 1,
    evaluation_function::Function = execute_on_input
) <: AbstractVLSNSearchIterator

"""
    AbstractSASearchIterator <: StochasticSearchIterator

This is the supertype for all SA search iterators. 
"""
abstract type AbstractSASearchIterator <: StochasticSearchIterator end

propose(iter::AbstractSASearchIterator, path::Vector{Int}, dict::Union{Nothing,Dict{String,Any}}) = random_fill_propose(get_solver(iter), path, dict)

temperature(iter::AbstractSASearchIterator, current_temperature::Real) = decreasing_temperature(iter.temperature_decreasing_factor)(current_temperature)

accept(::AbstractSASearchIterator, current_cost::Real, next_cost::Real, temperature::Real) = probabilistic_accept_with_temperature(current_cost, next_cost, temperature)

Base.@doc """
    SASearchIterator(spec, cost_function, initial_temperature=1, temperature_decreasing_factor = 0.99, evaluation_function::Function=HerbInterpret.execute_on_input)

Returns an enumerator that runs according to the Simulated Annealing Search algorithm.
- `spec` : array of examples
- `cost_function` : cost function to evaluate the programs proposed
- `initial_temperature` : the starting temperature of the algorithm
- `temperature_decreasing_factor` : the decreasing factor of the temperature of the time
- `evaluation_function` : evaluation function that evaluates the program generated and produces an output
The propose function is `random_fill_propose` (the same as for Metropolis Hastings). The accept function is probabilistic
but takes into account the tempeerature too.
""" SASearchIterator
@programiterator SASearchIterator(
    spec::Vector{<:IOExample},
    cost_function::Function,
    initial_temperature::Real = 1,
    temperature_decreasing_factor::Real = 0.99,
    evaluation_function::Function = execute_on_input
) <: AbstractSASearchIterator




