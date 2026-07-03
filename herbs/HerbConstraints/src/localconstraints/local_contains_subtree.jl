
"""
LocalContains

Enforces that a given `tree` appears at or below the given `path` at least once.

!!! warning:
    This is a stateful constraint can only be propagated by the UniformSolver.
    The `indices` and `candidates` fields should not be set by the user.
"""
mutable struct LocalContainsSubtree <: AbstractLocalConstraint
	path::Vector{Int}
    tree::AbstractRuleNode
    candidates::Union{Vector{AbstractRuleNode}, Nothing}
    indices::Union{StateSparseSet, Nothing}
end

"""
    LocalContainsSubtree(path::Vector{Int}, tree::AbstractRuleNode)

Enforces that a given `tree` appears at or below the given `path` at least once.
"""
function LocalContainsSubtree(path::Vector{Int}, tree::AbstractRuleNode)
    LocalContainsSubtree(path, tree, Vector{AbstractRuleNode}(), nothing)
end


"""
    function propagate!(::GenericSolver, ::LocalContainsSubtree)

!!! warning:
    LocalContainsSubtree uses stateful properties and can therefore not be propagated in the GenericSolver.
    (The GenericSolver shares constraints among different states, so they cannot use stateful properties)
"""
function propagate!(::GenericSolver, ::LocalContainsSubtree)
    throw(ArgumentError("LocalContainsSubtree cannot be propagated by the GenericSolver"))
end


"""
    function propagate!(solver::UniformSolver, c::LocalContainsSubtree)

Enforce that the `tree` appears at or below the `path` at least once.
Nodes that can potentially become the target sub-tree are considered `candidates`.
In case of multiple candidates, a stateful set of `indices` is used to keep track of active candidates.
"""
function propagate!(solver::UniformSolver, c::LocalContainsSubtree)
    @timeit_debug solver.statistics "LocalContainsSubtree propagation" begin
        if isnothing(c.candidates)
            # Initial propagation: pattern match all nodes, only store the candidates for re-propagation
            c.candidates = Vector{AbstractRuleNode}()
            for node ∈ get_nodes(solver)
                @match pattern_match(c.tree, node) begin
                    ::PatternMatchHardFail => ()
                    ::PatternMatchSuccess => begin
                        @timeit_debug solver.statistics "LocalContainsSubtree satisfied (initial propagation)" begin end
                        deactivate!(solver, c);
                        return
                    end
                    ::PatternMatchSoftFail || ::PatternMatchSuccessWhenHoleAssignedTo => push!(c.candidates, node)
                end
            end
            n = length(c.candidates)
            if n == 0
                @timeit_debug solver.statistics "LocalContainsSubtree inconsistency (initial propagation)" begin end
                set_infeasible!(solver)
                return
            elseif n == 1
                @match make_equal!(solver, c.candidates[1], c.tree) begin
                    ::MakeEqualHardFail => begin
                        @assert false "pattern_match failed to detect a hardfail"
                    end
                    ::MakeEqualSuccess => begin
                        @timeit_debug solver.statistics "LocalContainsSubtree deduction (initial)" begin end
                        deactivate!(solver, c);
                        return
                    end
                    ::MakeEqualSoftFail => begin
                        @timeit_debug solver.statistics "LocalContainsSubtree softfail (1 candidate) (initial)" begin end
                        return
                    end
                end
            else
                @timeit_debug solver.statistics "LocalContainsSubtree softfail (>=2 candidates) (initial)" begin end
                c.indices = StateSparseSet(solver.sm, n)
                return
            end
        else
            # Re-propagation
            if !isnothing(c.indices) && (size(c.indices) >= 2)
                # Update the candidates by pattern matching them again
                for i ∈ c.indices
                    match = pattern_match(c.candidates[i], c.tree)
                    @match match begin
                        ::PatternMatchHardFail => remove!(c.indices, i)
                        ::PatternMatchSuccess => begin
                            @timeit_debug solver.statistics "LocalContainsSubtree satisfied" begin end
                            deactivate!(solver, c);
                            return
                        end
                        ::PatternMatchSoftFail || ::PatternMatchSuccessWhenHoleAssignedTo => ()
                    end
                end
            end
            n = isnothing(c.indices) ? 1 : size(c.indices)
            if n == 1
                # If there is a single candidate remaining, set it equal to the target tree
                index = isnothing(c.indices) ? 1 : findfirst(c.indices)
                @match make_equal!(solver, c.candidates[index], c.tree) begin
                    ::MakeEqualHardFail => begin
                        @timeit_debug solver.statistics "LocalContainsSubtree inconsistency" begin end
                        set_infeasible!(solver)
                        return
                    end
                    ::MakeEqualSuccess => begin
                        @timeit_debug solver.statistics "LocalContainsSubtree deduction" begin end
                        deactivate!(solver, c);
                        return
                    end
                    ::MakeEqualSoftFail => begin
                        @timeit_debug solver.statistics "LocalContainsSubtree softfail (1 candidate)" begin end
                        return
                    end
                end
            elseif n == 0
                @timeit_debug solver.statistics "LocalContainsSubtree inconsistency" begin end
                set_infeasible!(solver)
                return
            end
            @timeit_debug solver.statistics "LocalContainsSubtree softfail (>=2 candidates)" begin end
        end
    end
end
