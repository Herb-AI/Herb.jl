### A Pluto.jl notebook ###
# v0.19.43

using Markdown
using InteractiveUtils

# ╔═╡ c784cbc3-19fc-45c9-b344-db10cf7a81fa
begin 
	using PlutoUI
	
	using HerbCore
	using HerbGrammar
	using HerbInterpret
end

# ╔═╡ 65fbf850-74ae-4ea4-85f0-683095c73fba
md"""
# Herb tutorial: Abstract syntax trees"""

# ╔═╡ 2493e9db-8b8e-4ef6-8379-f50ad26aab88
md"""
In this tutorial, you will learn
    
- How to represent a computer program as an abstract syntax tree  in Herb.
- How to replace parts of the tree to modify the program."""

# ╔═╡ 8ff96964-e39e-4762-ae03-e9166e163fca
md"""
## Abstract syntax trees

The syntactic structure of a computer program can be represented in a hierarchical tree structure, a so-called _Abstract Syntax Tree (AST)_. The syntax of a programming language is typically defined using a formal grammar, a set of rules on how valid programs can be constructed. ASTs are derived from the grammar, but are abstractions in the sense that they omit details such as parenthesis, semicolons, etc. and only retain what's necessary to capture the program structure. 

In the context of program synthesis, ASTs are often used to define the space of all possible programs which is searched to find one that satisfies the given specifications. During the search process, different ASTs, each corresponding to a different program, are generated and evaluated until a suitable one is found.

Each _node_ of the AST represents a construct in the program (e.g., a variable, an operator, a statement, or a function) and this construct corresponds to a rule in the formal grammar. 
An _edge_ describes the relationship between constructs, and the tree structure captures the nesting of constructs. """

# ╔═╡ bff155ab-ff0e-452b-a8f5-fe744e41a30f
md"""
## A simple example program

We first consider the simple program 5*(x+3). We will define a grammar that is sufficient to represent this program and use it to construct a AST for our program."""

# ╔═╡ caa3446e-c5df-4dac-905a-20515f681074
md"""
### Define the grammar"""

# ╔═╡ 9f54f013-e8b9-4e0d-8bac-9867f5d1a393
grammar = @csgrammar begin
        Number = |(0:9)
        Number = x
        Number = Number + Number
        Number = Number * Number
    end

# ╔═╡ 46fbbe87-ee6e-4874-9708-20a42347ff18
md"""
### Construct the syntax tree"""

# ╔═╡ 5dc6be9c-e4d9-4fdb-90bf-f4c59bb66a70
md"""
The AST of this program is shown in the diagram below. The number in each node refers to the index of the corresponding rule in our grammar. """

# ╔═╡ 64c2a6ce-5e3b-413b-bcb7-84936137439f
md"""
```mermaid
    flowchart 
    id1((13)) ---
    id2((6))
    id1 --- id3((12))
    id4((11))
    id5((4))
    id3 --- id4
    id3 --- id5
```
"""

# ╔═╡ 64f6f1e3-5cbc-4e37-a806-d4fd45c20855
md"""
```mermaid
    flowchart 
    id1((13)) ---
    id2((6))
    id1 --- id3((12))
    id4((11))
    id5((4))
    id3 --- id4
    id3 --- id5
```"""

# ╔═╡ 29b37a82-d022-453e-bf65-672aa94e4c87
md"""
In `Herb.jl`, the `HerbCore.RuleNode` is used to represent both an individual node, but also entire ASTs or sub-trees. This is achieved by nesting instances of `RuleNode`. A `RuleNode` can be instantiated by providing the index of the grammar rule that the node represents and a vector of child nodes. """

# ╔═╡ 822d9601-284d-4d30-9551-605684f83d90
syntaxtree = RuleNode(13, [RuleNode(6), RuleNode(12, [RuleNode(11), RuleNode(4)])])

# ╔═╡ 351210d1-20b6-4695-b9fe-f1136d4447d5
md"""
We can confirm that our AST is correct by displaying it in a more human-readable way, using `HerbGrammar.rulenode2expr` and by testing it on a few input examples using `HerbInterpret.execute_on_input`."""

# ╔═╡ dc882fd5-d0fd-4a7d-8d5b-40516f3a3bcb
rulenode2expr(syntaxtree, grammar)

# ╔═╡ cbfaa1b6-f3c5-490a-9e54-006262d0c727
# test solution on inputs
execute_on_input(grammar, syntaxtree, Dict(:x => 10))

# ╔═╡ 6e018fd3-7626-48b2-b56a-240ae62a1ac4
md"""
## Another example: FizzBuzz

Let's look at a more interesting example. 
The program `fizbuzz()` is based on the popular _FizzBuzz_ problem. Given an integer number, the program simply returns a `String` of that number, but replace numbers divisible by 3 with `\"Fizz\"`, numbers divisible by 5 with `\"Buzz\"`, and number divisible by both 3 and 5 with `\"FizzBuzz\"`."""

# ╔═╡ 3fd0895e-7f1f-4ecd-855f-95c69a466dde
function fizzbuzz(x)
    if x % 5 == 0 && x % 3 == 0
        return "FizzBuzz"
    else
        if x % 3 == 0
            return  "Fizz"
        else
            if x % 5 == 0
                return "Buzz"
            else
                return string(x)
            end
        end
    end
end

# ╔═╡ b302e44c-29a9-4851-bb11-e95c0dfbacdb
md"""
### Define the grammar

Let's define a grammar with all the rules that we need."""

# ╔═╡ 59444d63-8b2a-4b76-9af3-b92b4abd4a98
grammar_fizzbuzz = @csgrammar begin
    Int = input1
    Int = 0 | 3 | 5
    String = "Fizz" | "Buzz" | "FizzBuzz"
    String = string(Int)
    Return = String
    Int = Int % Int
    Bool = Int == Int
    Int = Bool ? Int : Int
    Bool = Bool && Bool
end

# ╔═╡ e389cf25-5f0b-4d94-bab0-7cf85ee0e6e0
md"""
### Construct the syntax tree"""

# ╔═╡ 8fa5cbbc-ad25-42ff-9ec8-284590fe1084
md"""
Given the grammar, the AST of `fizzbuzz()` looks like this:"""

# ╔═╡ 6a663bce-155b-4c0d-94ec-7dc5fbba348a
md"""
```mermaid
flowchart 
    id1((12)) --- id21((13))
    id1--- id22((9))
    id1--- id23((12))

    id21 --- id31((11))
    id21 --- id32((11))

    id31 --- id41((10))
    id31 --- id42((2))

    id41 --- id51((1))
    id41 --- id52((4))

    id32 --- id43((10)) 
    id32 --- id44((2))

    id43 --- id53((1))
    id43 --- id54((3))

    id22 --- id33((7))
    id23 --- id34((11))

    id34 --- id45((10))
    id34 --- id46((2))

    id45 --- id55((1))
    id45 --- id56((3))

    id23 --- id35((9))
    id35 --- id47((5))

    id23 --- id36((12))
    id36 --- id48((11))
    id48 --- id57((10))
    id57 --- id61((1))
    id57 --- id62((4))
    id48 --- id58((2))

    id36 --- id49((9))
    id49 --- id59((6))

    id36 --- id410((9))
    id410 --- id510((8))
    id510 --- id63((1))
    
    
    
```"""

# ╔═╡ d9272c48-a7da-4ca0-af15-98c0fe4a3f24
md"""
As before, we use nest instanced of `RuleNode` to implement the AST."""

# ╔═╡ 6a268dbb-e884-4b1f-b0c3-4ae1d36064a3
fizzbuzz_syntaxtree = RuleNode(12, [
               RuleNode(13, [
                   RuleNode(11, [
                       RuleNode(10, [
                           RuleNode(1),
                           RuleNode(4)
                       ]),
                       RuleNode(2)
                   ]),
                   RuleNode(11, [
                       RuleNode(10, [
                           RuleNode(1),
                           RuleNode(3)
                       ]),
                       RuleNode(2)
                   ])
               ]),
               RuleNode(9, [
                   RuleNode(7)
               
               ]),
               RuleNode(12, [
                   RuleNode(11, [
                       RuleNode(10, [
                           RuleNode(1),
                           RuleNode(3),
                       ]),
                       RuleNode(2)
                   ]),
                   RuleNode(9, [
                       RuleNode(5)
                   ]),
                   RuleNode(12, [
                       RuleNode(11, [
                           RuleNode(10, [
                               RuleNode(1),
                               RuleNode(4)
                           ]),
                           RuleNode(2)
                       ]),
                       RuleNode(9, [
                           RuleNode(6)
                       ]),
                       RuleNode(9, [
                           RuleNode(8, [
                                RuleNode(1)
                            ])
                       ])
                   ])
               ]) 
    ])

# ╔═╡ 61b27735-25ba-4995-b506-7982db8c50b5
md"""
And we check our syntax tree is correct:"""

# ╔═╡ 3692d164-4deb-4da2-834c-fc2eb8ac3fa0
rulenode2expr(fizzbuzz_syntaxtree, grammar_fizzbuzz)

# ╔═╡ 0d5aaa64-ae46-4b88-ac05-df8910da1648
begin
	# test solution on inputs
	input = [Dict(:input1 => 3), Dict(:input1 => 5), Dict(:input1 =>15), Dict(:input1 => 22)]
	output1 = execute_on_input(grammar_fizzbuzz, fizzbuzz_syntaxtree, input)
	output1
end

# ╔═╡ c9a57153-96f8-4bcb-905b-dc46bc1f7765
md"""
### Modify the AST/program

There are several ways to modify an AST and hence, a program. You can

- directly replace a node with `HerbCore.swap_node()`
- insert a rule node with `insert!`

Let's modify our example such that if the input number is divisible by 3, the program returns \"Buzz\" instead of \"Fizz\". 
We use `swap_node()` to replace the node of the AST that corresponds to rule 5 in the grammar (`String = Fizz`) with rule 6 (`String = Buzz`). To do so, `swap_node()` needs the tree that contains the node we want to modify, the new node we want to replace the node with, and the path to that node.

Note that `swap_node()` modifies the tree, hence we make a deep copy of it first."""

# ╔═╡ 6e0bed41-6f06-47e2-a659-ec61fa9c0d40
begin
    modified_fizzbuzz_syntaxtree = deepcopy(fizzbuzz_syntaxtree)
    newnode = RuleNode(6)
    path = [3, 2, 1]
    swap_node(modified_fizzbuzz_syntaxtree, newnode, path)
	rulenode2expr(modified_fizzbuzz_syntaxtree, grammar_fizzbuzz)
end

# ╔═╡ f9e4ec58-ded3-4bf8-9207-a05596d15586
md"""
Let's confirm that we modified the AST, and hence the program, correctly:"""

# ╔═╡ d9543762-e438-492c-a0b1-632c4c25c58b
# test solution on same inputs as before
execute_on_input(grammar_fizzbuzz, modified_fizzbuzz_syntaxtree, input)

# ╔═╡ 44cc6617-9262-44a5-8cec-90713819d03a
md"""
An alternative way to modify the AST is by using `insert!()`. This requires to provide the location of the node that we want to as `NodeLoc`. `NodeLoc` points to a node in the tree and consists of the parent and the child index of the node.
Again, we make a deep copy of the original AST first."""

# ╔═╡ 0b595e4a-c6a3-4986-b311-f09bb53ee189
begin
    anothermodified_fizzbuzz_syntaxtree = deepcopy(fizzbuzz_syntaxtree)
    # get the node we want to modify and instantiate a NodeLoc from it.
    node = get_node_at_location(anothermodified_fizzbuzz_syntaxtree, [3, 2, 1])
    nodeloc = NodeLoc(node, 0)
    # replace the node
    insert!(node, nodeloc, newnode)
	rulenode2expr(anothermodified_fizzbuzz_syntaxtree, grammar_fizzbuzz)
end

# ╔═╡ e40403aa-cb27-4bfb-b581-1795fc1cce41
md"""
Again, we check that we modified the program as intended:"""

# ╔═╡ 8847f8b8-bb52-4a95-86f1-6483e5e0ab85
# test on same inputs as before
execute_on_input(grammar_fizzbuzz, anothermodified_fizzbuzz_syntaxtree, input)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HerbCore = "2b23ba43-8213-43cb-b5ea-38c12b45bd45"
HerbGrammar = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"
HerbInterpret = "5bbddadd-02c5-4713-84b8-97364418cca7"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
HerbCore = "~0.2.0"
HerbGrammar = "~0.2.1"
HerbInterpret = "~0.1.2"
PlutoUI = "~0.7.59"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.4"
manifest_format = "2.0"
project_hash = "0ce6f08e629fb0ab6945e23b691d12a7e72d4c7a"

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
git-tree-sha1 = "4f2b57488ac7ee16124396de4f2bbdd51b2602ad"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.11.0"

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

[[deps.HerbCore]]
git-tree-sha1 = "f3312458fa882d4adaeecadf8f4b5721ec6e3322"
uuid = "2b23ba43-8213-43cb-b5ea-38c12b45bd45"
version = "0.2.0"

[[deps.HerbGrammar]]
deps = ["AbstractTrees", "DataStructures", "HerbCore", "Serialization", "TreeView"]
git-tree-sha1 = "aa70e06c5cec398294cc65c16e18f2ebdc3a7348"
uuid = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"
version = "0.2.1"

[[deps.HerbInterpret]]
deps = ["HerbCore", "HerbGrammar", "HerbSpecification"]
git-tree-sha1 = "3723e5ace26a2f2cd342b28689dea543491687c6"
uuid = "5bbddadd-02c5-4713-84b8-97364418cca7"
version = "0.1.2"

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
git-tree-sha1 = "ea8031dea4aff6bd41f1df8f2fdfb25b33626381"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.4"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

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

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

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

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "9ae599cd7529cfce7fea36cf00a62cfc56f0f37c"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.4"

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

    [deps.StaticArrays.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "36b3d696ce6366023a0ea192b4cd442268995a0d"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.2"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

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
git-tree-sha1 = "52ff2af32e591541550bd753c0da8b9bc92bb9d9"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.12.7+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

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
git-tree-sha1 = "b4bfde5d5b652e22b9c790ad00af08b6d042b97d"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.15.0+0"

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
# ╟─65fbf850-74ae-4ea4-85f0-683095c73fba
# ╟─2493e9db-8b8e-4ef6-8379-f50ad26aab88
# ╟─8ff96964-e39e-4762-ae03-e9166e163fca
# ╟─bff155ab-ff0e-452b-a8f5-fe744e41a30f
# ╟─caa3446e-c5df-4dac-905a-20515f681074
# ╠═c784cbc3-19fc-45c9-b344-db10cf7a81fa
# ╠═9f54f013-e8b9-4e0d-8bac-9867f5d1a393
# ╟─46fbbe87-ee6e-4874-9708-20a42347ff18
# ╟─5dc6be9c-e4d9-4fdb-90bf-f4c59bb66a70
# ╠═64c2a6ce-5e3b-413b-bcb7-84936137439f
# ╟─64f6f1e3-5cbc-4e37-a806-d4fd45c20855
# ╟─29b37a82-d022-453e-bf65-672aa94e4c87
# ╠═822d9601-284d-4d30-9551-605684f83d90
# ╟─351210d1-20b6-4695-b9fe-f1136d4447d5
# ╠═dc882fd5-d0fd-4a7d-8d5b-40516f3a3bcb
# ╠═cbfaa1b6-f3c5-490a-9e54-006262d0c727
# ╟─6e018fd3-7626-48b2-b56a-240ae62a1ac4
# ╠═3fd0895e-7f1f-4ecd-855f-95c69a466dde
# ╟─b302e44c-29a9-4851-bb11-e95c0dfbacdb
# ╠═59444d63-8b2a-4b76-9af3-b92b4abd4a98
# ╟─e389cf25-5f0b-4d94-bab0-7cf85ee0e6e0
# ╟─8fa5cbbc-ad25-42ff-9ec8-284590fe1084
# ╠═6a663bce-155b-4c0d-94ec-7dc5fbba348a
# ╟─d9272c48-a7da-4ca0-af15-98c0fe4a3f24
# ╠═6a268dbb-e884-4b1f-b0c3-4ae1d36064a3
# ╟─61b27735-25ba-4995-b506-7982db8c50b5
# ╠═3692d164-4deb-4da2-834c-fc2eb8ac3fa0
# ╠═0d5aaa64-ae46-4b88-ac05-df8910da1648
# ╟─c9a57153-96f8-4bcb-905b-dc46bc1f7765
# ╠═6e0bed41-6f06-47e2-a659-ec61fa9c0d40
# ╟─f9e4ec58-ded3-4bf8-9207-a05596d15586
# ╠═d9543762-e438-492c-a0b1-632c4c25c58b
# ╟─44cc6617-9262-44a5-8cec-90713819d03a
# ╠═0b595e4a-c6a3-4986-b311-f09bb53ee189
# ╟─e40403aa-cb27-4bfb-b581-1795fc1cce41
# ╠═8847f8b8-bb52-4a95-86f1-6483e5e0ab85
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
