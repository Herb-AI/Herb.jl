using HerbInterpret
using HerbInterpret: call_func
using HerbCore
using HerbGrammar
using Test


@testset verbose=true "HerbInterpret.jl" begin
    include("test_execute_on_input.jl")
    include("test_interpret.jl")
    include("test_call_func.jl")
    include("test_make_interpreter.jl")
end
