# Installation Guide

Before installing Herb.jl, ensure that you have a running Julia distribution installed (Julia version 1.7 and above were tested). 
To install Julia, getting to know it, and seting up an IDE, see [MoJuWo](https://modernjuliaworkflows.org/writing/)

Thanks to Julia's package management, installing Herb.jl is very straightforward. 
Activate the default Julia REPL using

```shell
julia
```

From the Julia REPL you can now add the package: 
```julia
] add Herb
```

This will install all dependencies automatically.

The package `Herb` includes the subpackages `HerbCore`, `HerbGrammar`, `HerbConstraints`, `HerbSearch`, and `HerbSpecification` as dependencies, and re-exports all of their exported types and functions. 
Including `Herb` should give you a "batteries-included" experience with everything you need to get started.

And just like this you are done! Welcome to Herb.jl!


## Create a project and run an example

For those new to Julia and Herb, this is a short totorial on how to set up your first Herb script. 

Let's start by creating a folder for our project. We can call it `juliaTestProject`. In the project folder, create a `src` folder and in it a new file with `.jl` as the suffix. Lets go with `my_first_script.jl`.

Below is a simple script using Herb; you can paste it into your file.

```julia
using Herb

# define our elementary context-free grammar
# Can add and multiply an input variable x or the integers 1,2.
grammar = @cfgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
end

# create a problem with 5 examples by using the function f(x) = 2x + 1
problem = Problem([IOExample(Dict(:x => x), 2x+1) for x ∈ 1:5])
iterator = BFSIterator(grammar, :Number, max_depth=5)

# The solution found is a program from the arithmetic grammar above that will pass all examples
solution, flag = synth(problem, iterator)
program = rulenode2expr(solution, grammar)

println("Found program is: ", program)
println("This program should be equiavalent to the function 2x + 1")

# Here we can evaluate our program with input x = 6
input = 6
output = execute_on_input(grammar2symboltable(grammar), program, Dict(:x => input)) 
println("Output for input ", input, " is: ", output)
```

To set up the enviorment and run the scripts, we will open a terminal in the folder of the project. 
acad
If you have Julia set up, you can activate the REPL by running:
```shell
julia
```

To create your own environment in your new project, run in a Julia REPL:

```julia
] 
activate .
add Herb
```

This first line will put you in pkg mode, you can see here which environment is active. The second line will create a new environment for your project, if it does not exist, and activate it. The second line adds Herb to this new environment. 
You will see that a `Project.toml` file was added to your project folder, and in it, Herb is specified as a dependency for this project. 

Now, you can exit the package mode by presing backspace, and run the following command the the Julia REPL to run you script:

```julia
include("./src/my_first_script.jl")
```

The script will now run and you will see the printed output. 
To understand this script step-by-step, go over the [Getting Started](https://herb-ai.github.io/Herb.jl/dev/tutorials/basic_getting_started/) page. 