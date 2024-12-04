### A Pluto.jl notebook ###
# v0.20.3

using Markdown
using InteractiveUtils

# ╔═╡ 84549502-876a-4ffc-8069-1ffc17622f9a
using HerbGrammar, HerbConstraints

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
HerbConstraints = "~0.2.2"
HerbGrammar = "~0.3.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.1"
manifest_format = "2.0"
project_hash = "940e4d43fa303c6cd39be535f576fbe0e88bfd9f"

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

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

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

[[deps.ICU_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "20b6765a3016e1fca0c9c93c80d50061b94218b7"
uuid = "a51ab1cf-af8e-5615-a023-bc2c838bba6b"
version = "69.1.0+0"

[[deps.Inflate]]
git-tree-sha1 = "d1b1b796e47d94588b3757fe84fbf65a5ec4a80d"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "be3dc50a92e5a386872a493a10050136d4703f9b"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.6.1"

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

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

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
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

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

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.7.0+0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

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
# ╟─93b96839-9676-477b-aebb-e50d733a6719
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
