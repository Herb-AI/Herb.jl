# Search

This notebook describes how you can search a program space as defined by a grammar.
Specifically, we will look at example-based search, where the goal is to find a program that is able to transform the inputs of every example to the corresponding output.

### Setup
First, we start with the setup. We need to access to all the function in the Herb.jl framework.


```julia
using HerbGrammar, HerbSpecification, HerbSearch, HerbInterpret, HerbConstraints
```

### Defining the program space

Next, we start by creating a grammar. We define a context-free grammar (cfg) as a [`HerbGrammar.ContextSpecificGrammar`](@ref) without any constraints. A cfg is just a simple set of production rules for defining combinations of terminal symbols (in our case real numbers). 

Contrary, we could define a context-sensitive grammar, when the production rules only hold in a certain context. However, for more information on this, please see our tutorial on [defining grammars](defining_grammars.md).

For now, we specify a simple grammar for dealing with integers and explain all the rules individually:

1. First, we specify our interval `[0:9]` on real numbers and also constrain them to be integer.
2. Then, we can also use the variable `x` to hold an integer.
3. The third rule determines we can add two integers.
4. The fourth rule determines we can subtract an integer from another.
5. Finally, we also allow the multiplication of two integers.

If you run this cell, you can see all the rules rolled out.


```julia
g = HerbGrammar.@cfgrammar begin
    Real = |(0:9)
    Real = x
    Real = Real + Real
    Real = Real - Real
    Real = Real * Real
end
```


    1: Real = 0
    2: Real = 1
    3: Real = 2
    4: Real = 3
    5: Real = 4
    6: Real = 5
    7: Real = 6
    8: Real = 7
    9: Real = 8
    10: Real = 9
    11: Real = x
    12: Real = Real + Real
    13: Real = Real - Real
    14: Real = Real * Real



### Defining the problem

As mentioned before, we are looking at example-based search. 
This means that the problem is defined by a set of input-output examples. 
A single example hence consists of an input and an output.
The input is defined as a dictionary, with a value assigned to each variable in the grammar.
It is important to write the variable name as a `Symbol` instead of a string.
A `Symbol` in Julia is written with a colon prefix, i.e. `:x`. 
The output of the input-output example is just a single value for this specific grammar, but could possibly relate to e.g. arrays of values, too.

In the cell below we automatically generate some examples for `x` assigning values `1-5`.


```julia
# Create input-output examples
examples = [HerbSpecification.IOExample(Dict(:x => x), 3x+5) for x ∈ 1:5]
```


    5-element Vector{IOExample}:
     IOExample(Dict{Symbol, Any}(:x => 1), 8)
     IOExample(Dict{Symbol, Any}(:x => 2), 11)
     IOExample(Dict{Symbol, Any}(:x => 3), 14)
     IOExample(Dict{Symbol, Any}(:x => 4), 17)
     IOExample(Dict{Symbol, Any}(:x => 5), 20)


Now that we have some input-output examples, we can define the problem. 
Next to the examples, a problem also contains a name meant to link to the file path, which can be used to keep track of current examples. 
For now, this is irrelevant, and you can give the program any name you like.


```julia
problem = HerbSpecification.Problem("example", examples)
```


    Problem{Vector{IOExample}}("example", IOExample[IOExample(Dict{Symbol, Any}(:x => 1), 8), IOExample(Dict{Symbol, Any}(:x => 2), 11), IOExample(Dict{Symbol, Any}(:x => 3), 14), IOExample(Dict{Symbol, Any}(:x => 4), 17), IOExample(Dict{Symbol, Any}(:x => 5), 20)])


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

So, we only need to give our grammar and the problem to our search procedure, along with a starting `Symbol`, in our case a `Real`. 


```julia
iterator = BFSIterator(g, :Real)
```


    BFSIterator(1: Real = 0
    2: Real = 1
    3: Real = 2
    4: Real = 3
    5: Real = 4
    6: Real = 5
    7: Real = 6
    8: Real = 7
    9: Real = 8
    10: Real = 9
    11: Real = x
    12: Real = Real + Real
    13: Real = Real - Real
    14: Real = Real * Real
    , :Real, 9223372036854775807, 9223372036854775807, 9223372036854775807, 9223372036854775807)



```julia
synth(problem, iterator)
```


    (12{14{11,4}6}, optimal_program)


As you can see, the search procedure found the correct program!

### Defining the search procedure

In the previous case, we used the built-ins of the search procedure. However, we can also give a custom enumerator to the search procedure and define a few more values.

We first define a new problem to test with, we are looking for the programs that can compute the value `167`. We immediately pass the examples to the problem and then set up the new search.

Search is done by passing the grammar, the problem and the starting point like before. We now also specify the enumeration function to be used, and now we use depth-first search. Then, we give the maximum depth of the programs we want to search for `(3)`, the maximum number of nodes in the Abstract Syntax Tree that exists during search `(10)`, and the maximum time in seconds allowed for the search.


```julia
problem = HerbSpecification.Problem("example2", [HerbSpecification.IOExample(Dict(:x => x), 168) for x ∈ 1:5])
iterator = HerbSearch.BFSIterator(g, :Real, max_depth=4, max_size=30, max_time=180)
expr = HerbSearch.synth(problem, iterator)
print(expr)
```

    (14{7,14{5,8}}, optimal_program)

We see that our synthesizer can find a program to construct the value `168`, though a fun experiment would be trying to get the value `167`, what do you think would happen? You can try below, using the same iterator.

In any case, this concludes our first introduction to the `Herb.jl` program synthesis framework. You can see more examples in this repository, or explore yourself. Enjoy!


```julia
problem = HerbSpecification.Problem("example3", [HerbSpecification.IOExample(Dict(:x => x), 167) for x ∈ 1:5])
expr = HerbSearch.synth(problem, iterator)
print(expr)
```

    (12{14{7,14{10,4}}6}, optimal_program)
