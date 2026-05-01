using HerbSearch: BFSIterator
using BenchmarkTools: @bprofile
using ProfileView: ProfileView

include("../benchmarks.jl")

function profile_length(g)
    res = @bprofile length(it) setup = (it = BFSIterator($g, :Int; max_size=10))
    display(res)
    ProfileView.view()
end
