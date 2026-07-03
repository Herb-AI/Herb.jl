"""
Tempereature functions are defined here. In the context of stocastic algorithms temperature describes the balance
between exploration and exploitation. Higher temperature values implies more exploration while lower values imply explotation.
"""

"""
    const_temperature(current_temperature::Real)

Returns the temperature unchanged. This function is used by Metropolis Hastings and Very Large Neighbourhood Search algorithms.
# Arguments
- `current_temperature::Real`: the current temperature of the search.
"""
function const_temperature(current_temperature::Real)
    return current_temperature
end


"""
    decreasing_temperature(percentage::Real)

Returns a function that produces a temperature decreased by `percentage`%. This function is used by the Simmulated Annealing algorithm.
# Arguments
- `percentage::Real`: the percentage to decrease the temperature by.
"""
function decreasing_temperature(percentage::Real)
    return current_temperature -> percentage * current_temperature
end
