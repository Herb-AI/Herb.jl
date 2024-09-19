### A Pluto.jl notebook ###
# v0.19.43

using Markdown
using InteractiveUtils

# ╔═╡ a93d954d-0f09-4b6d-a3a5-62bfe39681e2
using PlutoUI

# ╔═╡ c4441fa4-09ec-4b81-9681-b13b93a9c9c0
using HerbGrammar, HerbSpecification, HerbSearch, HerbInterpret, HerbConstraints


# ╔═╡ dddca175-3d88-45ce-90da-575c0ba38175
md"""
# Advanced Search Procedures in Herb.jl

[A more verbose getting started with Herb.jl]() described the concept of a program space and showed how to search it with Herb.jl, using a simple search with a BFS iterator. 
This tutorial takes a closer look at advanced search procedures. 

More specifically, you will learn about

- **Parameters** that can be specified and their effect on the search procedure.  
- **Search methods** that can be employed to find a solution program to a program synthesis problem, including basic search (BFS and DFS), stochastic search and genetic search methods.
- **Other functionality** of the module `HerbSearch.jl` 
   (TODO: why are they in this tutorial?)
"""

# ╔═╡ 6ab37bbc-73e2-4d9a-a8b2-e715a0b61c8f
TableOfContents()

# ╔═╡ 67931820-0f43-41e1-898e-5b5bd55e30d1
md"""
We start with a simple grammar:.
"""

# ╔═╡ e41c61a4-0b2c-46da-8f7b-fe6dc529c544
g_1 = @csgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
end

# ╔═╡ 9ad0a92a-10d5-458a-8f05-9011c8553609
md"""
Let's use the simple program `2x+1` as our problem and generate some input-output examples for the problem specification.
"""

# ╔═╡ 65317911-bc92-4b84-9744-ed784adcab4a
problem_1 = Problem([IOExample(Dict(:x => x), 2x+1) for x ∈ 1:5])

# ╔═╡ e9c6bc00-21f5-4a99-8bec-63cf2156c233
md"""
## Parameters

Search procedures typically have some hyperparameters that can be cofigured by the user. 

### `max_depth`

`max_depth` controls the maximum depth of the program trees we want to explore.

In the following example, we can see the effect of `max_depth` on the number of allocations considered. 
"""

# ╔═╡ 338f19f1-3a62-4462-b8dc-24424d7644f2
iterator_1 = BFSIterator(g_1, :Number, max_depth=3)

# ╔═╡ 542cd47e-74cd-4b6f-acc9-bf524222e583
iterator_2 = BFSIterator(g_1, :Number, max_depth=6)

# ╔═╡ a6fb2e91-b73a-4032-930f-d884abd539e2
begin
	println("Solution for max_depth = 3:")
	solution_1 = @time synth(problem_1, iterator_1)
	println(solution_1)
	println("----------------------")
	println("Solution for max_depth = 6:")
	solution_2 = @time synth(problem_1, iterator_2)
	println(solution_2)
end

# ╔═╡ 4b49f206-970e-47d2-af65-336ba65b1019
md"""
TODO: Explain @time
"""

# ╔═╡ 35405357-179b-4e77-9bdc-edf5a550b36d
md"""
### `max_enumerations`
Another parameter to use is `max_enumerations`, which describes the maximum number of programs that can be tested at evaluation. 
Let's see how many enumerations are necessary to solve our simple problem.
"""

# ╔═╡ 3954dd49-07a2-4ec2-91b4-9c9596d5c264
begin
	for i in range(1, 50)
	    println(i, " enumerations")
		iterator = BFSIterator(g_1, :Number, max_depth=i)
	    solution = @time synth(problem_1, iterator)
	    println(solution)
	end
end

# ╔═╡ 9892e91b-9115-4520-9637-f8d7c8905825
md"""
TODO: numbers seem to have changed. Not 24 anymore. How reproducible is this anyway?
What does allocations mean?

We see that only when `i >= 24`, there is a result, after that, increasing `i` does not have any effect on the number of allocations. 

A final parameter we consider here is `allow_evaluation_errors`, which is `false` by default. When this is set to `true`, the program will still run even when an exception is thrown during evaluation. To see the effect of this, we create a new grammar. We can also retrieve the error together with the solution from the search method.
"""

# ╔═╡ a4e58bbc-7c14-4fce-b35d-688b56e0eb61
md"""
### `allow_evaluation_errors`

TODO: What do we mean with 'program will still run'?

A final parameter we consider here is `allow_evaluation_errors`, which is `false` by default. When set to `true`, the program will still run even when an exception is thrown during evaluation. 

We will use a new example to see the effect of `allow_evaluation_errors`. After defining a new grammar and problem, ...


We can also retrieve the error together with the solution from the search method.
"""

# ╔═╡ 9fb40ceb-8d41-491b-8941-20a8b240eb82
begin
	g_2 = @cfgrammar begin
	    Number = 1
	    List = []
	    Index = List[Number]
	end
end

# ╔═╡ 94e0d676-a9c7-4291-8696-15301e541c30
problem_2 = Problem([IOExample(Dict(), x) for x ∈ 1:5])

# ╔═╡ a4a7daed-f89b-44ad-8787-9199c05bf046
iterator_3 = BFSIterator(g_2, :Number, max_depth=2)

# ╔═╡ 4821fd3a-ff2d-4991-99ad-76608d11b1da
solution_3 = @time synth(problem_2, iterator_3, allow_evaluation_errors=true)

# ╔═╡ 8d91b2e3-30b5-4ea2-bd3f-3055bb6d1d5a
# solution = search(g_2, problem_2, :Index, max_depth=2, allow_evaluation_errors=true)

# ╔═╡ 52332fa2-7ea7-4226-9460-e0bbc905c619
println("solution: ", solution_3)

# ╔═╡ c26fea48-f812-4f24-bb8c-680e14a55df7
md"""
There is another search method called `search_best` which returns both the solution and the possible error. The method returns the best program found so far. In this case, we can also see the error (`typemax(Int)`):
"""

# ╔═╡ 57f5face-d9d5-441a-8e0e-6ef6319fc178
solution, error = search_best(g, problem, :Index, max_depth=2, allow_evaluation_errors=true)
println("solution: ", solution)
println("error: ", error)

# ╔═╡ 9b4b21e0-dc6a-43ae-a511-79988ee99001
md"""
## Search methods

We now show examples of using different search procedures, which are initialized by passing different enumerators to the search function.

### Breadth-First Search

The breadth-first search will first enumerate all possible programs at the same depth before considering programs with a depth of one more. A tree of the grammar is returned with programs ordered in increasing sizes. We can first `collect` the programs that have a `max-depth` of 2 and a `max_size` of infinite (integer maximum value), where the starting symbol is of type `Real`. This function uses a default heuristic 'left-most first', such that the left-most child in the tree is always explored first.
"""

# ╔═╡ 3af650d9-19c6-4351-920d-d2361091f628
g1 = @cfgrammar begin
    Real = 1 | 2
    Real = Real * Real
end
programs = collect(get_bfs_enumerator(g1, 2, typemax(Int), :Real))

# ╔═╡ d3ff497e-d2c2-4df6-8e4c-cdca70fd0677
md"""
We can test that this function returns all and only the correct functions. 
"""

# ╔═╡ da7f326c-f0d5-4837-ac9a-5bcad604566e
answer_programs = [
    RuleNode(1),
    RuleNode(2),
    RuleNode(3, [RuleNode(1), RuleNode(1)]),
    RuleNode(3, [RuleNode(1), RuleNode(2)]),
    RuleNode(3, [RuleNode(2), RuleNode(1)]),
    RuleNode(3, [RuleNode(2), RuleNode(2)])
]

println(all(p ∈ programs for p ∈ answer_programs))

# ╔═╡ 0020b79a-6352-4e2d-93f6-2a1d7b03ae2c
md"""
### Depth-First Search

In depth-first search, we first explore a certain branch of the search tree till the `max_depth` or a correct program is reached before we consider the next branch. 
"""

# ╔═╡ 789150a8-862c-48c3-88b8-710b81ab34cf
g1 = @cfgrammar begin
Real = 1 | 2
Real = Real * Real
end
programs = collect(get_dfs_enumerator(g1, 2, typemax(Int), :Real))
println(programs)

# ╔═╡ 243165be-a9d2-484d-8046-811a2b0ba139
md"""
`get_dfs_enumerator` also has a default left-most heuristic and we consider what the difference is in output. 
"""

# ╔═╡ 3d01c6f1-80a6-4904-97e2-775170e97bbf
g1 = @cfgrammar begin
    Real = 1 | 2
    Real = Real * Real
end
programs = collect(get_dfs_enumerator(g1, 2, typemax(Int), :Real, heuristic_rightmost))
println(programs)

# ╔═╡ 168c71bf-ce5b-4ab3-b29a-5996981c42a5
md"""
## Stochastic search
We now introduce a few stochastic search algorithms, for which we first create a simple grammar and a helper function for problems.
"""

# ╔═╡ a4b522cf-78f0-4d44-88c8-82dd0cdbf952
grammar = @csgrammar begin
    X = |(1:5)
    X = X * X
    X = X + X
    X = X - X
    X = x
end

# ╔═╡ f313edb9-8fd9-4d78-88cd-89226f5c769d
function create_problem(f, range=20)
    examples = [IOExample(Dict(:x => x), f(x)) for x ∈ 1:range]
    return Problem(examples), examples
end

# ╔═╡ 0da9053a-959b-471e-8918-662ec63da71c
md"""
### Metropolis-Hastings

One of the stochastic search methods that is implemented is Metropolis-Hastings (MH), which samples from a distribution of programs based on the grammar. For more information on MH, see for example [this webpage](https://stephens999.github.io/fiveMinuteStats/MH_intro.html).

The example below uses a simple arithmetic example. You can try running this code block multiple times, which will give different programs, as the search is stochastic. 
"""

# ╔═╡ 0a30fb40-cd45-4661-a501-ae8e45f1e07e
e = x -> x * x + 4
problem, examples = create_problem(e)
enumerator = get_mh_enumerator(examples, mean_squared_error)
program, cost = search_best(grammar, problem, :X, enumerator=enumerator, error_function=mse_error_function, max_depth=3)

# ╔═╡ 700270ea-90bd-474b-91d9-0e5ed329776a
md"""
### Very Large Scale Neighbourhood Search 

The second implemented stochastic search method is VLSN, which searches for a local optimum in the neighbourhood. For more information, see [this article](https://backend.orbit.dtu.dk/ws/portalfiles/portal/5293785/Pisinger.pdf).

Given the same grammar as before, we can try it with some simple examples.
"""

# ╔═╡ 8731f312-bfcf-4f6c-86fa-60014dc146d6
e = x -> 10
max_depth = 2
problem, examples = create_problem(e)
enumerator = get_vlsn_enumerator(examples, mean_squared_error, max_depth)
program, cost = search_best(grammar, problem, :X, enumerator=enumerator, error_function=mse_error_function, max_depth=max_depth)


# ╔═╡ 46ca65d1-d876-4abc-a562-8d266bad195f
e = x -> x
max_depth = 1
problem, examples = create_problem(e)
enumerator = get_vlsn_enumerator(examples, mean_squared_error, max_depth)
program, cost = search_best(grammar, problem, :X, enumerator=enumerator, error_function=mse_error_function, max_depth=max_depth)

# ╔═╡ 599194a8-3f47-4917-9143-a5fe0d43029f
md"""
### Simulated Annealing

The third stochastic search method is called simulated annealing. This is another hill-climbing method to find local optima. For more information, see [this page](https://www.cs.cmu.edu/afs/cs.cmu.edu/project/learn-43/lib/photoz/.g/web/glossary/anneal.html).

We try the example from earlier, but now we can additionally define the `initial_temperature` of the algorithm, which is 1 by default. Change the value below to see the effect.
"""

# ╔═╡ cb5935ed-d89b-4e25-9243-d201daf18e78
e = x -> x * x + 4
initial_temperature = 1
problem, examples = create_problem(e)
enumerator = get_sa_enumerator(examples, mean_squared_error, initial_temperature)
program, cost = search_best(grammar, problem, :X, enumerator=enumerator, error_function=mse_error_function, max_depth=3)        

# ╔═╡ d0c3742e-23e5-4ca1-9e83-b6d1e8a7cded
e = x -> x * x + 4
initial_temperature = 2
problem, examples = create_problem(e)
enumerator = get_sa_enumerator(examples, mean_squared_error, initial_temperature)
program, cost = @time search_best(grammar, problem, :X, enumerator=enumerator, error_function=mse_error_function, max_depth=3)

# ╔═╡ 5df0ba53-b528-4baf-9980-cafe5d73f9dd
md"""
### Genetic Search

Genetic search is a type of evolutionary algorithm, which will simulate the process of natural selection and return the 'fittest' program of the population. For more information, see [here](https://www.geeksforgeeks.org/genetic-algorithms/).

We show the example of finding a lambda function. Try varying the parameters of the genetic search to see what happens.
"""

# ╔═╡ a434645b-d592-4162-a8b4-b4b04cea30a9
e = x -> 3 * x * x + (x + 2)
problem, examples = create_problem(e)
enumerator = get_genetic_enumerator(examples, 
    initial_population_size = 10,
    mutation_probability = 0.8,
    maximum_initial_population_depth = 3,
)
program, cost = search_best(grammar, problem, :X, enumerator=enumerator, error_function=mse_error_function, max_depth=nothing, max_time=20)    

# ╔═╡ 38cd9032-27c0-4179-a536-ce59a42ff16a
md"""
## Other functionality

Finally, we showcase two other functionalities of HerbSearch, sampling and heuristics.

### Sampling
Sampling is implemented for the different stochastic search methods.

We consider here a simple grammar, which gives different programs for different search depths.
"""

# ╔═╡ f8415d48-a51d-4845-8425-fd61ed79c06e
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

# ╔═╡ 7f88bf4f-d82c-4e5a-a9eb-93870954c79e
md"""
### Heuristics
"""

# ╔═╡ 53598f8f-9973-4cad-af0c-280f5531bb21
md"""
# More interesting domains & Use of constraints
In the following examples, we introduce some larger grammars and show that Herb can still efficiently find the correct program.
"""

# ╔═╡ bc971069-08c4-493c-a917-8092493d3233
#Expects to return a program equivalent to 1 + (1 - x) = 2 - x

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

# ╔═╡ 61a60c9c-36cf-4e86-b697-748b3524d3b4
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

# ╔═╡ a5b17c81-b667-4b1c-ab15-ddf1a162683b
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

# ╔═╡ e41feac7-6de6-4223-8a21-341b85da52c0
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

# ╔═╡ 1c4db74a-4caa-4ce5-815f-b631365c5129
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

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HerbConstraints = "1fa96474-3206-4513-b4fa-23913f296dfc"
HerbGrammar = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"
HerbInterpret = "5bbddadd-02c5-4713-84b8-97364418cca7"
HerbSearch = "3008d8e8-f9aa-438a-92ed-26e9c7b4829f"
HerbSpecification = "6d54aada-062f-46d8-85cf-a1ceaf058a06"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
HerbConstraints = "~0.2.2"
HerbGrammar = "~0.3.0"
HerbInterpret = "~0.1.3"
HerbSearch = "~0.3.0"
HerbSpecification = "~0.1.0"
PlutoUI = "~0.7.59"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.4"
manifest_format = "2.0"
project_hash = "5ee7afaa57cf163e03a42d572d1cb2cb022598e5"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "d57bd3762d308bded22c3b82d033bff85f6195c6"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.4.0"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9e2a6b69137e6969bab0152632dcb3bc108c8bdd"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+1"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "a2f1c8c668c8e3cb4cca4e57a8efdb09067bb3fd"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.0+2"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "b1c55339b7c6c350ee89f2c1604299660525b248"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.15.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1c6317308b9dc757616f0b5cb379db10494443a7"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.6.2+0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "db16beca600632c95fc8aca29890d83788dd8b23"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.96+0"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "5c1d8ae0efc6c2e7b1fc502cbe25def8f661b7bc"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.2+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "7c82e6a6cd34e9d935e9aa4051b66c6ff3af59ba"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.80.2+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "ebd18c326fa6cee1efb7da9a3b45cf69da2ed4d9"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.11.2"

[[deps.HarfBuzz_ICU_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "HarfBuzz_jll", "ICU_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "6ccbc4fdf65c8197738c2d68cc55b74b19c97ac2"
uuid = "655565e8-fb53-5cb3-b0cd-aec1ca0647ea"
version = "2.8.1+0"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HerbConstraints]]
deps = ["DataStructures", "HerbCore", "HerbGrammar", "MLStyle"]
git-tree-sha1 = "2e54da1d19119847b242d1ceda212b180cca36a9"
uuid = "1fa96474-3206-4513-b4fa-23913f296dfc"
version = "0.2.2"

[[deps.HerbCore]]
git-tree-sha1 = "923877c2715b8166d7ba9f9be2136d70eed87725"
uuid = "2b23ba43-8213-43cb-b5ea-38c12b45bd45"
version = "0.3.0"

[[deps.HerbGrammar]]
deps = ["AbstractTrees", "DataStructures", "HerbCore", "Serialization", "TreeView"]
git-tree-sha1 = "b4cbf9712dbb3ab281ff4ed517d3cd6bc12f3078"
uuid = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"
version = "0.3.0"

[[deps.HerbInterpret]]
deps = ["HerbCore", "HerbGrammar", "HerbSpecification"]
git-tree-sha1 = "9e19b4ee5f29eb8bb9b1049524728b38e878eca2"
uuid = "5bbddadd-02c5-4713-84b8-97364418cca7"
version = "0.1.3"

[[deps.HerbSearch]]
deps = ["DataStructures", "HerbConstraints", "HerbCore", "HerbGrammar", "HerbInterpret", "HerbSpecification", "Logging", "MLStyle", "Random", "StatsBase"]
git-tree-sha1 = "472e3f427c148f334dde3837b0bb1549897ed00a"
uuid = "3008d8e8-f9aa-438a-92ed-26e9c7b4829f"
version = "0.3.0"

[[deps.HerbSpecification]]
git-tree-sha1 = "5385b81e40c3cd62aeea591319896148036863c9"
uuid = "6d54aada-062f-46d8-85cf-a1ceaf058a06"
version = "0.1.0"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.ICU_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "20b6765a3016e1fca0c9c93c80d50061b94218b7"
uuid = "a51ab1cf-af8e-5615-a023-bc2c838bba6b"
version = "69.1.0+0"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "8b72179abc660bfab5e28472e019392b97d0985c"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.4"

[[deps.Inflate]]
git-tree-sha1 = "d1b1b796e47d94588b3757fe84fbf65a5ec4a80d"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c84a835e1a09b289ffcd2271bf2a337bbdda6637"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.0.3+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d986ce2d884d49126836ea94ed5bfb0f12679713"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "15.0.7+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "70c5da094887fd2cae843b8db33920bac4b6f07d"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.2+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll"]
git-tree-sha1 = "9fd170c4bbfd8b935fdc5f8b7aa33532c991a673"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.11+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fbb1f2bef882392312feb1ede3615ddc1e9b99ed"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.49.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f9557a255370125b405568f9767d6d195822a175"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0c4f9c4f1a50d8f35048fa0532dabbadf702f81e"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.40.1+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "5ee6203157c120d79034c748a2acba45b82b8807"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.40.1+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LittleCMS_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg"]
git-tree-sha1 = "110897e7db2d6836be22c18bffd9422218ee6284"
uuid = "d3a379c0-f9a3-5b72-a4c0-6bf4d2e8af0f"
version = "2.12.0+0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "18144f3e9cbe9b15b070288eef858f71b291ce37"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.27"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MLStyle]]
git-tree-sha1 = "bc38dff0548128765760c79eb7388a4b37fae2c8"
uuid = "d8e11817-5142-5d16-987a-aa16d5891078"
version = "0.4.17"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "2fa9ee3e63fd3a4f7a9a4f4744a52f4856de82df"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.13"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.OpenJpeg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libtiff_jll", "LittleCMS_jll", "Pkg", "libpng_jll"]
git-tree-sha1 = "76374b6e7f632c130e78100b166e5a48464256f8"
uuid = "643b3616-a352-519d-856d-80112ee9badc"
version = "2.4.0+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a12e56c72edee3ce6b96667745e6cbbe5498f200"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.23+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "35621f10a7531bc8fa58f74610b1bfb70a3cfc6b"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.43.4+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "ab55ee1510ad2af0ff674dbcced5e94921f867a9"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.59"

[[deps.Poppler_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "OpenJpeg_jll", "Pkg", "libpng_jll"]
git-tree-sha1 = "02148a0cb2532f22c0589ceb75c110e168fb3d1f"
uuid = "9c32591e-4766-534b-9725-b71a8799265b"
version = "21.9.0+0"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "eeafab08ae20c62c44c8399ccb9354a04b80db50"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.7"

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

    [deps.StaticArrays.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "192954ef1208c7019899fbf8049e717f92959682"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.3"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "5cf7606d6cef84b543b483848d4ae08ad9832b21"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.3"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TikzGraphs]]
deps = ["Graphs", "LaTeXStrings", "TikzPictures"]
git-tree-sha1 = "e8f41ed9a2cabf6699d9906c195bab1f773d4ca7"
uuid = "b4f28e30-c73f-5eaf-a395-8a9db949a742"
version = "1.4.0"

[[deps.TikzPictures]]
deps = ["LaTeXStrings", "Poppler_jll", "Requires", "tectonic_jll"]
git-tree-sha1 = "79e2d29b216ef24a0f4f905532b900dcf529aa06"
uuid = "37f6aa50-8035-52d0-81c2-5a1d08754b2d"
version = "3.5.0"

[[deps.TreeView]]
deps = ["CommonSubexpressions", "Graphs", "MacroTools", "TikzGraphs"]
git-tree-sha1 = "41ddcefb625f2ab0f4d9f2081c2da1af2ccbbf8b"
uuid = "39424ebd-4cf3-5550-a685-96706a953f40"
version = "0.5.1"

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "d9717ce3518dc68a99e6b96300813760d887a01d"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.1+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "a54ee957f4c86b526460a720dbc882fa5edcbefc"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.41+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "afead5aba5aa507ad5a3bf01f58f82c8d1403495"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6035850dcc70518ca32f012e46015b9beeda49d8"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.11+0"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "34d526d318358a859d7de23da945578e8e8727b7"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.4+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "d2d1a5c49fae4ba39983f63de6afcbea47194e85"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.6+0"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "47e45cd78224c53109495b3e324df0c37bb61fbe"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.11+0"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8fdda4c692503d44d04a0603d9ac0982054635f9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "bcd466676fef0878338c61e655629fa7bbc69d8e"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e92a1a012a10506618f10b7047e478403a046c77"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e678132f07ddb5bfa46857f0d7620fb9be675d3b"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.6+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "d7015d2e18a5fd9a4f47de711837e980519781a4"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.43+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.tectonic_jll]]
deps = ["Artifacts", "Fontconfig_jll", "FreeType2_jll", "Graphite2_jll", "HarfBuzz_ICU_jll", "HarfBuzz_jll", "ICU_jll", "JLLWrappers", "Libdl", "OpenSSL_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "54867b00af20c70b52a1f9c00043864d8b926a21"
uuid = "d7dd28d6-a5e6-559c-9131-7eb760cdacc5"
version = "0.13.1+0"
"""

# ╔═╡ Cell order:
# ╟─dddca175-3d88-45ce-90da-575c0ba38175
# ╠═a93d954d-0f09-4b6d-a3a5-62bfe39681e2
# ╠═6ab37bbc-73e2-4d9a-a8b2-e715a0b61c8f
# ╠═c4441fa4-09ec-4b81-9681-b13b93a9c9c0
# ╟─67931820-0f43-41e1-898e-5b5bd55e30d1
# ╠═e41c61a4-0b2c-46da-8f7b-fe6dc529c544
# ╟─9ad0a92a-10d5-458a-8f05-9011c8553609
# ╠═65317911-bc92-4b84-9744-ed784adcab4a
# ╟─e9c6bc00-21f5-4a99-8bec-63cf2156c233
# ╠═338f19f1-3a62-4462-b8dc-24424d7644f2
# ╠═542cd47e-74cd-4b6f-acc9-bf524222e583
# ╠═a6fb2e91-b73a-4032-930f-d884abd539e2
# ╠═4b49f206-970e-47d2-af65-336ba65b1019
# ╟─35405357-179b-4e77-9bdc-edf5a550b36d
# ╠═3954dd49-07a2-4ec2-91b4-9c9596d5c264
# ╠═9892e91b-9115-4520-9637-f8d7c8905825
# ╠═a4e58bbc-7c14-4fce-b35d-688b56e0eb61
# ╠═9fb40ceb-8d41-491b-8941-20a8b240eb82
# ╠═94e0d676-a9c7-4291-8696-15301e541c30
# ╠═a4a7daed-f89b-44ad-8787-9199c05bf046
# ╠═4821fd3a-ff2d-4991-99ad-76608d11b1da
# ╠═8d91b2e3-30b5-4ea2-bd3f-3055bb6d1d5a
# ╠═52332fa2-7ea7-4226-9460-e0bbc905c619
# ╟─c26fea48-f812-4f24-bb8c-680e14a55df7
# ╠═57f5face-d9d5-441a-8e0e-6ef6319fc178
# ╟─9b4b21e0-dc6a-43ae-a511-79988ee99001
# ╠═3af650d9-19c6-4351-920d-d2361091f628
# ╟─d3ff497e-d2c2-4df6-8e4c-cdca70fd0677
# ╠═da7f326c-f0d5-4837-ac9a-5bcad604566e
# ╟─0020b79a-6352-4e2d-93f6-2a1d7b03ae2c
# ╠═789150a8-862c-48c3-88b8-710b81ab34cf
# ╟─243165be-a9d2-484d-8046-811a2b0ba139
# ╠═3d01c6f1-80a6-4904-97e2-775170e97bbf
# ╟─168c71bf-ce5b-4ab3-b29a-5996981c42a5
# ╠═a4b522cf-78f0-4d44-88c8-82dd0cdbf952
# ╠═f313edb9-8fd9-4d78-88cd-89226f5c769d
# ╟─0da9053a-959b-471e-8918-662ec63da71c
# ╠═0a30fb40-cd45-4661-a501-ae8e45f1e07e
# ╟─700270ea-90bd-474b-91d9-0e5ed329776a
# ╠═8731f312-bfcf-4f6c-86fa-60014dc146d6
# ╠═46ca65d1-d876-4abc-a562-8d266bad195f
# ╟─599194a8-3f47-4917-9143-a5fe0d43029f
# ╠═cb5935ed-d89b-4e25-9243-d201daf18e78
# ╠═d0c3742e-23e5-4ca1-9e83-b6d1e8a7cded
# ╟─5df0ba53-b528-4baf-9980-cafe5d73f9dd
# ╠═a434645b-d592-4162-a8b4-b4b04cea30a9
# ╟─38cd9032-27c0-4179-a536-ce59a42ff16a
# ╠═f8415d48-a51d-4845-8425-fd61ed79c06e
# ╟─7f88bf4f-d82c-4e5a-a9eb-93870954c79e
# ╟─53598f8f-9973-4cad-af0c-280f5531bb21
# ╠═bc971069-08c4-493c-a917-8092493d3233
# ╠═61a60c9c-36cf-4e86-b697-748b3524d3b4
# ╠═a5b17c81-b667-4b1c-ab15-ddf1a162683b
# ╠═e41feac7-6de6-4223-8a21-341b85da52c0
# ╠═1c4db74a-4caa-4ce5-815f-b631365c5129
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
