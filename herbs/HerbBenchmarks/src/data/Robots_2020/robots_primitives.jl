using MLStyle
"""
Represents the state of a robot, including its position in a square grid of a given `size` 
and whether it holds a ball.
"""
struct RobotState
    holds_ball::Int
    robot_x::Int
    robot_y::Int
    ball_x::Int
    ball_y::Int
    size::Int # square grid of dimensions size x size
end

can_pickup(state::RobotState) = state.holds_ball == 0 && state.robot_x == state.ball_x && state.robot_y == state.ball_y

atTop(state::RobotState) = state.robot_y == 1
notAtTop(state::RobotState) = !atTop(state)
atBottom(state::RobotState) = state.robot_y == state.size
notAtBottom(state::RobotState) = !atBottom(state)

atLeft(state::RobotState) = state.robot_x == 1
notAtLeft(state::RobotState) = !atLeft(state)
atRight(state::RobotState) = state.robot_x == state.size
notAtRight(state::RobotState) = !atRight(state)

"""
    grab(state::RobotState)

Grab the ball (holds_ball -> true) if possible (see `can_pickup`).
"""
function grab(state::RobotState)
    return can_pickup(state) ? RobotState(1, state.robot_x, state.robot_y, state.ball_x, state.ball_y, state.size) : state
end

"""
    drop(state::RobotState)

Drop the ball (holds_ball -> false) if possible (holds_ball == true).
"""
function drop(state::RobotState)
    return state.holds_ball == 1 ? RobotState(0, state.robot_x, state.robot_y, state.ball_x, state.ball_y, state.size) : state
end

"""
Renders the current state of the robot and ball within a grid to the specified IO stream. 

If the robot holds the ball, the robot's position is marked with "#". Otherwise, the robot's position is marked with "R" 
and the ball's position with "B". All other positions are marked with ".".
"""
function Base.show(io::IO, state::RobotState)
    for y in 1:state.size
        row = ""
        for x in 1:state.size
            if (x == state.robot_x && y == state.robot_y)
                row *= state.holds_ball == 1 ? "#" : "R"
            elseif (x == state.ball_x && y == state.ball_y)
                row *= "B"
            else
                row *= "."
            end
        end
        println(io, row)
    end
end

"""
Moves the robots position to the right by one. If the robot is holding the ball, the ball's position is also moved by one.
Positions remain unchanged if the robot is on the boundaries.
"""
function moveRight(state::RobotState)
    if !(state.robot_x == state.size)
        if Bool(state.holds_ball)
            return RobotState(state.holds_ball, state.robot_x + 1, state.robot_y, state.ball_x + 1, state.ball_y, state.size)
        else
            return RobotState(state.holds_ball, state.robot_x + 1, state.robot_y, state.ball_x, state.ball_y, state.size)
        end
    else
        return state
    end
end

"""
Moves the robots position to the left by one. If the robot is holding the ball, the ball's position is also moved by one.
Positions remain unchanged if the robot is on the boundaries.
"""
function moveLeft(state::RobotState)
    if !(state.robot_x == 1)
        if Bool(state.holds_ball)
            return RobotState(state.holds_ball, state.robot_x - 1, state.robot_y, state.ball_x - 1, state.ball_y, state.size)
        else
            return RobotState(state.holds_ball, state.robot_x - 1, state.robot_y, state.ball_x, state.ball_y, state.size)
        end
    else
        return state
    end
end

"""
Moves the robots position down by one. If the robot is holding the ball, the ball's position is also moved by one.
Positions remain unchanged if the robot is on the boundaries.
"""
function moveDown(state::RobotState)
    if !(state.robot_y == state.size)
        if Bool(state.holds_ball)
            return RobotState(state.holds_ball, state.robot_x, state.robot_y + 1, state.ball_x, state.ball_y + 1, state.size)
        else
            return RobotState(state.holds_ball, state.robot_x, state.robot_y + 1, state.ball_x, state.ball_y, state.size)
        end
    else
        return state
    end
end

"""
Moves the robots position up by one. If the robot is holding the ball, the ball's position is also moved by one.
Positions remain unchanged if the robot is on the boundaries.
"""
function moveUp(state::RobotState)
    if !(state.robot_y == 1)
        if Bool(state.holds_ball)
            return RobotState(state.holds_ball, state.robot_x, state.robot_y - 1, state.ball_x, state.ball_y - 1, state.size)
        else
            return RobotState(state.holds_ball, state.robot_x, state.robot_y - 1, state.ball_x, state.ball_y, state.size)
        end
    else
        return state
    end
end
