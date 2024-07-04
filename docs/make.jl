using Documenter

using Herb

using HerbConstraints
using HerbSearch
using HerbGrammar 
using HerbInterpret
using HerbCore
using HerbSpecification

makedocs(
    modules=[HerbConstraints, HerbSearch, HerbGrammar, HerbSpecification, HerbInterpret, HerbCore],
    authors="PONYs",
    sitename="Herb.jl",
    pages = [
        "Basics" => [
            "index.md",
            "install.md",
            "get_started.md",
            "concepts.md"
           ],
        "Tutorials" => [
            "A more verbose getting started with Herb.jl" => "tutorials/getting_started_with_herb.md",
            "Defining Grammars in Herb.jl" => "tutorials/defining_grammars.md",
            "Advanced Search Procedures" => "tutorials/advanced_search.md"
            "Top Down Iterator" => "tutorials/TopDown"
        ],
        "Sub-Modules" => [
            "HerbCore.jl" => "HerbCore/index.md",
            "HerbGrammar.jl" => "HerbGrammar/index.md",
            "HerbSpecification.jl" => "HerbSpecification/index.md",
            "HerbInterpret.jl" => "HerbInterpret/index.md",
            "HerbConstraints.jl" => "HerbConstraints/index.md",
            "HerbSearch.jl" => "HerbSearch/index.md",
       ],
    ],
    format = Documenter.HTML(        
        sidebar_sitename = false
    ),
    warnonly = [:missing_docs, :cross_references, :doctest]
)

deploydocs(;
    repo="github.com/Herb-AI/Herb.jl.git",
    devbranch="documentation",
    # devurl="dev",
    push_preview=true
)

