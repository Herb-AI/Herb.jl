@enum SynthResult optimal_program = 1 suboptimal_program = 2

struct NoProgramFoundError <: Exception
    message::String
end
