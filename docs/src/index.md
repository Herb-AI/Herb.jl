```@meta
CurrentModule=Herb
```

# [Herb.jl](https://github.com/Herb-AI/Herb.jl)
*A library for defining and efficiently solving program synthesis tasks in Julia.*

## Why Herb.jl?

When writing research software we almost always investigate highly specific properties or algorithms of our domain, leading to us building the tools from scratch over and over again. The very same holds for the field of program synthesis: Tools are hard to run, benchmarks are hard to get and prepare, and its hard to adapt our existing code to a novel idea.

Herb.jl will take care of this for you and helps you defining, solving and extending your program synthesis problems.

Herb.jl provides...
- a unified and universal framework for program synthesis
- `Herb.jl` allows you to describe all sorts of program synthesis problems using context-free grammars
- a number of state-of-the-art benchmarks and solvers already implemented and usable out-of-the-box

Herb.jl's sub-packages provide fast and easily extendable implementations of 
- various static and dynamic search strategies,
- learning search strategies, sampling techniques and more,
- constraint formulation and propagation, 
- easy grammar formulation and usage,
- wide-range of usable program interpreters and languages + the possibility to use your own, and 
- efficient data formulation.

## Why Julia?


## Sub-Modules

Herb's functionality is distributed among several sub-packages:
- [HerbCore.jl](@ref HerbCore_docs): The core of Herb.jl defining core concepts to avoid circular dependencies.
- [HerbGrammar.jl](@ref HerbGrammar_docs):
- [HerbData.jl](@ref HerbData_docs):
- [HerbEvaluation.jl](@ref HerbEvaluation_docs):
- [HerbSearch.jl](@ref HerbSearch_docs):
- [HerbConstraints.jl](@ref HerbConstraints_docs):


## Basics:

```@contents
Pages = [ "def_pomdp.md", "interfaces.md"]
Depth = 3
```



```@contents
```

## Index

This is the index.

```@index
```


