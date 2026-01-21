### A Pluto.jl notebook ###
# v0.20.18

using Markdown
using InteractiveUtils

# ╔═╡ 1212cbc3-bb49-46cb-b9a3-475815d59f2d
begin
    import Pkg
    Pkg.activate(Base.current_project())
    Pkg.instantiate()
end

# ╔═╡ 1defafc5-ce65-42f0-90cd-de9e8895ec90
using Herb

# ╔═╡ adabb7f1-7952-43c4-88a9-54225b40aaf0
md"""
# Search

This notebook describes how you can search a program space as defined by a grammar.
Specifically, we will look at example-based search, where the goal is to find a program that is able to transform the inputs of every example to the corresponding output.
"""

# ╔═╡ 841f097d-a389-4dd2-9ad3-1a2292568634
md"""
### Setup
First, we start with the setup. We need access to all the function in the Herb.jl framework.
"""

# ╔═╡ db7fe47b-ab3e-4705-b6ac-2733b9e81434
md"""
### Defining the program space

Next, we start by creating a grammar. We define a context-free grammar as a [`HerbGrammar.ContextSpecificGrammar`](@ref) without any constraints. A context-free grammar is just a simple set of production rules for defining combinations of terminal symbols (in our case integers). 

Alternatively we could define a context-sensitive grammar, when the production rules only hold in a certain context. For more information on this, please see our tutorial on [defining grammars](defining_grammars.md).

For now, we specify a simple grammar (using the `@csgrammar` macro) for dealing with integers and explain all the rules individually:

1. First, we specify our number values and constrain them to being positive even integers.
2. Then, we can also use the variable `x` to hold an integer.
3. The third rule determines we can add two integers.
4. The fourth rule determines we can subtract an integer from another.
5. Finally, we also allow the multiplication of two integers.

If you run this cell, you can see all the rules rolled out.
"""

# ╔═╡ 763b378b-66f9-481e-a3da-ca37825eb255
g = HerbGrammar.@csgrammar begin
    Number = 0 | 2 | 4 | 6 | 8
    Number = x
    Number = Number + Number
    Number = Number - Number
    Number = Number * Number
end

# ╔═╡ 6d01dfe8-9048-4696-916c-b33fbc97268b
md"""
### Defining the problem
"""

# ╔═╡ 56a63f9e-b484-4d85-af3e-de2cc4476e09
md"""
As mentioned before, we are looking at example-based search. 
This means that the problem is defined by a set of input-output examples. 
A single example hence consists of an input and an output.
The input is defined as a dictionary, with a value assigned to each variable in the grammar.
It is important to write the variable name as a `Symbol` instead of a string.
A `Symbol` in Julia is written with a colon prefix, i.e. `:x`. 
The output of the input-output example is just a single value for this specific grammar, but could possibly relate to e.g. arrays of values, too.

In the cell below we automatically generate some examples for `x` assigning values `1-5`.
"""

# ╔═╡ 8bf48b7a-0ff5-4015-81d3-ed2eeeceff1c
# Create input-output examples
examples = [HerbSpecification.IOExample(Dict(:x => x), 4x + 6) for x ∈ 1:5]

# ╔═╡ 2baa7f33-c86d-40e2-9253-720ec19e4c43
md"""
Now that we have some input-output examples, we can define the problem. 
Next to the examples, a problem also contains a name meant to link to the file path, which can be used to keep track of current examples. 
For now, this is irrelevant, and you can give the program any name you like.
"""

# ╔═╡ 059306d1-a45a-4727-ab01-1b5b80187999
problem_1 = HerbSpecification.Problem("example", examples)

# ╔═╡ e3204b9a-a97b-4f73-b6d3-d276b07cdd00
md"""
### Connecting grammar and problem specification
For the search to produce programs that use the input examples, we need to ensure that there is a rule where the right-hand side matches the symbol used in the input to the `IOExample`.
For an example like `IOExample(Dict(:x => 1), 2)`, there must be some rule like `Number = x`--the `x`'s must match, otherwise the input value will never be used in any of the programs. If you have multiple input arguments, like `IOExample(Dict(:x => 1, :name => "Alice", "1. Alice"))`, then you need two rules, such as `Number = x` and `String = name`, to construct programs that use both inputs.
If these rules don't exist yet, they need to be added (see the tutorial on [Defining Grammars in Herb.jl](.defining_grammars.md) to learn how to add rules). 
"""

# ╔═╡ 0f090666-9007-417e-a801-8231fffa19f3
md"""
### Searching

Now that we have defined the search space and the goal of the search, we can start the search. 

Of course, our problem is underdefined as there might be multiple programs that satisfy our examples. 
Let us consider the case where we also have a ternary if-then-else operator and standard boolean operators in our grammar: we could synthesize the program `x ≤ 5 ? 3x+5 : 0`. 
This program satisfies all our examples, but we don't expect it to generalize very well.

To search through a program space, we first need to define a [`HerbSearch.ProgramIterator`](@ref), which can be instantiated with different iterators, for now we use a simple [`HerbSearch.BFSIterator`](@ref). For more advanced search methods check out our tutorial on [advanced search](.advanced_search.md). For more information about iterators, check out our tutorial on [working with interpreters](.working_with_interpreters.md). 

In general, we assume that a smaller program is more general than a larger program. 
Therefore, we search for the smallest program in our grammar that satisfies our examples. 
This can be done using a breadth-first search over the program/search space.

This search is very basic; it makes use of an enumeration technique, where we enumerate programs one-by-one until we find a program that matches our examples. The search procedure has a built-in default evaluator to verify the candidate programs with the given input. The search procedure also has a built-in search procedure using breadth-first search. 

So, we only need to give our grammar and the problem to our search procedure, along with a starting `Symbol`, in our case a `Number`. 
"""

# ╔═╡ d553f37b-bc8a-4426-a98b-fb195ed994d9
iterator_1 = BFSIterator(g, :Number)

# ╔═╡ e1910236-9783-4989-a014-c3f7ccdf33d3
synth(problem_1, iterator_1)

# ╔═╡ 4c9f6236-2a84-4e76-86ab-c1fd1c7a1ba1
md"""
As you can see, the search procedure found the correct program!
"""

# ╔═╡ 8f87eed7-dfa1-47e4-a9b3-8e2a8a966207
md"""
### Defining the search procedure

In the previous case, we used the built-ins of the search procedure. However, we can also give a custom enumerator to the search procedure and define a few more values.

We first define a new problem to test with, we are looking for the programs that can compute the value `168`. We immediately pass the examples to the problem and then set up the new search.

Search is done by passing the grammar, the problem and the starting point like before. We now also specify the enumeration function to be used, and now we use depth-first search. Then, we give the maximum depth of the programs we want to search for `(3)`, the maximum number of nodes in the Abstract Syntax Tree that exists during search `(10)`, and the maximum time in seconds allowed for the search.
"""

# ╔═╡ cdab3f55-37e4-4aee-bae1-14d3475cbdcd
begin
    problem_2 = HerbSpecification.Problem("example2", [HerbSpecification.IOExample(Dict(:x => x), 168) for x ∈ 1:5])
    iterator_2 = HerbSearch.BFSIterator(g, :Number, max_depth=4, max_size=30)
    expr_2, flag_2 = HerbSearch.synth(problem_2, iterator_2)
    println(expr_2)
    program_2 = rulenode2expr(expr_2, g)
    println(program_2)
end

# ╔═╡ 5ad86beb-eb25-4bae-b0c2-a33d1a38581a
md"""
We see that our synthesizer can find a program to construct the value `168`, though a fun experiment would be trying to get the value `167`, what do you think would happen? You can try below, using the same iterator.

In any case, this concludes our first introduction to the `Herb.jl` program synthesis framework. You can see more examples in this repository, or explore yourself. Enjoy!
"""

# ╔═╡ c06d09a5-138a-4821-8a60-074fa7ec026d
begin
    problem_3 = HerbSpecification.Problem("example3", [HerbSpecification.IOExample(Dict(:x => x), 167) for x ∈ 1:5])
    expr_3, flag_3 = HerbSearch.synth(problem_3, iterator_2)
    println(expr_3)
    program_3 = rulenode2expr(expr_3, g)
    println(program_3)
end

# ╔═╡ Cell order:
# ╟─adabb7f1-7952-43c4-88a9-54225b40aaf0
# ╟─841f097d-a389-4dd2-9ad3-1a2292568634
# ╠═1212cbc3-bb49-46cb-b9a3-475815d59f2d
# ╠═1defafc5-ce65-42f0-90cd-de9e8895ec90
# ╟─db7fe47b-ab3e-4705-b6ac-2733b9e81434
# ╠═763b378b-66f9-481e-a3da-ca37825eb255
# ╟─6d01dfe8-9048-4696-916c-b33fbc97268b
# ╟─56a63f9e-b484-4d85-af3e-de2cc4476e09
# ╠═8bf48b7a-0ff5-4015-81d3-ed2eeeceff1c
# ╟─2baa7f33-c86d-40e2-9253-720ec19e4c43
# ╠═059306d1-a45a-4727-ab01-1b5b80187999
# ╟─e3204b9a-a97b-4f73-b6d3-d276b07cdd00
# ╟─0f090666-9007-417e-a801-8231fffa19f3
# ╠═d553f37b-bc8a-4426-a98b-fb195ed994d9
# ╠═e1910236-9783-4989-a014-c3f7ccdf33d3
# ╟─4c9f6236-2a84-4e76-86ab-c1fd1c7a1ba1
# ╟─8f87eed7-dfa1-47e4-a9b3-8e2a8a966207
# ╠═cdab3f55-37e4-4aee-bae1-14d3475cbdcd
# ╟─5ad86beb-eb25-4bae-b0c2-a33d1a38581a
# ╠═c06d09a5-138a-4821-8a60-074fa7ec026d
