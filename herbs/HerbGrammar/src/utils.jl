"""
    mindepth_map(grammar::AbstractGrammar)

Returns the minimum depth achievable for each production rule in the [`AbstractGrammar`](@ref).
In other words, this function finds the depths of the lowest trees that can be made 
using each of the available production rules as a root.
"""
function mindepth_map(grammar::AbstractGrammar)
    dmap0 = Int[isterminal(grammar,i) ? 1 : typemax(Int)/2 for i in eachindex(grammar.rules)]
    dmap1 = fill(-1, length(grammar.rules)) 
    while dmap0 != dmap1
        for i in eachindex(grammar.rules)
            dmap1[i] = _mindepth(grammar, i, dmap0)
        end
        dmap1, dmap0 = dmap0, dmap1
    end
    dmap0
end


function _mindepth(grammar::AbstractGrammar, rule_index::Int, dmap::AbstractVector{Int})
    isterminal(grammar, rule_index) && return 1
    return 1 + maximum([mindepth(grammar, ctyp, dmap) for ctyp in child_types(grammar, rule_index)])
end


"""
    mindepth(grammar::AbstractGrammar, typ::Symbol, dmap::AbstractVector{Int})

Returns the minimum depth achievable for a given nonterminal symbol.
The minimum depth is the depth of the lowest tree that can be made using `typ` 
as a start symbol. `dmap` can be obtained from [`mindepth_map`](@ref).
"""
function mindepth(grammar::AbstractGrammar, typ::Symbol, dmap::AbstractVector{Int})
    return minimum(dmap[grammar.bytype[typ]])
end

"""
    SymbolTable

Type alias for a `Dict` that maps terminal symbols in the [`AbstractGrammar`](@ref)
to their Julia interpretation.
"""
const SymbolTable = Dict{Symbol,Any}

"""
    grammar2symboltable(grammar::AbstractGrammar, mod::Module=Main)

Returns a [`SymbolTable`](@ref) populated with a mapping from symbols in the 
[`AbstractGrammar`](@ref) to symbols in module `mod` or `Main`, if defined.
"""
function grammar2symboltable(grammar::AbstractGrammar, mod::Module=Main)
    tab = SymbolTable()
    for rule in grammar.rules
        _add_to_symboltable!(tab, rule, mod)
    end
    tab
end

# When we eventually remove this deprecation, also remove `SymbolTables` from
# the `treat_as_own` option in `test/runtests.jl` 
@deprecate SymbolTable(g::AbstractGrammar, m::Module) grammar2symboltable(g, m)

_add_to_symboltable!(tab::SymbolTable, rule::Any, mod::Module) = true


function _add_to_symboltable!(tab::SymbolTable, rule::Expr, mod::Module)
    if rule.head == :call && !iseval(rule)
        s = rule.args[1]
        if !_add_to_symboltable!(tab, s, mod)
            @warn "Unable to add function $s to symbol table"  
        end
        for s in rule.args[2:end]  #nested exprs
            _add_to_symboltable!(tab, s, mod)
        end
    end
    return true
end

function _apply_if_defined_in_modules(func::Function, s::Symbol, mods::Vector{Module})
    for mod in mods
        if isdefined(mod, s)
            func(mod, s)
            return true
        end
    end
    return false
end

function _is_defined_in_modules(s::Symbol, mods::Vector{Module})
    _apply_if_defined_in_modules((mod, s) -> nothing, s, mods)
end

function _add_to_symboltable!(tab::SymbolTable, s::Symbol, mod::Module)
    _add_to_table! = (mod, s) -> tab[s] = getfield(mod, s)

    return _apply_if_defined_in_modules(_add_to_table!, s, [mod, Base, Main])
end


"""
    containedin(vec1::Vector, vec2::Vector)

Checks if elements of `vec1` are contained in `vec2` in the same order (possibly with elements in between)
"""
function containedin(vec1::Vector, vec2::Vector)
    max_elements = length(vec1)
    vec1_index = 1 # keeps track where we are in the first vector
    for item in vec2
        if vec1_index > max_elements
            return true
        end
        
        if item == vec1[vec1_index]
            vec1_index += 1  # increase the index every time we encounter the matching element
        end
    end

    return vec1_index > max_elements
end


"""
    subsequenceof(vec1::Vector{Int}, vec2::Vector{Int})

Checks if `vec1` is a subsequence of `vec2`.
"""
function subsequenceof(vec1::Vector{Int}, vec2::Vector{Int})
    vec1_index = 1
    last_found_vec1_element_ind = 0
    vec2_index = 1

    while isassigned(vec2, vec2_index)
        vec2_elem = vec2[vec2_index]
        vec1_elem = get(vec1, vec1_index, nothing)

        if vec1_elem === nothing 
            break
        end

        if vec1_elem == vec2_elem && (last_found_vec1_element_ind == 0 || last_found_vec1_element_ind == vec2_index - 1)
            vec1_index += 1
            last_found_vec1_element_ind = vec2_index
        end

        vec2_index += 1
    end
    
    return get(vec1, vec1_index, nothing) === nothing

end
