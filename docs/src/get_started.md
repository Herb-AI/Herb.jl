# Getting Started

You can either paste this code into the Julia REPL or into a seperate file, e.g. `get_started.jl`. If using a separate file you can execute using `julia get_started.jl` or `julia --project=. get_started.jl` depending on whether you installed Herb.jl globally or in a project.

To begin, we need to import all needed packages using

```julia
using HerbGrammar, HerbSpecification, HerbSearch, HerbInterpret
```

To define a program synthesis problem, we need a grammar and specification. 

First, a grammar can be constructed using the `@csgrammar` macro included in `HerbGrammar`. 

Here, we describe a simple integer arithmetic example, that can add and multiply an input variable `x` or the integers `1,2`, using


```julia
g = @csgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
end
```

Second, the problem specification can be provided using e.g. input/output examples using `HerbSpecification`. Inputs are provided as a `Dict` assigning values to variables, and outputs as arbitrary values. The problem itself is then a list of `IOExample`s using

```julia
problem = Problem([IOExample(Dict(:x => x), 2x+1) for x ∈ 1:5])
```

The problem is given now, let us search for a solution with `HerbSearch`. For now we will just use the default parameters searching for a satisfying program over the grammar, given the problem and a starting symbol using

```julia
iterator = BFSIterator(g₁, :Number, max_depth=5)
solution, flag = synth(problem, iterator)
println(solution)
```

There are various ways to adapt the search technique to your needs. Please have a look at the [`synth`](@ref) documentation.

Eventually, we want to test our solution on some other inputs using `HerbInterpret`. We transform our grammar `g` to a Julia expression with `Symboltable(g)`, add our solution and the input, assigning the value `6` to the variable `x`.

```julia
program = rulenode2expr(solution, g) # should yield 2*6+1

output = execute_on_input(SymbolTable(g), program, Dict(:x => 6)) 
println(output)
```

Just like that we tackled (almost) all modules of Herb.jl.

## Where to go from here?

See our other tutorials!

## The full code example

```julia
using HerbSearch, HerbSpecification, HerbInterpret, HerbGrammar

# define our very simple context-free grammar
# Can add and multiply an input variable x or the integers 1,2.
g = @csgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
end

problem = Problem([IOExample(Dict(:x => x), 2x+1) for x ∈ 1:5])
iterator = BFSIterator(g₁, :Number, max_depth=5)

solution, flag = synth(problem, iterator)
program = rulenode2expr(solution, g) # should yield 2*6 +1 

output = execute_on_input(SymbolTable(g), program, Dict(:x => 6)) 
println(output)

```



