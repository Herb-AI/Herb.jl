using Random


"""
    heuristic_leftmost(node::AbstractRuleNode, max_depth::Int)::Union{ExpandFailureReason, HoleReference}
    
Defines a heuristic over holes, where the left-most hole always gets considered first. Returns a [`HoleReference`](@ref) once a hole is found. This is the default option for enumerators.
"""
function heuristic_leftmost(node::AbstractRuleNode, max_depth::Int)::Union{ExpandFailureReason, HoleReference}
    function leftmost(node::AbstractRuleNode, max_depth::Int, path::Vector{Int})::Union{ExpandFailureReason, HoleReference}
        if max_depth == 0 return LimitReached() end

        for (i, child) in enumerate(node.children)
            new_path = push!(copy(path), i)
            hole_res = leftmost(child, max_depth-1, new_path)
            if (hole_res == LimitReached()) || (hole_res isa HoleReference)
                return hole_res
            end
        end
    
        return AlreadyComplete()
    end
    
    function leftmost(hole::Hole, max_depth::Int, path::Vector{Int})::Union{ExpandFailureReason, HoleReference}
        if max_depth == 0 return LimitReached() end
        return HoleReference(hole, path)
    end

    return leftmost(node, max_depth, Vector{Int}())
end

"""
    heuristic_rightmost(node::AbstractRuleNode, max_depth::Int)::Union{ExpandFailureReason, HoleReference}

Defines a heuristic over holes, where the right-most hole always gets considered first. Returns a [`HoleReference`](@ref) once a hole is found. 
"""
function heuristic_rightmost(node::AbstractRuleNode, max_depth::Int)::Union{ExpandFailureReason, HoleReference}
    function rightmost(node::AbstractRuleNode, max_depth::Int, path::Vector{Int})::Union{ExpandFailureReason, HoleReference}
        if max_depth == 0 return LimitReached() end

        for (i, child) in Iterators.reverse(enumerate(node.children))
            new_path = push!(copy(path), i)
            hole_res = rightmost(child, max_depth-1, new_path)
            if (hole_res == LimitReached()) || (hole_res isa HoleReference)
                return hole_res
            end
        end
    
        return AlreadyComplete()
    end
    
    function rightmost(hole::Hole, max_depth::Int, path::Vector{Int})::Union{ExpandFailureReason, HoleReference}
        if max_depth == 0 return LimitReached() end
        return HoleReference(hole, path)
    end

    return rightmost(node, max_depth, Vector{Int}())
end


"""
    heuristic_random(node::AbstractRuleNode, max_depth::Int)::Union{ExpandFailureReason, HoleReference}

Defines a heuristic over holes, where random holes get chosen randomly using random exploration. Returns a [`HoleReference`](@ref) once a hole is found.
"""
function heuristic_random(node::AbstractRuleNode, max_depth::Int)::Union{ExpandFailureReason, HoleReference}
    function random(node::AbstractRuleNode, max_depth::Int, path::Vector{Int})::Union{ExpandFailureReason, HoleReference}
        if max_depth == 0 return LimitReached() end

        for (i, child) in shuffle(collect(enumerate(node.children)))
            new_path = push!(copy(path), i)
            hole_res = random(child, max_depth-1, new_path)
            if (hole_res == LimitReached()) || (hole_res isa HoleReference)
                return hole_res
            end
        end
    
        return AlreadyComplete()
    end
    
    function random(hole::Hole, max_depth::Int, path::Vector{Int})::Union{ExpandFailureReason, HoleReference}
        if max_depth == 0 return LimitReached() end
        return HoleReference(hole, path)
    end

    return random(node, max_depth, Vector{Int}())
end

"""
    heuristic_smallest_domain(node::AbstractRuleNode, max_depth::Int)::Union{ExpandFailureReason, HoleReference}

Defines a heuristic over all available holes in the unfinished AST, by considering the size of their respective domains. A domain here describes the number of possible derivations with respect to the constraints. Returns a [`HoleReference`](@ref) once a hole is found. 
"""
function heuristic_smallest_domain(node::AbstractRuleNode, max_depth::Int)::Union{ExpandFailureReason, HoleReference}
    function smallest_domain(node::AbstractRuleNode, max_depth::Int, path::Vector{Int})::Union{ExpandFailureReason, HoleReference}
        if max_depth == 0 return LimitReached() end

        smallest_size::Int = typemax(Int)
        smallest_result::Union{Nothing, HoleReference} = nothing

        for (i, child) in enumerate(node.children)
            new_path = push!(copy(path), i)
            hole_res = smallest_domain(child, max_depth-1, new_path)

            if hole_res == LimitReached()
                return hole_res
            end

            if hole_res isa HoleReference
                domain_size = count(hole_res.hole.domain)
                if domain_size < smallest_size
                    smallest_size = domain_size
                    smallest_result = hole_res
                end
            end
        end
    
        if isnothing(smallest_result) return AlreadyComplete() end
        return smallest_result
    end
    
    function smallest_domain(hole::Hole, max_depth::Int, path::Vector{Int})::Union{ExpandFailureReason, HoleReference}
        if max_depth == 0 return LimitReached() end
        return HoleReference(hole, path)
    end

    return smallest_domain(node, max_depth, Vector{Int}())
end
