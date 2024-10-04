using Documenter:
    HTML,
    deploydocs,
    makedocs

using PlutoStaticHTML
using Pkg: Pkg

using Herb

using HerbConstraints
using HerbSearch
using HerbGrammar
using HerbInterpret
using HerbCore
using HerbSpecification

tutorials_dir = joinpath(dirname(@__DIR__), "docs", "src", "tutorials")

function build()
    println("Building notebooks in $tutorials_dir")
    use_distributed = false
    output_format = documenter_output
    bopts = BuildOptions(tutorials_dir; use_distributed, output_format)
    build_notebooks(bopts)
    Pkg.activate(@__DIR__)
    return nothing
end

build()


makedocs(
    modules=[HerbConstraints, HerbSearch, HerbGrammar, HerbSpecification, HerbInterpret, HerbCore],
    authors="PONYs",
    sitename="Herb.jl",
    pages=[
        "Basics" => [
            "index.md",
            "install.md",
            "get_started.md",
            "concepts.md"
        ],
        "Tutorials" => [
            "A more verbose getting started with Herb.jl" => "tutorials/getting_started_with_herb.md",
            "Defining Grammars in Herb.jl" => "tutorials/defining_grammars.md",
            "Advanced Search Procedures" => "tutorials/advanced_search.md",
            "Top Down Iterator" => "tutorials/TopDown.md",
            "Getting started with Constraints" => "tutorials/getting_started_with_constraints.md",
            "Working with custom interpreters" => "tutorials/working_with_interpreters.md",
            "Abstract Syntax Trees" => "tutorials/abstract_syntax_trees.md",
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
    format=HTML(
        sidebar_sitename=false,
        size_threshold=2^20,
    ),
    warnonly=[:missing_docs, :cross_references, :doctest]
)

deploydocs(;
    repo="github.com/Herb-AI/Herb.jl.git",
    devbranch="documentation",
    # devurl="dev",
    push_preview=true
)

