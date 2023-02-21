module HerbTest

include("../src/Herb.jl")

using .Herb.Grammars
using .Herb.Evaluation
using .Herb.Search
using .Herb.Data
using Test

# include("../Grammar.jl/test/test_cfg.jl")
include("../Search.jl/test/test_iterators.jl")

end