using StatsBase
"""
    Contains all function for sampling expressions and from expressions
"""


"""
    rand(::Type{RuleNode}, grammar::AbstractGrammar, max_depth::Int=10)

Generates a random [`RuleNode`](@ref) of arbitrary type and maximum depth max_depth.
"""
function Base.rand(::Type{RuleNode}, grammar::AbstractGrammar, max_depth::Int=10)
    random_type = StatsBase.sample(grammar.types)
    dmap = mindepth_map(grammar)
    return rand(RuleNode, grammar, random_type, dmap, max_depth)
end

"""
    rand(::Type{RuleNode}, grammar::AbstractGrammar, typ::Symbol, max_depth::Int=10)

Generates a random [`RuleNode`](@ref) of return type typ and maximum depth max_depth.
"""
function Base.rand(::Type{RuleNode}, grammar::AbstractGrammar, typ::Symbol, max_depth::Int=10)
    dmap = mindepth_map(grammar)
    return rand(RuleNode, grammar, typ, dmap, max_depth)
end


"""
    rand(::Type{RuleNode}, grammar::AbstractGrammar, typ::Symbol, dmap::AbstractVector{Int}, max_depth::Int=10)

Generates a random [`RuleNode`](@ref), i.e. an expression tree, of root type typ and maximum depth max_depth guided by a depth map dmap if possible.
"""
function Base.rand(::Type{RuleNode}, grammar::AbstractGrammar, typ::Symbol, dmap::AbstractVector{Int}, 
    max_depth::Int=10)
    rules = grammar[typ]
    filtered = filter(r->dmap[r] ≤ max_depth, rules)
    if isempty(filtered)
        error("The random function could not find an expression of the given $max_depth depth")
        return
    end

    rule_index = StatsBase.sample(filtered)
    @assert max_depth >= 0

    rulenode = iseval(grammar, rule_index) ?
        RuleNode(rule_index, Core.eval(grammar, rule_index)) :
        RuleNode(rule_index)

    if !grammar.isterminal[rule_index]
        for ch in child_types(grammar, rule_index)
            push!(rulenode.children, rand(RuleNode, grammar, ch, dmap, max_depth-1))
        end
    end
    return rulenode
end

mutable struct RuleNodeAndCount
    node::RuleNode
    cnt::Int
end

"""
    sample(root::RuleNode, typ::Symbol, grammar::AbstractGrammar, maxdepth::Int=typemax(Int))

Uniformly samples a random node from the tree limited to maxdepth.
"""
function StatsBase.sample(root::RuleNode, maxdepth::Int=typemax(Int))
    x = RuleNodeAndCount(root, 1)
    for child in root.children
        _sample(child, x, maxdepth-1)
    end
    x.node
end

function _sample(node::RuleNode, x::RuleNodeAndCount, maxdepth::Int)
    maxdepth < 1 && return
    x.cnt += 1
    if rand() <= 1/x.cnt
        x.node = node
    end
    for child in node.children
        _sample(child, x, maxdepth-1)
    end
end

"""
    sample(root::RuleNode, typ::Symbol, grammar::AbstractGrammar,
                          maxdepth::Int=typemax(Int))

Uniformly selects a random node of the given return type typ limited by maxdepth.
"""
function StatsBase.sample(root::RuleNode, typ::Symbol, grammar::AbstractGrammar,
                          maxdepth::Int=typemax(Int))
    x = RuleNodeAndCount(root, 0)
    if grammar.types[root.ind] == typ
        x.cnt += 1
    end
    for child in root.children
        _sample(child, typ, grammar, x, maxdepth-1)
    end
    grammar.types[x.node.ind] == typ || error("type $typ not found in RuleNode")
    x.node
end
function _sample(node::RuleNode, typ::Symbol, grammar::AbstractGrammar, x::RuleNodeAndCount,
                 maxdepth::Int)
    maxdepth < 1 && return
    if grammar.types[node.ind] == typ
        x.cnt += 1
        if rand() <= 1/x.cnt
            x.node = node
        end
    end
    for child in node.children
        _sample(child, typ, grammar, x, maxdepth-1)
    end
end

mutable struct NodeLocAndCount
    loc::NodeLoc
    cnt::Int
end


"""
    sample(::Type{NodeLoc}, root::RuleNode, maxdepth::Int=typemax(Int))
    
Uniformly selects a random node in the tree no deeper than maxdepth using reservoir sampling.
Returns a [`NodeLoc`](@ref) that specifies the location using its parent so that the subtree can be replaced.
"""
function StatsBase.sample(::Type{NodeLoc}, root::RuleNode, maxdepth::Int=typemax(Int))
    x = NodeLocAndCount(NodeLoc(root, 0), 1)
    _sample(NodeLoc, root, x, maxdepth-1)
    x.loc
end


function _sample(::Type{NodeLoc}, node::RuleNode, x::NodeLocAndCount, maxdepth::Int)
    maxdepth < 1 && return
    for (j,child) in enumerate(node.children)
        x.cnt += 1
        if rand() <= 1/x.cnt
            x.loc = NodeLoc(node, j)
        end
        _sample(NodeLoc, child, x, maxdepth-1)
    end
end
    
"""
    StatsBase.sample(::Type{NodeLoc}, root::RuleNode, typ::Symbol, grammar::AbstractGrammar, maxdepth::Int=typemax(Int))
    
Uniformly selects a random node in the tree of a given type, specified using its parent such that the subtree can be replaced.
Returns a [`NodeLoc`](@ref).
"""
function StatsBase.sample(::Type{NodeLoc}, root::RuleNode, typ::Symbol, grammar::AbstractGrammar, maxdepth::Int=typemax(Int))
    x = NodeLocAndCount(NodeLoc(root, 0)
    , 0)
    if grammar.types[root.ind] == typ
        x.cnt += 1
    end
    _sample(NodeLoc, root, typ, grammar, x, maxdepth-1)
    grammar.types[get(root,x.loc).ind] == typ || error("type $typ not found in RuleNode")
    x.loc
end
    
function _sample(::Type{NodeLoc}, node::RuleNode, typ::Symbol, grammar::AbstractGrammar, x::NodeLocAndCount, maxdepth::Int)
    maxdepth < 1 && return
    for (j,child) in enumerate(node.children)
        if grammar.types[child.ind] == typ
            x.cnt += 1
            if rand() <= 1/x.cnt
                x.loc = NodeLoc(node, j)
            end
            _sample(NodeLoc, child, typ, grammar, x, maxdepth-1)
        end
    end
end
