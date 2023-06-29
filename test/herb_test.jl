module HerbTest

include("../src/Herb.jl")

using .Herb.HerbCore
using .Herb.HerbGrammar
using .Herb.HerbConstraints
using .Herb.HerbEvaluation
using .Herb.HerbSearch
using .Herb.HerbData
using Test


@testset verbose=true "Herb" begin
    include("../HerbGrammar.jl/test/test_cfg.jl")
    include("../HerbGrammar.jl/test/test_csg.jl")
    include("../HerbConstraints.jl/test/test_propagators.jl")
    include("../HerbSearch.jl/test/test_algorithms.jl")
    include("../HerbSearch.jl/test/test_context_free_iterators.jl")
    include("../HerbSearch.jl/test/test_context_sensitive_iterators.jl")
    include("../HerbSearch.jl/test/test_search_procedure.jl")
end

end # module