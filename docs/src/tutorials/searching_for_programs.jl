### A Pluto.jl notebook ###
# v0.19.35

using Markdown
using InteractiveUtils

# ╔═╡ a8a9228c-9826-11ee-2121-0f8a50830605
# ╠═╡ show_logs = false
begin
	import Pkg
    # activate a temporary environment
    Pkg.activate(mktempdir())
    Pkg.add([
        Pkg.PackageSpec(name="Herb"),
		Pkg.PackageSpec(name="HerbSearch", rev="allow-module-choice-symbol-tables"),
		# Need dev branch for now for hole-aware rulenode2expr
		Pkg.PackageSpec(name="HerbGrammar", rev="dev"),
		Pkg.PackageSpec(name="BenchmarkTools")
    ])
	using Herb, HerbSearch, HerbGrammar, BenchmarkTools
end

# ╔═╡ d7af800b-7bde-4e09-8996-80aeee3358da
md"""
# Searching for Programs

Given a grammar and some examples, how do we found a program? Using `HerbSearch.jl`, of course. What search approaches does the package provide?

Currently, there are are two categories of search available: brute force, and stochastic.

## Brute Force
Under the brute force category, there are 2 approaches
- Breadth-first enumeration
- Depth-first enumeration
"""

# ╔═╡ 86f0c94a-b07a-4c9d-a201-5a275fb4b61b
md"""
### Problem Definition

Our running example for this document will be a string transformation problem borrowed from [duet's benchmarks](https://github.com/wslee/duet/blob/3f0eced782f8169e73b06129422e69156c13ac05/tests/string/35016216.sl)[^1] task with the following grammar:
"""

# ╔═╡ 8fb5b9fe-f6f7-42a6-b531-8632a98d8d64
begin
	function replace_first(regexp, templ, s)
		replace(s, regexp, templ; count=1)
	end
	
	function get_char_at(string_to_query, index)
		string(string_to_query[index])
	end

	function int_to_string(integer)
		string(integer)
	end

	StringFunctions = @__MODULE__
end;

# ╔═╡ 9c64b12c-4137-404c-8613-55d6b2d88c80
gₛ = Herb.@cfgrammar begin
	NTString = s1 | s2 | "" | " " | "C0"
	NTString = NTString * NTString
	NTString = replace_first(NTString, NTString, NTString)
	NTString = get_char_at(NTString, NTInt)
	NTString = int_to_string(NTInt)
	NTString = NTBool ? NTString : NTString
	NTString = SubString(NTString, Int, Int)
	NTInt = 1 | 0 | -1
	NTInt = NTInt + NTInt
	NTInt = NTInt - NTInt
	NTInt = length(NTString)
	NTInt = parse(Int, NTString)
	NTInt = NTBool ? NTInt : NTInt
	NTInt = findnext(NTString, NTString, NTInt)
	NTBool = true | false
	NTBool = NTInt == NTInt
	NTBool = startswith(NTString, NTString)
	NTBool = endswith(NTString, NTString)
	NTBool = contains(NTString, NTString)
end;

# ╔═╡ e01ed714-fa60-417e-9dc7-a3ec76a78b06
md"""
Now we define the I/O examples.
"""

# ╔═╡ 11017e7d-4d3b-474f-874e-bb93754d9c0c
problem = Herb.Problem([
	Herb.IOExample(Dict(:s1 => "C0abc", :s2 => "def"), "C0abc"),
	Herb.IOExample(Dict(:s1 => "aabc", :s2 => "def"), "def"),
	Herb.IOExample(Dict(:s1 => "C0dd", :s2 => "qwe"), "C0dd"),
	Herb.IOExample(Dict(:s1 => "dd", :s2 => "qwe"), "qwe"),
	Herb.IOExample(Dict(:s1 => "ddC0", :s2 => "qwe"), "qwe"),
]);

# ╔═╡ 8b71c312-65f1-4641-9094-5b15e6ccfbaf
md"""
A solution should look like the following (or be functionally equivalent):
"""

# ╔═╡ f1fd0b19-5c10-41f9-a107-55a6a4ed05d9
function solution(s1, s2)
	if startswith(s1, "C0")
		s1
	else
		s2
	end
end;

# ╔═╡ c25bae65-4f4b-49e8-a32e-1809bc579638
[rulenode2expr(prog, gₛ) for prog in get_bfs_enumerator(gₛ, 4, 6, :NTString)]

# ╔═╡ c3d86a1d-3620-404f-b511-1658e1d1a5c3
@btime bfs_solution = Herb.search(gₛ, problem, :NTString, max_depth=4, max_size=6, enumerator=get_bfs_enumerator, allow_evaluation_errors=true, mod=StringFunctions)

# ╔═╡ 37588131-c86b-49a5-aba7-186b18fe7a3f
@btime dfs_solution = Herb.search(gₛ, problem, :NTString, max_depth=4, max_size=6, enumerator=get_dfs_enumerator, allow_evaluation_errors=true, mod=StringFunctions)

# ╔═╡ e09802be-4744-4bad-a915-a5e7434b2650
md"""
[^1]: Woosuk Lee. 2021. Combining the top-down propagation and bottom-up enumeration for inductive program synthesis. Proc. ACM Program. Lang. 5, POPL, Article 54 (January 2021), 28 pages. https://doi.org/10.1145/3434335
"""

# ╔═╡ Cell order:
# ╟─d7af800b-7bde-4e09-8996-80aeee3358da
# ╠═a8a9228c-9826-11ee-2121-0f8a50830605
# ╟─86f0c94a-b07a-4c9d-a201-5a275fb4b61b
# ╟─8fb5b9fe-f6f7-42a6-b531-8632a98d8d64
# ╠═9c64b12c-4137-404c-8613-55d6b2d88c80
# ╟─e01ed714-fa60-417e-9dc7-a3ec76a78b06
# ╠═11017e7d-4d3b-474f-874e-bb93754d9c0c
# ╟─8b71c312-65f1-4641-9094-5b15e6ccfbaf
# ╠═f1fd0b19-5c10-41f9-a107-55a6a4ed05d9
# ╠═c25bae65-4f4b-49e8-a32e-1809bc579638
# ╠═c3d86a1d-3620-404f-b511-1658e1d1a5c3
# ╠═37588131-c86b-49a5-aba7-186b18fe7a3f
# ╟─e09802be-4744-4bad-a915-a5e7434b2650
