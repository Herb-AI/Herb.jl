module ASPExt

using HerbCore
using HerbGrammar
using HerbConstraints
using TimerOutputs
using MLStyle
using Clingo_jll

import HerbConstraints: rulenode_to_ASP, enforce_varnode_equality,
    map_varnodes_to_asp_indices, grammar_to_ASP, constraint_to_ASP,
    constraint_rulenode_to_ASP, rulenode_comparisons_asp

include("asp_tree_transformations.jl")
include("asp_constraint_transformations.jl")
include("asp_uniform_tree_solver.jl")


end # module ASPExt
