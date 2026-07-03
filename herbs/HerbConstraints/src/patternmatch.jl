"""
    abstract type PatternMatchResult end

A result of the `pattern_match` function. Can be one of 4 cases:
- [`PatternMatchSuccess`](@ref)
- [`PatternMatchSuccessWhenHoleAssignedTo`](@ref)
- [`PatternMatchHardFail`](@ref)
- [`PatternMatchSoftFail`](@ref)
"""
abstract type PatternMatchResult end

"""
The pattern is exactly matched and does not involve any holes at all
"""
struct PatternMatchSuccess <: PatternMatchResult
end

"""
The pattern can be matched when the `hole` is filled with any of the given `ind`(s).
"""
struct PatternMatchSuccessWhenHoleAssignedTo <: PatternMatchResult
    hole::AbstractHole
    ind::Union{Int, Vector{Int}}
end

"""
The pattern is not matched and can never be matched by filling in holes
"""
struct PatternMatchHardFail <: PatternMatchResult
end

"""
The pattern can still be matched in a non-trivial way. Includes two cases:
- multiple holes are involved. this result stores a reference to one of them
- a single hole is involved, but needs to be filled with a node of size >= 2
"""
struct PatternMatchSoftFail <: PatternMatchResult
    hole::AbstractHole
end

#Shared reference to a dict of vars to reduce memory allocations.
VARS = Dict{Symbol, AbstractRuleNode}()

"""
    pattern_match(rn::AbstractRuleNode, mn::AbstractRuleNode)::PatternMatchResult

Recursively tries to match [`AbstractRuleNode`](@ref) `rn` with [`AbstractRuleNode`](@ref) `mn`.
Returns a `PatternMatchResult` that describes if the pattern was matched.
"""
function pattern_match(rn::AbstractRuleNode, mn::AbstractRuleNode)::PatternMatchResult
    empty!(VARS)
    pattern_match(rn, mn, VARS)
end

"""
Generic fallback function for commutativity. Swaps arguments 1 and 2, then dispatches to a more specific signature.
If this gets stuck in an infinite loop, the implementation of an AbstractRuleNode type pair is missing.
"""
function pattern_match(mn::AbstractRuleNode, rn::AbstractRuleNode, vars::Dict{Symbol, AbstractRuleNode})
    pattern_match(rn, mn, vars)
end

"""
    pattern_match(rns::Vector{AbstractRuleNode}, mns::Vector{AbstractRuleNode}, vars::Dict{Symbol, AbstractRuleNode})::PatternMatchResult

Pairwise tries to match two ordered lists of [AbstractRuleNode](@ref)s. 
Typically, this function is used to pattern match the children two AbstractRuleNodes.
"""
function pattern_match(rns::Vector{AbstractRuleNode}, mns::Vector{AbstractRuleNode}, vars::Dict{Symbol, AbstractRuleNode})::PatternMatchResult
    # Currently, invalid arities are not supported.
    # Suppose rule 3 = "S -> -S"
    # Consider two equivalent constraints: 
    #     A) Forbidden(RuleNode(3, [RuleNode(3, [VarNode(:a)])]))
    #     B) Forbidden(RuleNode(3, [RuleNode(3)]))
    # Constraint A has the correct arities for rule 3. This is the expected format.
    # Constraint B has a more implicit way of saying that the children of the final node don't matter.
    # Currently, constraints of type B are not supported, as they might lead into unexpected behavior.
    # Use the following 3 lines if type B should be allowed:
    # if (length(rns) == 0 || length(mns) == 0)
    #     return PatternMatchSuccess()
    # end
    @assert length(rns) == length(mns) "Unable to pattern match rulenodes with different arities"
    match_result = PatternMatchSuccess()
    for (n1, n2) ∈ zip(rns, mns)
        child_match_result = pattern_match(n1, n2, vars)
        @match child_match_result begin
            ::PatternMatchHardFail => return child_match_result;
            ::PatternMatchSoftFail => (match_result = child_match_result); #continue searching for a hardfail
            ::PatternMatchSuccess => (); #continue searching for a hardfail
            ::PatternMatchSuccessWhenHoleAssignedTo => begin
                if !(match_result isa PatternMatchSuccess)
                    return PatternMatchSoftFail(child_match_result.hole)
                end
                match_result = child_match_result;
            end
        end
    end
    return match_result
end

"""
    pattern_match(rn::AbstractRuleNode, var::VarNode, vars::Dict{Symbol, AbstractRuleNode})::PatternMatchResult

Comparing any [`AbstractRuleNode`](@ref) with a named [`VarNode`](@ref)
"""
function pattern_match(rn::AbstractRuleNode, var::VarNode, vars::Dict{Symbol, AbstractRuleNode})::PatternMatchResult
    if var.name ∈ keys(vars) 
        return pattern_match(rn, vars[var.name])
    end
    vars[var.name] = rn
    return PatternMatchSuccess()
end

"""
    pattern_match(node::AbstractRuleNode, domainrulenode::DomainRuleNode, vars::Dict{Symbol, AbstractRuleNode})::PatternMatchResult

Comparing any [`AbstractRuleNode`](@ref) with a [`DomainRuleNode`](@ref)
"""
function pattern_match(node::AbstractRuleNode, domainrulenode::DomainRuleNode, vars::Dict{Symbol, AbstractRuleNode})::PatternMatchResult
    if isfilled(node)
        #(RuleNode, DomainRuleNode)
        if !domainrulenode.domain[get_rule(node)]
            return PatternMatchHardFail()
        end
        return pattern_match(get_children(node), get_children(domainrulenode), vars)
    else
        #(AbstractHole, DomainRuleNode)
        if are_disjoint(node.domain, domainrulenode.domain)
            return PatternMatchHardFail()
        end
        if length(get_children(domainrulenode)) != length(get_children(node))
            #a large hole is involved
            return PatternMatchSoftFail(node)
        end
        children_match_result = pattern_match(get_children(node), get_children(domainrulenode), vars)
        @match children_match_result begin
            ::PatternMatchHardFail => return children_match_result;
            ::PatternMatchSoftFail => return children_match_result;
            ::PatternMatchSuccess => begin
                if is_subdomain(node.domain, domainrulenode.domain)
                    return children_match_result
                end
                # the pattern match will be successful if the hole is filled with any of the values in the intersection
                intersection = get_intersection(node.domain, domainrulenode.domain)
                @assert !isempty(intersection) "overlapping sets cannot have an empty intersection. the `are_disjoint` check failed."
                if length(intersection) == 1
                    return PatternMatchSuccessWhenHoleAssignedTo(node, intersection[1]) #exactly this value
                end
                return PatternMatchSuccessWhenHoleAssignedTo(node, intersection) #one of multiple values
            end 
            ::PatternMatchSuccessWhenHoleAssignedTo => begin
                if is_subdomain(node.domain, domainrulenode.domain)
                    return children_match_result
                end
                return PatternMatchSoftFail(children_match_result.hole)
            end 
        end
    end
end

"""
    pattern_match(h1::Union{RuleNode, AbstractHole}, h2::Union{RuleNode, AbstractHole}, vars::Dict{Symbol, AbstractRuleNode})::PatternMatchResult

Comparing any pair of [`Rulenode`](@ref) and/or [`AbstractHole`](@ref).
It is important to note that some `AbstractHole`s are already filled and should be treated as `RuleNode`.
This is why this function is dispatched on `(isfilled(h1), isfilled(h2))`.
The '(RuleNode, AbstractHole)' case could still include two nodes of type `AbstractHole`, but one of them should be treated as a rulenode.
"""
function pattern_match(h1::Union{RuleNode, AbstractHole}, h2::Union{RuleNode, AbstractHole}, vars::Dict{Symbol, AbstractRuleNode})::PatternMatchResult
    @match (isfilled(h1), isfilled(h2)) begin
        #(RuleNode | Hole [domain size == 1], RuleNode | Hole [domain size == 1])
        (true, true) => begin
            if get_rule(h1) ≠ get_rule(h2)
                return PatternMatchHardFail()
            end
            
            # domain of hole must have been 1 because it `isfilled`
            # but still has no children, so there's nothing more that
            # can be deduced before the hole is simplified
            # ideally, these holes should be simplified before making
            # it to the pattern matching step.
            if h1 isa Hole && !isempty(get_children(h2))
                return PatternMatchSoftFail(h1)
            elseif h2 isa Hole && !isempty(get_children(h1))
                return PatternMatchSoftFail(h2)
            end

            return pattern_match(get_children(h1), get_children(h2), vars)
        end

        #(RuleNode, AbstractHole)
        (true, false) => begin
            if !h2.domain[get_rule(h1)]
                return PatternMatchHardFail()
            end
            if isuniform(h2)
                children_match_result = pattern_match(get_children(h1), get_children(h2), vars)
                @match children_match_result begin
                    ::PatternMatchHardFail => return children_match_result;
                    ::PatternMatchSoftFail => return children_match_result;
                    ::PatternMatchSuccess => return PatternMatchSuccessWhenHoleAssignedTo(h2, get_rule(h1));
                    ::PatternMatchSuccessWhenHoleAssignedTo => return PatternMatchSoftFail(children_match_result.hole);
                end
            end
            if !h2.domain[get_rule(h1)]
                return PatternMatchHardFail()
            end
            if isempty(h1.children)
                return PatternMatchSuccessWhenHoleAssignedTo(h2, get_rule(h1))
            end
            #a large hole is involved
            return PatternMatchSoftFail(h2)
        end

        #(AbstractHole, RuleNode)
        (false, true) => pattern_match(h2, h1, vars) #commutativity

        #(AbstractHole, AbstractHole)
        (false, false) => begin
            if are_disjoint(h1.domain, h2.domain)
                return PatternMatchHardFail()
            end
            if isuniform(h1) && isuniform(h2)
                children_match_result = pattern_match(get_children(h1), get_children(h2), vars)
                @match children_match_result begin
                    ::PatternMatchHardFail => return children_match_result;
                    ::PatternMatchSoftFail => return children_match_result;
                    ::PatternMatchSuccess => return PatternMatchSoftFail(h1);
                    ::PatternMatchSuccessWhenHoleAssignedTo => return PatternMatchSoftFail(children_match_result.hole);
                end
            end
            return PatternMatchSoftFail(isuniform(h1) ? h2 : h1)
        end
    end
end
