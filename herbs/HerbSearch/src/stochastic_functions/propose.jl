"""
The propose functions return the fully constructed proposed programs given a path to a location to fill in.
"""

"""
    random_fill_propose(solver::Solver, path::Vector{Int}, dict::Union{Nothing,Dict{String,Any}}, nr_random=5)

Returns a list with only one proposed, completely random, subprogram.
# Arguments
- `solver::solver`: solver
- `path::Vector{Int}`: path to the location to be filled.
- `dict::Dict{String, Any}`: the dictionary with additional arguments; not used.
- `nr_random`=1 : the number of random subprograms to be generated.
"""
function random_fill_propose(solver::Solver, path::Vector{Int}, dict::Union{Nothing,Dict{String,Any}}, nr_random=1)
    return Iterators.take(RandomSearchIterator(solver, path), nr_random)
end 

"""
    enumerate_neighbours_propose(enumeration_depth::Int64)

The return function is a function that produces a list with all the subprograms with depth at most `enumeration_depth`.
"""
function enumerate_neighbours_propose(enumeration_depth::Int64)
    return (solver::Solver, path::Vector{Int}, dict::Union{Nothing,Dict{String,Any}}) -> begin
        return BFSIterator(solver)
    end
end
    

