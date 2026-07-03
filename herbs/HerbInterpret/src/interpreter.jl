"""
    execute_on_input(tab::SymbolTable, expr::Any, input::Dict{Symbol, T})::Any where T

Evaluates an expression `expr` within the context of a symbol table `tab` and a single input dictionary `input`. 
The input dictionary keys should match the symbols used in the expression, and their values are used during the expression's evaluation.

# Arguments
- `tab::SymbolTable`: A symbol table containing predefined symbols and their associated values or functions.
- `expr::Any`: The expression to be evaluated. Can be any Julia expression that is valid within the context of the provided symbol table and input.
- `input::Dict{Symbol, T}`: A dictionary where each key is a symbol used in the expression, and the value is the corresponding value to be used in the expression's evaluation. The type `T` can be any type.

# Returns
- `Any`: The result of evaluating the expression with the given symbol table and input dictionary.

!!! warning
    This function throws exceptions that are caused in the given expression. These exceptions have to be handled by the caller of this function.

"""
function execute_on_input(tab::SymbolTable, expr::Any, input::Dict{Symbol, T})::Any where T
    # Add input variable values
    symbols = merge(tab, input)
    return interpret(symbols, expr)
end

"""
    execute_on_input(tab::SymbolTable, expr::Any, input::Vector{T})::Vector{<:Any} where T <: Dict{Symbol, <:Any}

Wrapper around [`execute_on_input`](@ref) to execute all inputs given as an array.

# Arguments
- `tab::SymbolTable`: A symbol table containing predefined symbols and their associated values or functions.
- `expr::Any`: The expression to be evaluated for each input dictionary.
- `inputs::Vector{T}`: A vector of dictionaries, each serving as an individual set of inputs for the expression's evaluation.

# Returns
- `Vector{<:Any}`: A vector containing the results of evaluating the expression for each input dictionary.
"""
function execute_on_input(tab::SymbolTable, expr::Any, input::Vector{T})::Vector{<:Any} where T <: Dict{Symbol, <:Any}
    return [execute_on_input(tab, expr, example) for example in input]
end

"""
    execute_on_input(grammar::AbstractGrammar, program::RuleNode, input::Dict{Symbol, T})::Any where T

Converts a `RuleNode` program into an expression using a given `grammar`, then evaluates this expression with a single input dictionary `input` and a symbol table derived from the `grammar` using `execute_on_input(tab::SymbolTable, expr::Any, input::Dict{Symbol, T})`.

# Arguments
- `grammar::AbstractGrammar`: A grammar object used to convert the `RuleNode` into an executable expression.
- `program::RuleNode`: The program, represented as a `RuleNode`, to be converted and evaluated.
- `input::Dict{Symbol, T}`: A dictionary providing input values for symbols used in the generated expression.

# Returns
- `Any`: The result of evaluating the generated expression with the given input dictionary.
"""
function execute_on_input(grammar::AbstractGrammar, program::RuleNode, input::Dict{Symbol, T})::Any where T
    expression = rulenode2expr(program, grammar)
    symboltable = grammar2symboltable(grammar)
    return execute_on_input(symboltable, expression, input)
end

"""
    execute_on_input(grammar::AbstractGrammar, program::RuleNode, input::Vector{T})::Vector{Any} where T <: Dict{Symbol, <:Any}

Converts a `RuleNode` program into an expression using a given `grammar`, then evaluates this expression for each input dictionary in a vector `input` and a symbol table derived from the `grammar` using `execute_on_input(tab::SymbolTable, expr::Any, input::Dict{Symbol, T})`.

# Arguments
- `grammar::AbstractGrammar`: A grammar object used to convert the `RuleNode` into an executable expression.
- `program::RuleNode`: The program, represented as a `RuleNode`, to be converted and evaluated.
- `input::Vector{T}`: A vector of dictionaries, each providing input values for symbols used in the generated expression.

# Returns
- `Vector{Any}`: A vector containing the results of evaluating the generated expression for each input dictionary.
"""
function execute_on_input(grammar::AbstractGrammar, program::RuleNode, input::Vector{T})::Vector{Any} where T <: Dict{Symbol, <:Any}
    expression = rulenode2expr(program, grammar)
    symboltable = grammar2symboltable(grammar)
    return execute_on_input(symboltable, expression, input)
end


"""
    evaluate_program(program::RuleNode, examples::Vector{<:IOExample}, grammar::AbstractGrammar, evaluation_function::Function)

Runs a program on the examples and returns tuples of actual desired output and the program's output
"""
function evaluate_program(program::RuleNode, examples::Vector{<:IOExample}, grammar::AbstractGrammar, evaluation_function::Function)
    depwarn("`evaluate_program` is deprecated and should no longer be used. Please use HerbSearch.evaluate instead.", :evaluate_program)

    results = Tuple{<:Number,<:Number}[]
    expression = rulenode2expr(program, grammar)
    symbol_table = SymbolTable(grammar)
    for example ∈ filter(e -> e isa IOExample, examples)
        outcome = evaluation_function(symbol_table, expression, example.in)
        push!(results, (example.out, outcome))
    end
    return results
end


"""
    interpret(tab::SymbolTable, ex::Expr)

Evaluates an expression without compiling it.
Uses AST and symbol lookups. Only supports :call and :(=)
expressions at the moment.

Example usage:
```
tab = SymbolTable(:f => f, :x => x)
ex = :(f(x))
interpret(tab, ex)
```

WARNING: This function throws exceptions that are caused in the given expression.
These exceptions have to be handled by the caller of this function.
"""
interpret(tab::SymbolTable, x::Any) = x
interpret(tab::SymbolTable, s::Symbol) = tab[s]

function interpret(tab::SymbolTable, ex::Expr)
    args = ex.args
    if ex.head == :call
        if ex.args[1] == Symbol(".&")
            return (interpret(tab, args[2]) .& interpret(tab, args[3]))
        elseif ex.args[1] == Symbol(".|")
            return (interpret(tab, args[2]) .| interpret(tab, args[3]))
        elseif ex.args[1] == Symbol(".==")
            return (interpret(tab, args[2]) .== interpret(tab, args[3]))
        elseif ex.args[1] == Symbol(".>=")
            return (interpret(tab, args[2]) .>= interpret(tab, args[3]))
        elseif ex.args[1] == Symbol(".<=")
            return (interpret(tab, args[2]) .<= interpret(tab, args[3]))
        else
            len = length(args)
            #unroll for performance and avoid excessive allocations
            if len == 1
                return tab[args[1]]()
            elseif len == 2
                return tab[args[1]](interpret(tab,args[2]))
            elseif len == 3
                return tab[args[1]](interpret(tab,args[2]), interpret(tab,args[3]))
            elseif len == 4
                return tab[args[1]](interpret(tab,args[2]), interpret(tab,args[3]), interpret(tab,args[4]))
            elseif len == 5
                return tab[args[1]](interpret(tab,args[2]), interpret(tab,args[3]), interpret(tab,args[4]),
                                       interpret(tab,args[5]))
            elseif len == 6
                return tab[args[1]](interpret(tab,args[2]), interpret(tab,args[3]), interpret(tab,args[4]),
                                       interpret(tab,args[5]), interpret(tab,args[6]))
            else
                return tab[args[1]](interpret.(Ref(tab),args[2:end])...)
            end
        end
    elseif ex.head == :(.)
        return Base.broadcast(Base.eval(args[1]), interpret(tab, args[2])...)
    elseif ex.head == :tuple
        return tuple(interpret.(Ref(tab), args)...)
    elseif ex.head == :vect
        return [interpret.(Ref(tab), args)...]
    elseif ex.head == :||
        return (interpret(tab, args[1]) || interpret(tab, args[2]))
    elseif ex.head == :&&
        return (interpret(tab, args[1]) && interpret(tab, args[2]))
    elseif ex.head == :(=)
        return (tab[args[1]] = interpret(tab, args[2])) #assignments made to symboltable
    elseif ex.head == :block
        result = nothing
        for x in args
            result = interpret(tab, x)
        end
        return result
    elseif ex.head == :if
        if interpret(tab, args[1])
            return interpret(tab, args[2])
        else
            return interpret(tab, args[3])
        end
    else
        error("Expression type not supported")
    end
end


### Raw interpret, no symbol table
function interpret(ex::Expr, M::Module=Main)
    result = if ex.head == :call
        call_func(M, ex.args...)
    elseif ex.head == :vect
        ex.args
    else
        Core.eval(M, ex)
    end
end
call_func(M::Module, f::Symbol, x...) = getproperty(M,f)(x...)
