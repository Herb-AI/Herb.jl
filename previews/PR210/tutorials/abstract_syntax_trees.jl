### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ 4df80808-0c93-4ea0-a920-404b035340f2
begin
	import Pkg
	Pkg.activate(Base.current_project())
	Pkg.instantiate()
end

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
syntaxtree = @rulenode 13{6,12{11,4}}

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
As before, we use nested instance of `RuleNode` to implement the AST."""

# ╔═╡ 6a268dbb-e884-4b1f-b0c3-4ae1d36064a3
fizzbuzz_syntaxtree = @rulenode 12{13{11{10{1,4},2},11{10{1,3},2}},9{7},12{11{10{1,3},2},9{5},12{11{10{1,4},2},9{6},9{8{1}}}}}

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

# ╔═╡ Cell order:
# ╟─65fbf850-74ae-4ea4-85f0-683095c73fba
# ╟─2493e9db-8b8e-4ef6-8379-f50ad26aab88
# ╟─8ff96964-e39e-4762-ae03-e9166e163fca
# ╟─bff155ab-ff0e-452b-a8f5-fe744e41a30f
# ╟─caa3446e-c5df-4dac-905a-20515f681074
# ╟─8f3dba2b-cfdc-4042-9ca4-b3bf0dbaf637
# ╠═4df80808-0c93-4ea0-a920-404b035340f2
# ╠═4ab41dab-63f0-4ee0-b30d-532513406a0f
# ╠═9f54f013-e8b9-4e0d-8bac-9867f5d1a393
# ╟─46fbbe87-ee6e-4874-9708-20a42347ff18
# ╟─5dc6be9c-e4d9-4fdb-90bf-f4c59bb66a70
# ╟─64c2a6ce-5e3b-413b-bcb7-84936137439f
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
# ╟─6a663bce-155b-4c0d-94ec-7dc5fbba348a
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
