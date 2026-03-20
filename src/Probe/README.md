# Probe

[Publication (Open Access)](https://doi.org/10.1145/3428295)

```
@article{DBLP:journals/pacmpl/BarkePP20,
  author       = {Shraddha Barke and
                  Hila Peleg and
                  Nadia Polikarpova},
  title        = {Just-in-time learning for bottom-up enumerative synthesis},
  journal      = {Proc. {ACM} Program. Lang.},
  volume       = {4},
  number       = {{OOPSLA}},
  pages        = {227:1--227:29},
  year         = {2020}
}
```

Probe is a bottom-up program synthesis strategy that alternates between enumerating candidate programs from a probabilistic grammar, keeping candidates that solve at least part of the specification, and reweighting grammar rules based on those promising partial solutions.
This implementation returns the first exact solution it finds together with the number of enumerated candidate programs. If no exact solution is found within the given budgets, it returns `nothing`.

How to run:
```julia
using Garden.Probe: probe
using Herb

# Define the grammar
grammar = @cfgrammar begin
    Start = Int
    Int = Int + Int
    Int = |(1:5)
    Int = x
end

# Define a toy problem
problem = Problem([IOExample(Dict{Symbol, Any}(:x => x), x + 1) for x in 1:5])

# Generate an interpret function:
interp = HerbInterpret.make_interpreter(
    grammar;
    input_symbols=[:x],
    target_module = @__MODULE__,
    cache_module  = @__MODULE__,
)

# Run Probe
program, programs_enumerated = probe(
    grammar,
    :Start,
    problem;
    interpret = interp,
    max_depth = 4,
    probe_cycles = 3,
)

# Print results, if existent
if isnothing(program)
    println("No solution found after enumerating $programs_enumerated programs.")
else
    println("Found after $programs_enumerated programs:")
    println(rulenode2expr(program, grammar))
end
```

For the example above, Probe should synthesize a program equivalent to `x + 1`.
