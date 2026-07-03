"""
    abstract type LessThanOrEqualResult end

A result of the `less_than_or_equal` function. Can be one of 3 cases:
- [`LessThanOrEqualSuccess`](@ref)
- [`LessThanOrEqualHardFail`](@ref)
- [`LessThanOrEqualSoftFail`](@ref)
"""
abstract type LessThanOrEqualResult end


"""
    abstract type LessThanOrEqualSuccess <: LessThanOrEqualResult

`node1` <= `node2` is guaranteed under all possible assignments of the holes involved.
The strictness of a LessThanOrEqualSuccess is specified by 1 of 2 concrete cases:
- [`LessThanOrEqualSuccessLessThan`](@ref): `node1` < `node2`
- [`LessThanOrEqualSuccessEquality`](@ref): `node1` == `node2`
- [`LessThanOrEqualSuccessWithHoles`](@ref): `node1` <= `node2`. Unable to specific.
"""
abstract type LessThanOrEqualSuccess <: LessThanOrEqualResult end


"""
    struct LessThanOrEqualSuccessEquality <: LessThanOrEqualSuccess end

`node1` < `node2` is guaranteed under all possible assignments of the holes involved.
"""
struct LessThanOrEqualSuccessLessThan <: LessThanOrEqualSuccess end


"""
    struct LessThanOrEqualSuccessEquality <: LessThanOrEqualSuccess end

`node1` == `node2` is guaranteed under all possible assignments of the holes involved.
"""
struct LessThanOrEqualSuccessEquality <: LessThanOrEqualSuccess end


"""
    struct LessThanOrEqualSuccessWithHoles <: LessThanOrEqualSuccess end

`node1` <= `node2` is guaranteed under all possible assignments of the holes involved.
Because of the holes involved, it is not possible to specify '<' or '=='.
"""
struct LessThanOrEqualSuccessWithHoles <: LessThanOrEqualSuccess end


"""
    struct LessThanOrEqualHardFail <: LessThanOrEqualResult end

`node1` > `node2` is guaranteed under all possible assignments of the holes involved.
"""
struct LessThanOrEqualHardFail <: LessThanOrEqualResult end


"""
    struct LessThanOrEqualSoftFail <: LessThanOrEqualResult

`node1` <= `node2` and `node1` > `node2` are both possible depending on the assignment of `hole1` and `hole2`.
Includes two cases:
- hole2::AbstractHole: A failed `AbstractHole`-`AbstractHole` comparison. (e.g. AbstractHole(BitVector((1, 0, 1))) vs AbstractHole(BitVector((0, 1, 1))))
- hole2::Nothing: A failed `AbstractHole`-`RuleNode` comparison. (e.g. AbstractHole(BitVector((1, 0, 1))) vs RuleNode(2))
"""
struct LessThanOrEqualSoftFail <: LessThanOrEqualResult
    hole1::AbstractHole
    hole2::Union{AbstractHole, Nothing}
end

LessThanOrEqualSoftFail(hole) = LessThanOrEqualSoftFail(hole, nothing)


"""
    function make_less_than_or_equal!(h1::Union{RuleNode, AbstractHole}, h2::Union{RuleNode, AbstractHole})::LessThanOrEqualResult

Ensures that n1<=n2 by removing impossible values from holes. Returns one of the following results:
- [`LessThanOrEqualSuccess`](@ref). When [n1<=n2].
- [`LessThanOrEqualHardFail`](@ref). When [n1>n2] or when the solver state is infeasible.
- [`LessThanOrEqualSoftFail`](@ref). When no further deductions can be made, but [n1<=n2] and [n1>n2] are still possible.
"""
function make_less_than_or_equal!(
    solver::Solver, 
    hole1::Union{RuleNode, AbstractHole}, 
    hole2::Union{RuleNode, AbstractHole}
)::LessThanOrEqualResult
    make_less_than_or_equal!(solver, hole1, hole2, Vector{Tuple{AbstractHole, Int}}())
end

"""
    function make_less_than_or_equal!(h1::Union{RuleNode, AbstractHole}, h2::Union{RuleNode, AbstractHole}, guards::Vector{Tuple{AbstractHole, Int}})::LessThanOrEqualResult

Helper function that keeps track of the guards
"""
function make_less_than_or_equal!(
    solver::Solver, 
    hole1::Union{RuleNode, AbstractHole}, 
    hole2::Union{RuleNode, AbstractHole},
    guards::Vector{Tuple{AbstractHole, Int}}
)::LessThanOrEqualResult
    @assert isfeasible(solver)
    @match (isfilled(hole1), isfilled(hole2)) begin
        (true, true) => begin
            #(RuleNode | Hole [domain size == 1], RuleNode | Hole [domain size == 1])
            if get_rule(hole1) < get_rule(hole2)
                return LessThanOrEqualSuccessLessThan()
            elseif get_rule(hole1) > get_rule(hole2)
                return LessThanOrEqualHardFail()
            end

            return make_less_than_or_equal!(solver, get_children(hole1), get_children(hole2), guards)
        end
        (true, false) => begin
            #(RuleNode, AbstractHole)
            if length(guards) > 0
                if get_rule(hole1) > findlast(hole2.domain)
                    return LessThanOrEqualHardFail()
                elseif get_rule(hole1) > findfirst(hole2.domain)
                    return LessThanOrEqualSoftFail(hole2)
                end
            end
            path2 = get_path(solver, hole2)
            remove_below!(solver, path2, get_rule(hole1))
            if !isfeasible(solver)
                return LessThanOrEqualHardFail()
            end
            hole2 = get_node_at_location(solver, path2)
            if isuniform(hole2)
                if !isfilled(hole2)
                    if get_rule(hole1) < findfirst(hole2.domain)
                        # 2 < {3, 4}, tiebreaking is not needed
                        return LessThanOrEqualSuccessLessThan()
                    end
                    # 2 <= {2, 3}, add this hole as a guard for tiebreaking.
                    push!(guards, (hole2, get_rule(hole1)))
                elseif get_rule(hole1) < get_rule(hole2)
                    # 2 < 3, tiebreaking is not needed
                    return LessThanOrEqualSuccessLessThan()
                end
                # tiebreak on the children
                return make_less_than_or_equal!(solver, get_children(hole1), get_children(hole2), guards)
            else
                return LessThanOrEqualSoftFail(hole2)
            end
        end
        (false, true) => begin
            #(AbstractHole, RuleNode)
            if length(guards) > 0
                if findfirst(hole1.domain) > get_rule(hole2)
                    return LessThanOrEqualHardFail()
                elseif findlast(hole1.domain) > get_rule(hole2)
                    return LessThanOrEqualSoftFail(hole1)
                end
            end
            path1 = get_path(solver, hole1)
            remove_above!(solver, path1, get_rule(hole2))
            if !isfeasible(solver)
                return LessThanOrEqualHardFail()
            end
            hole1 = get_node_at_location(solver, path1)
            if isuniform(hole1)
                if !isfilled(hole1)
                    if findlast(hole1.domain) < get_rule(hole2)
                        # {2, 3} < 4, with or without children.
                        return LessThanOrEqualSuccessLessThan()
                    end
                    # 2 <= {2, 3}, add this hole as a guard for tiebreaking.
                    push!(guards, (hole1, get_rule(hole2)))
                elseif get_rule(hole1) < get_rule(hole2)
                    # 2 < 3, tiebreaking is not needed
                    return LessThanOrEqualSuccessLessThan()
                end
                # tiebreak on the children
                return make_less_than_or_equal!(solver, get_children(hole1), get_children(hole2), guards)
            else
                return LessThanOrEqualSoftFail(hole1)
            end
        end
        (false, false) => begin
            #(AbstractHole, AbstractHole)
            if length(guards) > 0
                if findfirst(hole1.domain) > findlast(hole2.domain)
                    return LessThanOrEqualHardFail()
                elseif findlast(hole1.domain) > findfirst(hole2.domain)
                    return LessThanOrEqualSoftFail(hole1, hole2)
                end
            end
            path1 = get_path(solver, hole1)
            path2 = get_path(solver, hole2)
            # Example:
            # Before: {2, 3, 5} <= {1, 3, 4}
            # After:  {2, 3} <= {3, 4}
            left_lowest_ind = findfirst(hole1.domain) #2
            remove_below!(solver, path2, left_lowest_ind) #removes the 1
            if !isfeasible(solver)
                return LessThanOrEqualHardFail()
            end
            right_highest_ind = findlast(hole2.domain) #4
            remove_above!(solver, path1, right_highest_ind) #removes the 5
            if !isfeasible(solver)
                return LessThanOrEqualHardFail()
            end
            hole1 = get_node_at_location(solver, path1)
            hole2 = get_node_at_location(solver, path2)
            if !isuniform(hole1)
                return LessThanOrEqualSoftFail(hole1)
            end
            if !isuniform(hole2)
                return LessThanOrEqualSoftFail(hole2)
            end
            if !(isfilled(hole1) || isfilled(hole2))
                left_highest_ind = findlast(hole1.domain)
                right_lowest_ind = findfirst(hole2.domain)
                if left_highest_ind == right_lowest_ind
                    # {2, 3} <= {3, 4}, try to tiebreak on the children
                    push!(guards, (hole1, 0))
                    push!(guards, (hole2, 0))
                    return make_less_than_or_equal!(solver, get_children(hole1), get_children(hole2), guards)
                elseif left_highest_ind < right_lowest_ind
                    # {2, 3} < {7, 8}, success
                    return LessThanOrEqualSuccessLessThan()
                else
                    # {2, 3} <=> {2, 3}, softfail
                    return LessThanOrEqualSoftFail(hole1, hole2)
                end
            end
            #at least one of the holes is a rulenode now, dispatch to another case
            return make_less_than_or_equal!(solver, hole1, hole2, guards)
        end
    end
end

"""
    function make_less_than_or_equal!(solver::Solver, nodes1::Vector{AbstractRuleNode}, nodes2::Vector{AbstractRuleNode}, guards::Vector{Tuple{AbstractHole, Int}})::LessThanOrEqualResult

Helper function that tiebreaks on children.
"""
function make_less_than_or_equal!(
    solver::Solver,
    nodes1::Vector{AbstractRuleNode},
    nodes2::Vector{AbstractRuleNode},
    guards::Vector{Tuple{AbstractHole, Int}}
)::LessThanOrEqualResult
    for (node1, node2) ∈ zip(nodes1, nodes2)
        result = make_less_than_or_equal!(solver, node1, node2, guards)
        @match result begin
            ::LessThanOrEqualSuccessWithHoles => ();
            ::LessThanOrEqualSuccessEquality => ();
            ::LessThanOrEqualSuccessLessThan => return result;
            ::LessThanOrEqualSoftFail => return result;
            ::LessThanOrEqualHardFail => begin 
                if length(guards) == 0
                    return result
                elseif length(guards) == 1
                    # a single guard is involved, preventing equality on the guard prevents the hardfail on the tiebreak
                    path = get_path(solver, guards[1][1])
                    remove!(solver, path, guards[1][2])
                    return LessThanOrEqualSuccessLessThan()
                else
                    # multiple guards are involved, we cannot deduce anything
                    return LessThanOrEqualSoftFail(guards[1][1], guards[2][1])
                end
            end
        end
    end
    return isnothing(guards) ? LessThanOrEqualSuccessEquality() : LessThanOrEqualSuccessWithHoles()
end
