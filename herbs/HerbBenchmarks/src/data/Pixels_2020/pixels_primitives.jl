using MLStyle
"""
Represents the mutable the state of a pixel grid. It holds a matrix of boolean
values and a cursor pointing to a specific pixel in the grid.

Position is relative to the top left corner starting at (1, 1).
"""
mutable struct PixelState
    matrix::Matrix{Bool}
    position::Tuple{Int,Int} # (x, y)
    PixelState(matrix::Matrix{Bool}) = new(matrix, (1, 1))
    PixelState(matrix::Matrix{Bool}, position::Tuple{Int64,Int64}) = new(matrix, position)
end

"""
    atBottom(state::PixelState)

Is the state at the bottom of the pixel matrix?
"""
function atBottom(state::PixelState)
    (_, y_pos) = state.position
    (_, height) = size(state.matrix)
    return y_pos == height
end

function notAtBottom(state::PixelState)
    return !atBottom(state)
end

"""
    atTop(state::PixelState)

Is the state at the top of the pixel matrix?
"""
function atTop(state::PixelState)
    (_, y_pos) = state.position
    return y_pos == 1
end

function notAtTop(state::PixelState)
    return !atTop(state)
end

"""
    atLeft(state::PixelState)

Is the state at the left side of the pixel matrix?
"""
function atLeft(state::PixelState)
    (x_pos, _) = state.position
    return x_pos == 1
end

function notAtLeft(state::PixelState)
    return !atLeft(state)
end
"""
    atRight(state::PixelState)

Is the state at the right of the pixel matrix?
"""
function atRight(state::PixelState)
    (x_pos, _) = state.position
    (width, _) = size(state.matrix)
    return x_pos == width
end

function notAtRight(state::PixelState)
    return !atRight(state)
end

"""
Moves the position of the curosor to the right by one pixel. Position remains unchanged if the cursor is on the boundaries.
"""
function moveRight(state::PixelState)
    if !(state.position[1] == size(state.matrix, 2))
        state.position = (state.position[1] + 1, state.position[2])
    end
    return state
end


"""
Moves the position of the curosor to the left by one pixel. Position remains unchanged if the cursor is on the boundaries.
"""
function moveLeft(state::PixelState)
    if !(state.position[1] == 1)
        state.position = (state.position[1] - 1, state.position[2])
    end
    return state
end

"""
Moves the position of the curosor to down by one pixel. Position remains unchanged if the cursor is on the boundaries.
"""
function moveDown(state::PixelState)
    if !(state.position[2] == size(state.matrix, 1))
        state.position = (state.position[1], state.position[2] + 1)
    end
    return state
end


"""
Moves the position of the curosor up by one pixel. Position remains unchanged if the cursor is on the boundaries.
"""
function moveUp(state::PixelState)
    if !(state.position[2] == 1)
        state.position = (state.position[1], state.position[2] - 1)
    end
    return state
end

"""
Draws a 0 at the current position of the cursor by setting the value to `false`.
"""
function draw0(state::PixelState)
    state.matrix[state.position[2], state.position[1]] = false
    return state
end

"""
Draws a 1 at the current position of the cursor by setting the value to `true`.
"""
function draw1(state::PixelState)
    state.matrix[state.position[2], state.position[1]] = true
    return state
end
