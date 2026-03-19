module Garden

using DocStringExtensions

include("utils.jl")
include("probe/Probe.jl")
include("frangel/method.jl")

export 
    Probe,
    NoProgramFoundError,
    SynthResult,
    FrAngel

end # module Garden
