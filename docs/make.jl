using Documenter

include("../src/Herb.jl")

using .Herb

using HerbConstraints
using HerbSearch
using HerbGrammar 
using HerbData
using HerbEvaluation
using HerbCore

makedocs(;
    modules=[HerbConstraints, HerbSearch, HerbGrammar, HerbData, HerbEvaluation, HerbCore],
    authors="SEBs",
    sitename="Herb.jl",
    repo="https://github.com/Herb-AI/Herb.jl",
    pages = [
        "Home" => "index.md",
        "Sub-Modules" => [
        "HerbGrammar.jl" => "HerbGrammar.md",
        "HerbSearch.jl" => "HerbSearch.md",
        "HerbConstraints.jl" => "HerbConstraints.md",
        "HerbCore.jl" => "HerbData.md",
        "HerbEvaluation.jl" => "HerbEvaluation.md",
        "HerbData.jl" => "HerbData.md",
       ],
    ],
)

deploydocs(;
    repo="github.com/Herb-AI/Herb.jl.git",
    devbranch="documentation",
)

