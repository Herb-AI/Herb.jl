# Smaller cost means a better program. Bigger cost means a worse program.

"""
    probabilistic_accept(current_cost::Real, next_cost::Real, temperature::Real)

Probabilistically decides whether to accept the new program (next) based on the ratio of costs (smaller is better) between the previous and new program.
Returns `True` if the new program is accepted, `False` otherwise.
# Arguments
- `current_cost::Real`: the cost of the current program.
- `next_cost::Real`: the cost of the proposed program.
- `temperature::Real`: the temperature; not used.
"""
function probabilistic_accept(current_cost::Real, next_cost::Real, temperature::Real)
    ratio = current_cost / (current_cost + next_cost)
    return ratio >= rand()
end

"""
    probabilistic_accept_with_temperature_fraction(current_cost::Real, program_to_consider_cost::Real, temperature::Real)

Probabilistically decides whether to accept the new program (next) based on the ratio of costs (smaller is better) between the previous and new program multiplied
by the temperature.
Returns `True` if the new program is accepted, `False` otherwise.
# Arguments
- `current_cost::Real`: the cost of the current program.
- `next_cost::Real`: the cost of the proposed program.
- `temperature::Real`: the current temperature 
"""
function probabilistic_accept_with_temperature_fraction(current_cost::Real, program_to_consider_cost::Real, temperature::Real)
    ratio = current_cost / (program_to_consider_cost + current_cost)
    if ratio >= 1
        return true
    end
    return ratio * temperature >= rand()
end

"""
    best_accept(current_cost::Real, next_cost::Real, temperature::Real)

Returns true if the cost of the proposed program is smaller than the cost of the current program.
Otherwise, returns false.
# Arguments
- `current_cost::Real`: the cost of the current program.
- `next_cost::Real`: the cost of the proposed program.
- `temperature::Real`: the temperature; not used.
"""
function best_accept(current_cost::Real, next_cost::Real, temperature::Real)
    return current_cost > next_cost
end

"""
    probabilistic_accept_with_temperature(current_cost::Real, next_cost::Real, temperature::Real)

Returns true if the cost of the proposed program is smaller than the cost of the current program.
Otherwise, returns true with the probability equal to: 
```math
1 / (1 + exp(delta / temperature))
```
In any other case, returns false.
# Arguments
- `current_cost::Real`: the cost of the current program.
- `next_cost::Real`: the cost of the proposed program.
- `temperature::Real`: the temperature of the search.
"""
function probabilistic_accept_with_temperature(current_cost::Real, next_cost::Real, temperature::Real)
    delta = next_cost - current_cost
    if delta < 0
        return true
    end
    return 2 / (1 + exp(delta / temperature)) > rand()
end
