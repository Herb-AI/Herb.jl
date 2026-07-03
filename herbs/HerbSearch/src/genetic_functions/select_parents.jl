"""
    select_fitness_proportional_parents(population::Array{RuleNode}, fitness_array::Array{<:Real})::Tuple{RuleNode,RuleNode}

Selects two parent chromosomes (individuals) from a population based on fitness-proportionate selection. The selected parents can be used for genetic crossover in the next steps of the algorithm.
"""
function select_fitness_proportional_parents(population::Array{RuleNode}, fitness_array::Array{<:Real})::Tuple{RuleNode,RuleNode}
    fitness_array_normalized = fitness_array/sum(fitness_array)
    parent1 = select_chromosome(population, fitness_array_normalized)
    parent2 = select_chromosome(population, fitness_array_normalized)
    return parent1, parent2
end


"""
    select_chromosome(population::Array{RuleNode}, fitness_array::Array{<:Real})::RuleNode

Selects a chromosome (individual) from the population based on a fitness array. The function uses a fitness-proportionate selection strategy, often referred to as "roulette wheel" selection. Assumes `fitness_array` to be normalized already.
"""
function select_chromosome(population::Array{RuleNode}, fitness_array::Array{<:Real})::RuleNode
    random_number = rand()
    current_fitness_sum = 0
    for (fitness_value, chromosome) in zip(fitness_array, population)
        # random number between 0 and 1
        current_fitness_sum += fitness_value
        if random_number < current_fitness_sum
            return chromosome
        end
    end
    return population[end]
end
