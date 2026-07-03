"""
    struct IOExample

An input-output example.
`in` is a [`Dict`](@ref) of `{Symbol,Any}` where the symbol represents a variable in a program.
`out` can be anything.
"""
@auto_hash_equals struct IOExample{InType, OutType}
    in::Dict{Symbol, InType}
    out::OutType
end

"""
    struct Trace

A trace defining a wanted program execution for program synthesis. 
@TODO combine with Gen.jl
"""
@auto_hash_equals struct Trace{T}
    exec_path::Vector{T}
end

abstract type AbstractFormalSpecification end

"""
    struct SMTSpecification <: AbstractFormalSpecification

A specification based on a logical formula defined by a SMT solver.
"""
@auto_hash_equals struct SMTSpecification{F} <: AbstractFormalSpecification
    formula::F
end


abstract type AbstractTypeSpecification end

"""
    struct AbstractDependentTypeSpecification <: AbstractTypeSpecification

Defines a specification through dependent types. Needs a concrete type checker as oracle.
"""
abstract type AbstractDependentTypeSpecification <: AbstractTypeSpecification end

"""
    struct AgdaSpecification <: AbstractDependentTypeSpecification

Defines a specification 
"""
@auto_hash_equals struct AgdaSpecification{F} <: AbstractDependentTypeSpecification
    formula::F
end

const AbstractSpecification = Union{
    AbstractVector{<:IOExample},
    AbstractFormalSpecification, 
    AbstractVector{<:Trace},
    AbstractTypeSpecification
    }

"""
    struct Problem

Program synthesis problem defined by an [`AbstractSpecification`](@ref)s. Has a name and a specification of type `T`.

!!! warning
    Please care that concrete `Problem` types with different values of `T` are never subtypes of each other. 
"""
@auto_hash_equals struct Problem{T <: AbstractSpecification}
    name::AbstractString
    spec::T

    function Problem(spec::T) where T <: AbstractSpecification
        new{T}("", spec)
    end
    function Problem(name::AbstractString, spec::T) where T <: AbstractSpecification
        new{T}(name, spec)
    end
end

"""
    struct MetricProblem{T <: Vector{IOExample}}

Program synthesis problem defined by an specification and a metric. The specification has to be based on input/output examples, while the function needs to return a numerical value.
"""
@auto_hash_equals struct MetricProblem{T <: AbstractVector{<:IOExample}, F}
    name::AbstractString
    cost_function::F
    spec::T

    function MetricProblem(cost_function::F, spec::T) where {T<:AbstractVector{<:IOExample}, F}
        new{T, F}("", cost_function, spec)
    end

    function MetricProblem(name::AbstractString, cost_function::F, spec::T) where {T<:AbstractVector{<:IOExample}, F}
        new{T, F}(name, cost_function, spec)
    end

end


"""
    Base.getindex(p::Problem{Vector{IOExample}}, indices)

Overwrite `Base.getindex` to allow for slicing of input/output-based problems.
"""
Base.getindex(p::Problem{<:AbstractVector{<:IOExample}}, indices) = Problem(p.name, p.spec[indices])
Base.getindex(p::MetricProblem{<:AbstractVector{<:IOExample}}, indices) = MetricProblem(p.name, p.cost_function, p.spec[indices])
