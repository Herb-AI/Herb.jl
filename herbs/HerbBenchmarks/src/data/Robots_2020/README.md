# Robots\_2020

This dataset represents robot tasks. A robot and a ball are in a `n X n` grid.
The `RobotState` describes the positions of the robot and the ball, whether the robot holds the ball, and the size of the grid:
- `:robot_x`: `x`-coordinate of the robot.
- `:robot_y`: `y`-coordinate of the robot.
- `:ball_x`: `x`-coordinate of the ball.
- `:ball_y`: `y`-coordinate of the ball.
- `:holds_ball`: A boolean value that determines if the robot is holding the ball, can be either 0,1.
- `:size`: The size of the grid in one dimension, `n`.

Each task is a `Problem` with a `RobotState` as input and and a `RobotState` as output. The first value in the problem name represents the value `n`.


See
> Cropper, Andrew, and Sebastijan Dumančić. "Learning large logic programs by going beyond entailment." arXiv preprint arXiv:2004.09855 (2020).
