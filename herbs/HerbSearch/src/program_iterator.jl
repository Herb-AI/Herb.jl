import HerbConstraints: get_grammar, get_starting_symbol, get_max_size,
    get_max_depth

"""
    abstract type ProgramIterator

Abstract iterator type for all search strategies.

See [`@programiterator`](@ref) for details on constructing iterators or
defining new strategies.
"""
abstract type ProgramIterator end

"""
    get_solver(pi::ProgramIterator)

Get the program iterator solver.
"""
function get_solver(pi::ProgramIterator)
    return pi.solver
end

"""
    HerbConstraints.get_grammar(pi::ProgramIterator)

"""
function HerbConstraints.get_grammar(pi::ProgramIterator)
    return get_grammar(get_solver(pi))
end

"""
    HerbConstraints.get_starting_symbol(pi::ProgramIterator)

Get the starting symbol of the iterator.

# Example

Given an iterator that is initialized with `:Int` as the starting symbol, the
root of each of the programs returned from the iterator will have the same
type, and this will match the symbol returned by [`get_starting_symbol`](@ref).

```jldoctest
julia> g = @csgrammar begin
           Int = length(List)
           Int = Int + Int
           List = x
       end;

julia> it = BFSIterator(g, :Int; max_depth=4);

julia> programs = rulenode2expr.((freeze_state(p) for p in it), (g,))
5-element Vector{Expr}:
 :(length(x))
 :(length(x) + length(x))
 :(length(x) + (length(x) + length(x)))
 :((length(x) + length(x)) + length(x))
 :((length(x) + length(x)) + (length(x) + length(x)))

julia> get_starting_symbol(it)
:Int
```

Note that all of the programs will return an `Int`, matching the type returned
by `get_starting_symbol(it)`.
"""
function HerbConstraints.get_starting_symbol(pi::ProgramIterator)
    return get_starting_symbol(get_solver(pi))
end

"""
    HerbConstraints.get_max_depth(pi::ProgramIterator)

Get the maximum depth of the programs that the program iterator will return.
"""
function HerbConstraints.get_max_depth(pi::ProgramIterator)
    return get_max_depth(get_solver(pi))
end

"""
    HerbConstraints.get_max_size(pi::ProgramIterator)

Get the maximum size of the programs that the program iterator will return.
"""
function HerbConstraints.get_max_size(pi::ProgramIterator)
    return get_max_size(get_solver(pi))
end

Base.IteratorSize(::ProgramIterator) = Base.SizeUnknown()

Base.eltype(::ProgramIterator) = Union{RuleNode,StateHole}

"""
    Base.length(iter::ProgramIterator)    

Counts and returns the number of possible programs without storing all the programs.

!!! warning
    Modifies and exhausts the iterator
"""
function Base.length(iter::ProgramIterator)
    l = 0
    for _ ∈ iter
        l += 1
    end
    return l
end

const RESERVERD_ARG_NAMES = [:solver, :start_symbol, :initial_node, :grammar, :max_depth, :max_size]

"""
    @programiterator

Create a new type `T<:ProgramIterator` that includes the common fields of
[`ProgramIterator`](@ref)s and some useful constructors.

## Fields

$(join(("""
    - $a
    """ for a in RESERVERD_ARG_NAMES)))

Syntax accepted by the macro is as follows (anything enclosed in square
brackets is optional):

```julia
@programiterator [mutable] <IteratorName>(
<arg₁>,
...,
<argₙ>
) [<: <SupertypeIterator>]
```

The `mutable` keyword determines whether the declared struct is mutable.
`SupertypeIterator` must be an abstract type `<:ProgramIterator`. If no
supertype is given, the new iterator extends `ProgramIterator` directly. Each
<argᵢ> may be (almost) any expression valid in a struct declaration, and they
must be comma separated.

!!! warning
    An inner constructor must always be given using the extended `function
    <name>(...) ... end` syntax.

# Example
```jldoctest
julia> abstract type SomeIteratorFamily<:ProgramIterator end

julia> @programiterator mutable SomeCustomIterator(a_param::Int) <: SomeIteratorFamily;
```
"""
macro programiterator(mut, ex)
    if mut == :mutable
        generate_iterator(__module__, ex, true)
    else
        throw(ArgumentError("$mut is not a valid argument to @programiterator"))
    end
end

macro programiterator(ex)
    generate_iterator(__module__, ex)
end

function generate_iterator(mod::Module, ex::Expr, mut::Bool=false)
    Base.remove_linenums!(ex)

    @match ex begin
        Expr(:(<:), decl::Expr, super) => begin
            # a check that `super` is a subtype of `ProgramIterator`
            check = :($mod.$super <: HerbSearch.ProgramIterator ||
                      throw(ArgumentError("attempting to inherit a non-ProgramIterator")))

            # process the decl 
            Expr(:block, check, _processdecl(mod, mut, decl, super)...)
        end
        decl => Expr(:block, _processdecl(mod, mut, decl)...)
    end
end

_processdecl(mod::Module, mut::Bool, decl::Expr, super=nothing) = @match decl begin
    Expr(:call, name::Symbol, extrafields...) => begin
        kwargs_fields = map(esc, filter(_is_kwdef, extrafields))
        notkwargs = map(esc, filter(!_is_kwdef, extrafields))

        # create field names
        field_names = map(_extract_name_from_argument, extrafields)

        # throw an error if user used one of the reserved arg names 
        colliding_field_names = intersect(field_names, RESERVERD_ARG_NAMES)
        if !isempty(colliding_field_names)
            throw(ArgumentError(
                """You have provided field(s) to the `@programiterator` macro \
                that collide with the defaults.

                You provided: $colliding_field_names

                Defaults: $RESERVERD_ARG_NAMES

                Please change the name(s) of the field argument(s) to not collide \
                with the default fields above."""
            ))
        end

        field_names = map(esc, field_names)
        escaped_name = esc(name) # this is the name of the struct

        # keyword arguments come after the normal arguments (notkwargs)
        all_constructors = Base.remove_linenums!(
            :(
                begin
                    # solver main constructor
                    function $(escaped_name)($(notkwargs...); solver::Solver, max_size=nothing, max_depth=nothing, $(kwargs_fields...))
                        if !isnothing(max_size)
                            solver.max_size = max_size
                        end
                        if !isnothing(max_depth)
                            solver.max_depth = max_depth
                        end
                        return $(escaped_name)(solver, $(field_names...))
                    end
                    # solver with grammar and start symbol
                    function $(escaped_name)(grammar::AbstractGrammar, start_symbol::Symbol, $(notkwargs...);
                        max_size=typemax(Int), max_depth=typemax(Int), $(kwargs_fields...))
                        return $(escaped_name)(GenericSolver(grammar, start_symbol, max_size=max_size, max_depth=max_depth), $(field_names...))
                    end

                    # solver with grammar and initial rulenode to start with
                    function $(escaped_name)(grammar::AbstractGrammar, initial_node::AbstractRuleNode, $(notkwargs...);
                        max_size=typemax(Int), max_depth=typemax(Int), $(kwargs_fields...))
                        return $(escaped_name)(GenericSolver(grammar, initial_node, max_size=max_size, max_depth=max_depth), $(field_names...))
                    end
                end
            )
        )

        # create the struct declaration
        head = Expr(:(<:), name, isnothing(super) ? :(HerbSearch.ProgramIterator) : :($mod.$super))
        fields = Base.remove_linenums!(quote
            solver::Solver
        end)

        kwargs = Vector{Expr}()
        map!(ex -> _processkwarg!(kwargs, ex), extrafields, extrafields)
        append!(fields.args, extrafields)

        constrfields = copy(fields)
        map!(esc, constrfields.args, constrfields.args)
        struct_decl = Expr(:struct, mut, esc(head), constrfields)

        # return the expression for the struct declaration and for the constructors
        struct_decl, all_constructors
    end
    _ => throw(ArgumentError("invalid declaration structure for the iterator"))
end


"""
    _extract_name_from_argument(ex)

Extracts the name of a field declaration, otherwise throws an `ArgumentError`.
A field declaration is either a simple field name with possible a type attached to it or a keyword argument.

# Example
x::Int     -> x 
hello      -> hello 
x = 4      -> x 
x::Int = 3 -> x
"""
function _extract_name_from_argument(ex)
    @match ex begin
        Expr(:(::), name, type) => name
        name::Symbol => name
        Expr(:kw, Expr(:(::), name, type), ::Any) => name
        Expr(:kw, name::Symbol, ::Any) => name
        _ => throw(ArgumentError("unexpected field: $ex"))
    end
end

""" 
    is_kwdeg(ex)

Checks if a field declaration is a keyword argument or not. 
This is called when filtering if the user arguments to the program iteartor are keyword arguments or not.
"""
function _is_kwdef(ex)
    @match ex begin
        Expr(:kw, name, type) => true
        _ => false
    end
end


"""
    _is_field_decl(ex)

Check if `extractname(ex)` returns a name.
"""
function _is_field_decl(ex)
    try
        extractname(ex)
        true
    catch e
        if e == ArgumentError("unexpected field: $ex")
            false
        else
            throw(e)
        end
    end
end


"""
    _processkwarg!(keywords::Vector{Expr}, ex::Union{Expr,Symbol})

Checks if `ex` has a default value specified, if so it returns only the field declaration, 
and pushes `ex` to `keywords`. Otherwise it returns `ex`
"""
function _processkwarg!(keywords::Vector{Expr}, ex::Union{Expr,Symbol})
    @match ex begin
        Expr(:kw, field_decl, ::Any) => begin
            push!(keywords, ex)
            field_decl
        end
        _ => ex
    end
end
