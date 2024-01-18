using Documenter

using Herb

using HerbConstraints
using HerbSearch
using HerbGrammar 
using HerbData
using HerbInterpret
using HerbCore

makedocs(;
    modules=[HerbConstraints, HerbSearch, HerbGrammar, HerbData, HerbInterpret, HerbCore],
    authors="SEBs",
    sitename="Herb.jl",
    repo="https://github.com/Herb-AI/Herb.jl",
    pages = [
        "Basics" => [
            "index.md",
            "install.md",
            "get_started.md",
            "concepts.md"
           ],
        "Tutorials" => [
            "A more verbose getting started with Herb.jl" => "tutorials/getting_started_with_herb.md",
            "Defining Grammars in Herb.jl" => "tutorials/defining_grammars.md"
            "Advanced Search Procedures" => "tutorials/advanced_search.md"
        ],
        "Sub-Modules" => [
            "HerbGrammar.jl" => "HerbGrammar/index.md",
            "HerbSearch.jl" => "HerbSearch/index.md",
            "HerbConstraints.jl" => "HerbConstraints/index.md",
            "HerbCore.jl" => "HerbData/index.md",
            "HerbInterpret.jl" => "HerbInterpret/index.md",
            "HerbData.jl" => "HerbData/index.md",
       ],
    ],
)

deploydocs(;
    repo="github.com/Herb-AI/Herb.jl.git",
    devbranch="documentation",
    devurl="dev",
)

