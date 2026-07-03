# Define a struct to represent the grid
struct Grid
    width::Int
    height::Int
    data::Matrix{Int}
end

Grid(mat::Matrix{Int}) = Grid(size(mat)..., mat)

"""
Returns a new `Grid` initialized from a one-dimensional vector of integers (`raw_grid`).
"""
function initState(raw_grid::Vector{Int})
    return Grid(array_to_matrix(raw_grid))
end

"""
Helper function to transform the input vector to a matrix of square form. 
    
If length is not a squared integer, then iteratively adjust the factors a,b such that a<b and `a*b = length(input_array)`
"""
function array_to_matrix(arr::Vector{T}) where {T}
    n = length(arr)
    a = isqrt(n)  # Start with the integer square root of n
    b = a

    # Adjust a and b to meet the requirements
    while a * b < n || b < a
        if a * b < n
            b += 1
        elseif b < a
            a -= 1
        end
    end

    # Create the matrix and fill it
    mat = Matrix{T}(undef, a, b)
    fill!(mat, 0)

    for i in 1:n
        row = div(i - 1, b) + 1
        col = rem(i - 1, b) + 1
        mat[row, col] = arr[i]
    end

    return mat
end

"""
Returns the `Grid` data as a one-dimensional vector.
"""
function returnState(grid::Grid)
    return (grid.mat')[:] # transform and flatten matrix @TODO: grid struct has no field `mat`
end

"""
Initializes a `Grid` of given width and height with zeros.
"""
function init_grid(width::Int, height::Int)
    return Grid(width, height, zeros(Int, height, width))
end


"""
Returns a new `Grid` cloned from the input `grid`.

"""
function clone_grid(grid::Grid)
    return Grid(grid.width, grid.height, copy(grid.data))
end

"""Return a new `Grid` based on the input `grid`, resized to the new width and height.

Data is copied to the new `Grid` from the top-left corner of the grid. 
If the new dimensions are smaller than the current dimensions, the grid is cropped.  
If the new dimensions are larger, the grid is padded with zeros.
"""
function resize_grid(grid::Grid, new_width::Int, new_height::Int)
    new_grid = clone_grid(grid)
    new_data = zeros(Int, new_height, new_width)
    for i in 1:min(grid.height, new_height), j in 1:min(grid.width, new_width)
        new_data[i, j] = grid.data[i, j]
    end
    return Grid(new_data)
end

"""
Wrapper around `clone_grid`. 
"""
# @TODO: Why clone and copy_from_input?
function copy_from_input(source::Grid)
    return clone_grid(source)
end

"""
Creates a new `Grid` instance with the same dimensions as the input `grid`, 
but sets all values within `Grid.data` to zero. 
"""
function reset_grid(grid::Grid)
    new_grid = clone_grid(grid)
    fill!(new_grid.data, 0)
    return new_grid
end

"""
Returns a copy of the input `grid` with the value at the cel at position `row` and `col` set to `color`.
"""
function set_cell(grid::Grid, row::Int, col::Int, color::Int)
    new_grid = clone_grid(grid)
    new_grid.data[row, col] = color
    return new_grid
end

"""
Returns a list of coordinates within a rectangle defined by the top-left and bottom-right corners. 
"""
function select(grid::Grid, start_row::Int, start_col::Int, end_row::Int, end_col::Int) # redundant function
    selected_cells = []
    if start_row > end_row || start_col > end_col
        return selected_cells
    end

    for i in start_row:min(end_row, grid.height), j in start_col:min(end_col, grid.width)
        push!(selected_cells, (i, j))
    end
    return selected_cells
end

"""
Selects a rectangular region from the input `grid` and pastes it at the specified position into the copy of a grid. 

The function is overloaded to work either on a single grid or between two grids.
"""
function select_and_paste(grid::Grid, start_row::Int, start_col::Int, end_row::Int, end_col::Int, paste_row::Int, paste_col::Int)
    new_grid = clone_grid(grid) # Copy of the input grid to paste into.
    new_grid.data[paste_row:paste_row+end_row-start_row, paste_col:paste_col+end_col-start_col] = grid.data[start_row:end_row, start_col:end_col]
    return new_grid
end

function select_and_paste(input_grid::Grid, start_row::Int, start_col::Int, end_row::Int, end_col::Int, target_grid::Grid, paste_row::Int, paste_col::Int)
    new_grid = clone_grid(target_grid) # Copy of the target grid to paste into.
    new_grid.data[paste_row:paste_row+end_row-start_row, paste_col:paste_col+end_col-start_col] = input_grid.data[start_row:end_row, start_col:end_col]
    return new_grid

end

"""
Applies the floodfill algorithm to a Grid. 

The algorithm starts with the cell at the given row and column and changes the color of all connected cells to the given color.
"""
function floodfill(grid::Grid, row::Int, col::Int, color::Int)
    old_value = grid.data[row, col]
    if old_value == color # No need to floodfill if the color is the same
        return grid
    end

    new_grid = clone_grid(grid)
    function floodfill_recursive(r, c)
        if r < 1 || r > new_grid.height || c < 1 || c > new_grid.width || new_grid.data[r, c] != old_value
            return
        end
        new_grid.data[r, c] = color
        floodfill_recursive(r - 1, c)
        floodfill_recursive(r + 1, c)
        floodfill_recursive(r, c - 1)
        floodfill_recursive(r, c + 1)
    end

    floodfill_recursive(row, col)
    return new_grid
end
