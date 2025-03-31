### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ e0a7076c-9345-40ef-a26e-99e8bad31463
using Herb

# ╔═╡ 55719688-3940-11ef-1f29-f51dea064ff3
md"# Using the Julia interpreter

To know how good a candidate program is, program synthesisers execute them. The easiest way to execute a program is to rely on Julia itself. To leverage the Julia interpreter, you only have to ensure that your programs are valid Julia expressions. 

For example, assume the following grammar.
"

# ╔═╡ 39eaa982-ba88-49b9-ad52-076a169d0439
g = @csgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number
    Number = Number * Number
end

# ╔═╡ 2478d5a4-a11e-42aa-87dd-d97a3fa5d378
md"
Let's construct a program `x+3`, which would correspond to the following `RuleNode` representation
"

# ╔═╡ 1e15898e-568c-4211-ba00-27de61806aeb
myprog = RuleNode(4, [RuleNode(3), RuleNode(1)])

# ╔═╡ d43a2094-b215-4d6c-b6d8-8d32fe8898d6
md"
To run this program, we have to convert it into a Julia expression, which we can do in the following way:
"

# ╔═╡ a77621ce-1749-4e16-b3dc-f5312cc5ee73
myprog_julia = rulenode2expr(myprog, g)

# ╔═╡ 48997ff5-a492-4bfd-8c64-d935433228c0
md"
Now we have a valid Julia expression, but we are still missing one key ingredient: we have to inform the interpreter about the special symbols. In our case, these are `:x` and `:+`. To do so, we need to create a symbol table, which is nothing more than a dictionary mapping symbols to their values:
"

# ╔═╡ 3e4f7ed5-bfba-4aa0-9f43-2978a9082054
symboltable = Dict{Symbol,Any}(:x => 2, :+ => +)

# ╔═╡ 2a6f6456-2937-4520-8427-8d7595076ec5
md"
Now we can execute our program through the default interpreter available in `HerbInterpret`:
"

# ╔═╡ c0dcdbc8-2355-4f4d-85c2-ec37bfeab226
interpret(symboltable, myprog_julia)

# ╔═╡ b3ac6903-8513-40cc-91ee-8ae7beb08d1d
md"And that's it!"

# ╔═╡ f765b471-74f8-4e17-8e1e-e556d88eb84b
md"# Defining a custom interpreter

A disadvantage of the default Julia interpreter is that it needs to traverse abstract syntax tree twice -- once to convert it into a Julia expression, and the second time to execute that expression. Program execution is regularly the most consuming part of the entire pipeline and, by eliminating one of these steps, we can cut the runtime in half.

We can define an interpreter that works directly over `RuleNode`s. 
Consider the scenario in which we want to write programs for robot navigation: imagine a 2D world in which the robot can move around and pick up a ball. The programs we could write direct the robot to go up, down, left, and right. For convenience, the programming language also offers conditionals and loops:
"

# ╔═╡ 1b251d0f-3a77-494f-a359-d8dc33ad5d44
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

# ╔═╡ aff77be9-365f-4672-bbd4-07f23528e32e
md"
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
 "

# ╔═╡ 1f700607-3cdf-43bf-91f2-72de3c9abc85
md"
The remaining functions follow a similar idea. (You can see the full implementation of this interpreter [here](https://github.com/Herb-AI/HerbBenchmarks.jl/blob/new-robots/src/data/Robots_2020/robots_primitives.jl))."

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HerbGrammar = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"
HerbInterpret = "5bbddadd-02c5-4713-84b8-97364418cca7"

[compat]
HerbGrammar = "~0.5.0"
HerbInterpret = "~0.1.6"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.2"
manifest_format = "2.0"
project_hash = "d028e4e441d418989f64ba766e46ee0ffefd7742"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.AutoHashEquals]]
git-tree-sha1 = "4ec6b48702dacc5994a835c1189831755e4e76ef"
uuid = "15f4f7f2-30c1-5605-9d31-71845cf9641f"
version = "2.2.0"

[[deps.HerbCore]]
deps = ["AbstractTrees"]
git-tree-sha1 = "7af906201c6d701957b9d061c58940a28bfa4b83"
uuid = "2b23ba43-8213-43cb-b5ea-38c12b45bd45"
version = "0.3.4"

[[deps.HerbGrammar]]
deps = ["HerbCore", "Serialization"]
git-tree-sha1 = "3c667987e8a27d9b697993fab68dfc602b3a18e6"
uuid = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"
version = "0.5.0"

[[deps.HerbInterpret]]
deps = ["HerbCore", "HerbGrammar", "HerbSpecification"]
git-tree-sha1 = "6dd2913b88e0cbd0bc5ed78e67d4d406df61ddda"
uuid = "5bbddadd-02c5-4713-84b8-97364418cca7"
version = "0.1.6"

[[deps.HerbSpecification]]
deps = ["AutoHashEquals"]
git-tree-sha1 = "4a153a24694d4d91cf811d63581c9115087f06fc"
uuid = "6d54aada-062f-46d8-85cf-a1ceaf058a06"
version = "0.2.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"
"""

# ╔═╡ Cell order:
# ╠═e0a7076c-9345-40ef-a26e-99e8bad31463
# ╟─55719688-3940-11ef-1f29-f51dea064ff3
# ╠═39eaa982-ba88-49b9-ad52-076a169d0439
# ╟─2478d5a4-a11e-42aa-87dd-d97a3fa5d378
# ╠═1e15898e-568c-4211-ba00-27de61806aeb
# ╟─d43a2094-b215-4d6c-b6d8-8d32fe8898d6
# ╠═a77621ce-1749-4e16-b3dc-f5312cc5ee73
# ╟─48997ff5-a492-4bfd-8c64-d935433228c0
# ╠═3e4f7ed5-bfba-4aa0-9f43-2978a9082054
# ╟─2a6f6456-2937-4520-8427-8d7595076ec5
# ╠═c0dcdbc8-2355-4f4d-85c2-ec37bfeab226
# ╟─b3ac6903-8513-40cc-91ee-8ae7beb08d1d
# ╟─f765b471-74f8-4e17-8e1e-e556d88eb84b
# ╠═1b251d0f-3a77-494f-a359-d8dc33ad5d44
# ╟─aff77be9-365f-4672-bbd4-07f23528e32e
# ╠═1f700607-3cdf-43bf-91f2-72de3c9abc85
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
