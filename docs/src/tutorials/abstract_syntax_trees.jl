### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ 8f3dba2b-cfdc-4042-9ca4-b3bf0dbaf637
# hide
using Kroki

# ╔═╡ 4ab41dab-63f0-4ee0-b30d-532513406a0f
using Herb

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
Diagram(:mermaid, """
flowchart TD
    id1((13)) ---
    id2((6))
    id1 --- id3((12))
    id4((11))
    id5((4))
    id3 --- id4
    id3 --- id5
""")

# ╔═╡ 29b37a82-d022-453e-bf65-672aa94e4c87
md"""
In `Herb.jl`, the `HerbCore.RuleNode` is used to represent both an individual node, but also entire ASTs or sub-trees. This is achieved by nesting instances of `RuleNode`. A `RuleNode` can be instantiated by providing the index of the grammar rule that the node represents and a vector of child nodes. """

# ╔═╡ 822d9601-284d-4d30-9551-605684f83d90
syntaxtree = HerbGrammar.RuleNode(13, [RuleNode(6), RuleNode(12, [RuleNode(11), RuleNode(4)])])

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
The program `fizzbuzz()` is based on the popular _FizzBuzz_ problem. Given an integer number, the program simply returns a `String` of that number, but replace numbers divisible by 3 with `\"Fizz\"`, numbers divisible by 5 with `\"Buzz\"`, and number divisible by both 3 and 5 with `\"FizzBuzz\"`."""

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
Diagram(:mermaid, """
flowchart TD
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
""")

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
Herb = "c09c6b7f-4f63-49de-90d9-97a3563c0f4a"
Kroki = "b3565e16-c1f2-4fe9-b4ab-221c88942068"

[compat]
Herb = "~0.5.1"
Kroki = "~1.0.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.4"
manifest_format = "2.0"
project_hash = "5e5428756acadeea69b2e35010312f98931f1d33"

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

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "bce6804e5e6044c6daab27bb533d1295e4a2e759"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.6"

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

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "f36e5e8fdffcb5646ea5da81495a5a7566005127"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.4.3"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "4e1fe97fdaed23e9dc21d4d664bea76b65fc50a0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.22"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "d36f682e590a83d63d1c7dbd287573764682d12a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.11"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "PrecompileTools", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "c67b33b085f6e2faf8bf79a61962e7339a81129c"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.15"

[[deps.Herb]]
deps = ["HerbConstraints", "HerbCore", "HerbGrammar", "HerbInterpret", "HerbSearch", "HerbSpecification", "Reexport"]
git-tree-sha1 = "09a14d1a598e89a2b17dbae255b39095c7155361"
uuid = "c09c6b7f-4f63-49de-90d9-97a3563c0f4a"
version = "0.5.1"

[[deps.HerbConstraints]]
deps = ["DataStructures", "HerbCore", "HerbGrammar", "MLStyle"]
git-tree-sha1 = "3803de2d99ad7fbdcf9ea980930d5fa2e64e7473"
uuid = "1fa96474-3206-4513-b4fa-23913f296dfc"
version = "0.3.2"

[[deps.HerbCore]]
deps = ["AbstractTrees"]
git-tree-sha1 = "6a4938b0c67a44000dc649d6da7477760057c324"
uuid = "2b23ba43-8213-43cb-b5ea-38c12b45bd45"
version = "0.3.8"

[[deps.HerbGrammar]]
deps = ["HerbCore", "Serialization"]
git-tree-sha1 = "b79740118413e5450a40948afe34df0642146ee5"
uuid = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"
version = "0.5.2"

[[deps.HerbInterpret]]
deps = ["HerbCore", "HerbGrammar", "HerbSpecification"]
git-tree-sha1 = "baf4cda9f2e68d7141da4d4cdb2ed41e004ab36c"
uuid = "5bbddadd-02c5-4713-84b8-97364418cca7"
version = "0.1.7"

[[deps.HerbSearch]]
deps = ["DataStructures", "HerbConstraints", "HerbCore", "HerbGrammar", "HerbInterpret", "HerbSpecification", "MLStyle", "Random", "StatsBase"]
git-tree-sha1 = "3fc2aa376873ba26042d579efd70e32f404629c3"
uuid = "3008d8e8-f9aa-438a-92ed-26e9c7b4829f"
version = "0.4.4"

[[deps.HerbSpecification]]
deps = ["AutoHashEquals"]
git-tree-sha1 = "835853c205b55b1e841410d3022395812fdec0d7"
uuid = "6d54aada-062f-46d8-85cf-a1ceaf058a06"
version = "0.2.1"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IrrationalConstants]]
git-tree-sha1 = "e2222959fbc6c19554dc15174c81bf7bf3aa691c"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.4"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "a007feb38b422fbdab534406aeca1b86823cb4d6"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.Kroki]]
deps = ["Base64", "CodecZlib", "DocStringExtensions", "HTTP", "JSON", "Markdown", "Reexport"]
git-tree-sha1 = "8ff3884b3f5613214b520d6054f8df8ce0de1396"
uuid = "b3565e16-c1f2-4fe9-b4ab-221c88942068"
version = "1.0.0"

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

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "f02b56007b064fbfddb4c9cd60161b6dd0f40df3"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.1.0"

[[deps.MLStyle]]
git-tree-sha1 = "bc38dff0548128765760c79eb7388a4b37fae2c8"
uuid = "d8e11817-5142-5d16-987a-aa16d5891078"
version = "0.4.17"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

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

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "38cb508d080d21dc1128f7fb04f20387ed4c0af4"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.3"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7493f61f55a6cce7325f197443aa80d32554ba10"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.15+3"

[[deps.OrderedCollections]]
git-tree-sha1 = "cc4054e898b852042d7b503313f7ad03de99c3dd"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

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

[[deps.SimpleBufferStream]]
git-tree-sha1 = "f305871d2f381d21527c770d4788c06c097c9bc1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.2.0"

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

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"
"""

# ╔═╡ Cell order:
# ╟─65fbf850-74ae-4ea4-85f0-683095c73fba
# ╟─2493e9db-8b8e-4ef6-8379-f50ad26aab88
# ╟─8ff96964-e39e-4762-ae03-e9166e163fca
# ╟─bff155ab-ff0e-452b-a8f5-fe744e41a30f
# ╟─caa3446e-c5df-4dac-905a-20515f681074
# ╟─8f3dba2b-cfdc-4042-9ca4-b3bf0dbaf637
# ╠═4ab41dab-63f0-4ee0-b30d-532513406a0f
# ╠═9f54f013-e8b9-4e0d-8bac-9867f5d1a393
# ╟─46fbbe87-ee6e-4874-9708-20a42347ff18
# ╟─5dc6be9c-e4d9-4fdb-90bf-f4c59bb66a70
# ╠═64c2a6ce-5e3b-413b-bcb7-84936137439f
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
