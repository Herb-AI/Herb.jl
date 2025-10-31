### A Pluto.jl notebook ###
# v0.20.18

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

First, a grammar can be constructed using the `@csgrammar` macro included in `HerbGrammar`. 

Here, we describe a simple integer arithmetic example, that can add and multiply an input variable `x` or the integers `1,2`, using

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
Second, the problem specification can be provided using e.g. input/output examples using `HerbSpecification`. Inputs are provided as a `Dict` assigning values to variables, and outputs as arbitrary values. The problem itself is then a list of `IOExample`s using
"

# ╔═╡ dc8926aa-91c1-4a04-ab8d-6820edc6db2b
problem = Problem([IOExample(Dict(:x => x), 2x+1) for x ∈ 1:5])

# ╔═╡ 08cc1274-3ea2-4e21-891b-e4cca9281eeb
md"
For the search to produce programs that use the input examples, we need to ensure that there is a rule where the right-hand side matches the symbol used in the input to the `IOExample`.
In our case, the input is defined like this: 
`IOExample(Dict(:x => x))`.
Our grammar has already a corresponding rule (`Number = x`) that can handle the input. 

The problem is given now, let us search for a solution with `HerbSearch`. For now, we will just use the default parameters searching for a satisfying program over the grammar, given the problem and a starting symbol using
"

# ╔═╡ 30b431b2-e5a2-451d-a553-328111249515


# ╔═╡ 2732bd85-4076-4530-99bf-9076a8811329
iterator = BFSIterator(g, :Number, max_depth=5)

# ╔═╡ 01ce2ad4-ad00-41cf-afe3-757ae62ac4c6
solution, flag = synth(problem, iterator)

# ╔═╡ a94e49d4-a348-4af9-8236-f18dcbe7ef5c
md"
There are various ways to adapt the search technique to your needs. Please have a look at the [`synth`](@ref) documentation.

Eventually, we want to test our solution on some other inputs using `HerbInterpret`. We transform our grammar `g` to a Julia expression with `grammar2symboltable(g)`, add our solution and the input, assigning the value `6` to the variable `x`.
"

# ╔═╡ fb3e47bf-03f1-4eda-85ff-1897751c1d00
program = rulenode2expr(solution, g)

# ╔═╡ 4ce7545e-2f1c-40c3-9044-5092b66d3c3c
output = execute_on_input(grammar2symboltable(g), program, Dict(:x => 6))  # should yield 2*6+1

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
# ╟─27e843c5-df97-4ede-9294-88cb3b5df748
# ╠═eec315e4-ae65-4d97-ac9e-8b31a6d3ad0e
# ╟─b55c696a-a421-462a-abfd-b8f2c652d4f0
# ╠═dc8926aa-91c1-4a04-ab8d-6820edc6db2b
# ╠═08cc1274-3ea2-4e21-891b-e4cca9281eeb
# ╠═30b431b2-e5a2-451d-a553-328111249515
# ╠═2732bd85-4076-4530-99bf-9076a8811329
# ╠═01ce2ad4-ad00-41cf-afe3-757ae62ac4c6
# ╟─a94e49d4-a348-4af9-8236-f18dcbe7ef5c
# ╠═fb3e47bf-03f1-4eda-85ff-1897751c1d00
# ╠═4ce7545e-2f1c-40c3-9044-5092b66d3c3c
# ╟─b049977a-71d0-4e3e-b915-626aa5909bd6
# ╟─cccf503e-f36a-11ef-1697-3f13720272cf
