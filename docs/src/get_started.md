# Getting Started

You can either paste this code into the Julia REPL or into a seperate file, e.g. `get_started.jl`.

```julia
using HerbSearch, HerbData, HerbInterpret

# define our very simple context-free grammar
# Can add and multiply an input variable x or the integers 1,2.
g = @cfgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
end

problem = Problem([IOExample(Dict(:x => x), 2x+1) for x ∈ 1:5])
solution = search(g₁, problem, :Number, max_depth=3)

test_with_input(SymbolTable(g₁), solution, Dict(:x => 6))
```

