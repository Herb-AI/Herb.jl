module HerbTest

include("../src/Herb.jl")

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
    include("../HerbSearch.jl/test/test_iterators.jl")
end

end # module