"""
$(TESTABLEREADME)
"""
module HerbBenchmarks

using HerbCore
using HerbSpecification
using HerbGrammar
using DocStringExtensions

include("utils/docstrings.jl")

include("utils/SExpressionParser.jl")

include("utils/benchmarks_io.jl")
include("utils/problem_fetcher.jl")

# Include data types
include("datatypes/problem_grammar_pair.jl")
include("datatypes/benchmark.jl")

include("data/Abstract_Reasoning_2019/Abstract_Reasoning_2019.jl")
include("data/DeepCoder_2016/DeepCoder_2016.jl")
include("data/Pixels_2020/Pixels_2020.jl")
include("data/Robots_2020/Robots_2020.jl")
include("data/String_transformations_2020/String_transformations_2020.jl")
include("data/SyGuS/PBE_BV_Track_2018/PBE_BV_Track_2018.jl")
include("data/SyGuS/PBE_SLIA_Track_2019/PBE_SLIA_Track_2019.jl")

export
    # Data types
    ProblemGrammarPair,
    Benchmark,

    # utils
    parse_file,
    write_problem,
    parse_to_julia,
    append_cfgrammar,
    enumerate_problem_files,

    # Problem fetcher
    get_all_benchmarks,
    get_benchmark,
    get_all_problem_grammar_pairs,
    get_all_problems,
    get_all_identifiers,
    get_problem_grammar_pair,
    get_problem,
    get_grammar,
    get_default_grammar
end # module HerbBenchmarks
