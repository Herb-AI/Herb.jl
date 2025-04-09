### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ 93b96839-9676-477b-aebb-e50d733a6719
md"""
# Defining Grammars in Herb.jl using HerbGrammar

The program space in Herb.jl is defined using a grammar. 
This notebook demonstrates how such a grammar can be created. 
There are multiple kinds of grammars, but they can all be defined in a very similar way.
"""

# ╔═╡ d863795b-5fea-4b69-8f63-e04352bb970a
md"""
### Setup
First, we import the necessary Herb packages.
"""

# ╔═╡ 84549502-876a-4ffc-8069-1ffc17622f9a
using Herb

# ╔═╡ 751e1119-fe59-41dc-8785-a3ed0a9cacb9
md"""
### Creating a simple grammar

This cell contains a very simple arithmetic grammar. 
The grammar is defined using the `@csgrammar` macro. 
This macro converts the grammar definition in the form of a Julia expression into Herb's internal grammar representation. 
Macro's are executed during compilation.
If you want to load a grammar during execution, have a look at the `HerbGrammar.expr2csgrammar` function.
"""

# ╔═╡ 1030a96d-b739-4232-820b-f21826512251
g₁ = HerbGrammar.@csgrammar begin
    Int = 1
    Int = 2
    Int = 3
    Int = Int * Int
    Int = Int + Int
end

# ╔═╡ 0224c914-3763-4c55-844c-e9aca430b377
md"""
Defining every integer one-by-one can be quite tedious. Therefore, it is also possible to use the following syntax that makes use of a Julia iterator:
"""

# ╔═╡ 4619b92e-2f9e-429f-9e9a-77b97be7edd1
g₂ = HerbGrammar.@csgrammar begin
    Int = |(0:9)
    Int = Int * Int
    Int = Int + Int
end

# ╔═╡ f8e82610-b0d0-4763-939d-aadc92336c52
md"""
You can do the same with lists:
"""

# ╔═╡ f4d34f0a-6c88-48db-84a0-ed3fb01fb7aa
g₃ = HerbGrammar.@csgrammar begin
    Int = |([0, 2, 4, 6, 8])
    Int = Int * Int
    Int = Int + Int
end

# ╔═╡ 8732f232-3069-4fb1-9b6a-0e24b8724451
md"""
Variables can also be added to the grammar by just using the variable name:
"""

# ╔═╡ b68090b2-0eed-4e4a-acdc-6df71747a46d
g₄ = HerbGrammar.@csgrammar begin
    Int = |(0:9)
    Int = Int * Int
    Int = Int + Int
    Int = x
end

# ╔═╡ 89e8ab14-7097-4088-937f-6453722da9d0
md"""
Grammars can also work with functions. 
After all, `+` and `*` are just infix operators for Julia's identically-named functions.
You can use functions that are provided by Julia, or functions that you wrote yourself:
"""

# ╔═╡ 26b9a050-c4b4-42a8-b1d7-e50fb98a7e8a
begin
	f(a) = a + 1
	
	g₅ = HerbGrammar.@csgrammar begin
	    Int = |(0:9)
	    Int = Int * Int
	    Int = Int + Int
	    Int = f(Int)
	    Int = x
	end
end

# ╔═╡ 7ebb2202-8aa1-4404-b1dd-ac1669f9a120
md"""
Similarly, we can also define the operator times (x) manually.
"""

# ╔═╡ 9351c7ab-a39f-4f47-a3ee-e1684e2b3c07
begin
	×(a, b) = a * b
	
	g₆ = HerbGrammar.@csgrammar begin
	    Int = |(0:9)
	    Int = a
	    Int = Int + Int
	    Int = Int × Int
	end
end

# ╔═╡ 3f44d67b-bd18-481e-bca8-bb4904f6b418
md"""
### Working with grammars

If you want to implement something using these grammars, it is useful to know about the functions that you can use to manipulate grammars and extract information. 
This section is not complete, but it aims to give an overview of the most important functions. 

It is recommended to also read up on [Julia metaprogramming](https://docs.julialang.org/en/v1/manual/metaprogramming/) if you are not already familiar with the concept.

One of the most important things about grammars is that each rule has an index associated with it:
"""

# ╔═╡ 58af16a2-7f23-4d06-8836-fb737788ada0
begin
	g₇ = HerbGrammar.@csgrammar begin
	    Int = |(0:9)
	    Int = Int + Int
	    Int = Int * Int
	    Int = x
	end
	
	collect(enumerate(g₇.rules))
end

# ╔═╡ 303894cd-a0c2-461c-a671-7330f75b338e
md"""
We can use this index to extract information from the grammar.
"""

# ╔═╡ 5c103ce3-0cb2-4004-ac44-50613a461153
md"""
### isterminal

`isterminal` returns `true` if a rule is terminal, i.e. it cannot be expanded. For example, rule 1 is terminal, but rule 11 is not, since it contains the non-terminal symbol `:Int`. 
"""

# ╔═╡ 38422e77-cfd8-4a2c-8cf2-f1b430f64ad1
HerbGrammar.isterminal(g₇, 1)

# ╔═╡ 112d4837-e646-4e24-84c8-771b9855aebf
HerbGrammar.isterminal(g₇, 11)

# ╔═╡ e8d4890b-db1c-4b74-8a6d-4388597cead8
md"""
### return_type

This function is rather obvious; it returns the non-terminal symbol that corresponds to a certain rule. The return type for all rules in our grammar is `:Int`.
"""

# ╔═╡ 842f6873-1f7f-4785-9be5-336dee828ad8
HerbGrammar.return_type(g₇, 11)

# ╔═╡ c894f9c1-d608-4a11-9146-ea4b83b40325
md"""
### child_types

`child_types` returns the types of the nonterminal children of a rule in a vector.
If you just want to know how many children a rule has, and not necessarily which types they have, you can use `nchildren`
"""

# ╔═╡ c4c058fb-28e6-4aa4-8609-5d0e9d29f42e
HerbGrammar.child_types(g₇, 11)

# ╔═╡ d17660c0-fe52-4b71-9f7e-c77533801e5b
HerbGrammar.nchildren(g₇, 11)

# ╔═╡ 681ac0f0-b207-48d1-9524-e2bb93f79717
md"""
### nonterminals

The `nonterminals` function can be used to obtain a list of all nonterminals in the grammar.
"""

# ╔═╡ df689c72-deeb-4d94-8c10-702c3621bcba
HerbGrammar.nonterminals(g₇)

# ╔═╡ 5374925a-46ef-49bc-b3b1-14a5afc5f523
md"""
### Adding rules

It is also possible to add rules to a grammar during execution. This can be done using the `add_rule!` function. The exclamation mark is a Julia convention and is appended to name if a function modifies its arguments (in our example the grammar).

A rule can be provided in the same syntax as is used in the grammar definition.
The rule should be of the `Expr` type, which is a built-in type for representing expressions. 
An easy way of creating `Expr` values in Julia is to encapsulate it in brackets and use a colon as prefix:
"""

# ╔═╡ d7f632bb-c3a5-4196-b4ce-9fc80ed24034
HerbGrammar.add_rule!(g₇, :(Int = Int - Int))

# ╔═╡ 44aa6111-2374-4261-8616-73925c320b34
md"""
### Removing rules

It is also possible to remove rules in Herb.jl, however, this is a bit more involved. 
As said before, rules have an index associated with them. 
The internal representation of programs that are defined by the grammar makes use of those indices for efficiency.
Blindly removing a rule would shift the indices of other rules, and this could mean that existing programs get a different meaning or become invalid. 

Therefore, there are two functions for removing rules:

- `remove_rule!` removes a rule from the grammar, but fills its place with a placeholder. Therefore, the indices stay the same, and only programs that use the removed rule become invalid.
- `cleanup_removed_rules!` removes all placeholders and shifts the indices of the other rules.

"""

# ╔═╡ f381e96a-a8c6-4ebd-adf2-e6da20ca63de
HerbGrammar.remove_rule!(g₇, 11)

# ╔═╡ 5e0cb560-2a27-4372-945b-4be44fca1fbc
HerbGrammar.cleanup_removed_rules!(g₇)

# ╔═╡ eb3bfde8-62c0-4497-b9cd-faba6ec9cf8d
md"""
## Context-sensitive grammars

Context-sensitive grammars introduce additional constraints compared to context-free grammars (like the simple grammar examples above).
As before, we use the `@csgrammar` macro:
"""

# ╔═╡ 112ce5fc-560d-438d-b58f-d52991a1651f
g₈ = HerbGrammar.@csgrammar begin
    Int = |(0:9)
    Int = Int + Int
    Int = Int * Int
    Int = x
end

# ╔═╡ 327fcddb-9bdc-4ae8-8908-86a0b0619639
md"""
Constraints can be added using the `addconstraint!` function, which takes a context-sensitive grammar and a constraint and adds the constraint to the grammar.

For example, we can add a `` constraint to enforce that the input symbol `x` (rule 13) appears at least once in the program, to avoid programs that are just a constant.  
"""

# ╔═╡ 2b23504e-8e2c-47c5-b9b8-07b7b0063d2e
HerbGrammar.addconstraint!(g₈, Contains(13))

# ╔═╡ 4fb800af-7ac7-45b0-a3a0-ce153c7eb464
md"""
There is a dedicated tutorial for constraints in Herb.jl and how to work with them.
"""

# ╔═╡ 85724067-ff56-40e2-99e5-e26698a4a444
md"""
### Probabilistic grammars

Herb.jl also supports probabilistic grammars. 
These grammars allow the user to assign a probability to each rule in the grammar.
A probabilistic grammar can be defined in a very similar way to a standard grammar, but has some slightly different syntax:
"""

# ╔═╡ 19ef2475-1ebd-4b73-af6b-d7079182f27a
begin
	g₉ = HerbGrammar.@pcsgrammar begin
	    0.4 : Int = |(0:9)
	    0.2 : Int = Int + Int
	    0.1 : Int = Int * Int
	    0.3 : Int = x
	end
	
	for r ∈ 1:length(g₃.rules)
	    p = HerbGrammar.probability(g₈, r)
	
	    println("$p : $r")
	end
end

# ╔═╡ 7f78d745-8b16-4308-9191-4dbe8bd11da9
md"""
The numbers before each rule represent the probability assigned to that rule.
The total probability for each return type should add up to 1.0.
If this isn't the case, Herb.jl will normalize the probabilities.

If a single line in the grammar definition represents multiple rules, such as `0.4 : Int = |(0:9)`, the probability will be evenly divided over all these rules.
"""

# ╔═╡ 1f0ef848-d9b0-414d-9e1a-82beb6633c02
md"""
## File writing

### Saving & loading context-free grammars

If you want to store a grammar on the disk, you can use the `store_csg`, `read_csg` and functions to store and read grammars respectively. 
The `store_csg` grammar can also be used to store probabilistic grammars. To read probabilistic grammars, use `read_pcsg`.
The stored grammar files can also be opened using a text editor to be modified, as long as the contents of the file doesn't violate the syntax for defining grammars.
"""

# ╔═╡ 9426a96a-43e3-458d-933e-44b36966db57
HerbGrammar.store_csg(g₇, "demo.txt")

# ╔═╡ 5ac3dfc3-54c0-438a-a3b9-d2d24309f532
HerbGrammar.read_csg("demo.txt")

# ╔═╡ fc5bd55a-3936-4b93-8f62-b2f708b83a4e
md"""
### Saving & loading context-sensitive grammars

Saving and loading context-sensitive grammars is very similar to how it is done with context-free grammars.
The only difference is that an additional file is created for the constraints. 
The file that contains the grammars can be edited and can also be read using the reader for context-free grammars.
The file that contains the constraints cannot be edited.
"""

# ╔═╡ 32f1afed-5ccf-4378-8f1d-14e293ff2c1a
HerbGrammar.store_csg( g₈, "demo.grammar", "demo.constraints")

# ╔═╡ c21e2aa6-55ba-4068-b127-d7b53c17eb45
g₈, g₈.constraints

# ╔═╡ 407f8c03-a0ec-4b23-ba2c-22de526becc8
g₁₀  = HerbGrammar.read_csg("demo.grammar", "demo.constraints")

# ╔═╡ ad351cf6-8f2b-4cd0-b207-1ecb53eb2e38
g₁₀, g₁₀.constraints

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HerbConstraints = "1fa96474-3206-4513-b4fa-23913f296dfc"
HerbGrammar = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"

[compat]
HerbConstraints = "~0.2.4"
HerbGrammar = "~0.5.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.2"
manifest_format = "2.0"
project_hash = "9de8bf1f46b443ee9eabd7d66473cb29d9736653"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

    [deps.Compat.weakdeps]
    Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.HerbConstraints]]
deps = ["DataStructures", "HerbCore", "HerbGrammar", "MLStyle"]
git-tree-sha1 = "a89c7d2ef3283b8feb846822505722a0a0c50a91"
uuid = "1fa96474-3206-4513-b4fa-23913f296dfc"
version = "0.2.4"

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

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.MLStyle]]
git-tree-sha1 = "bc38dff0548128765760c79eb7388a4b37fae2c8"
uuid = "d8e11817-5142-5d16-987a-aa16d5891078"
version = "0.4.17"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.OrderedCollections]]
git-tree-sha1 = "12f1439c4f986bb868acda6ea33ebc78e19b95ad"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.7.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"
"""

# ╔═╡ Cell order:
# ╠═93b96839-9676-477b-aebb-e50d733a6719
# ╟─d863795b-5fea-4b69-8f63-e04352bb970a
# ╠═84549502-876a-4ffc-8069-1ffc17622f9a
# ╟─751e1119-fe59-41dc-8785-a3ed0a9cacb9
# ╠═1030a96d-b739-4232-820b-f21826512251
# ╟─0224c914-3763-4c55-844c-e9aca430b377
# ╠═4619b92e-2f9e-429f-9e9a-77b97be7edd1
# ╟─f8e82610-b0d0-4763-939d-aadc92336c52
# ╠═f4d34f0a-6c88-48db-84a0-ed3fb01fb7aa
# ╟─8732f232-3069-4fb1-9b6a-0e24b8724451
# ╠═b68090b2-0eed-4e4a-acdc-6df71747a46d
# ╟─89e8ab14-7097-4088-937f-6453722da9d0
# ╠═26b9a050-c4b4-42a8-b1d7-e50fb98a7e8a
# ╟─7ebb2202-8aa1-4404-b1dd-ac1669f9a120
# ╠═9351c7ab-a39f-4f47-a3ee-e1684e2b3c07
# ╟─3f44d67b-bd18-481e-bca8-bb4904f6b418
# ╠═58af16a2-7f23-4d06-8836-fb737788ada0
# ╟─303894cd-a0c2-461c-a671-7330f75b338e
# ╟─5c103ce3-0cb2-4004-ac44-50613a461153
# ╠═38422e77-cfd8-4a2c-8cf2-f1b430f64ad1
# ╠═112d4837-e646-4e24-84c8-771b9855aebf
# ╟─e8d4890b-db1c-4b74-8a6d-4388597cead8
# ╠═842f6873-1f7f-4785-9be5-336dee828ad8
# ╟─c894f9c1-d608-4a11-9146-ea4b83b40325
# ╠═c4c058fb-28e6-4aa4-8609-5d0e9d29f42e
# ╠═d17660c0-fe52-4b71-9f7e-c77533801e5b
# ╟─681ac0f0-b207-48d1-9524-e2bb93f79717
# ╠═df689c72-deeb-4d94-8c10-702c3621bcba
# ╟─5374925a-46ef-49bc-b3b1-14a5afc5f523
# ╠═d7f632bb-c3a5-4196-b4ce-9fc80ed24034
# ╟─44aa6111-2374-4261-8616-73925c320b34
# ╠═f381e96a-a8c6-4ebd-adf2-e6da20ca63de
# ╠═5e0cb560-2a27-4372-945b-4be44fca1fbc
# ╟─eb3bfde8-62c0-4497-b9cd-faba6ec9cf8d
# ╠═112ce5fc-560d-438d-b58f-d52991a1651f
# ╟─327fcddb-9bdc-4ae8-8908-86a0b0619639
# ╠═2b23504e-8e2c-47c5-b9b8-07b7b0063d2e
# ╟─4fb800af-7ac7-45b0-a3a0-ce153c7eb464
# ╟─85724067-ff56-40e2-99e5-e26698a4a444
# ╠═19ef2475-1ebd-4b73-af6b-d7079182f27a
# ╟─7f78d745-8b16-4308-9191-4dbe8bd11da9
# ╟─1f0ef848-d9b0-414d-9e1a-82beb6633c02
# ╠═9426a96a-43e3-458d-933e-44b36966db57
# ╠═5ac3dfc3-54c0-438a-a3b9-d2d24309f532
# ╟─fc5bd55a-3936-4b93-8f62-b2f708b83a4e
# ╠═32f1afed-5ccf-4378-8f1d-14e293ff2c1a
# ╠═c21e2aa6-55ba-4068-b127-d7b53c17eb45
# ╠═407f8c03-a0ec-4b23-ba2c-22de526becc8
# ╠═ad351cf6-8f2b-4cd0-b207-1ecb53eb2e38
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
