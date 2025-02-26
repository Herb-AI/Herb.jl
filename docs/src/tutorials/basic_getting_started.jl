### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

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
The problem is given now, let us search for a solution with `HerbSearch`. For now, we will just use the default parameters searching for a satisfying program over the grammar, given the problem and a starting symbol using
"

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

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Herb = "c09c6b7f-4f63-49de-90d9-97a3563c0f4a"

[compat]
Herb = "~0.4.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.4"
manifest_format = "2.0"
project_hash = "cc5379f7256e78eae462fcee129fe637f8be509a"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AutoHashEquals]]
git-tree-sha1 = "4ec6b48702dacc5994a835c1189831755e4e76ef"
uuid = "15f4f7f2-30c1-5605-9d31-71845cf9641f"
version = "2.2.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

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

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Herb]]
deps = ["HerbConstraints", "HerbCore", "HerbGrammar", "HerbInterpret", "HerbSearch", "HerbSpecification", "Reexport"]
git-tree-sha1 = "be2ac3fe4f378fa9f3c6ed3abf14515c2d6c6c97"
uuid = "c09c6b7f-4f63-49de-90d9-97a3563c0f4a"
version = "0.4.1"

[[deps.HerbConstraints]]
deps = ["DataStructures", "HerbCore", "HerbGrammar", "MLStyle"]
git-tree-sha1 = "3367f188d76fcf1c9fee626dc2a9110674f480a5"
uuid = "1fa96474-3206-4513-b4fa-23913f296dfc"
version = "0.2.5"

[[deps.HerbCore]]
deps = ["AbstractTrees"]
git-tree-sha1 = "7af906201c6d701957b9d061c58940a28bfa4b83"
uuid = "2b23ba43-8213-43cb-b5ea-38c12b45bd45"
version = "0.3.4"

[[deps.HerbGrammar]]
deps = ["HerbCore", "Serialization"]
git-tree-sha1 = "3c667987e8a27d9b697993fab68dfc602b3a18e6"
uuid = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"
version = "0.5.0"

[[deps.HerbInterpret]]
deps = ["HerbCore", "HerbGrammar", "HerbSpecification"]
git-tree-sha1 = "6dd2913b88e0cbd0bc5ed78e67d4d406df61ddda"
uuid = "5bbddadd-02c5-4713-84b8-97364418cca7"
version = "0.1.6"

[[deps.HerbSearch]]
deps = ["DataStructures", "HerbConstraints", "HerbCore", "HerbGrammar", "HerbInterpret", "HerbSpecification", "MLStyle", "Random", "StatsBase"]
git-tree-sha1 = "30a9bcb6b668dbaf175e53405a7998fa129609df"
uuid = "3008d8e8-f9aa-438a-92ed-26e9c7b4829f"
version = "0.4.2"

[[deps.HerbSpecification]]
deps = ["AutoHashEquals"]
git-tree-sha1 = "4a153a24694d4d91cf811d63581c9115087f06fc"
uuid = "6d54aada-062f-46d8-85cf-a1ceaf058a06"
version = "0.2.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IrrationalConstants]]
git-tree-sha1 = "e2222959fbc6c19554dc15174c81bf7bf3aa691c"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.4"

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

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.MLStyle]]
git-tree-sha1 = "bc38dff0548128765760c79eb7388a4b37fae2c8"
uuid = "d8e11817-5142-5d16-987a-aa16d5891078"
version = "0.4.17"

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

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.OrderedCollections]]
git-tree-sha1 = "cc4054e898b852042d7b503313f7ad03de99c3dd"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.PtrArrays]]
git-tree-sha1 = "1d36ef11a9aaf1e8b74dacc6a731dd1de8fd493d"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.3.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

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
deps = ["AliasTables", "DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "29321314c920c26684834965ec2ce0dacc9cf8e5"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.4"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"
"""

# ╔═╡ Cell order:
# ╟─0677e60e-d77c-4bda-ac8e-6ff8b21f0431
# ╠═0c1f68b7-a802-4d2a-b1a7-e4da11945907
# ╟─27e843c5-df97-4ede-9294-88cb3b5df748
# ╠═eec315e4-ae65-4d97-ac9e-8b31a6d3ad0e
# ╟─b55c696a-a421-462a-abfd-b8f2c652d4f0
# ╠═dc8926aa-91c1-4a04-ab8d-6820edc6db2b
# ╟─08cc1274-3ea2-4e21-891b-e4cca9281eeb
# ╠═2732bd85-4076-4530-99bf-9076a8811329
# ╠═01ce2ad4-ad00-41cf-afe3-757ae62ac4c6
# ╟─a94e49d4-a348-4af9-8236-f18dcbe7ef5c
# ╠═fb3e47bf-03f1-4eda-85ff-1897751c1d00
# ╠═4ce7545e-2f1c-40c3-9044-5092b66d3c3c
# ╟─b049977a-71d0-4e3e-b915-626aa5909bd6
# ╟─cccf503e-f36a-11ef-1697-3f13720272cf
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
