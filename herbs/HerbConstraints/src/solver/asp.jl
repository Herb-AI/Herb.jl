"""
    $(TYPEDEF)

A solver that uses [Answer Set
Programming](https://en.wikipedia.org/wiki/Answer_set_programming) to yield all
solutions for a given uniform tree.

$(TYPEDFIELDS)

An ASPSolver is instantiated with a `grammar` and a `uniform_rulenode`, automatically
calling the `solve` function to retrieve all `solutions`. The constraints of
the `grammar` and the `uniform_rulenode` are transformed to ASP rules. Then, Clingo_jll
is used to generate all solutions for this Answer Set Program. These
`solutions` can then be iterated. 
    
To use the ASP Solver, Clingo_jll must be manually specified to be used, which
automaticlaly loads the ASPExt extension module of HerbConstraints.

```julia
julia> using Clingo_jll
```
"""
mutable struct ASPSolver <: Solver
    "The grammar of the program we are solving. It likely has constraints."
    grammar::AbstractGrammar
    "The root of the uniform tree."
    uniform_rulenode::Union{RuleNode,UniformHole,StateHole}
    "All solutions (concrete programs) for the current `uniform_rulenode` given the
    `grammar` and its constraints."
    solutions::Vector{Dict{Int64,Int64}} #vector of dictionaries with key=node and value=matching rule index
    "Whether the solver is in a feasible state."
    isfeasible::Bool
    "Statistics about the solving process."
    statistics::Union{TimerOutput,Nothing}
end

"""
    ASPSolver(grammar::AbstractGrammar, uniform_rulenode::AbstractRuleNode)
"""
function HerbConstraints.ASPSolver(grammar::AbstractGrammar, uniform_rulenode::AbstractRuleNode; with_statistics=false)
    if contains_nonuniform_hole(uniform_rulenode)
        error("$(uniform_rulenode) contains non-uniform holes. The ASPSolver only works with uniform trees.")
    end
    statistics = @match with_statistics begin
        ::TimerOutput => with_statistics
        ::Bool => with_statistics ? TimerOutput("ASP Solver") : nothing
        ::Nothing => nothing
    end
    solver = ASPSolver(grammar, uniform_rulenode, Vector{Dict{Int32,Int32}}(), false, statistics)
    solve(solver)
    return solver
end

# implemented in ext/ASPExt
function solve end
