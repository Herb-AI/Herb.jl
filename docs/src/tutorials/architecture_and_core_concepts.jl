### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ 4f96e98e-5611-4acc-893d-a52aaf4bb582
using PlutoUI

# ╔═╡ a7192eb2-2583-44ae-a176-59e58bd751c1
using Herb

# ╔═╡ c8b6066a-5b93-498a-8f74-59544f635ea5
using Kroki

# ╔═╡ 86e43713-8e45-4ad2-9e91-46a095752293
using Test 

# ╔═╡ 00cb9e76-ed1d-11ef-0b64-152537924f72
md"
# Herb Architecture and Core Concepts

## Overview Architecture 

Program synthesis searches over a space of programs to find one that satisfies our specifications, typically provided as input/output examples. 

This diagram shows the program synthesis process:

"

# ╔═╡ d6206c68-63e6-4600-919b-7c72a062cf7d
LocalResource("assets/herb_architecture.png")

# ╔═╡ 132068b4-d842-4109-9649-1140b073aefd
md"
This tutorial breaks down the four essential components of program synthesis:
1. Problem specification - input/output examples (missing)
1. Grammars
1. Programs and program interpreter
1. Program iterator

We'll explore how each of them works, and show their implementation in Herb.jl with practical code examples. 
By the end, you'll understand Herb.jl's core architecture and modules.
"

# ╔═╡ ea0bbd3e-6945-418e-a63d-d6a9e86e5dc3
md"
## Problem specification (TODO)
"

# ╔═╡ 12700526-a23b-4d96-a485-5d66fe897f01
md"
## Grammars 

A grammar defines the rules for creating syntactically valid program. The rules in the grammar can be combined to create programs.

For example, we might want to define a grammar for
- Arithmetic operation (addition, subtraction, multiplication, etc.)
- Bit manipulation operations (shift left, shift right, etc.)
- String manipulation operation (`concat`, `replace`, `findindex`, etc.)

While grammars are traditionally defined in formats like BNF - below is an example of a grammar with arithmetic operations - Herb.jl takes a different approach.  


Ideally, we would want to be able to define any grammar we want in Herb. 

One way to do this would be to have a file in a grammar format (e.g., BNF) that contains the grammar definition. A grammar with arithmetic operations, for example, would look like this

```
<expr> ::= <term> \"+\" <expr>
        |  <term>

<term> ::= <factor> \"*\" <term>
        |  <factor>

<factor> ::= \"(\" <expr> \")\"
          |  <const>

<const> ::= integer
```


A grammar only what syntactically valid programs look like - it doesn't tell us how to run them. Without a mechanism to execute programs, users would need to define both the grammar and how to evaluate programs, basically creating a new programming language from scratch.

Instead, Herb.jl leaverages Julia's built-in capabilities. Through Julia's [meta-programming support](https://docs.julialang.org/en/v1/manual/metaprogramming/), Herb.jl uses the Julia parser to process grammar definitions and the Julia interpreter to evaluate programs. With this approach, users can wirte the grammar directly in Julia code.

Let's look at an example of a simple grammar in Herb.jl.

"

# ╔═╡ aa0fd9dd-f500-49ed-ac8a-764a6c737136
grammar = @csgrammar begin
    Number = Constant
    Constant = 1 | 2 | 3 # constant can be 1 or 2 or 3
    Number = x
    Number = Number + Number
    Number = Number - Number
    Number = Number * Number
end

# ╔═╡ bf841a41-accf-40e7-b97a-06f72a7f2ce5
md"
We define a grammar with six rules. When you run this code cell in a notebook, or in the Julia REPL, you notice more rules being output. 
Each line in the grammar has a `Symbol` on the left-hand side, and a Julia expression on the right.
The second rule exploits the `|` symbol to define multiple rules in a single line. 

We can access specific rules of the grammar by their index (remember that Julia indices start from 1). We get the RHS of a grammar rule with:
"

# ╔═╡ 5b2f698d-1e0f-4b33-a729-6ca4cf97a409
grammar.rules[1] 

# ╔═╡ 8cb71b93-f63f-4616-b76d-7528aea79ee2
grammar.rules[6]

# ╔═╡ 10e6c74d-6242-4fb0-8a5d-83ecd0438130
md"
To get the LHS of a rule, we can use
"

# ╔═╡ 3f8ecba9-c1d1-47b5-ae7d-ce0ab78bbd2f
grammar.types[6]

# ╔═╡ 03ca4570-8719-4763-9256-9ad04f3ceb4d
md"
To see all the fields of the grammar, type `@doc` in notebook cell, or `?` from the REPL, followed by the type `ContextSensitiveGrammar`. For more details on working with grammars in Herb.jl, including useful helper functions, check out the tutorial on [Defining Grammars in Herb.jl](../defining_grammars.md).
"

# ╔═╡ 56568b5f-94b3-4780-aac7-0405735f4a5b
@doc ContextSensitiveGrammar

# ╔═╡ 9e5bf840-3b01-46f0-a244-54cbc5978711
md"
All functionality related to grammar can be found in the module [HerbGrammar.jl] (@ref Sub-Modules/HerbGrammar.jl).
"

# ╔═╡ 51fdff46-cac6-4372-959b-fdc14e26c55f
md"
## Programs and program interpreter 

While grammars define the rules for valid programs, we also need a way to represent and evaluate them. In this section, we explore how programs are represented in Herb.jl, how to manipulate and evaluate them.

Programs can be expressed in a hierarchical tree structure, a so-called Abstract Syntax Tree (AST) where each node in the tree corresponds to a rule index in the grammar (see also the [tutorial on ASTs](@ref Abstract Syntax Trees)).

If you're not familiar with ASTs, the following exmaple will help you:
We return to the `grammar` we defined above. We want to represent the expression `1 + 2 * 3` in a tree structure:
"

# ╔═╡ 3622c2c1-7ed4-4e69-899c-90268a88d315
# Diagram(:mermaid, """
# flowchart TD
#     id1((2)) --- id2((1))
#     id1 --- id3((3))
#     id3 --- id4((2))
#     id3 --- id5((3))
# """)

# ╔═╡ 93dd198a-2956-4164-96cb-0a1b35317f70
md"
We can relate this AST to the derivation rules of the grammar:
"

# ╔═╡ 7a41b422-b590-4598-8e72-359a7d571a0a
LocalResource("assets/rulenode.png")

# ╔═╡ 61b93d74-a6c4-492d-8e9c-6c1261709108
md"
On the left, you can see that grammar rules and their corresponding indices. On the right, you can see the tree for `1 + 2 * 3`, where each node contains an expression. The rule indices are shown next to each node.
"

# ╔═╡ f25c54b0-8586-4698-adfb-4248537febab
md"
### Representing programs with `RuleNode`

In Herb.jl, a program is represented as such a tree structure using the type `RuleNode`, which is defined in HerbCore.jl. Let's have a look at the documentation to learn more about this type.
"

# ╔═╡ df386704-7987-44e2-8737-d219af11e769
@doc RuleNode

# ╔═╡ e3824116-8e7e-4fce-a09a-8ecea61e80a2
md"
With `RuleNode`, we can represent either programs that consist of a single rule 
without `children`, corresponding to a leaf node or terminal node in your expression tree. If we want to represent more complex programs with a nested structure, we express that via the field `children`. Each child can itself have children, allowing for an arbitrary depth of nesting.

Let's go back to our grammar and use its rule indices to create the simple program `1 + 2 * 3` with `RuleNode`:
"

# ╔═╡ f37a297b-4069-48a4-8746-3a6f55eccc4a
rulenode = RuleNode(6,
           [   RuleNode(2),
               RuleNode(8, [RuleNode(3), RuleNode(4)])
           ])

# ╔═╡ 999ddc86-7f27-48de-82cd-6fbbae21f612
md"
The output of the code cells shows the shorthand notation of `rulenode`. This is not very human-readable, and it's hard to spot if we made a mistake. Luckily, we can easily convert it into a Julia expression using the function [`HerbGrammar.rulenode2expr`](@ref). 
"

# ╔═╡ c4858fae-f2e6-4194-a50d-8242cef5d05d
rulenode2expr(rulenode,  grammar)

# ╔═╡ 3725a255-3fd7-41ec-906f-db928d24e0ac
md"
### Manipulating `RuleNode`s
As mentioned, `RuleNode`s are tree data structures, we can manipulate them using standard tree operations. The struct `RuleNode` is mutable, hence we can directly change both the `children` vector and the grammar rule index (`ind`). 

One thing to keep in mind is that `RuleNode` is specifically designed to work with a grammar. Without an associated grammar, a `RuleNode` is meaningless. 

For example, if we change the value of the root index to 9, we get an error when trying to convert the modified `rulenode` to a Julia expressions - our grammar only has eight rules.
"

# ╔═╡ 4d04d9d9-0dd4-4bb2-af59-7baf6be6f2ce
rulenode.ind = 9

# ╔═╡ 684f5667-85d7-44c9-8867-8ea5ac6ea8fc
Test.@test_throws BoundsError rulenode2expr(rulenode, grammar)

# ╔═╡ 1841ab4e-ceb9-4fde-81b2-fd879db3529b
md"
Similarly, we get an error when we add more children than to a `RuleNode` than a corresponding rule expects, for example by adding a third child to the additon:
"

# ╔═╡ a7afc265-2f89-4150-97a4-7c5bbf257ebd
rulenode.children =  [RuleNode(2),
               RuleNode(8, [RuleNode(3), RuleNode(4), RuleNode(3)])]

# ╔═╡ e2cfb9ba-c101-4d9f-b45c-6240b4a1fcf1
Test.@test_throws BoundsError rulenode2expr(rulenode, grammar)

# ╔═╡ 20a9d753-2007-484a-8ca7-58a35e1e187f
md"
## Program iterators

Iterators are the core building block in Herb.jl, exploring the space of possible progrmas to disscover solutions that satisfy a given problem specification. 

Like many programming languages, Julia provides an [iteration interface](https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-iteration). In Julia, an iterator is a type that implements two methods:
- `Base.iterator(iterator::MyIterator)`: Returns either a tuple of the first item and initial state or `nothing` if empty.
- `Base.iterator(iterator::MyIterator, state::MyIteratorState)`: Returns either a tuple of the next item and next state or nothing if no items remain.
"

# ╔═╡ 90de4099-8367-4c77-ae8a-f6bbeca5b7ed
iter = collect(1:5) # any type that can be iterated 

# ╔═╡ c53f10f3-496c-414b-bacb-5a6c71a98168
md"
An object that implements `iterate` can be used in functions that rely on iteration, or, for example, in a for loop.
"

# ╔═╡ 16826e84-63eb-4e61-b492-a58c1d4ff4ab
for item in iter
	# do something
	println(item)
end

# ╔═╡ 442ffa84-389d-4dac-86ed-26b97d697441
md"
This syntax is translated into:
"

# ╔═╡ 92b72847-3640-4dc7-b673-e2963867706f
md"
After each iteration, the curren iterator state is passed to the next `Base.iterate` call. This is a very powerfule pattern for implementing search algorithms (such as the ones we want to use for program synthesis) in a memory-efficient way, as it allows to generate program one at a time rather than all at one.

The different search algorithms, such as BFS, DFS, simply provide the order in they enumerate the search space.


### Build your own search algorithm in Herb.jl (incomplete)

Let's have a go at creating a new (and quirky) search algorithm from scratch. We want the search iterator that toggles between random sampling and BFS. I.e.,
we randomly sample programs for a given duration (for example, 2 seconds), before switching to BFS enumeration for another given duration (say 3 seconds), after which the process repeats. The BFS enumeration resumes from the previously saved state of the BFS iterator.

For this, we need the following three ingredients:
1. A new iteratore type. We call it `NiceCustomIterator`.
2. A `state` for the iterator
3. The methods `Base.iterate(iter::NiceCustomIterator)` and `Base.iterate(iter::NiceCustomIterator, state)`


#### 1. Custom iterator type

Our `NiceCustomIterator` type needs to store:
- A grammar for random program sampling
- Two timeouts: one for random search, one for BFS mode
"

# ╔═╡ 2cad0843-0cec-4138-8af6-6a030e77e1ea
struct NiceCustomIterator
    grammar::AbstractGrammar
    timer_run_random::Float64
    timer_run_bfs::Float64
end

# ╔═╡ d3e938df-8e97-40c6-9c4f-4a93c8faeeef
md"
### 2. Iterator state

Next, we need the iterator `state` to keep track of both running timers to make sure we switch at the right time between random sampling and BFS. A very simple way to do this is by storing the `start_time_random` of the random iterator. Then we can check in `iterate()` if the `current_time` is exceeds `starting time + timer_run_random`. We can do the same for BFS with `start_time_bfs`. To know which timer to check, we use a boolean `is_running_random`.
"

# ╔═╡ 7e488c0e-c7e2-4b3d-93be-c66f8f85681e
struct NiceCustomIteratorState
    start_time_random::Float64
    start_time_bfs::Float64
    is_running_random::Bool # true while running random search, false otherwise
end

# ╔═╡ 5e9f5569-d906-46b1-96a4-843fd8f0b57b
md"
### 3. Methods `Base.iterate()`

Now we implement `Base.iterate(iterator)`. This function is only run once - `state` is not needed as input parameter. It returns the new program and a new state (`nothing`).
"

# ╔═╡ 21a7e6ed-76b0-4b76-8f1c-b1bc60980f95
function Base.iterate(iterator::NiceCustomIterator) 
    random_program = rand(RuleNode, iterator.grammar)
    return random_program, nothing
end

# ╔═╡ c45269bf-69fc-4254-957b-a4e7ab87461b
next = iterate(iter)

# ╔═╡ 1fc9816b-1a78-4578-befd-9d3035d9a077
while next !== nothing
	(item, state) = next
	# do something
	println(item)
	next = iterate(iter, state)
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Herb = "c09c6b7f-4f63-49de-90d9-97a3563c0f4a"
Kroki = "b3565e16-c1f2-4fe9-b4ab-221c88942068"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[compat]
Herb = "~0.4.1"
Kroki = "~1.0.0"
PlutoUI = "~0.7.61"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.4"
manifest_format = "2.0"
project_hash = "0def3b8be4e0627954410fc29bf190fcdf773c3f"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

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
git-tree-sha1 = "962834c22b66e32aa10f7611c08c8ca4e20749a9"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.8"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

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
git-tree-sha1 = "d9d26935a0bcffc87d2613ce14c527c99fc543fd"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.5.0"

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

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "d36f682e590a83d63d1c7dbd287573764682d12a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.11"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "PrecompileTools", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "c67b33b085f6e2faf8bf79a61962e7339a81129c"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.15"

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
git-tree-sha1 = "95a5c1e87cd61b14cf9785f293e5633b39a69fc5"
uuid = "3008d8e8-f9aa-438a-92ed-26e9c7b4829f"
version = "0.4.1"

[[deps.HerbSpecification]]
deps = ["AutoHashEquals"]
git-tree-sha1 = "4a153a24694d4d91cf811d63581c9115087f06fc"
uuid = "6d54aada-062f-46d8-85cf-a1ceaf058a06"
version = "0.2.0"

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

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

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

[[deps.MIMEs]]
git-tree-sha1 = "1833212fd6f580c20d4291da9c1b4e8a655b128e"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.0.0"

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
git-tree-sha1 = "a9697f1d06cc3eb3fb3ad49cc67f2cfabaac31ea"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.16+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "cc4054e898b852042d7b503313f7ad03de99c3dd"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "7e71a55b87222942f0f9337be62e26b1f103d3e4"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.61"

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

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

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

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╠═4f96e98e-5611-4acc-893d-a52aaf4bb582
# ╟─00cb9e76-ed1d-11ef-0b64-152537924f72
# ╟─d6206c68-63e6-4600-919b-7c72a062cf7d
# ╟─132068b4-d842-4109-9649-1140b073aefd
# ╟─ea0bbd3e-6945-418e-a63d-d6a9e86e5dc3
# ╟─12700526-a23b-4d96-a485-5d66fe897f01
# ╠═a7192eb2-2583-44ae-a176-59e58bd751c1
# ╠═aa0fd9dd-f500-49ed-ac8a-764a6c737136
# ╟─bf841a41-accf-40e7-b97a-06f72a7f2ce5
# ╠═5b2f698d-1e0f-4b33-a729-6ca4cf97a409
# ╠═8cb71b93-f63f-4616-b76d-7528aea79ee2
# ╟─10e6c74d-6242-4fb0-8a5d-83ecd0438130
# ╠═3f8ecba9-c1d1-47b5-ae7d-ce0ab78bbd2f
# ╠═03ca4570-8719-4763-9256-9ad04f3ceb4d
# ╠═56568b5f-94b3-4780-aac7-0405735f4a5b
# ╟─9e5bf840-3b01-46f0-a244-54cbc5978711
# ╠═51fdff46-cac6-4372-959b-fdc14e26c55f
# ╠═c8b6066a-5b93-498a-8f74-59544f635ea5
# ╠═3622c2c1-7ed4-4e69-899c-90268a88d315
# ╟─93dd198a-2956-4164-96cb-0a1b35317f70
# ╟─7a41b422-b590-4598-8e72-359a7d571a0a
# ╟─61b93d74-a6c4-492d-8e9c-6c1261709108
# ╟─f25c54b0-8586-4698-adfb-4248537febab
# ╠═df386704-7987-44e2-8737-d219af11e769
# ╟─e3824116-8e7e-4fce-a09a-8ecea61e80a2
# ╠═f37a297b-4069-48a4-8746-3a6f55eccc4a
# ╟─999ddc86-7f27-48de-82cd-6fbbae21f612
# ╠═c4858fae-f2e6-4194-a50d-8242cef5d05d
# ╟─3725a255-3fd7-41ec-906f-db928d24e0ac
# ╠═4d04d9d9-0dd4-4bb2-af59-7baf6be6f2ce
# ╠═86e43713-8e45-4ad2-9e91-46a095752293
# ╠═684f5667-85d7-44c9-8867-8ea5ac6ea8fc
# ╟─1841ab4e-ceb9-4fde-81b2-fd879db3529b
# ╠═a7afc265-2f89-4150-97a4-7c5bbf257ebd
# ╠═e2cfb9ba-c101-4d9f-b45c-6240b4a1fcf1
# ╟─20a9d753-2007-484a-8ca7-58a35e1e187f
# ╠═90de4099-8367-4c77-ae8a-f6bbeca5b7ed
# ╟─c53f10f3-496c-414b-bacb-5a6c71a98168
# ╠═16826e84-63eb-4e61-b492-a58c1d4ff4ab
# ╟─442ffa84-389d-4dac-86ed-26b97d697441
# ╠═c45269bf-69fc-4254-957b-a4e7ab87461b
# ╠═1fc9816b-1a78-4578-befd-9d3035d9a077
# ╟─92b72847-3640-4dc7-b673-e2963867706f
# ╠═2cad0843-0cec-4138-8af6-6a030e77e1ea
# ╟─d3e938df-8e97-40c6-9c4f-4a93c8faeeef
# ╠═7e488c0e-c7e2-4b3d-93be-c66f8f85681e
# ╟─5e9f5569-d906-46b1-96a4-843fd8f0b57b
# ╠═21a7e6ed-76b0-4b76-8f1c-b1bc60980f95
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
