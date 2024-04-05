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

Julia is a perfect fit for program synthesis due to numerous reasons. Starting from scientific reasons like speed of execution and composability over to practical reasons like speed of writing Julia code. For a full ode on why to use Julia, please see [the WhyJulia manifesto](https://github.com/pitmonticone/whyjulia-manifesto/tree/main).

## Sub-Modules

Herb's functionality is distributed among several sub-packages:
- [HerbCore.jl](@ref HerbCore_docs): The core of Herb.jl defining core concepts to avoid circular dependencies.
- [HerbGrammar.jl](@ref HerbGrammar_docs):
- [HerbSpecification.jl](@ref HerbSpecification_docs):
- [HerbInterpret.jl](@ref HerbInterpret_docs):
- [HerbSearch.jl](@ref HerbSearch_docs):
- [HerbConstraints.jl](@ref HerbConstraints_docs):


## Basics

```@contents
Pages = ["install.md", "get_started.md", "concepts.md"]
```

## Advanced content

```@contents
```
