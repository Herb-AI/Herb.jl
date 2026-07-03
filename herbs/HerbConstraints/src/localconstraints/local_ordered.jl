"""
Enforces an order over two or more subtrees that fill the variables 
specified in `order` when the pattern is applied at the location given by `path`.
Use an `Ordered` constraint for enforcing this throughout the entire search space.
"""
mutable struct LocalOrdered <: AbstractLocalConstraint
    path::Vector{Int}
    tree::AbstractRuleNode
    order::Vector{Symbol}
end

"""
    function propagate!(solver::Solver, c::LocalOrdered)

Enforce that the [`VarNode`](@ref)s in the `tree` are in the specified `order`.
First the node located at the `path` is matched to see if the ordered constraint applies here.
The nodes matching the variables are stored in the `vars` dictionary.
Then the `order` is enforced within the [`make_less_than_or_equal!`](@ref) tree manipulation.   
"""
function propagate!(solver::Solver, c::LocalOrdered)
    @assert isfeasible(solver)
    node = get_node_at_location(solver, c.path)
    @timeit_debug solver.statistics "LocalOrdered propagation" begin end
    vars = Dict{Symbol, AbstractRuleNode}()
    @match pattern_match(node, c.tree, vars) begin
        ::PatternMatchHardFail => begin 
            # A match fail means that the constraint is already satisfied.
            # This constraint does not have to be re-propagated.
            deactivate!(solver, c)
            @timeit_debug solver.statistics "LocalOrdered match hardfail" begin end
        end;
        ::PatternMatchSoftFail || ::PatternMatchSuccessWhenHoleAssignedTo => begin 
            # The constraint will re-propagated on any tree manipulation.
            @timeit_debug solver.statistics "LocalOrdered match softfail" begin end
            ()
        end
        ::PatternMatchSuccess => begin 
            # The forbidden tree is exactly matched.
            should_deactivate = true 
            for (name1, name2) ∈ zip(c.order[1:end-1], c.order[2:end])
                # Removing rules is handled inside make_less_than_or_equal!
                @match make_less_than_or_equal!(solver, vars[name1], vars[name2]) begin
                    ::LessThanOrEqualHardFail => begin
                        # vars[name1] > vars[name2]. This means the state is infeasible.
                        @timeit_debug solver.statistics "LocalOrdered inconsistency" begin end
                        set_infeasible!(solver) #throw(InconsistencyException())
                        return
                    end
                    ::LessThanOrEqualSoftFail => begin
                        # vars[name1] <= vars[name2] and vars[name1] > vars[name2] still possible
                        should_deactivate = false
                    end
                    ::LessThanOrEqualSuccess => begin
                        # vars[name1] <= vars[name2]. the constaint is satisfied. repropagation is never needed.
                        ()
                    end
                end
            end
            if should_deactivate
                deactivate!(solver, c)
            end
        end
    end
end
