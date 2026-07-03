const OptionalPath = Union{Nothing, AbstractString}

"""
    store_csg(g::ContextSensitiveGrammar, grammarpath::AbstractString, constraintspath::OptionalPath=nothing)

Writes a [`ContextSensitiveGrammar`](@ref) to the files at `grammarpath` and `constraintspath`.
The `grammarpath` file will contain a [`ContextSensitiveGrammar`](@ref) definition, and the
`constraintspath` file will contain the [`AbstractConstraint`](@ref)s of the [`ContextSensitiveGrammar`](@ref).
"""
function store_csg(grammar::ContextSensitiveGrammar, filepath::AbstractString, constraintspath::OptionalPath=nothing)
    # Store grammar as CFG
    open(filepath, write=true) do file
        if !isprobabilistic(grammar)
            for (type, rule) ∈ zip(grammar.types, grammar.rules)
                println(file, "$type = $rule")
            end
        else
            for (type, rule, prob) ∈ zip(grammar.types, grammar.rules, grammar.log_probabilities)
                println(file, "$(ℯ^prob) : $type = $rule")
            end
        end
    end
    
    # exit if no constraintspath is given
    isnothing(constraintspath) && return

    # Store constraints separately
    open(constraintspath, write=true) do file
        serialize(file, grammar.constraints)
    end
end

"""
    read_csg(grammarpath::AbstractString, constraintspath::OptionalPath=nothing)::ContextSensitiveGrammar

Reads a [`ContextSensitiveGrammar`](@ref) from the files at `grammarpath` and `constraintspath`.

!!! danger
    Only open trusted grammars. 
    Parts of the grammar can be passed to Julia's `eval` function.  
"""
function read_csg(grammarpath::AbstractString, constraintspath::OptionalPath=nothing)::ContextSensitiveGrammar
    # Read the contents of the file into a string
    file = open(grammarpath)
    program::AbstractString = read(file, String)
    close(file)

    # Parse the string into an expression
    ex::Expr = Meta.parse("begin $program end")

    # Convert the expression to a context-free grammar
    g =  expr2csgrammar(ex)

    if !isnothing(constraintspath)
        file = open(constraintspath)
        constraints = deserialize(file)
        close(file)
    else
        constraints = AbstractConstraint[]
    end

    return ContextSensitiveGrammar(g.rules, g.types, g.isterminal, 
        g.iseval, g.bytype, g.domains, g.childtypes, g.bychildtypes, g.log_probabilities, constraints)
end

"""
    read_pcsg(grammarpath::AbstractString, constraintspath::OptionalPath=nothing)::ContextSensitiveGrammar

Reads a probabilistic [`ContextSensitiveGrammar`](@ref) from the files at `grammarpath` and `constraintspath`.

!!! danger
    Only open trusted grammars. 
    Parts of the grammar can be passed to Julia's `eval` function.  
"""
function read_pcsg(grammarpath::AbstractString, constraintspath::OptionalPath=nothing)::ContextSensitiveGrammar
    # Read the contents of the file into a string
    file = open(grammarpath)
    program::AbstractString = read(file, String)
    close(file)

    # Parse the string into an expression
    ex::Expr = Meta.parse("begin $program end")

    # Convert the expression to a context-free grammar
    g = expr2pcsgrammar(ex)
    
    if !isnothing(constraintspath)
        file = open(constraintspath)
        constraints = deserialize(file)
        close(file)
    else
        constraints = AbstractConstraint[]
    end
    
    return ContextSensitiveGrammar(g.rules, g.types, g.isterminal, 
        g.iseval, g.bytype, g.domains, g.childtypes, g.bychildtypes, g.log_probabilities, constraints)
end


