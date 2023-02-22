module HerbTest

include("../src/Herb.jl")

using .Herb.Grammars
using .Herb.Constraints
using .Herb.Evaluation
using .Herb.Search
using .Herb.Data
using Test


@testset verbose=true "Herb" begin
    include("../Grammar.jl/test/test_cfg.jl")
    include("../Grammar.jl/test/test_csg.jl")
    include("../Constraints.jl/test/test_propagators.jl")
    include("../Search.jl/test/test_iterators.jl")
end

end # module