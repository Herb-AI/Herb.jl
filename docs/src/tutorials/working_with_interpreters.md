# Using the Julia interpreter

To know how good a candidate program is, program synthesisers execute them. The easiest way to execute a program is to rely on Julia itself. To leverage the Julia interpreter, you only have to ensure that your programs are valid Julia expressions. 

First, let's import the necessary packages


```julia
using HerbGrammar, HerbInterpret
```


Now, assume the following grammar.


```julia
g = @cfgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
 end
```


    1: Number = 1
    2: Number = 2
    3: Number = x
    4: Number = Number + Number
    5: Number = Number * Number



Let's construct a program `x+3`, which would correspond to the following `RuleNode` representation


```julia
myprog = RuleNode(4,[RuleNode(3),RuleNode(1)])
```


    4{3,1}


To run this program, we have to convert it into a Julia expression, which we can do in the following way:


```julia
myprog_julia = rulenode2expr(myprog, g)
```


    :(x + 1)


Now we have a valid Julia expression, but we are still missing one key ingredient: we have to inform the interpreter about the special symbols. In our case, these are `:x` and `:+`. To do so, we need to create a symbol table, which is nothing more than a dictionary mapping symbols to their values:


```julia
symboltable = Dict{Symbol,Any}(:x => 2, :+ => +)
```


    Dict{Symbol, Any} with 2 entries:
      :+ => +
      :x => 2


Now we can execute our program through the defaul interpreter available in `HerbInterpret`:



```julia
interpret(symboltable, myprog_julia)
```


    3


And that's it!

# Defining a custom interpreter

A disadvantage of the default Julia interpreter is that it needs to traverse abstract syntax tree twice -- once to convert it into a Julia expression, and the second time to execute that expression. Program execution is regularly the most consuming part of the entire pipeline and, by eliminating one of these steps, we can cut the runtime in half.

We can define an interpreter that works directly over `RuleNode`s. 
Consider the scenario in which we want to write programs for robot navigation: imagine a 2D world in which the robot can move around and pick up a ball. The programs we could write direct the robot to go up, down, left, and right. For convenience, the programming language also offers conditionals and loops:


```julia
grammar_robots = @csgrammar begin
    Start = Sequence                   #1

    Sequence = Operation                #2
    Sequence = (Operation; Sequence)    #3
    Operation = Transformation          #4
    Operation = ControlStatement        #5

    Transformation = moveRight() | moveDown() | moveLeft() | moveUp() | drop() | grab()     #6
    ControlStatement = IF(Condition, Sequence, Sequence)        #12
    ControlStatement = WHILE(Condition, Sequence)               #13

    Condition = atTop() | atBottom() | atLeft() | atRight() | notAtTop() | notAtBottom() | notAtLeft() | notAtRight()      #14
end
```

This grammar specifies a simple sequential program with instructions for the robot. A couple of example programs:
  - `moveRight(); moveLeft(); drop()`
  - WHILE(notAtTop(), moveUp())

The idea behind this programming language is that the program specifies a set of transformations over a state of the robot world. Thus, a program can only be executed over a particular state. In this case, the state represents the size of the 2D world, the current position of a robot, the current position of a ball, and whether the robot is currently holding a ball. The execution of a particular instruction acts as a state transformation: each instruction takes a state as an input, transforms it, and passes it to the subsequent instruction. For example, execution of the program `moveRight(); moveLeft(); drop()` would proceed as:
  1. take an input state, 
  2. pass it to the `moveRight()` instruction,
  3. pass the output of `moveRight()` to `moveLeft()` instructions,
  4. pass the output of `moveLeft()` to `drop()`,
  5. return the output of `drop()`.


 The following is only one possible way to implement a custom interpreter, but it demonstrates a general template that can always be followed.

 We want to implement the following function, which would take in a program in the form of a `RuleNode`, a grammar, and a starting state, and return the state obtained after executing the program:

        interpret(prog::AbstractRuleNode, grammar::ContextSensitiveGrammar, state::RobotState)::RobotState

 As `RuleNode`s only store indices of derivation rules from the grammar, not the functions themselves, we will first pull the function call associated with every derivation rule. In Julia, this is indicated by the top-level symbol of the rules. For example, the top-level symbol for the derivation rule 6 is `:moveRight`; for rule 12, that is `:IF`.

The remaining functions follow a similar idea. (You can see the full implementation of this interpreter [here](https://github.com/Herb-AI/HerbBenchmarks.jl/blob/new-robots/src/data/Robots_2020/robots_primitives.jl)).


```julia
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HerbGrammar = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"
HerbInterpret = "5bbddadd-02c5-4713-84b8-97364418cca7"

[compat]
HerbGrammar = "~0.3.0"
HerbInterpret = "~0.1.3"
"""
```
