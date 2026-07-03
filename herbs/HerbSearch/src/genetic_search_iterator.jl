using Random

struct AlgorithmStateIsInvalid <: Exception
    message::String
end

Base.showerror(io::IO, e::AlgorithmStateIsInvalid) = print(io, e.message)

Base.@doc """
    GeneticSearchIterator{FitnessFunction,CrossOverFunction,MutationFunction,SelectParentsFunction,EvaluationFunction} <: ProgramIterator

Defines an [`ProgramIterator`](@ref) using genetic search. 

Consists of:
- `examples::Vector{<:IOExample}`: a collection of examples defining the specification 
- `evaluation_function::EvaluationFunction`: interpreter to evaluate the individual programs

- `population_size::Int64`: number of inviduals in the population
- `mutation_probability::Float64`: probability of mutation for each individual
- `maximum_initial_population_depth::Int64`: maximum depth of trees when population is initialized 

end
""" GeneticSearchIterator
@programiterator GeneticSearchIterator(
    spec::Vector{<:IOExample},
    evaluation_function::Function=execute_on_input, 
     
    population_size::Int64=10, 
    mutation_probability::Float64=0.1, 
    maximum_initial_population_depth::Int64=3
   )

"""
    fitness(::GeneticSearchIterator, program, results)

Assigns a numerical value (fitness score) to each individual based on how closely it meets the desired objective.
"""
fitness(::GeneticSearchIterator, program::RuleNode, results::AbstractVector{<:Tuple{Any, Any}}) = default_fitness(program, results)

"""
    cross_over(::GeneticSearchIterator, parent_1::RuleNode, parent_2::RuleNode)

Combines the program from two parent individuals to create one or more offspring individuals.
"""
cross_over(::GeneticSearchIterator, parent_1::RuleNode, parent_2::RuleNode) = crossover_swap_children_2(parent_1, parent_2)


"""
    mutate!(::GeneticSearchIterator, program::RuleNode, grammar::AbstractGrammar, max_depth::Int = 2)

Mutates the program of an invididual.
"""
mutate!(::GeneticSearchIterator, program::RuleNode, grammar::AbstractGrammar, max_depth::Int = 2) = mutate_random!(program, grammar, max_depth)

"""
    select_parents(::GeneticSearchIterator, population::Array{RuleNode}, fitness_array::Array{<:Real})

Selects two parents for the crossover.
"""
select_parents(::GeneticSearchIterator, population::Array{RuleNode}, fitness_array::Array{<:Real}) = select_fitness_proportional_parents(population, fitness_array)

struct GeneticIteratorState
    population::Array{RuleNode}
end

Base.IteratorSize(::GeneticSearchIterator) = Base.SizeUnknown()
Base.eltype(::GeneticSearchIterator) = RuleNode


"""
    validate_iterator(iter)

Validates the parameters of the iterator
"""
function validate_iterator(iter)
    if iter.population_size <= 0 
        throw(AlgorithmStateIsInvalid("The iterator population size: '$(iter.population_size)' should be > 0"))
    end

    if !hasmethod(fitness, Tuple{typeof(iter), RuleNode, AbstractVector{<:Tuple{Any,Any}}})

        throw(AlgorithmStateIsInvalid("The iterator fitness function should have two parameters: the program and an Vector with pair of tuples [(expected, value)]"))
    end

    # Check for cross_over method
    if !hasmethod(cross_over, Tuple{typeof(iter), RuleNode, RuleNode})
        throw(AlgorithmStateIsInvalid(
            """The iterator crossover function should get two parameters:
                - parent1 :: RuleNode -> parent1 program
                - parent2 :: RuleNode -> parent2 program
                and return a list of children.
            """
        ))
    end

    # Check for select_parents method
    if !hasmethod(select_parents, Tuple{typeof(iter), Array{RuleNode}, Array{<:Real}})
        throw(AlgorithmStateIsInvalid(
            """The iterator select_parent function should get two paramaters:
                 - population: Array{RuleNode} -> array of programs
                 - fitness array:  Array{<:Number} -> array of fitness value for the population
                and return two rulenodes as the new parents.
            """))
    end
    return true
end

"""
    get_best_program(population::Array{RuleNode}, iter::GeneticSearchIterator)::RuleNode

Returns the best program within the population with respect to the fitness function.
"""
function get_best_program(population::Array{RuleNode}, iter::GeneticSearchIterator)::RuleNode
    best_program = nothing
    best_fitness = 0
    grammar = get_grammar(iter)
    for index ∈ eachindex(population)
        chromosome = population[index]
        zipped_outputs = zip([example.out for example in iter.spec], execute_on_input(grammar, chromosome, [example.in for example in iter.spec]))
        fitness_value = fitness(iter, chromosome, collect(zipped_outputs))
        if isnothing(best_program) 
            best_fitness = fitness_value
            best_program = chromosome
        else 
            if fitness_value > best_fitness
                best_fitness = fitness_value
                best_program = chromosome
            end
        end
    end 
    return best_program
end

"""
    Base.iterate(iter::GeneticSearchIterator)

Iterates the search space using a genetic algorithm. First generates a population sampling random programs. Returns the best program-so-far, and the state of the iterator.
"""
function Base.iterate(iter::GeneticSearchIterator)
    validate_iterator(iter)
    grammar = get_grammar(iter)
    
    population = Vector{RuleNode}(undef,iter.population_size)

    start_symbol = get_starting_symbol(get_solver(iter))
    for i in 1:iter.population_size
        # sample a random nodes using start symbol and grammar
        population[i] = rand(RuleNode, grammar, start_symbol, iter.maximum_initial_population_depth)
    end 
    best_program = get_best_program(population, iter)
    return (best_program, GeneticIteratorState(population))
end


"""
    Base.iterate(iter::GeneticSearchIterator, current_state::GeneticIteratorState)

Iterates the search space using a genetic algorithm. Takes the iterator and the current state to mutate and crossover random inviduals. Returns the best program-so-far and the state of the iterator.
"""
function Base.iterate(iter::GeneticSearchIterator, current_state::GeneticIteratorState)

    current_population = current_state.population

    # Calculate fitness
    zipped_outputs(chromosome) = zip([example.out for example in iter.spec], execute_on_input(get_grammar(iter), chromosome, [example.in for example in iter.spec]))
    fitness_array = [fitness(iter, chromosome, collect(zipped_outputs(chromosome))) for chromosome in current_population]
    
    new_population = Vector{RuleNode}(undef,iter.population_size)

    # put the best program in the first slot of the population
    best_program = get_best_program(current_population, iter)
    new_population[begin] = best_program
    
    # do crossover
    index = 2
    while index <= iter.population_size
        parent1, parent2 = select_parents(iter, current_population, fitness_array)
        children = cross_over(iter, parent1, parent2)
        for child ∈ children
            if index > iter.population_size
                break
            end
            new_population[index] = child
            index += 1
        end
    end

    # Do mutation 
    for chromosome in new_population
        random_number = rand()
        if random_number < iter.mutation_probability
            mutate!(iter, chromosome, get_grammar(iter))
        end
    end

    # return the program that has the highest fitness
    return (new_population[begin], GeneticIteratorState(new_population))
end
