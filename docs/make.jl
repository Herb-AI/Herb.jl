using Documenter

using Herb

using HerbConstraints
using HerbSearch
using HerbGrammar 
using HerbInterpret
using HerbCore
using HerbSpecification

# Use jupyter.nbconver to convert notebooks to markdown
using PyCall
jupyter = pyimport("jupyterlab")
nbconvert = pyimport("nbconvert")
all_notebooks = readdir("docs/src/tutorials/")
for file in all_notebooks
    if occursin("ipynb", file)
        path = "docs/src/tutorials/" *  file
        run(`jupyter nbconvert --to markdown $path`)
    end
end

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
            "Advanced Search Procedures" => "tutorials/advanced_search.md",
            "Getting started with Constraints" => "tutorials/getting_started_with_constraints.md",
            "Working with custom interpreters" => "tutorials/working_with_interpreters.html"
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

