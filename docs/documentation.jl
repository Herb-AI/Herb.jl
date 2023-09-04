using Documenter

include("../src/Herb.jl")

using .Herb

using HerbConstraints
using HerbSearch
using HerbGrammar 
using HerbData
using HerbEvaluation

makedocs(
    sitename="Herb.jl",
    pages = [
        "HerbGrammar.jl" => "HerbGrammar.md",
        "HerbSearch.jl" => "HerbSearch.md",
        "HerbConstraints.jl" => "HerbConstraints.md"
    ]
)

