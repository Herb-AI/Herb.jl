### A Pluto.jl notebook ###
# v0.20.21

using Markdown
using InteractiveUtils

# ╔═╡ 146ff53a-eab6-4b31-82fc-370bbdc4236f
begin
	import Pkg
	Pkg.activate(Base.current_project())
	Pkg.instantiate()
end

# ╔═╡ 0c1f68b7-a802-4d2a-b1a7-e4da11945907
using Herb

# ╔═╡ 0677e60e-d77c-4bda-ac8e-6ff8b21f0431
md"
# Getting Started

You can either paste this code into the Julia REPL or into a separate file, e.g. `get_started.jl`. If using a separate file you can execute using `julia get_started.jl` or `julia --project=. get_started.jl` depending on whether you installed Herb.jl globally or in a project.

To begin, we need to import `Herb`.
"

# ╔═╡ 27e843c5-df97-4ede-9294-88cb3b5df748
md"
To define a program synthesis problem, we need a grammar and specification. 
- The grammar defines the space of programs, in the form of syntax trees.
- The specification describes the behavior of the desired program. 

Having defined a problem, we use [`HerbSearch`](https://herb-ai.github.io/Herb.jl/dev/HerbSearch/) to find syntax trees that match the specification. These trees can be executed using [`HerbInterpret`](https://herb-ai.github.io/Herb.jl/dev/HerbInterpret/).

## The Grammar

We will start by creating a grammar using the [`@csgrammar`](https://herb-ai.github.io/Herb.jl/dev/HerbGrammar/#HerbGrammar.@csgrammar-Tuple{Any}) macro, included in [`HerbGrammar`](https://herb-ai.github.io/Herb.jl/dev/HerbGrammar/). 
Here, we describe a simple integer arithmetic example grammar that consisting of a only one type, `Number`. We define a single input variable `x`, and the values `1,2`, of that type. Then, we allow the addition and multiplication of `Number`s.
"

# ╔═╡ eec315e4-ae65-4d97-ac9e-8b31a6d3ad0e
grammar = @csgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
end

# ╔═╡ b55c696a-a421-462a-abfd-b8f2c652d4f0
md"
!!! note

    The symbol `x` in the grammar corresponds to a variable in the arithmetic expression. It can have any name in the grammar, as long as the name does not collide with already defined symbols in julia, such as `+`.

## The Specification

[`HerbSpecification`](https://herb-ai.github.io/Herb.jl/dev/HerbSpecification/) defines different forms for the specification. In this guide, the specification is a collection of examples, constructed for input-output pairs.
Inputs are provided as a [`Dict`](https://docs.julialang.org/en/v1/base/collections/#Base.Dict), where the keys are symbols of the input variables (in this example, `x`), and the values are the input variables corresponding values.
The outputs of the program are simply the expected return values for the given inputs.
The specification is then defined as a list of [`IOExample`](https://herb-ai.github.io/Herb.jl/dev/HerbSpecification/#HerbSpecification.IOExample)s.
"

# ╔═╡ dc8926aa-91c1-4a04-ab8d-6820edc6db2b
specification = [IOExample(Dict(:x => x), 2x+1) for x ∈ 1:5]

# ╔═╡ 7e1a10b5-8c24-41fb-a3aa-4ec1617d05cf
md"
The specification is used to construct a problem instance.
"

# ╔═╡ 63af0e76-db88-432d-9fc1-11ec016c45c2
problem = Problem(specification)

# ╔═╡ 08cc1274-3ea2-4e21-891b-e4cca9281eeb
md"""


# Searching for Programs

Having defined the grammar and problem, let us search for a solution with [`HerbSearch`](https://herb-ai.github.io/Herb.jl/dev/HerbSearch/). 

!!! note

    For the search to be able produce programs that use the examples' inputs, we need to ensure that there is a rule where the right-hand side matches the symbol used in the input of the `IOExample`s.
    For an example `IOExample(Dict(:x => 1), 2)`, there must be some rule `Number = x` -- the `x`'s must match, otherwise the input value will never be used in any of the programs. 
    If you have multiple input arguments, like `IOExample(Dict(:x => 1, :name => "Alice"), "1. Alice")`, then you need two rules, such as `Number = x` and `String = name`, to construct programs that use both inputs.


To do so, we will iterate the space of all possible program trees in a breadth-first manner using a [`BFSIterator`](https://herb-ai.github.io/Herb.jl/dev/HerbSearch/#HerbSearch.BFSIterator). 
We define it to start with a program tree that have a `:Number` node in the root, dictating the output of the problem is of type `Number` defined in the grammar. 
We also bound the search by setting the maximum depth of the program tree to 5.
"""

# ╔═╡ 2732bd85-4076-4530-99bf-9076a8811329
program_tree_iterator = BFSIterator(grammar, :Number, max_depth=5)

# ╔═╡ 5a4a491d-dcb0-4623-90ea-d3c5e59a5f72
md"

The problem, along with the program tree iterator, can then be handed to the [`synth`](https://herb-ai.github.io/Herb.jl/dev/HerbSearch/#HerbSearch.synth-Tuple{Problem,%20ProgramIterator}) function to run the search. 
The search will continue until it finds a program that satisfies all the examples in the specification, or until the iterator is exhausted.
When it terminates, it returns the program that satisfies the most examples, along with a flag that indicates whether the program satisfies _all_ the examples or not.

"

# ╔═╡ 0983097a-d592-44e3-950b-9d9dfeb30edf
solution, flag = synth(problem, program_tree_iterator)

# ╔═╡ a94e49d4-a348-4af9-8236-f18dcbe7ef5c
md"

## Using the Synthesized Program

Eventually, we want to test our solution on some other inputs. To that end, we transform the solution from a syntax tree back to a readable and exicutable format using [`rulenode2expr`](https://herb-ai.github.io/Herb.jl/dev/HerbGrammar/#HerbGrammar.rulenode2expr-Tuple%7BAbstractRuleNode,%20AbstractGrammar%7D).
"

# ╔═╡ fb3e47bf-03f1-4eda-85ff-1897751c1d00
begin
    program = rulenode2expr(solution, grammar)
    println(program)
end

# ╔═╡ 76d48e3c-0347-4d49-afed-7812feee930c
md"

To set up an environment that correctly binds values to the variables in the program, we provide the [`execute_on_input`](https://herb-ai.github.io/Herb.jl/dev/HerbInterpret/#HerbInterpret.execute_on_input-Union{Tuple{T},%20Tuple{Dict{Symbol,%20Any},%20Any,%20Dict{Symbol,%20T}}}%20where%20T) function. 
It takes in three arguments:
- A [`SymbolTable`](https://herb-ai.github.io/Herb.jl/dev/HerbGrammar/#HerbGrammar.SymbolTable), which is nothing more than a dictionary mapping symbols from the grammar to symbols in the Julia expression. This can be created using the [`grammar2symboltable`](https://herb-ai.github.io/Herb.jl/dev/HerbGrammar/#HerbGrammar.grammar2symboltable) function.
- The program to execute. **Note:** This is not the solution from the search, but the Julia expression built from the solution and the grammar.
- Values for all the variables in the grammar.
"

# ╔═╡ 4ce7545e-2f1c-40c3-9044-5092b66d3c3c
begin
    output = execute_on_input(grammar2symboltable(grammar), program, Dict(:x => 6)) 
    println(output)
end

# ╔═╡ b049977a-71d0-4e3e-b915-626aa5909bd6
md"
If you run the completed code it will output both the generated Julia expression and the result from assigning value.

Just like that we tackled (almost) all modules of Herb.jl.

## Where to go from here?

See our other tutorials!

## The full code example

"

# ╔═╡ cccf503e-f36a-11ef-1697-3f13720272cf
md"
```julia
using Herb

# define our very simple context-free grammar
# Can add and multiply over the input variable x and the integers 1,2.
grammar = @csgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
end

# define the synthesis problem specification as input-output examples, in this case using the function 2x+1
problem = Problem([IOExample(Dict(:x => x), 2x+1) for x ∈ 1:5])

# define a breadth-first iterator over program trees with root node :Number and max depth 5
iterator = BFSIterator(grammar, :Number, max_depth=5)

# run the synthesis, returning the best solution and a flag indicating whether all examples were satisfied
solution, flag = synth(problem, iterator)

# convert the solution from a syntax tree to a Julia expression, and print it
program = rulenode2expr(solution, grammar)
println(program)

# execute the program on the input x=6, and print the output
output = execute_on_input(grammar2symboltable(grammar), program, Dict(:x => 6)) 
println(output)

```
"

# ╔═╡ Cell order:
# ╟─0677e60e-d77c-4bda-ac8e-6ff8b21f0431
# ╠═146ff53a-eab6-4b31-82fc-370bbdc4236f
# ╠═0c1f68b7-a802-4d2a-b1a7-e4da11945907
# ╠═27e843c5-df97-4ede-9294-88cb3b5df748
# ╠═eec315e4-ae65-4d97-ac9e-8b31a6d3ad0e
# ╠═b55c696a-a421-462a-abfd-b8f2c652d4f0
# ╠═dc8926aa-91c1-4a04-ab8d-6820edc6db2b
# ╠═7e1a10b5-8c24-41fb-a3aa-4ec1617d05cf
# ╠═63af0e76-db88-432d-9fc1-11ec016c45c2
# ╠═08cc1274-3ea2-4e21-891b-e4cca9281eeb
# ╠═2732bd85-4076-4530-99bf-9076a8811329
# ╠═5a4a491d-dcb0-4623-90ea-d3c5e59a5f72
# ╠═0983097a-d592-44e3-950b-9d9dfeb30edf
# ╠═a94e49d4-a348-4af9-8236-f18dcbe7ef5c
# ╠═fb3e47bf-03f1-4eda-85ff-1897751c1d00
# ╠═76d48e3c-0347-4d49-afed-7812feee930c
# ╠═4ce7545e-2f1c-40c3-9044-5092b66d3c3c
# ╟─b049977a-71d0-4e3e-b915-626aa5909bd6
# ╟─cccf503e-f36a-11ef-1697-3f13720272cf
