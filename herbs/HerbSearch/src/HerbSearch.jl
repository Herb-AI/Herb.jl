module HerbSearch

using DataStructures

using HerbCore
using HerbGrammar
using HerbConstraints
using HerbInterpret
using HerbSpecification
using MLStyle

using DocStringExtensions
using TimerOutputs

include("sampling_grammar.jl")

include("program_iterator.jl")
include("uniform_iterator.jl")
include("uniform_asp_iterator.jl")

include("heuristics.jl")

include("top_down_iterator.jl")

include("evaluate.jl")

include("search_procedure.jl")

include("stochastic_iterator.jl")
include("stochastic_functions/cost_functions.jl")
include("stochastic_functions/neighbourhood.jl")
include("stochastic_functions/propose.jl")
include("stochastic_functions/accept.jl")
include("stochastic_functions/temperature.jl")

include("genetic_functions/fitness.jl")
include("genetic_functions/mutation.jl")
include("genetic_functions/crossover.jl")
include("genetic_functions/select_parents.jl")
include("genetic_search_iterator.jl")

include("random_iterator.jl")

include("bottom_up_iterator.jl")
include("bottom_up_iterators/costbased_bus.jl")
include("bottom_up_iterators/shapebased_bus.jl")


# include("divide_conquer_functions/divide.jl")
# include("divide_conquer_functions/decide.jl")
# include("divide_conquer_functions/conquer.jl")

function divide_and_conquer end

export
    ProgramIterator,
    @programiterator, 
    get_solver,
    heuristic_leftmost,
    heuristic_rightmost,
    heuristic_random,
    heuristic_smallest_domain, derivation_heuristic, synth,
    SynthResult,
    optimal_program,
    suboptimal_program, UniformIterator,
    next_solution!, TopDownIterator,
	UniformASPIterator,
    RandomIterator,
    BFSIterator,
    DFSIterator,
    MLFSIterator, MHSearchIterator,
    VLSNSearchIterator,
    SASearchIterator, mean_squared_error,
    misclassification, GeneticSearchIterator,
    misclassification,
    validate_iterator,
    sample,
    rand,

    # Bottom-up Searches
    BottomUpState,
    BottomUpIterator,
    AbstractAddress,
    SizeBasedBottomUpIterator,
    DepthBasedBottomUpIterator,
    CostBasedBottomUpIterator,
    AccessAddress,
    CombineAddress,
    remaining_combinations,
    state_tracker,
    new_combinations!,
    new_state_tracker!,
    has_remaining_iterations,
    GenericBUState,
    populate_bank!,
    combine,
    add_to_bank!,
    new_address,
    retrieve,
    init_combine_structure,
    get_bank,

    divide_and_conquer,
    EvaluationError,
    get_solver
end # module HerbSearch
