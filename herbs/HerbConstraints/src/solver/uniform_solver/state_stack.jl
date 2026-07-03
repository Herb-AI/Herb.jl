"""
Simple stack that can only increase in size.
Supports backtracking by decreasing the size to the saved size.
"""
struct StateStack{T}
    vec::Vector{T}
    size::StateInt
end

"""
    function StateStack{T}(sm::AbstractStateManager) where T

Create an empty StateStack supporting elements of type T
"""
function StateStack{T}(sm::AbstractStateManager) where T
    return StateStack{T}(Vector{T}(), StateInt(sm, 0))
end

"""
    function StateStack{T}(sm::AbstractStateManager, vec::Vector{T}) where T

Create a StateStack for the provided `vec`
"""
function StateStack{T}(sm::AbstractStateManager, vec::Vector{T}) where T
    return StateStack{T}(vec, StateInt(sm, length(vec)))
end

"""
    function Base.push!(stack::StateStack, item)

Place an `item` on top of the `stack`.
"""
function Base.push!(stack::StateStack, item)
    increment!(stack.size)
    if length(stack.vec) > size(stack)
        stack.vec[size(stack)] = item
    else
        push!(stack.vec, item)
    end
end

"""
    function Base.size(stack::StateStack)

Get the current size of the `stack`.
"""
function Base.size(stack::StateStack)::Int
    return get_value(stack.size)
end

"""
    function Base.collect(stack::StateStack)

Return the internal `Vector` representation of the `stack`.
!!! warning:
    The returned vector is read-only.
"""
function Base.collect(stack::StateStack)
    return stack.vec[1:size(stack)]
end

"""
    function Base.in(stack::StateStack, value)::Bool

Checks whether the `value` is in the `stack`.
"""
function Base.in(stack::StateStack{T}, value::T)::Bool where T
    return value ∈ stack.vec[1:size(stack)]
end
