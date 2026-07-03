struct StateSparseSet
    values::Vector{Int}
    indices::Vector{Int}
    size::StateInt
    min::StateInt
    max::StateInt
    n::Int
end

"""
Create a new `StateSparseSet` with values [1, 2, ..., n]
"""
function StateSparseSet(sm::StateManager, n::Int)
    values = collect(1:n)
    indices = collect(1:n)
    size = StateInt(sm, n)
    min = StateInt(sm, 1)
    max = StateInt(sm, n)
    return StateSparseSet(values, indices, size, min, max, n)
end

"""
Converts a BitVector domain representation to a StateSparseSet
Example:
```
set = StateSparseSet(sm, BitVector((1, 1, 0, 0, 1, 0, 0))) #{1, 2, 5}
```
"""
function StateSparseSet(sm::StateManager, domain::BitVector)
    n = length(domain)
    values = collect(1:n)
    indices = collect(1:n)
    size = StateInt(sm, n)
    min = StateInt(sm, 1)
    max = StateInt(sm, n)
    set = StateSparseSet(values, indices, size, min, max, n)
    for v ∈ findall(.!domain)
        remove!(set, v)
    end
    return set
end


"""
Pretty print the `StateSparseSet`.
"""
function Base.show(io::IO, set::StateSparseSet)
    print(io, "{")
    size = get_value(set.size)
    if size > 0
        for i ∈ 1:size-1
            print(io, set.values[i])
            print(io, ", ")
        end
        print(io, set.values[size])
    end
    print(io, "}")
end

"""
Returns the number of values in the `StateSparseSet`.
"""
function Base.length(set::StateSparseSet)
    return get_value(set.size)
end

"""
Returns the number of values in the `StateSparseSet`.
"""
function Base.size(set::StateSparseSet)
    return get_value(set.size)
end

"""
Returns the minimum value in the set.
This function name is used instead of `min` to allow code reuse for domains of type `BitVector` and `StateSparseSet`.
"""
function Base.findfirst(set::StateSparseSet)
    return get_value(set.min)
end

"""
Returns all elements in the set.
"""
function Base.findall(set::StateSparseSet)
    return collect(set)
end

"""
Returns the number of values in the `StateSparseSet`.
!!! warning:
    This is not actually the sum of the set. It is the length of the set.
    This allows a `StateSparseSet` to be used as if it were a `BitVector` representation of a set
"""
function Base.sum(set::StateSparseSet)
    return get_value(set.size)
end

"""
Checks if value `val` is in StateSparseSet `s`.
!!! warning:
    This allows a `StateSparseSet` to be used as if it were a `BitVector` representation of a set
"""
function Base.getindex(set::StateSparseSet, val::Int)
    return val ∈ set
end


"""
Returns the maximum value in the set.
This function name is used instead of `min` to allow code reuse for domains of type `BitVector` and `StateSparseSet`.
"""
function Base.findlast(set::StateSparseSet)
    return get_value(set.max)
end

function Base.isempty(set::StateSparseSet)
    return get_value(set.size) == 0
end

function Base.empty!(set::StateSparseSet)
    set_value!(set.size, 0)
end

"""
Checks if value `val` is in StateSparseSet `s`.
"""
function Base.in(val::Int, set::StateSparseSet)
    if val < 1 || val > set.n
        return false
    end
    return set.indices[val] <= get_value(set.size)
end


Base.eltype(::StateSparseSet) = Int


function Base.iterate(set::StateSparseSet)
    index = 1
    if index > get_value(set.size) return nothing end
    return set.values[index], index
end


function Base.iterate(set::StateSparseSet, index::Int)
    index += 1
    if index > get_value(set.size) return nothing end
    return set.values[index], index
end


"""
    remove!(set::StateSparseSet, val::Int)

Removes value `val` from StateSparseSet `set`. Returns true if `val` was in `set`.
"""
function remove!(set::StateSparseSet, val::Int)::Bool
    if val ∉ set
        return false;
    end
    _exchange_positions!(set, val, set.values[get_value(set.size)]);
    decrement!(set.size);
    _update_bounds_val_removed!(set, val);
    return true;
end


"""
    remove_all_but!(set::StateSparseSet, val::Int)::Bool

Removes all values from StateSparseSet `set`, except `val`
"""
function remove_all_but!(set::StateSparseSet, val::Int)::Bool
    @assert val ∈ set
    if get_value(set.size) <= 1
        return false
    end
    _val = set.values[1]
    _i = set.indices[val]
    set.indices[val] = 1
    set.values[1] = val
    set.indices[_val] = _i
    set.values[_i] = _val
    set_value!(set.min, val)
    set_value!(set.max, val)
    set_value!(set.size, 1)
    return true
end

"""
    remove_all_but!(set::StateSparseSet, vals::Vector{Int})::Bool

Removes all values from StateSparseSet `set`, except those in `vals`
"""
function remove_all_but!(set::StateSparseSet, vals::Vector{Int})::Bool
    @assert issubset(vals, set) "$vals is not a subset of $set"
    removed = false

    for v in set
        if v ∉ vals
            removed = removed || remove!(set, v)
        end
    end

    return removed
end

"""
Remove all the values less than `val` from the `set`
"""
function remove_below!(set::StateSparseSet, val::Int)::Bool
    if get_value(set.min) >= val
        return false
    elseif get_value(set.max) < val
        Base.empty!(set)
    else
        for v ∈ get_value(set.min):val-1
            remove!(set, v)
        end
    end
    return true
end

"""
Remove all the values greater than `val` from the `set`
"""
function remove_above!(set::StateSparseSet, val::Int)::Bool
    if get_value(set.max) <= val
        return false
    elseif get_value(set.min) > val
        Base.empty!(set)
    else
        for v ∈ val+1:get_value(set.max)
            remove!(set, v)
        end
    end
    return true
end

"""
Exchanges the positions in the internal representation of the StateSparseSet.
"""
function _exchange_positions!(set::StateSparseSet, val1::Int, val2::Int)
    @assert (val1 >= 1) && (val2 >= 1) && (val1 <= set.n) && (val2 <= set.n)
    v1 = val1
    v2 = val2
    i1 = set.indices[v1]
    i2 = set.indices[v2]
    set.values[i1] = v2
    set.values[i2] = v1
    set.indices[v1] = i2
    set.indices[v2] = i1
end

"""
This function should be called whenever the minimum or maximum value from the set might have been removed.
The minimum and maximum value of the set will be updated to the actual bounds of the set.
"""
function _update_bounds_val_removed!(set::StateSparseSet, val::Int)
    _update_max_val_removed!(set, val)
    _update_min_val_removed!(set, val)
end

"""
This function should be called whenever the maximum value from the set might have been removed.
The maximum value of the set will be updated to the actual maximum of the set.
"""
function _update_max_val_removed!(set::StateSparseSet, val::Int)
    max = get_value(set.max)
    if !isempty(set) && max == val
        for v ∈ max-1:-1:1
            if v ∈ set
                set_value!(set.max, v)
                return
            end
        end
    end
end

"""
This function should be called whenever the minimum value from the set might have been removed.
The minimum value of the set will be updated to the actual minimum of the set.
"""
function _update_min_val_removed!(set::StateSparseSet, val::Int)
    min = get_value(set.min)
    if !isempty(set) && min == val
        for v ∈ min+1:set.n
            if v ∈ set
                set_value!(set.min, v)
                return
            end
        end
    end
end


"""
    are_disjoint(set1::StateSparseSet, set2::StateSparseSet)

Returns true if there is no overlap in values between `set1` and `set2`
"""
function are_disjoint(set1::StateSparseSet, set2::StateSparseSet)
    for v ∈ set1
        if v ∈ set2
            return false
        end
    end
    return true
end
