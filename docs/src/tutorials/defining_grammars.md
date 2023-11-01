# Defining Grammars in Herb.jl using `HerbGrammar`

The program space in Herb.jl is defined using a grammar. 
This notebook demonstrates how such a grammar can be created. 
There are multiple kinds of grammars, but they can all be defined in a very similar way.

### Setup

```julia
using HerbGrammar, HerbConstraints
```

### Creating a simple grammar

This cell contains a very simple arithmetic grammar. 
The grammar is defined using the `@cfgrammar` macro. 
This macro converts the grammar definition in the form of a Julia expression into Herb's internal grammar representation. 
Macro's are executed during compilation.
If you want to load a grammar during execution, have a look at the `HerbGrammar.expr2cfgrammar` function.


```julia
g₁ = HerbGrammar.@cfgrammar begin
    Int = 1
    Int = 2
    Int = 3
    Int = Int * Int
    Int = Int + Int
end
```


    1: Int = 1
    2: Int = 2
    3: Int = 3
    4: Int = Int * Int
    5: Int = Int + Int



Defining every integer one-by-one can be quite tedious. Therefore, it is also possible to use the following syntax that makes use of a Julia iterator:


```julia
g₂ = HerbGrammar.@cfgrammar begin
    Int = |(0:9)
    Int = Int * Int
    Int = Int + Int
end
```


    1: Int = 0
    2: Int = 1
    3: Int = 2
    4: Int = 3
    5: Int = 4
    6: Int = 5
    7: Int = 6
    8: Int = 7
    9: Int = 8
    10: Int = 9
    11: Int = Int * Int
    12: Int = Int + Int



You can do the same with lists:


```julia
g₃ = HerbGrammar.@cfgrammar begin
    Int = |([0, 2, 4, 6, 8])
    Int = Int * Int
    Int = Int + Int
end
```


    1: Int = 0
    2: Int = 2
    3: Int = 4
    4: Int = 6
    5: Int = 8
    6: Int = Int * Int
    7: Int = Int + Int



Variables can also be added to the grammar by just using the variable name:


```julia
g₄ = HerbGrammar.@cfgrammar begin
    Int = |(0:9)
    Int = Int * Int
    Int = Int + Int
    Int = x
end
```


    1: Int = 0
    2: Int = 1
    3: Int = 2
    4: Int = 3
    5: Int = 4
    6: Int = 5
    7: Int = 6
    8: Int = 7
    9: Int = 8
    10: Int = 9
    11: Int = Int * Int
    12: Int = Int + Int
    13: Int = x



Grammars can also work with functions. 
After all, `+` and `*` are just infix operators for Julia's identically-named functions.
You can use functions that are provided by Julia, or functions that you wrote yourself:


```julia
f(a) = a + 1

g₅ = HerbGrammar.@cfgrammar begin
    Int = |(0:9)
    Int = Int * Int
    Int = Int + Int
    Int = f(Int)
    Int = x
end
```


    1: Int = 0
    2: Int = 1
    3: Int = 2
    4: Int = 3
    5: Int = 4
    6: Int = 5
    7: Int = 6
    8: Int = 7
    9: Int = 8
    10: Int = 9
    11: Int = Int * Int
    12: Int = Int + Int
    13: Int = f(Int)
    14: Int = x



Similarly, we can also define the operator times (x) manually.


```julia
×(a, b) = a * b

g₆ = HerbGrammar.@cfgrammar begin
    Int = |(0:9)
    Int = a
    Int = Int + Int
    Int = Int × Int
end
```


    1: Int = 0
    2: Int = 1
    3: Int = 2
    4: Int = 3
    5: Int = 4
    6: Int = 5
    7: Int = 6
    8: Int = 7
    9: Int = 8
    10: Int = 9
    11: Int = a
    12: Int = Int + Int
    13: Int = Int × Int



### Working with grammars

If you want to implement something using these grammars, it is useful to know about the functions that you can use to manipulate grammars and extract information. 
This section is not necessarily complete, but it aims to give an overview of the most important functions. 

It is recommended to also read up on [Julia metaprogramming](https://docs.julialang.org/en/v1/manual/metaprogramming/) if you are not already familiar with that.

One of the most important things about grammars is that each rule has an index associated with it:


```julia
g₇ = HerbGrammar.@cfgrammar begin
    Int = |(0:9)
    Int = Int + Int
    Int = Int * Int
    Int = x
end

collect(enumerate(g₇.rules))
```


    13-element Vector{Tuple{Int64, Any}}:
     (1, 0)
     (2, 1)
     (3, 2)
     (4, 3)
     (5, 4)
     (6, 5)
     (7, 6)
     (8, 7)
     (9, 8)
     (10, 9)
     (11, :(Int + Int))
     (12, :(Int * Int))
     (13, :x)


We can use this index to extract information from the grammar.

### isterminal

`isterminal` returns `true` if a rule is terminal, i.e. it cannot be expanded. For example, rule 1 is terminal, but rule 11 is not, since it contains the non-terminal symbol `:Int`. 


```julia
HerbGrammar.isterminal(g₇, 1)
```


    true



```julia
HerbGrammar.isterminal(g₇, 11)
```


    false


### return_type

This function is rather obvious; it returns the non-terminal symbol that corresponds to a certain rule. The return type for all rules in our grammar is `:Int`.


```julia
HerbGrammar.return_type(g₇, 11)
```


    :Int


### child_types

`child_types` returns the types of the nonterminal children of a rule in a vector.
If you just want to know how many children a rule has, and not necessarily which types they have, you can use `nchildren`


```julia
HerbGrammar.child_types(g₇, 11)
```


    2-element Vector{Symbol}:
     :Int
     :Int



```julia
HerbGrammar.nchildren(g₇, 11)
```


    2


### nonterminals

The `nonterminals` function can be used to obtain a list of all nonterminals in the grammar.


```julia
HerbGrammar.nonterminals(g₇)
```


    1-element Vector{Symbol}:
     :Int


### Adding rules

It is also possible to add rules to a grammar during execution. This can be done using the `add_rule!` function.
As with most functions in Julia that end with an exclamation mark, this function modifies its argument (the grammar).

A rule can be provided in the same syntax as is used in the grammar definition.
The rule should be of the `Expr` type, which is a built-in type for representing expressions. 
An easy way of creating `Expr` values in Julia is to encapsulate it in brackets and use a colon as prefix:


```julia
HerbGrammar.add_rule!(g₇, :(Int = Int - Int))
```


    1: Int = 0
    2: Int = 1
    3: Int = 2
    4: Int = 3
    5: Int = 4
    6: Int = 5
    7: Int = 6
    8: Int = 7
    9: Int = 8
    10: Int = 9
    11: Int = Int + Int
    12: Int = Int * Int
    13: Int = x
    14: Int = Int - Int



### Removing rules

It is also possible to remove rules in Herb.jl, however, this is a bit more involved. 
As said before, rules have an index associated with them. 
The internal representation of programs that are defined by the grammar makes use of those indices for efficiency.
Blindly removing a rule would shift the indices of other rules, and this could mean that existing programs get a different meaning or become invalid. 

Therefore, there are two functions for removing rules:

- `remove_rule!` removes a rule from the grammar, but fills its place with a placeholder. Therefore, the indices stay the same, and only programs that use the removed rule become invalid.
- `cleanup_removed_rules!` removes all placeholders and shifts the indices of the other rules.



```julia
HerbGrammar.remove_rule!(g₇, 11)
```


    1: Int = 0
    2: Int = 1
    3: Int = 2
    4: Int = 3
    5: Int = 4
    6: Int = 5
    7: Int = 6
    8: Int = 7
    9: Int = 8
    10: Int = 9
    11: nothing = nothing
    12: Int = Int * Int
    13: Int = x
    14: Int = Int - Int




```julia
HerbGrammar.cleanup_removed_rules!(g₇)
```


    1: Int = 0
    2: Int = 1
    3: Int = 2
    4: Int = 3
    5: Int = 4
    6: Int = 5
    7: Int = 6
    8: Int = 7
    9: Int = 8
    10: Int = 9
    11: Int = Int * Int
    12: Int = x
    13: Int = Int - Int



## Context-sensitive grammars

Context-sensitive grammars allow additional constraints to be added with respect to context-free grammars.
The syntax for defining a context-sensitive grammar is identical to defining a context-sensitive grammar:


```julia
g₈ = HerbGrammar.@csgrammar begin
    Int = |(0:9)
    Int = Int + Int
    Int = Int * Int
    Int = x
end
```


    1: Int = 0
    2: Int = 1
    3: Int = 2
    4: Int = 3
    5: Int = 4
    6: Int = 5
    7: Int = 6
    8: Int = 7
    9: Int = 8
    10: Int = 9
    11: Int = Int + Int
    12: Int = Int * Int
    13: Int = x



Constraints can be added using the `addconstraint!` function, which takes a context-sensitive grammar and a constraint and adds the constraint to the grammar.
Currently, Herb.jl only has propagators constraints. 
These constraints each have a corresponding `propagate` function that removes all options that violate that constraint from the domain. 
At the moment, there are three propagator constraints:

- `ComesAfter(rule, predecessors)`: It is only possible to use rule `rule` when `predecessors` are in its path to the root.
- `Forbidden(sequence)`: Forbids the derivation specified as a path in an expression tree.
- `Ordered(order)`: Rules have to be used in the specified order. That is, rule at index K can only be used if rules at indices `[1...K-1]` are used in the left subtree of the current expression.

Below, an example is given of a context-sensitive grammar with a `ComesAfter` constraint:


```julia
HerbGrammar.addconstraint!(g₈, HerbConstraints.ComesAfter(1, [9]))
```


    1-element Vector{Main.HerbCore.Constraint}:
     Main.HerbConstraints.ComesAfter(1, [9])


### Probabilistic grammars

Herb.jl also supports probabilistic grammars. 
These grammars allow the user to assign a probability to each rule in the grammar.
A probabilistic grammar can be defined in a very similar way to a standard grammar, but has some slightly different syntax:


```julia
g₉ = HerbGrammar.@pcfgrammar begin
    0.4 : Int = |(0:9)
    0.2 : Int = Int + Int
    0.1 : Int = Int * Int
    0.3 : Int = x
end

for r ∈ 1:length(g₃.rules)
    p = HerbGrammar.probability(g₈, r)

    println("$p : $r")
end
```

    0.07692307692307693 : 1
    0.07692307692307693 : 2
    0.07692307692307693 : 3
    0.07692307692307693 : 4
    0.07692307692307693 : 5
    0.07692307692307693 : 6
    0.07692307692307693 : 7


    ┌ Warning: Requesting probability in a non-probabilistic grammar.
    │ Uniform distribution is assumed.
    └ @ Main.HerbGrammar d:\GitHub\HerbGrammar.jl\src\grammar_base.jl:155
    ┌ Warning: Requesting probability in a non-probabilistic grammar.
    │ Uniform distribution is assumed.
    └ @ Main.HerbGrammar d:\GitHub\HerbGrammar.jl\src\grammar_base.jl:155
    ┌ Warning: Requesting probability in a non-probabilistic grammar.
    │ Uniform distribution is assumed.
    └ @ Main.HerbGrammar d:\GitHub\HerbGrammar.jl\src\grammar_base.jl:155
    ┌ Warning: Requesting probability in a non-probabilistic grammar.
    │ Uniform distribution is assumed.
    └ @ Main.HerbGrammar d:\GitHub\HerbGrammar.jl\src\grammar_base.jl:155
    ┌ Warning: Requesting probability in a non-probabilistic grammar.
    │ Uniform distribution is assumed.
    └ @ Main.HerbGrammar d:\GitHub\HerbGrammar.jl\src\grammar_base.jl:155
    ┌ Warning: Requesting probability in a non-probabilistic grammar.
    │ Uniform distribution is assumed.
    └ @ Main.HerbGrammar d:\GitHub\HerbGrammar.jl\src\grammar_base.jl:155
    ┌ Warning: Requesting probability in a non-probabilistic grammar.
    │ Uniform distribution is assumed.
    └ @ Main.HerbGrammar d:\GitHub\HerbGrammar.jl\src\grammar_base.jl:155


The numbers before each rule represent the probability assigned to that rule.
The total probability for each return type should add up to 1.0.
If this isn't the case, Herb.jl will normalize the probabilities.

If a single line in the grammar definition represents multiple rules, such as `0.4 : Int = |(0:9)`, the probability will be evenly divided over all these rules.

## File writing

### Saving & loading context-free grammars

If you want to store a grammar on the disk, you can use the `store_cfg`, `read_cfg` and functions to store and read grammars respectively. 
The `store_cfg` grammar can also be used to store probabilistic grammars. Reading probabilistic grammars can be done using `read_pcfg`.
The stored grammar files can also be opened using a text editor to be modified, as long as the contents of the file doesn't violate the syntax for defining grammars.


```julia
HerbGrammar.store_cfg("demo.txt", g₇)
```


```julia
HerbGrammar.read_cfg("demo.txt")
```


    1: Int = 0
    2: Int = 1
    3: Int = 2
    4: Int = 3
    5: Int = 4
    6: Int = 5
    7: Int = 6
    8: Int = 7
    9: Int = 8
    10: Int = 9
    11: Int = Int * Int
    12: Int = x
    13: Int = Int - Int



### Saving & loading context-sensitive grammars

Saving and loading context-sensitive grammars is very similar to how it is done with context-free grammars.
The only difference is that an additional file is created for the constraints. 
The file that contains the grammars can be edited and can also be read using the reader for context-free grammars.
The file that contains the constraints cannot be edited.


```julia
HerbGrammar.store_csg("demo.grammar", "demo.constraints", g₈)
g₈, g₈.constraints
```


    (1: Int = 0
    2: Int = 1
    3: Int = 2
    4: Int = 3
    5: Int = 4
    6: Int = 5
    7: Int = 6
    8: Int = 7
    9: Int = 8
    10: Int = 9
    11: Int = Int + Int
    12: Int = Int * Int
    13: Int = x
    , Main.HerbCore.Constraint[Main.HerbConstraints.ComesAfter(1, [9])])



```julia
g₉ = HerbGrammar.read_csg("demo.grammar", "demo.constraints")
g₉, g₉.constraints
```


    (1: Int = 0
    2: Int = 1
    3: Int = 2
    4: Int = 3
    5: Int = 4
    6: Int = 5
    7: Int = 6
    8: Int = 7
    9: Int = 8
    10: Int = 9
    11: Int = Int + Int
    12: Int = Int * Int
    13: Int = x
    , Main.HerbCore.Constraint[Main.HerbConstraints.ComesAfter(1, [9])])

