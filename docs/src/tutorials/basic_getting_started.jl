### A Pluto.jl notebook ###
# v0.20.20

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
- The grammar defines the shape of the syntax tree. 
- The specification describes the behavior of the desired program. In this guide, the specification is a collection of input/output examples, but [`HerbSpecification`](https://herb-ai.github.io/Herb.jl/dev/HerbSpecification/) defines other forms of specification as well.

Having defined a problem, we use [`HerbSearch`](https://herb-ai.github.io/Herb.jl/dev/HerbSearch/) to find syntax trees that match the specification. These trees can be executed using [`HerbInterpret`](https://herb-ai.github.io/Herb.jl/dev/HerbInterpret/).

## The Grammar

We will start by creating a grammar using the [`@csgrammar`](https://herb-ai.github.io/Herb.jl/dev/HerbGrammar/#HerbGrammar.@csgrammar-Tuple{Any}) macro. Here, we describe a simple integer arithmetic example, that can add and multiply an input variable `x` or the integers `1,2`.

"

# ╔═╡ eec315e4-ae65-4d97-ac9e-8b31a6d3ad0e
g = @csgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
end

# ╔═╡ b55c696a-a421-462a-abfd-b8f2c652d4f0
md"
!!! note

    The symbol `x` in the grammar corresponds to a variable in the arithmetic expression. It can have any name in the grammar, as long as the name does not collide with already defined symbols.

## The Specification

Separate from the grammar we specify the behavior of the program using input/output examples. Inputs are provided as a [`Dict`](https://docs.julialang.org/en/v1/base/collections/#Base.Dict), where the keys are values for the variable `x` and the values are the outputs of the program. The problem itself is then a list of [`IOExample`](https://herb-ai.github.io/Herb.jl/dev/HerbSpecification/#HerbSpecification.IOExample)s.
"

# ╔═╡ dc8926aa-91c1-4a04-ab8d-6820edc6db2b
specification = [IOExample(Dict(:x => x), 2x+1) for x ∈ 1:5]

# ╔═╡ 7e1a10b5-8c24-41fb-a3aa-4ec1617d05cf
md"
The specification is used to construct a problem instance. It will be combined with the grammar once we start searching for programs in the next section.
"

# ╔═╡ 63af0e76-db88-432d-9fc1-11ec016c45c2
problem = Problem(specification)

# ╔═╡ 08cc1274-3ea2-4e21-891b-e4cca9281eeb
md"

# Searching for Programs

Having defined the grammar and problem, let us search for a solution with [`HerbSearch`](https://herb-ai.github.io/Herb.jl/dev/HerbSearch/). 

To do so, we will iterate the space of all possible program trees in a breadth-first manner using a [`BFSIterator`](https://herb-ai.github.io/Herb.jl/dev/HerbSearch/#HerbSearch.BFSIterator). It starts with program tree consisting of a single `:Number` node, and is bounded by setting the maximum depth of the program tree to 5.
"

# ╔═╡ 2732bd85-4076-4530-99bf-9076a8811329
program_tree_iterator = BFSIterator(g, :Number, max_depth=5)

# ╔═╡ 5a4a491d-dcb0-4623-90ea-d3c5e59a5f72
md"

The problem can then be handed to the [`synth`](https://herb-ai.github.io/Herb.jl/dev/HerbSearch/#HerbSearch.synth-Tuple{Problem,%20ProgramIterator}) function to run the search. It will iterate over all program trees to find a program that satisfies the specification. When it terminates, it returns the program that satisfies the most examples, along with a flag that indicates whether the program satisfies _all_ the examples or not.

"

# ╔═╡ 0983097a-d592-44e3-950b-9d9dfeb30edf
solution, flag = synth(problem, program_tree_iterator)

# ╔═╡ a94e49d4-a348-4af9-8236-f18dcbe7ef5c
md"
There are various ways to adapt the search technique to your needs. Look at the [`synth`](https://herb-ai.github.io/Herb.jl/dev/HerbSearch/#HerbSearch.synth-Tuple{Problem,%20ProgramIterator}) documentation for all the available options.

## Using the Synthesized Program

Eventually, we want to test our solution on some other inputs. This means we need a way to execute the solution, for which we provide [`HerbInterpret`](https://herb-ai.github.io/Herb.jl/dev/HerbInterpret/).

We transform the solution into a Julia expression with [`rulenode2expr`](https://herb-ai.github.io/Herb.jl/dev/HerbGrammar/#HerbGrammar.rulenode2expr-Tuple%7BAbstractRuleNode,%20AbstractGrammar%7D). The resulting expression can be executed using Julia's builtin [`eval`](https://docs.julialang.org/en/v1/base/base/#eval) function.
"

# ╔═╡ fb3e47bf-03f1-4eda-85ff-1897751c1d00
program = rulenode2expr(solution, g)

# ╔═╡ 76d48e3c-0347-4d49-afed-7812feee930c
md"

To set up an environment that correctly binds values to the variables in the program, we provide the [`execute_on_input`](https://herb-ai.github.io/Herb.jl/dev/HerbInterpret/#HerbInterpret.execute_on_input-Union{Tuple{T},%20Tuple{Dict{Symbol,%20Any},%20Any,%20Dict{Symbol,%20T}}}%20where%20T) function. It takes in three arguments:
- A [`SymbolTable`](https://herb-ai.github.io/Herb.jl/dev/HerbGrammar/#HerbGrammar.SymbolTable), which is nothing more than a dictionary mapping symbols from the grammar to symbols in the Julia expression. This can be created using the [`grammar2symboltable`](https://herb-ai.github.io/Herb.jl/dev/HerbGrammar/#HerbGrammar.grammar2symboltable) function.
- The program to execute. **Note:** This is not the solution from the search, but the Julia expression built from the solution.
- Values for all the variables in the expression.
"

# ╔═╡ 4ce7545e-2f1c-40c3-9044-5092b66d3c3c
output = execute_on_input(grammar2symboltable(g), program, Dict(:x => 6))  # yields 2*6+1

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
# Can add and multiply an input variable x or the integers 1,2.
g = @csgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
end

problem = Problem([IOExample(Dict(:x => x), 2x+1) for x ∈ 1:5])
iterator = BFSIterator(g, :Number, max_depth=5)

solution, flag = synth(problem, iterator)
program = rulenode2expr(solution, g)
println(program)

output = execute_on_input(grammar2symboltable(g), program, Dict(:x => 6)) 
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
