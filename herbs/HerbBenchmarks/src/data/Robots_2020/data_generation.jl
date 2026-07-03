using Random

# Seed the random number generator
Random.seed!(42);

"""
    rand_coord(size::Integer)::String

Generates a random integer coordinate with both x and y in the [1, size]. Used for the `robots` dataset.
"""
function rand_coord(size::Integer)::String
    x = rand(1:size)
    y = rand(1:size)
    return "$x,$y"
end


"""
    rand_state(size::Integer)::String

Generates a random `robots` state.
"""
function rand_state(size::Integer)::String
    robo_pos = rand_coord(size)
    ball_pos = rand_coord(size)
    holding = if (robo_pos == ball_pos) rand(0:1) else 0 end
    return "w($robo_pos,$ball_pos,$holding,$size)"
end


"""
    generate_single_robot_datapoint(size, task, trial, filepath::String="generated_data.jl")

Generate and write single datapoints given world size, task and trial number. Useful for generating specific worlds.
"""
function generate_single_robot_datapoint(size, task, trial, filepath::String="generated_data.jl")
    s1 = rand_state(size)
    s2 = rand_state(size)
  
    problem = parseline_robots("pos($s1,$s2).")
    write_problem(filepath, problem, "$size-$task-$trial", "a")
end


"""
    generate_robots_dataset(max_size=10, n_tasks=10, n_trials=10, filepath::String="generated_data.jl")

Generate entire `robots` dataset.
"""
function generate_robots_dataset(max_size=10, n_tasks=10, n_trials=10, filepath::String="generated_data.jl")
  sizes = 1:2:max_size
  trials = 1:n_trials
  tasks = 1:n_tasks

  jobs = [(size,task,trial) for size in sizes for task in tasks for trial in trials]

  for (size, task, trial) in jobs
      generate_single_robot_datapoint(size, task, trial, filepath)
  end
end
