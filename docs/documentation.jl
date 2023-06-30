using Documenter

include("../src/Herb.jl")

using .Herb

using .Herb.HerbConstraints
using .Herb.HerbSearch
using .Herb.HerbGrammar 
using .Herb.HerbData
using .Herb.HerbEvaluation

makedocs(
    sitename="Herb.jl",
    pages = [
        "HerbGrammar.jl" => "HerbGrammar.md",
        "HerbSearch.jl" => "HerbSearch.md",
        "HerbConstraints.jl" => "HerbConstraints.md"
    ]
)

