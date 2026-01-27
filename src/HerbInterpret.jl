module HerbInterpret

using HerbCore
using HerbGrammar
using HerbSpecification

include("interpreter.jl")
include("make_interpret.jl")

export 
    SymbolTable,
    interpret,

    @make_interpreter,
    execute_on_input,
    build_match_cases,
    get_relevant_tags
end # module HerbInterpret
