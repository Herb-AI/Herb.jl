# Getting started

You can either paste this code into the Julia REPL or run it using the `advanced_search.ipynb` notebook. Alternatively you can copy the code into a file like `get_started.jl`, followed by running `julia get_started.jl`.

To start, we import the necessary packages.

```julia
using HerbGrammar, HerbSpecification, HerbSearch, HerbInterpret
```

We start with the same simple grammar from the main file [get_started.md](../get_started.md).

```julia
g = @cfgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
end
```

We use a simple problem.

```julia
    problem = Problem([IOExample(Dict(:x => x), 2x+1) for x ∈ 1:5])
```

## Parameters

We can use a search strategy, where we can specify different parameters. For example, by setting the `max_depth`, we limit the depth of the search. In the next example, we can see the effect of the depth on the number of allocations considered. 

```julia
solution = @time search(g, problem, :Number, max_depth=3)
>>> 0.003284 seconds (50.08 k allocations: 2.504 MiB)
println(solution)
>>> (x + 1) + x

solution = @time search(g, problem, :Number, max_depth=6)
>>> 0.005696 seconds (115.28 k allocations: 5.910 MiB)
println(solution)
>>> (1 + x) + x
```

Another parameter to use is `max_enumerations`, which limits the number of programs that can be tested at evaluation. We can see the number of enumerations necessary to solve a simple problem in the next example.

```julia
for i in range(1, 50)
    println(i, " enumerations")
    solution = @time search(g, problem, :Number, max_enumerations=i)
    println(solution)
end

>>> ....
>>> 23 enums: nothing
>>>  0.010223 seconds (117.01 k allocations: 5.935 MiB, 44.23% gc time)
>>> 24 enums: (1 + x) + x
>>>  0.005305 seconds (117.01 k allocations: 5.935 MiB)
>>> 25 enums: (1 + x) + x
>>>  0.005381 seconds (117.01 k allocations: 5.935 MiB)
>>> ...
```

We see that only when `i >= 24`, there is a result. After that, increasing `i` does not have any effect on the number of allocations. 

A final parameter we consider here is `allow_evaluation_errors`, which is `false` by default. When this is set to `true`, the program will still run even when an exception is thrown during evaluation. To see the effect of this, we create a new grammar. We can also retrieve the error together with the solution from the search method.

```julia
g = @cfgrammar begin
    Number = 1
    List = []
    Index = List[Number]
end

problem = Problem([IOExample(Dict(), x) for x ∈ 1:5])
solution = search(g, problem, :Index, max_depth=2, allow_evaluation_errors=true)
println(solution)
>>> nothing
```

There is also another search method called `search_best` which returns both the solution and the possible error. The method returns the best program found so far. In this case, we can also see the error:

```julia
solution, error = search_best(g, problem, :Index, max_depth=2, allow_evaluation_errors=true)
println(solution)
>>> nothing
println(error)
>>> 9223372036854775807 # or: typemax(Int)
```

## Search methods

We now show examples of using different search procedures.

### Breadth-First Search

The breadth-first search will first enumerate all possible programs at the same depth before considering programs with a depth of one more. A tree of the grammar is returned with programs ordered in increasing sizes. We can first `collect` the programs that have a `max-depth` of 2 and a `max_size` of infinite (integer maximum value), where the starting symbol is of type `Real`. This function uses a default heuristic 'left-most first', such that the left-most child in the tree is always explored first. 

```julia
g1 = @cfgrammar begin
    Real = 1 | 2
    Real = Real * Real
end
programs = collect(get_bfs_enumerator(g1, 2, typemax(Int), :Real))
```

We can test that this function returns all and only the correct functions. 

```julia
answer_programs = [
    RuleNode(1),
    RuleNode(2),
    RuleNode(3, [RuleNode(1), RuleNode(1)]),
    RuleNode(3, [RuleNode(1), RuleNode(2)]),
    RuleNode(3, [RuleNode(2), RuleNode(1)]),
    RuleNode(3, [RuleNode(2), RuleNode(2)])
]

println(all(p ∈ programs for p ∈ answer_programs))
>>> true
```
### Depth-First Search

In depth-first search, we first explore a certain branch of the search tree till the `max_depth` or a correct program is reached before we consider the next branch. 

```julia
g1 = @cfgrammar begin
Real = 1 | 2
Real = Real * Real
end
programs = collect(get_dfs_enumerator(g1, 2, typemax(Int), :Real))
println(programs)
>>> RuleNode[1,, 3{1,1}, 3{1,2}, 3{2,1}, 3{2,2}, 2,]
```

`get_dfs_enumerator` also has a default left-most heuristic and we consider what the difference is in output. 


```julia
g1 = @cfgrammar begin
    Real = 1 | 2
    Real = Real * Real
end
programs = collect(get_dfs_enumerator(g1, 2, typemax(Int), :Real, heuristic_rightmost))
println(programs)
>>> RuleNode[1,, 3{1,1}, 3{2,1}, 3{1,2}, 3{2,2}, 2,]
```

## Stochastic search 

For the examples below, we use this grammar and helper function.
```julia
grammar = @csgrammar begin
    X = |(1:5)
    X = X * X
    X = X + X
    X = X - X
    X = x
end
function create_problem(f, range=20)
    examples = [IOExample(Dict(:x => x), f(x)) for x ∈ 1:range]
    return Problem(examples), examples
end
```

### Metropolis-Hastings

One of the stochastic search methods that is implemented is Metropolis-Hastings (MH), which samples from a distribution of programs based on the grammar. For more information on MH, see for example [this webpage](https://stephens999.github.io/fiveMinuteStats/MH_intro.html).



The below example uses a simple arithmetic example. As the search method is stochastic, different programs may be returned, as shown below.

```julia
e = Meta.parse("x -> x * x + 4")
problem, examples = create_problem(eval(e))
enumerator = get_mh_enumerator(examples, mean_squared_error)
program, cost = search_best(grammar, problem, :X, enumerator=enumerator, error_function=mse_error_function, max_depth=3)

>>> (:(x * x - (1 - 5)), 0)
>>> (:(4 + x * x), 0)
>>> (:(x * x + 4), 0)
```

### Very Large Scale Neighbourhood Search 

The second implemented stochastic search method is VLSN, which search for a local optimum in the neighbourhood. For more information, see [this article](https://backend.orbit.dtu.dk/ws/portalfiles/portal/5293785/Pisinger.pdf).

Given the same grammar as before, we can try with some simple examples.

```julia
e = Meta.parse("x -> 10")
max_depth = 2
problem, examples = create_problem(eval(e))
enumerator = get_vlsn_enumerator(examples, mean_squared_error, max_depth)
program, cost = search_best(grammar, problem, :X, enumerator=enumerator, error_function=mse_error_function, max_depth=max_depth)
>>> (:(5 + 5), 0)
```

```julia
e = Meta.parse("x -> x")
max_depth = 1
problem, examples = create_problem(eval(e))
enumerator = get_vlsn_enumerator(examples, mean_squared_error, max_depth)
program, cost = search_best(grammar, problem, :X, enumerator=enumerator, error_function=mse_error_function, max_depth=max_depth)
>>> (:x, 0)
```

### Simulated Annealing

The third stochastic search method is called simulated annealing. This is another hill-climbing method to find local optima. For more information, see [this page](https://www.cs.cmu.edu/afs/cs.cmu.edu/project/learn-43/lib/photoz/.g/web/glossary/anneal.html).

We try the example from earlier, but now we can additionally define the `initial_temperature` of the algorithm, which is 1 by default. Two possible answers to the program are given as well.

```julia
e = Meta.parse("x -> x * x + 4")
initial_temperature = 2
problem, examples = create_problem(eval(e))
enumerator = get_sa_enumerator(examples, mean_squared_error, initial_temperature)
program, cost = search_best(grammar, problem, :X, enumerator=enumerator, error_function=mse_error_function, max_depth=3)
>>> (:(4 + x * x), 0)
>>> (:(x * x + (5 - 1)), 0)
```

### Genetic Search

Genetic search is a type of evolutionary algorithm, which will simulate the process of natural selection and return the 'fittest' program of the population. For more information, see [here](https://www.geeksforgeeks.org/genetic-algorithms/).

We show the example of finding a lambda function.

```julia
e = x -> 3 * x * x + (x + 2)
problem, examples = create_problem(e)
enumerator = get_genetic_enumerator(examples, 
    initial_population_size = 10,
    mutation_probability = 0.8,
    maximum_initial_population_depth = 3,
)
program, cost = search_best(grammar, problem, :X, enumerator=enumerator, error_function=mse_error_function, max_depth=nothing, max_time=20)
>>> (:(((((x - 5) + x) + x * x) + 1) + (((((2 + x * x) + 3) + x * x) + 1) - ((x - x) + x))), 0)
>>> (:(x * 1 + (x * ((x + x) + x * 1) + (1 + 1) * 1)), 0)
>>> (:((((x + x) + x) + 2) * x + ((x - x) + (2 - x))), 0)
```

## Other functionality

Finally, we showcase two other functionalities of HerbSearch, sampling and heuristics.

### Sampling
Sampling is implemented for the different stochastic search methods.

We consider here a simple grammar, which gives different programs for different search depths.

```julia
grammar = @cfgrammar begin 
    A = B | C | F
    F = G
    C = D
    D = E
end

# A->B (depth 1) or A->F->G (depth 2) or A->C->D->E (depth 3)

# For depth ≤ 1 the only option is A->B
expression = rand(RuleNode, grammar, :A, 1)
@assert rulenode2expr(expression, grammar) in [:B,:C,:F]

# For depth ≤ 2 the two options are A->B (depth 1) and A->B->G| A->C->G | A->F->G (depth 2)
expression = rand(RuleNode, grammar, :A, 2)
@assert rulenode2expr(expression,grammar) in [:B,:C,:F,:G]
```

### Heuristics


# Examples with larger domains and constraints
Here, we showcase a few examples using a more complicated grammar and a few types of constraints
```julia
# Expects to return a program equivalent to 1 + (1 - x) = 2 - x

g₁ = @csgrammar begin
    Element = |(1 : 3)          # 1 - 3
    Element = Element + Element # 4
    Element = 1 - Element       # 5
    Element = x                 # 6
end

addconstraint!(g₁, ComesAfter(6, [5]))

examples = [
    IOExample(Dict(:x => 0), 2),
    IOExample(Dict(:x => 1), 1),
    IOExample(Dict(:x => 2), 0)
]
problem = Problem(examples)
solution = search(g₁, problem, :Element, max_depth=3)

@assert test_with_input(SymbolTable(g₁), solution, Dict(:x => -2)) == 4

# Expects to return a program equivalent to 4 + x * (x + 3 + 3) = x^2 + 6x + 4

g₂ = @csgrammar begin
    Element = Element + Element + Element # 1
    Element = Element + Element * Element # 2
    Element = x                           # 3
    Element = |(3 : 5)                    # 4
end

# Restrict .. + x * x
addconstraint!(g₂, Forbidden(MatchNode(2, [MatchVar(:x), MatchNode(3), MatchNode(3)])))
# Restrict 4 and 5 in lower level
addconstraint!(g₂, ForbiddenPath([2, 1, 5]))
addconstraint!(g₂, ForbiddenPath([2, 1, 6]))

examples = [
    IOExample(Dict(:x => 1), 11)
    IOExample(Dict(:x => 2), 20)
    IOExample(Dict(:x => -1), -1)
]
problem = Problem(examples)
solution = search(g₂, problem, :Element)

@assert test_with_input(SymbolTable(g₂), solution, Dict(:x => 0)) == 4

# Expects to return a program equivalent to (1 - (((1 - x) - 1) - 1)) - 1 = x + 1

g₃ = @csgrammar begin
    Element = |(1 : 20)   # 1 - 20
    Element = Element - 1 # 21
    Element = 1 - Element # 22
    Element = x           # 23
end

addconstraint!(g₃, ComesAfter(23, [22, 21]))
addconstraint!(g₃, ComesAfter(22, [21]))

examples = [
    IOExample(Dict(:x => 1), 2)
    IOExample(Dict(:x => 10), 11)
]
problem = Problem(examples)
solution = search(g₃, problem, :Element)

@assert test_with_input(SymbolTable(g₃), solution, Dict(:x => 0)) == 1
@assert test_with_input(SymbolTable(g₃), solution, Dict(:x => 100)) == 101

# Expects to return a program equivalent to 18 + 4x

g₄ = @csgrammar begin
    Element = |(0 : 20)                   # 1 - 20
    Element = Element + Element + Element # 21
    Element = Element + Element * Element # 22
    Element = x                           # 23
end

# Enforce ordering on + +
addconstraint!(g₄, Ordered(
    MatchNode(21, [MatchVar(:x), MatchVar(:y), MatchVar(:z)]),
    [:x, :y, :z]
))

examples = [
    IOExample(Dict(:x => 1), 22),
    IOExample(Dict(:x => 0), 18),
    IOExample(Dict(:x => -1), 14)
]
problem = Problem(examples)
solution = search(g₄, problem, :Element)

@assert test_with_input(SymbolTable(g₄), solution, Dict(:x => 100)) == 418

# Expects to return a program equivalent to (x == 2) ? 1 : (x + 2)

g₅ = @csgrammar begin
    Element = Number # 1
    Element = Bool # 2

    Number = |(1 : 3) # 3-5
    
    Number = Number + Number # 6
    Bool = Number ≡ Number # 7
    Number = x # 8
    
    Number = Bool ? Number : Number # 9
    Bool = Bool ? Bool : Bool # 10
end

# Forbid ? = ?
addconstraint!(g₅, Forbidden(MatchNode(7, [MatchVar(:x), MatchVar(:x)])))
# Order =
addconstraint!(g₅, Ordered(MatchNode(7, [MatchVar(:x), MatchVar(:y)]), [:x, :y]))
# Order +
addconstraint!(g₅, Ordered(MatchNode(6, [MatchVar(:x), MatchVar(:y)]), [:x, :y]))

examples = [
    IOExample(Dict(:x => 0), 2)
    IOExample(Dict(:x => 1), 3)
    IOExample(Dict(:x => 2), 1)
]
problem = Problem(examples)
solution = search(g₅, problem, :Element)

@assert test_with_input(SymbolTable(g₅), solution, Dict(:x => 3)) == 5
```