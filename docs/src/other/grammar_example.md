## Defining complex grammars
The `Julia` meta programming should allow for arbitrary complex grammars. Let's look at an example where we define while loops, conditionals and use user-defined functions in our programs.

The whole code is below
```jl
using HerbGrammar 
using HerbSearch # only used to sample random programs from the grammar

# define a custom function 
function customfunction(x,y)
    return x * x + y * y
end

complex_grammar = @csgrammar begin
    # the starting symbol (does not necessary have be at the top of the grammar)
    StartExpression = begin 
        x = Constant # initialize x to a constant
        Expression   # run expression with x
    end
    # Number definition
    Number = Constant
    Constant = 1 | 2 | 3
    Number = x
    Number = Number + Number
    Number = Number * Number

    # Expression definition
    Expression = Number 
    Expression = customfunction(Number, Number)
    Expression = println(Number) # use Julia's print function
    Condition = BoolExpression | (BoolExpression && Condition) | (BoolExpression || Condition)
    BoolExpression = (Number < Number) | (Number > Number) | (Number == Number)

    # if condition
    Expression = 
        if Condition 
            Expression
        end 
    # if then else
    Expression = 
        if Condition 
            Expression
        else 
            Expression
        end

    Expression = WhileLoop
    WhileLoop = while Condition 
                    Expression 
                end

end


# generate some random programs to see if they look good
using Random
Random.seed!(42)
for _ in 1:10
    rulenode_program = rand(RuleNode, complex_grammar, :StartExpression)
    # print program tree
    println("Rulenode program: ", rulenode_program)
    # convert prorgam tree to an expression
    expression_program = rulenode2expr(rulenode_program, complex_grammar)
    println("Program: ",  expression_program)
    # WARNING: some programs will loop forever and you may need to stop julia
    # println("Eval program: ", eval(expression)) 
end
```

The code is quite long and complex, but it shows that this way of defining grammars can be powerful. It is very **important** to note that everything on the right-hand side of the rule **must** be a valid Julia expression that can be parsed. This is the limitation that we are imposed when defining grammars like this. 

One example where one might encounter this limitation, is when trying to define boolean expressions as below.
```jl
g = @csgrammar begin 
    number = 1  
    boolexpr = number operator number 
    operator = < | > | ==
end
```
This might be a valid approach in a BNF grammar for instance, but it will not work in Julia. Why?

Julia can't parse the expression `number operator number`. Since we are using the Julia's parser to implement our grammars, we have to comply to the parsing rules Julia has. Usually there is always a work around that will allow you to do what you want.

For instance, this will work

```jl
g = @csgrammar begin 
    number = 1  
    boolexpr = number < number | number > number | number == number
end
```

You should also always check that the operator precedence that Julia uses matches your intent. You do not want to debug a grammar that does not work because Julia parses the expression on the right-hand side the way you do not want it to do. That's why it is good practice to add parenthesis `()` around your expressions when not sure about operator precedence.

What I usually do is to _sample_ from the grammar many expressions and check by looking at them to see if they are parsed properly.





<details>
<summary> Bonus question about grammars</summary>
<br>

Are you up for a challenge? Well, since you opened the dropdown I assume you are :wink: 

Below is an incorrect grammar definition taken from some code written in Herb some time ago (it is slightly simplified).

Try to find the spot the bug :lady_beetle:. Good luck :+1: 

You can check the hints below if you get stuck.
```jl
grammar_string = @cfgrammar begin
    Start = (state = Init; Sequence; Return)
    Init = initState(_arg_1)
    Return = getString(state)

    Sequence = Operation 
    Sequence = Operation; Sequence
    Operation = Transformation 
    Operation = ControlStatement

    Transformation = moveRight(state) | moveLeft(state) | makeUppercase(state) | makeLowercase(state) | drop(state)
    ControlStatement = (Condition ? Sequence : Sequence) | (while Condition; Sequence; end)

    Condition = atEnd(state) | notAtEnd(state) 
end
```

<details>
<summary>Hint 1</summary>
<br>
Try to paste the grammar definition in a Julia REPL. Do you notice anything unusual?
</details>


<details>
<summary>Hint 2</summary>
<br>
Look at this grammar rule `Sequence = Operation; Sequence` and try to find it in the output.
</details>


<details>
<summary>Solution</summary>
<br>
The expression `Operation; Sequence` is not parsed as we want by Julia. Checking the output we can see that there are two identical rules.

```jl
1: Start = begin
    state = Init
    Sequence
    Return
end
2: Init = initState(_arg_1)
3: Return = getString(state)
4: Sequence = Operation
5: Sequence = Operation  # is the same as the one on top
6: Operation = Transformation
// other rules
13: ControlStatement = if Condition
    Sequence
else
    Sequence
end
```

Adding parentheses around `Operation; Sequence` fixes the issue. Thus, `Sequence = (Operation; Sequence)` this is the correct way of writing the grammar. You can check by changing the grammar and looking at the output of the REPL.

Also if you ask Julia to parse `Sequence; Operation` vs `(Sequence; Operation)` you will notice different results:
```sh
julia> Meta.parse("Operation; Sequence")
:($(Expr(:toplevel, :Operation, :Sequence))) # <- I have no idea what :toplevel means but it is not what we want most probably

julia> Meta.parse("(Operation; Sequence)")
quote                    # this output looks good. It has one operation followed by another operation.
    Operation
    #= none:1 =# 
    Sequence
end
```
[`Meta.parse`](@ref) is a function is Julia that allows you to see how a raw string is parsed as an expression. 

Meta-programming is hard in general. Hopefully you will be able to easily debug this kindof issues that you might encounter from now on.

</details>



</details>

## Sum
We have seen how to define grammars in Herb by use of the [`@csgrammar`](@ref) macro. The general syntax for a rule is `RuleName -> some_julia_expr`.
The `RuleName` does not necessarily need to start with a capital case, it can be any identifier like expression (e.g., `rule1`, `rule_with_underscore`, etc.). However, it is nice to keep the convention that non-terminal rules start with capital rule (e.g. `Number`, `Start`) and terminal rules start with a lower case letter (e.g. `x`).

The `HerbGrammar` package also allows for the creation of _constraints_ that can be enforced in the grammar. I am not knowledgeable enough to talk about them. I will leave to other contributors to better explain these concepts. 
