### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ 73ca98e1-9937-4ea7-a9bb-1a16aa67b5f8
begin
	import Pkg
	Pkg.activate(Base.current_project())
	Pkg.instantiate()
end

# ╔═╡ d52591c1-7544-4543-a4a1-2a1b94bd1d87
# hide
using PrettyTables

# ╔═╡ c0748da9-24da-4365-ba67-43bd593d5ea6
# hide
using Test

# ╔═╡ c4441fa4-09ec-4b81-9681-b13b93a9c9c0
using Herb

# ╔═╡ dddca175-3d88-45ce-90da-575c0ba38175
md"""
# Advanced Search Procedures in Herb.jl

[A more verbose getting started with Herb.jl]() described the concept of a program space and showed how to search it with Herb.jl, using a simple breadth-first-search (BFS) iterator for the search. 
This tutorial takes a closer look at advanced search procedures hat can be employed to find a solution program to a program synthesis problem. 

More specifically, you will learn about

- **Parameters** that can be specified and their effect on the search procedure.  
- **Deterministic search methods** BFS and DFS.
- **Stochastic search methods**, which introduce randomness to search the program space. We will look at Metropolis-Hastings, Very Large Scale Neighbourhood Search, Simulated Annealing and Genetic Search.
"""

# ╔═╡ 61cee94c-2481-4268-823b-ca596592b63c
md"""
Let's import all the Herb modules that we will use throughout the tutorial.
"""

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

Search procedures typically have some hyperparameters that you can configure.

### `max_depth`

`max_depth` controls the maximum depth of the program trees that are explored during the search, effectively limiting the size and complexity of the synthesized program. The parameter is configured as part of the iterator.

In the following example, we consider two different values for `max_depth`.
"""

# ╔═╡ 338f19f1-3a62-4462-b8dc-24424d7644f2
iterator_1 = BFSIterator(g_1, :Number, max_depth=3)

# ╔═╡ 542cd47e-74cd-4b6f-acc9-bf524222e583
iterator_2 = BFSIterator(g_1, :Number, max_depth=6)

# ╔═╡ 63e97576-1c34-464d-a106-d59d5fb1ee38
md"""
To see the effect `max_depth` has on the number of memory allocations made during the program synthesis process, we use the `@time` macro.  
"""

# ╔═╡ 7e251a07-0041-4dc2-ac09-94fb01075c03
md"""
Solution for max_depth = 3:
"""

# ╔═╡ a6fb2e91-b73a-4032-930f-d884abd539e2
solution_1 = @time synth(problem_1, iterator_1)

# ╔═╡ d44afab4-dca1-4507-ab4d-0d2573603fa7
rulenode2expr(solution_1[1], g_1)

# ╔═╡ d1b02aac-f93d-4643-98da-62eb74933e5b
md"""
Solution for max_depth = 6:
"""

# ╔═╡ e1d2cb58-5409-4eed-8ce1-9636e5ee2d1e
begin
	solution_2 = @time synth(problem_1, iterator_2)
	rulenode2expr(solution_2[1], g_1)
end

# ╔═╡ 58c1a904-4d87-43f7-bcc3-884a8663c1da
md"""
While increasing `max_depth` allows us to explore more complex and deeper program trees, which may lead to a better solution, it also requires more memory allocation and can increase the execution time. 
"""

# ╔═╡ 35405357-179b-4e77-9bdc-edf5a550b36d
md"""
### `max_enumerations`
`max_enumerations` defines the maximum number of candidate programs that can be evaluated before the search is terminated. 

Let's explore how many enumerations are necessary to solve our simple problem.
"""

# ╔═╡ 3954dd49-07a2-4ec2-91b4-9c9596d5c264
begin
	solutions = []
	times = []
	nodes = []
	iterations = []
	for i in range(1, 50)
		iterator = BFSIterator(g_1, :Number, max_depth=i)
		solution = @timed synth(problem_1, iterator)
		push!(times, solution.time)
		push!(nodes, solution[1][1])
		push!(solutions, rulenode2expr(solution[1][1], g_1))
		push!(iterations, i)
	end
       pretty_table(HTML, [iterations nodes solutions times], column_labels=[["Iteration", "RuleNode", "Program", "Duration"]])
end

# ╔═╡ 9892e91b-9115-4520-9637-f8d7c8905825
md"""
At `i = 3`, we observe that an optimal program is found. Increasing the number of enumerations beyond that does not affect the solution or the number of memory allocations. 
"""

# ╔═╡ a4e58bbc-7c14-4fce-b35d-688b56e0eb61
md"""
### `allow_evaluation_errors`

A final parameter we consider here is `allow_evaluation_errors`, which is `false` by default. When `true`, the search continues even if an exception occurs during the evaluation of a candidate program. This allows the search process to handle faulty candidate programs and explore other ones, instead of throwing an error and terminating prematurely.


We will use a new example to see the effect of `allow_evaluation_errors`. We begin defining a new simple grammar. We then create some input-output examples to specify the problem we want to solve. This time, we choose a problem that we cannot solve with the provided grammar. 
"""

# ╔═╡ 9fb40ceb-8d41-491b-8941-20a8b240eb82
g_2 = @csgrammar begin
	Number = 1
	List = []
	Index = List[Number]
end

# ╔═╡ 94e0d676-a9c7-4291-8696-15301e541c30
problem_2 = Problem([IOExample(Dict{Symbol,Any}(), x) for x ∈ 1:5])

# ╔═╡ a4a7daed-f89b-44ad-8787-9199c05bf046
iterator_3 = BFSIterator(g_2, :Index, max_depth=2)

# ╔═╡ 4821fd3a-ff2d-4991-99ad-76608d11b1da
Test.@test_throws HerbSearch.EvaluationError synth(problem_2, iterator_3)

# ╔═╡ b2eb08d7-3e53-46c5-84b1-e1fa0e07e291
md"""
As expected, an exception occurs during the synthesis process. Now we try the same again, with `allow_evaluation_errors=true`.
"""

# ╔═╡ 606070e1-83a7-4cca-a716-4fa459f78772
solution_4 = synth(problem_2, iterator_3, allow_evaluation_errors=true)

# ╔═╡ c262116e-138e-4133-a032-d2f50bfbf5bd
md""""This time we find a solution, although a suboptimal one."""

# ╔═╡ 9b4b21e0-dc6a-43ae-a511-79988ee99001
md"""
## Top-down search

Herb.jl provides already implemented, ready-to-use search methods. The core building block of the search is the program iterator, which represents a walk through the program space. All program iterators share the top-level abstract type `ProgramIterator`. For more information on iterators and how to customize them, see [this tutorial](https://herb-ai.github.io/Herb.jl/dev/tutorials/TopDown/).

First, we explore two fundamental deterministic top-down search algorithms: **breadth-first search (BFS)** and **depth-first search (DFS)**. Both algorithms are implemented using the abstract type `TopDownIterator`, which can be customized through the functions 
- `priority_function`
- `derivation_heuristic`
- `hole_heuristic`
"""

# ╔═╡ 115c02c9-ae0c-4623-a61d-831fc6ad55a2
md"""
First, we explore two fundamental deterministic top-down search algorithms: **breadth-first search (BFS)** and **depth-first search (DFS)**. Both algorithms are implemented using the abstract type `TopDownIterator`, which can be customized through the functions priority_function, derivation_heuristic, and hole_heuristic.

### Breadth-First Search

The `BFSIterator` enumerates all possible programs at a given depth before progressing to the next level, ensuring that trees are explored in increasing order of size. This guarantees that smaller programs are evaluated first, and larger, more complex ones are considered only after all smaller ones have been processed.

To explore `BFSIterator`, we define another very simple grammar.
"""

# ╔═╡ 3af650d9-19c6-4351-920d-d2361091f628
g_3 = @csgrammar begin
	    Real = 1 | 2
	    Real = Real * Real
end

# ╔═╡ 4cb08dba-aea5-4c31-998c-844d1fce8c81
md"""
Next, we define a `BFSIterator` with a `max_depth` of 2 and a `max_size` of infinite (which we approximate with the maximum value of `Int`), and a starting symbol of type `Real`. By default, `BFSIterator` uses the heuristic 'left-most first', i.e., the left-most child in the tree is always explored first.
"""

# ╔═╡ f2521a57-267e-4b49-9179-4e9c2e6bdec7
iterator_bfs = BFSIterator(g_3, :Real, max_depth=2, max_size=typemax(Int))

# ╔═╡ bf038215-1ecf-4e1c-a9be-e133e4497293
md"""
To see all possible solution programs the iterator explores, we use `collect`. It returs a list of the programs, ordered by increasing size and depth. 
"""

# ╔═╡ 6aec7358-225a-4764-9a36-da86234b6cf8
programs_bfs = collect(iterator_bfs)

# ╔═╡ d3ff497e-d2c2-4df6-8e4c-cdca70fd0677
md"""
Let's verify that the iterator returns the programs we expect (keep in mind we use a leftmost-first heuristic).
"""

# ╔═╡ 07b54acf-0c0d-40ac-ae18-fb26094b4aca
answer_programs = [
	RuleNode(1),
	RuleNode(2),
	RuleNode(3, [RuleNode(1), RuleNode(1)]),
	RuleNode(3, [RuleNode(1), RuleNode(2)]),
	RuleNode(3, [RuleNode(2), RuleNode(1)]),
	RuleNode(3, [RuleNode(2), RuleNode(2)])
]

# ╔═╡ a2ce4b5c-da9a-468a-8bf3-5a784e123266
rulenode_programs = [rulenode2expr(r, g_3) for r in answer_programs]

# ╔═╡ 9efb01cf-b190-4e3e-aa19-11499ba46489
found_all_programs = all(p ∈ programs_bfs for p ∈ answer_programs)

# ╔═╡ 0020b79a-6352-4e2d-93f6-2a1d7b03ae2c
md"""
### Depth-First Search

The `DFSIterator` explores one branch of the search tree at a time, fully traversing it unitl a correct program is found or the specified `max_depth` is reached. Only after completing the current branch, it proceeds to the next branch.

As before, we `collect` the candidate programs using the same grammar, but a `DFSIterator`. 
"""

# ╔═╡ db5be2c3-0b36-40b4-bf14-20e2c7063ad7
iterator_dfs = DFSIterator(g_3, :Real, max_depth=2, max_size=typemax(Int))

# ╔═╡ 4048ff37-e7d1-44ee-bfa3-aa058b6f53b6
programs_dfs = collect(iterator_dfs)

# ╔═╡ 243165be-a9d2-484d-8046-811a2b0ba139
md"""
`DFSIterator` also uses by default a **leftmost-first** heuristic. If we want to use a **rightmost-first** heuristic instead, we can create our own iterator `DFSIteratorRightmost` as a sub-type of `TopDownIterator`, using the `@programiterator` macro. Then we implement the functions `priority_function` and `hole_heuristic`. Also see the tutorial [Top Down Iterator](https://herb-ai.github.io/Herb.jl/dev/tutorials/TopDown/) for how to build iterators is Herb.jl. 
"""

# ╔═╡ 4b97602a-5226-429f-86ea-8ecac3c807fa
@programiterator DFSIteratorRightmost() <: TopDownIterator

# ╔═╡ ed198b79-1b95-4531-b148-c1037cfdacf4
md"""
By default, `priority_function` for a `TopDownIterator` is that of a BFS iterator. Hence, we need to provide a new implementation. 
"""

# ╔═╡ 75b1abfd-19ed-43f5-ac65-f8ffde76c581
function priority_function(
    ::DFSIteratorRightmost, 
    ::AbstractGrammar, 
    ::AbstractRuleNode, 
    parent_value::Union{Real, Tuple{Vararg{Real}}},
    isrequeued::Bool
)
    if isrequeued
        return parent_value;
    end
    return parent_value - 1;
end

# ╔═╡ 7480d1e4-e417-4d87-80b7-513a098da70e
md"""
Next, we need to implement the `hole_heuristic` to be rightmost-first.
"""

# ╔═╡ 7e2af72d-b71c-4234-9bca-cb9a90732a91
function hole_heuristic(::DFSIteratorRightmost, node::AbstractRuleNode, max_depth::Int)::Union{ExpandFailureReason, HoleReference}
    return heuristic_rightmost(node, max_depth);
end

# ╔═╡ 00d05a7e-ca79-4d6b-828d-b24ef1cb80a2
iteratordfs_rightmost = DFSIteratorRightmost(g_3, :Real, max_depth=2, max_size=typemax(Int))

# ╔═╡ e0e8042d-ae41-4046-ab4f-5954a0d1cfb7
programs_dfs_rightmost = collect(iteratordfs_rightmost)

# ╔═╡ 02010940-df9f-4847-b0be-0bc9c6bb2ad4
md"""
We observe that the order of programs has changed. We can also test if both DFS iterators return the same programs:
"""

# ╔═╡ f5edcb4d-da72-4eeb-b55e-0ace1697133a
Set(programs_dfs)==Set(programs_dfs_rightmost)

# ╔═╡ 168c71bf-ce5b-4ab3-b29a-5996981c42a5
md"""
## Stochastic search

While deterministic search methods explore the search space in a predictable way, stochastic ones introduce randomness to allow for more flexibility.

In this section, we will look at the stochastic search algorithms: Metropolis-Hastings (MH), Very Large Scale Neighbourhood Search (VLSNS), and Simulated Annealing (SA). In Herb.jl, all of these search methodsthe share a common supertype `StochasticSearchIterator`, which defines the following fields
 - `examples` 
 - `cost_function`
 - `initial_temperature` 
 - `evaluation_function`.

They are customized by overriding the functions `neighbourhood`, `propose`, `accept` and `temperature` as required.

We start with a simple grammar and a helper function to create the input-output examples for the problem we want to solve.
"""

# ╔═╡ a4b522cf-78f0-4d44-88c8-82dd0cdbf952
g_4 = @csgrammar begin
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

# ╔═╡ 8e75ec35-94dc-4292-ab36-83731b3b9318
md"""
Throughout the stochastic search examples, we will use mean-squared-error as cost function. The cost function helps to guide the search by evaluating how well a candidate program solves the given task. This is used to decide whether a proposed program should be accepted or rejected.
"""

# ╔═╡ eebb9554-b657-4be3-aecf-c0869a2b38fa
cost_function = mean_squared_error

# ╔═╡ 0da9053a-959b-471e-8918-662ec63da71c
md"""
### Metropolis-Hastings

Metropolis-Hastings (MH) is a method to produce samples from a distribution that may otherwise be difficult to sample. In the context of program synthesis, we sample from a distribution of programs defined by the grammar. 

For more information on MH, see for example [this webpage](https://stephens999.github.io/fiveMinuteStats/MH_intro.html).

To illustrate MH, we use a simple arithmetic example.
"""

# ╔═╡ 4df84c71-99b5-487f-9db5-c048c0c74151
e_mh = x -> x * x + 4

# ╔═╡ afe1872c-6641-4fa0-a53e-50c6b4a712ee
problem_mh, examples_mh = create_problem(e_mh)

# ╔═╡ 69e91ae9-8475-47dd-826e-8c229faa11e8
md"""
Run the following code block to define the iterator and perform the program synthesis multiple times. Since the search process is stochastic, you will likely see different solution programs with each run.
"""

# ╔═╡ 0a30fb40-cd45-4661-a501-ae8e45f1e07e
begin
	rules = []
	programs = []
	iters = []
	for i in range(1, 3)
		iterator_mh = MHSearchIterator(g_4, :X, examples_mh, cost_function, max_depth=3) 
		program_mh = synth(problem_mh, iterator_mh)
		push!(rules, program_mh[1])
		push!(programs, rulenode2expr(program_mh[1], g_4))
		push!(iters, i)
	end
       pretty_table(HTML, [iters rules programs], column_labels=[["Run", "RuleNode", "Program"]])
end

# ╔═╡ 700270ea-90bd-474b-91d9-0e5ed329776a
md"""
### Very Large Scale Neighbourhood Search 

The second stochastic search method we consider is Very Large Scale Neighbourhood Search (VLSN). In each iteration, the algorithm searches the neighbourhood of the current candidate program for a local optimum, aiming to find a better candidate solution.

For more information, see [this article](https://backend.orbit.dtu.dk/ws/portalfiles/portal/5293785/Pisinger.pdf).

Given the same grammar as before, we can try it with some simple examples.
"""

# ╔═╡ e6e5c63b-34e8-40d6-bc12-bd31f40b4b16
e_vlsn = x -> 10

# ╔═╡ 2397f65f-e6b4-4f11-bf66-83440c58b688
problem_vlsn1, examples_vlsn1 = create_problem(e_vlsn)

# ╔═╡ 7c738d7b-bf05-40c7-b3b7-1512fbae7299
iterator_vlsn1 = VLSNSearchIterator(g_4, :X, examples_vlsn1, cost_function, max_depth=2) 

# ╔═╡ 33af905e-e8ca-425d-9805-eb02bec7c26b
program_vlsn1 = synth(problem_vlsn1, iterator_vlsn1)

# ╔═╡ bea28b36-6613-4895-98f9-27dfd9e57b09
e_vlsn2 = x -> x

# ╔═╡ aa95cb5e-926d-4119-8d08-353f37a59039
problem_vlsn2, examples_vlsn2 = create_problem(e_vlsn2)

# ╔═╡ 285043ef-c295-400f-91c5-f3c6c69ac2bf
iterator_vlsn2 = VLSNSearchIterator(g_4, :X, examples_vlsn2, cost_function, max_depth=1) 

# ╔═╡ 36f0e0cf-c871-42c9-956e-054767cbf693
program_vlsn2 = synth(problem_vlsn2, iterator_vlsn2)

# ╔═╡ 599194a8-3f47-4917-9143-a5fe0d43029f
md"""
### Simulated Annealing

Simulated Annealing (SA) explores smaller, incremental changes to the candidate program in each iteration, gradually refining the solution. It is a variation of the hill-climbing algorithm: Instead of always selecting the best move, SA picks a random move. If the move improves the solution (i.e., the candidate program), it is accepted.

Occasionally, SA will accept a move that worsens the solution. This allows the algorithm to escape local optima and explore more of the solution space. However, this strategy follows a cooling (annealing) schedule: at the beginning (high temperature), the algorithm explores more broadly and is more likely to accept worse solutions. As the temperature decreases, it becomes more selective, accepting worse solutions less often.

For more information, see [this page](https://www.cs.cmu.edu/afs/cs.cmu.edu/project/learn-43/lib/photoz/.g/web/glossary/anneal.html).
"""

# ╔═╡ dd6aee87-cd96-4be1-b8fb-03fffee5ea43
md"""
We use the same example as for MH. SA additionally has the option to specify the `initial_temperature` for the annealing (default `initial_temperature=1`). Let's see what effect changing the temperature from 1 to 2 has on the solution program.   
"""

# ╔═╡ e25d115f-7549-4606-b96c-9ef700810f7b
problem_sa, examples_sa = create_problem(e_mh)

# ╔═╡ 94f2bd5e-e11e-42e7-9a3e-3c9d5ae43cd4
initial_temperature1 = 1

# ╔═╡ eb851d7b-803e-45f6-ad10-fa0bde78826a
iterator_sa1 = SASearchIterator(g_4, :X, examples_sa, cost_function, max_depth=3, initial_temperature = initial_temperature1) 

# ╔═╡ 73304e3f-05bf-4f0c-9acd-fc8afa87b460
program_sa1 = synth(problem_sa, iterator_sa1)

# ╔═╡ 07f11eb1-6b45-441a-a481-57628bad23ae
initial_temperature2 = 2

# ╔═╡ 4ff69f0a-6626-4593-b361-a2387eecc731
iterator_sa2 = SASearchIterator(g_4, :X, examples_sa, cost_function, max_depth=3, initial_temperature = initial_temperature2) 

# ╔═╡ 5df0ba53-b528-4baf-9980-cafe5d73f9dd
md"""
## Genetic Search

Genetic search is a type of evolutionary algorithm, which simulates the process of natural selection. It evolves a population of candidate programs through operations like mutation, crossover (recombination), and selection. Then, the fitness of each program is assessed (i.e., how well it satisfies the given specifications). Only the 'fittest' programs are selected for the next generation, thus gradually refining the population of candidate programs.

For more information, see [here](https://www.geeksforgeeks.org/genetic-algorithms/).

We show the example of finding a lambda function. Try varying the parameters of the genetic search to see what happens.
"""

# ╔═╡ 99ea1c20-ca2c-4d77-bc3b-06814db1d666
e_gs = x -> 3 * x * x + (x + 2)

# ╔═╡ d991edb9-2291-42a7-97ff-58c456515505
problem_gs, examples_gs = create_problem(e_gs)

# ╔═╡ 069591a3-b89b-4fc6-afba-2145e32852b7
iterator_gs = GeneticSearchIterator(g_4, :X, examples_gs, population_size = 10, mutation_probability = 0.8, maximum_initial_population_depth = 3) 

# ╔═╡ 5bef5754-d81b-4160-8ed6-396d02853d9a
begin
	program_gs, error_gs = synth(problem_gs, iterator_gs)
	rulenode2expr(program_gs, g_4)
end

# ╔═╡ Cell order:
# ╟─dddca175-3d88-45ce-90da-575c0ba38175
# ╟─d52591c1-7544-4543-a4a1-2a1b94bd1d87
# ╟─c0748da9-24da-4365-ba67-43bd593d5ea6
# ╟─61cee94c-2481-4268-823b-ca596592b63c
# ╠═73ca98e1-9937-4ea7-a9bb-1a16aa67b5f8
# ╠═c4441fa4-09ec-4b81-9681-b13b93a9c9c0
# ╟─67931820-0f43-41e1-898e-5b5bd55e30d1
# ╠═e41c61a4-0b2c-46da-8f7b-fe6dc529c544
# ╟─9ad0a92a-10d5-458a-8f05-9011c8553609
# ╠═65317911-bc92-4b84-9744-ed784adcab4a
# ╟─e9c6bc00-21f5-4a99-8bec-63cf2156c233
# ╠═338f19f1-3a62-4462-b8dc-24424d7644f2
# ╠═542cd47e-74cd-4b6f-acc9-bf524222e583
# ╟─63e97576-1c34-464d-a106-d59d5fb1ee38
# ╠═7e251a07-0041-4dc2-ac09-94fb01075c03
# ╠═a6fb2e91-b73a-4032-930f-d884abd539e2
# ╠═d44afab4-dca1-4507-ab4d-0d2573603fa7
# ╠═d1b02aac-f93d-4643-98da-62eb74933e5b
# ╠═e1d2cb58-5409-4eed-8ce1-9636e5ee2d1e
# ╟─58c1a904-4d87-43f7-bcc3-884a8663c1da
# ╟─35405357-179b-4e77-9bdc-edf5a550b36d
# ╠═3954dd49-07a2-4ec2-91b4-9c9596d5c264
# ╟─9892e91b-9115-4520-9637-f8d7c8905825
# ╟─a4e58bbc-7c14-4fce-b35d-688b56e0eb61
# ╠═9fb40ceb-8d41-491b-8941-20a8b240eb82
# ╠═94e0d676-a9c7-4291-8696-15301e541c30
# ╠═a4a7daed-f89b-44ad-8787-9199c05bf046
# ╠═4821fd3a-ff2d-4991-99ad-76608d11b1da
# ╟─b2eb08d7-3e53-46c5-84b1-e1fa0e07e291
# ╠═606070e1-83a7-4cca-a716-4fa459f78772
# ╟─c262116e-138e-4133-a032-d2f50bfbf5bd
# ╟─9b4b21e0-dc6a-43ae-a511-79988ee99001
# ╟─115c02c9-ae0c-4623-a61d-831fc6ad55a2
# ╠═3af650d9-19c6-4351-920d-d2361091f628
# ╟─4cb08dba-aea5-4c31-998c-844d1fce8c81
# ╠═f2521a57-267e-4b49-9179-4e9c2e6bdec7
# ╟─bf038215-1ecf-4e1c-a9be-e133e4497293
# ╠═6aec7358-225a-4764-9a36-da86234b6cf8
# ╟─d3ff497e-d2c2-4df6-8e4c-cdca70fd0677
# ╠═07b54acf-0c0d-40ac-ae18-fb26094b4aca
# ╠═a2ce4b5c-da9a-468a-8bf3-5a784e123266
# ╠═9efb01cf-b190-4e3e-aa19-11499ba46489
# ╟─0020b79a-6352-4e2d-93f6-2a1d7b03ae2c
# ╠═db5be2c3-0b36-40b4-bf14-20e2c7063ad7
# ╠═4048ff37-e7d1-44ee-bfa3-aa058b6f53b6
# ╟─243165be-a9d2-484d-8046-811a2b0ba139
# ╠═4b97602a-5226-429f-86ea-8ecac3c807fa
# ╟─ed198b79-1b95-4531-b148-c1037cfdacf4
# ╠═75b1abfd-19ed-43f5-ac65-f8ffde76c581
# ╟─7480d1e4-e417-4d87-80b7-513a098da70e
# ╠═7e2af72d-b71c-4234-9bca-cb9a90732a91
# ╠═00d05a7e-ca79-4d6b-828d-b24ef1cb80a2
# ╠═e0e8042d-ae41-4046-ab4f-5954a0d1cfb7
# ╟─02010940-df9f-4847-b0be-0bc9c6bb2ad4
# ╠═f5edcb4d-da72-4eeb-b55e-0ace1697133a
# ╟─168c71bf-ce5b-4ab3-b29a-5996981c42a5
# ╠═a4b522cf-78f0-4d44-88c8-82dd0cdbf952
# ╠═f313edb9-8fd9-4d78-88cd-89226f5c769d
# ╟─8e75ec35-94dc-4292-ab36-83731b3b9318
# ╠═eebb9554-b657-4be3-aecf-c0869a2b38fa
# ╟─0da9053a-959b-471e-8918-662ec63da71c
# ╠═4df84c71-99b5-487f-9db5-c048c0c74151
# ╠═afe1872c-6641-4fa0-a53e-50c6b4a712ee
# ╟─69e91ae9-8475-47dd-826e-8c229faa11e8
# ╠═0a30fb40-cd45-4661-a501-ae8e45f1e07e
# ╠═700270ea-90bd-474b-91d9-0e5ed329776a
# ╠═e6e5c63b-34e8-40d6-bc12-bd31f40b4b16
# ╠═2397f65f-e6b4-4f11-bf66-83440c58b688
# ╠═7c738d7b-bf05-40c7-b3b7-1512fbae7299
# ╠═33af905e-e8ca-425d-9805-eb02bec7c26b
# ╠═bea28b36-6613-4895-98f9-27dfd9e57b09
# ╠═aa95cb5e-926d-4119-8d08-353f37a59039
# ╠═285043ef-c295-400f-91c5-f3c6c69ac2bf
# ╠═36f0e0cf-c871-42c9-956e-054767cbf693
# ╟─599194a8-3f47-4917-9143-a5fe0d43029f
# ╟─dd6aee87-cd96-4be1-b8fb-03fffee5ea43
# ╠═e25d115f-7549-4606-b96c-9ef700810f7b
# ╠═94f2bd5e-e11e-42e7-9a3e-3c9d5ae43cd4
# ╠═eb851d7b-803e-45f6-ad10-fa0bde78826a
# ╠═73304e3f-05bf-4f0c-9acd-fc8afa87b460
# ╠═07f11eb1-6b45-441a-a481-57628bad23ae
# ╠═4ff69f0a-6626-4593-b361-a2387eecc731
# ╟─5df0ba53-b528-4baf-9980-cafe5d73f9dd
# ╠═99ea1c20-ca2c-4d77-bc3b-06814db1d666
# ╠═d991edb9-2291-42a7-97ff-58c456515505
# ╠═069591a3-b89b-4fc6-afba-2145e32852b7
# ╠═5bef5754-d81b-4160-8ed6-396d02853d9a
