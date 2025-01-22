### A Pluto.jl notebook ###
# v0.20.3

using Markdown
using InteractiveUtils

# ╔═╡ a93d954d-0f09-4b6d-a3a5-62bfe39681e2
# hide
using PlutoUI

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

# ╔═╡ 6ab37bbc-73e2-4d9a-a8b2-e715a0b61c8f
# hide
TableOfContents()

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
	pretty_table(HTML, [iterations nodes solutions times], header=["Iteration", "RuleNode", "Program", "Duration"])
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
	pretty_table(HTML, [iters rules programs], header=["Run", "RuleNode", "Program"])
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

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HerbConstraints = "1fa96474-3206-4513-b4fa-23913f296dfc"
HerbCore = "2b23ba43-8213-43cb-b5ea-38c12b45bd45"
HerbGrammar = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"
HerbInterpret = "5bbddadd-02c5-4713-84b8-97364418cca7"
HerbSearch = "3008d8e8-f9aa-438a-92ed-26e9c7b4829f"
HerbSpecification = "6d54aada-062f-46d8-85cf-a1ceaf058a06"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
PrettyTables = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[compat]
HerbConstraints = "~0.2.2"
HerbCore = "~0.3.0"
HerbGrammar = "~0.3.0"
HerbInterpret = "~0.1.3"
HerbSearch = "~0.3.0"
HerbSpecification = "~0.1.0"
PlutoUI = "~0.7.59"
PrettyTables = "~2.4.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.1"
manifest_format = "2.0"
project_hash = "edca5a73f01350950590d222b2bce4d0cb1a613d"

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
version = "1.1.2"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "d57bd3762d308bded22c3b82d033bff85f6195c6"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.4.0"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "8873e196c2eb87962a2048b3b8e08946535864a1"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+2"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "009060c9a6168704143100f36ab08f06c2af4642"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.2+1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.CommonSubexpressions]]
deps = ["MacroTools"]
git-tree-sha1 = "cda2cfaebb4be89c9084adaca7dd7333369715c5"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.1"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

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
version = "1.11.0"

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
git-tree-sha1 = "674ff0db93fffcd11a3573986e550d66cd4fd71f"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.80.5+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "1dc470db8b1131cfc7fb4c115de89fe391b9e780"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.12.0"

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
git-tree-sha1 = "98a4c7b30a8a752bb33bddc2475f6554602b588b"
uuid = "2b23ba43-8213-43cb-b5ea-38c12b45bd45"
version = "0.3.1"

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
git-tree-sha1 = "ce13a9a2b7970686ef4befc2e79c2e6f1a2c4dc6"
uuid = "6d54aada-062f-46d8-85cf-a1ceaf058a06"
version = "0.1.1"

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
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.Inflate]]
git-tree-sha1 = "d1b1b796e47d94588b3757fe84fbf65a5ec4a80d"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "be3dc50a92e5a386872a493a10050136d4703f9b"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.6.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "25ee0be4d43d0269027024d75a24c24d6c6e590c"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.0.4+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "78211fb6cbc872f77cad3fc0b6cf647d923f4929"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "18.1.7+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "854a9c268c43b77b0a27f22d7fab8d33cdb3a731"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.2+1"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll"]
git-tree-sha1 = "8be878062e0ffa2c3f67bb58a595375eda5de80b"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.11.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c6ce1e19f3aec9b59186bdf06cdf3c4fc5f5f3e6"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.50.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "61dfdba58e585066d8bce214c5a51eaa0539f269"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+1"

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
version = "1.11.0"

[[deps.LittleCMS_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg"]
git-tree-sha1 = "110897e7db2d6836be22c18bffd9422218ee6284"
uuid = "d3a379c0-f9a3-5b72-a4c0-6bf4d2e8af0f"
version = "2.12.0+0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "a2d09619db4e765091ee5c6ffe8872849de0feea"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.28"

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
version = "1.11.0"

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
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OpenJpeg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libtiff_jll", "LittleCMS_jll", "Pkg", "libpng_jll"]
git-tree-sha1 = "76374b6e7f632c130e78100b166e5a48464256f8"
uuid = "643b3616-a352-519d-856d-80112ee9badc"
version = "2.4.0+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ad31332567b189f508a3ea8957a2640b1147ab00"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.23+1"

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
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eba4810d5e6a01f612b948c9fa94f905b49087b0"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.60"

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

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "1101cd475833706e4d0e7b122218257178f48f34"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.4.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

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
version = "1.11.0"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"
version = "1.11.0"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.11.0"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "777657803913ffc7e8cc20f0fd04b634f871af8f"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.8"

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
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

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

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "a6b1675a536c5ad1a60e5a5153e1fee12eb146e3"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.4.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.7.0+0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "598cd7c1f68d1e205689b1c2fe65a9f85846f297"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

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
git-tree-sha1 = "7822b97e99a1672bfb1b49b668a6d46d58d8cbcb"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.9"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "6a451c6f33a176150f315726eba8b92fbfdb9ae7"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.4+0"

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
git-tree-sha1 = "555d1076590a6cc2fdee2ef1469451f872d8b41b"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.6+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "b70c870239dc3d7bc094eb2d6be9b73d27bef280"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.44+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

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
# ╟─a93d954d-0f09-4b6d-a3a5-62bfe39681e2
# ╟─6ab37bbc-73e2-4d9a-a8b2-e715a0b61c8f
# ╟─d52591c1-7544-4543-a4a1-2a1b94bd1d87
# ╟─c0748da9-24da-4365-ba67-43bd593d5ea6
# ╟─61cee94c-2481-4268-823b-ca596592b63c
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
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
