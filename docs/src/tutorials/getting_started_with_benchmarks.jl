### A Pluto.jl notebook ###
# v1.0.1

using Markdown
using InteractiveUtils

# ╔═╡ 43a23fc5-cbc6-40cd-8b0d-2ae06ee9336a
begin
	import Pkg
	Pkg.activate(Base.current_project())
	Pkg.add(url="https://github.com/Herb-AI/HerbBenchmarks.jl.git")
	Pkg.instantiate()
end

# ╔═╡ c5cb3782-c9af-4cf5-9e28-e1892c6442a2
using HerbBenchmarks, Herb

# ╔═╡ c5509a19-43bc-44d3-baa9-9af83717b6e6
md"""
# Getting started with HerbBenchmarks

In the domain of program synthesis, multiple benchmarks are used to evaluate the performance of new techniques. To make running them accessible and quick with Herb, we have set up [HerbBenchmarks.jl](https://github.com/Herb-AI/HerbBenchmarks.jl). 
"""

# ╔═╡ 864bc658-9612-4439-9024-74668ba3f971
md"""
### Setup

As always, we need to activate the environment we want to use. For the purpose of this demonstration, we explicitly add HerbBenchmarks, but this only needs to be run once in the environment, not every use. Note that since it is not in the registry, we need to add it using the GitHub URL.
"""

# ╔═╡ 75b0e996-3869-42f1-b2bc-a063eca4af0c
md"""
In addition to HerbBenchmarks, we will import Herb so we can demonstrate its use on the benchmarks.
"""

# ╔═╡ 57129cd2-b884-4d0a-91b7-05c34a97e207
md"""
### Choosing a Benchmark

To see what benchmarks are available, you can look at the [HerbBenchmarks.jl](https://github.com/Herb-AI/HerbBenchmarks.jl) repository, in the `src/data` folder. There, each repository represents a benchmark. For each benchmark, we have the following files:

- `README.dm`: A short description.
- `citation.bib`: A BibTex file with the source.
- `data.jl` file(s): Lists the problems, each a set of input-output examples.
- `grammar(s).jl`: Including a common grammar for all problems, or a grammar for each problem.
- `<type>_primitives/functions.jl`: Containing the implementation of the functions used in the grammar. 
- `<bench_name>.jl`: Defining the module with all the functionalities we need to run the benchmark.

In this tutorial, we will focus on the `SyGuS/PBE_SLIA_Track_2019` benchmark (Note that SyGuS has multiple tracks, each operating as an independent benchmark). You can start by taking a quick look at each of the files above to get a sense of what we have at our disposal. 

Now, we can import the benchmark we choose. Note that importing only the benchmark we want, without `using HerbBenchmarks`, will not work, since we also need the shared functionalities defined in HerbBenchmarks itself.
"""

# ╔═╡ 8eb51516-19d5-4a24-ab4a-032039008a60
import HerbBenchmarks.PBE_SLIA_Track_2019 as SLIA

# ╔═╡ 7a94562f-1111-4bb6-9537-00d1b0cb2568
md"""
### Accessing the Benchmark

Usually, we would want to iterate over all the problems and their corresponding grammars. Lucky for us, there is a function just for that!
"""

# ╔═╡ 90f2a875-6590-4243-9f6c-05fce0639980
PG_pairs = get_all_problem_grammar_pairs(SLIA)

# ╔═╡ bb188450-f03b-4f84-823b-9b2af701a30f
md"""
Each pair has an identifier, a problem, and a grammar. We can look at the first 3 problems to see what we have. Each problem has a name and a spec. The spec is a list of examples, each with an input dictionary and an output value.
"""

# ╔═╡ f8f7a74f-5fa3-44d3-8d53-f10a6d4fcba3
begin
	function print_problem(problem)
		println("Problem: $(problem.name)")
		for i in eachindex(problem.spec)
			println("$i\tInputs: \n\t\t$(join(["$k => $v" for (k,v) in problem.spec[i].in], "\n\t\t"))")
			println("\tOutput:\n\t\t$(problem.spec[i].out)")
		end
		println("\n")
	end
	for pair in PG_pairs[1:3]
		println("Identifier: $(pair.identifier)\n")
		print_problem(pair.problem)
	end
end

# ╔═╡ d7f386bc-476f-4e3f-a5ff-482b5dda91f7
md"""
We can also fetch a specific pair by the identifier. We will also look at the grammar this time (Rules 3 and 4 are the empty string and a space, respectively). Can you guess what the solution to this problem is?
"""

# ╔═╡ 6499922d-68bd-42fa-8633-fdae441f0a0a
begin
	pair = get_problem_grammar_pair(SLIA, "19558979")
	println("Identifier: $(pair.identifier)\n")
	print_problem(pair.problem)
	println("Grammar:\n$(pair.grammar)")
end

# ╔═╡ 06f116be-40d0-4401-8c77-2b84f728caf3
md"""
### Solving the benchmark
Now that we know how to access the problems and grammars, we can try to solve them with a simple BFS, and see the result. We will demonstrate how to solve the problem we have just fetched. Note that all problems will have the `:Start` type conversion rule, to state the actual output type we want for this problem. Additionally, we need to pass the benchmark module that defines the grammar functions to the `synth` function, so that it can evaluate candidate solutions.
"""

# ╔═╡ 6cb9e0be-4e63-4733-9436-208f669af4d8
begin 
	grammar = pair.grammar
	problem = pair.problem
	iterator = BFSIterator(grammar, :Start, max_depth=3)
	solution, flag = synth(problem, iterator; mod=SLIA)
	println(flag)
	program = rulenode2expr(solution, grammar)
	println(program)
end

# ╔═╡ 37cfe0bf-3285-4610-ae4b-671a3d7277e0
md""" We found an `optimal_program`! And we can see that, as you might have expected, it is a simple `at` function. Now you can write yourself a loop over all the pairs, and solve each one.
"""

# ╔═╡ c248ecc9-100c-4664-b1b9-e2d05dcf43f1
md"""
### Running the Solution
Now that we have a solution to a problem, we might want to run the solution program on some (new) inputs. To do that, we have interpreters.
"""

# ╔═╡ c26c48c1-9dd0-4a5a-9a09-40a875c55473
begin
	interpret = SLIA.make_SLIA_interpreter(grammar)
	ex = problem.spec[1].in
	println("For the specified example:\n\t$(ex)\nThe output is:  \n\t$(interpret(solution, ex))")
	new_input = Dict{Symbol, Any}(:_arg_1 => "test_new_input", :_arg_2 => 7)
	println("For the new example:\n\t$(new_input)\nThe output is:  \n\t$(interpret(solution, new_input))")
end


# ╔═╡ ae41e649-d2d6-4bac-bbaa-ce4256420541
md"""
### Summery
We saw how to review the available benchmarks, access their problems, solve each, and interpret the solution on new inputs. Now you can pick your own benchmark and write a script that iterates over all the problems and compares your new synthesis ideas!
"""

# ╔═╡ Cell order:
# ╟─c5509a19-43bc-44d3-baa9-9af83717b6e6
# ╟─864bc658-9612-4439-9024-74668ba3f971
# ╠═43a23fc5-cbc6-40cd-8b0d-2ae06ee9336a
# ╟─75b0e996-3869-42f1-b2bc-a063eca4af0c
# ╠═c5cb3782-c9af-4cf5-9e28-e1892c6442a2
# ╠═57129cd2-b884-4d0a-91b7-05c34a97e207
# ╠═8eb51516-19d5-4a24-ab4a-032039008a60
# ╠═7a94562f-1111-4bb6-9537-00d1b0cb2568
# ╠═90f2a875-6590-4243-9f6c-05fce0639980
# ╟─bb188450-f03b-4f84-823b-9b2af701a30f
# ╠═f8f7a74f-5fa3-44d3-8d53-f10a6d4fcba3
# ╠═d7f386bc-476f-4e3f-a5ff-482b5dda91f7
# ╠═6499922d-68bd-42fa-8633-fdae441f0a0a
# ╠═06f116be-40d0-4401-8c77-2b84f728caf3
# ╠═6cb9e0be-4e63-4733-9436-208f669af4d8
# ╠═37cfe0bf-3285-4610-ae4b-671a3d7277e0
# ╠═c248ecc9-100c-4664-b1b9-e2d05dcf43f1
# ╠═c26c48c1-9dd0-4a5a-9a09-40a875c55473
# ╟─ae41e649-d2d6-4bac-bbaa-ce4256420541
