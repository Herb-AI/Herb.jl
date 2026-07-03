"""
     is_subdomain(subdomain::BitVector, domain::BitVector)
     is_subdomain(subdomain::StateSparseSet, domain::BitVector)

Checks if `subdomain` is a subdomain of `domain`.
Example: [0, 0, 1, 0] is a subdomain of [0, 1, 1, 1]
"""
function is_subdomain(subdomain::BitVector, domain::BitVector)
    return all(.!subdomain .| domain)
end
function is_subdomain(subdomain::StateSparseSet, domain::BitVector)
    for v ∈ subdomain
        if !domain[v]
            return false
        end
    end
    return true
end

"""
    is_subdomain(specific_tree::AbstractRuleNode, general_tree::AbstractRuleNode)

Checks if the `specific_tree` can be obtained by repeatedly removing values from the `general_tree`
"""
function is_subdomain(specific_tree::AbstractRuleNode, general_tree::AbstractRuleNode)
    @match (isfilled(specific_tree), isfilled(general_tree)) begin
        #(RuleNode, RuleNode), the rules must be equal
        (true, true) => begin
            if get_rule(specific_tree) != get_rule(general_tree)
                return false
            end
        end
        
        #(RuleNode, AbstractHole), the rule must be inside the domain of the general_tree
        (true, false) => begin 
            if !general_tree.domain[get_rule(specific_tree)]
                return false
            end
        end

        #(AbstractHole, RuleNode), the specific_tree holds more rules than the general_tree, this cannot be a subdomain
        (false, true) => return false

        #(AbstractHole, AbstractHole), dispatch to the is_subdomain for domains
        (false, false) => begin 
            if !is_subdomain(specific_tree.domain, general_tree.domain)
                return false
            end
        end
    end

    #the general_tree is a non-uniform hole, the specific_tree must be more specific
    #Example: general_tree = Hole({3, 4, 5}). specific_tree = RuleNode(3, [RuleNode(1), RuleNode(1)]).
    if !isuniform(general_tree)
        return true
    end

    #continue checking the children
    @assert isuniform(general_tree)
    @assert isuniform(specific_tree) "The specific_tree cannot be a non-uniform Hole at this point."
    @assert length(get_children(specific_tree)) == length(get_children(general_tree))
    for (specific_child, general_child) ∈ zip(get_children(specific_tree), get_children(general_tree))
        if !is_subdomain(specific_child, general_child)
            return false
        end
    end
    return true
end

"""
    partition(hole::Hole, grammar::ContextSensitiveGrammar)::Vector{BitVector}

Partition a [Hole](@ref) into subdomains grouped by childtypes and the parent type.
"""
function partition(hole::Hole, grammar::ContextSensitiveGrammar)::Vector{BitVector}
    domain = copy(hole.domain)
    fixed_shaped_domains = []
    while true
        rule = findfirst(domain)
        if isnothing(rule)
            break
        end
        
        parent_mask = falses(length(domain))
        parent_mask[grammar.bytype[grammar.types[rule]]] .= true

        fixed_shaped_domain = grammar.bychildtypes[rule] .& parent_mask .& hole.domain
        push!(fixed_shaped_domains, fixed_shaped_domain)
        domain .-= fixed_shaped_domain
    end
    return fixed_shaped_domains
end

"""
    are_disjoint(domain1::BitVector, domain2::BitVector)::Bool

Returns true if there is no overlap in values between `domain1` and `domain2`
"""
function are_disjoint(domain1::BitVector, domain2::BitVector)::Bool
    return all(.!domain1 .| .!domain2)
end
are_disjoint(bitvector::BitVector, sss::StateSparseSet)::Bool = are_disjoint(sss, bitvector)
function are_disjoint(sss::StateSparseSet, bitvector::BitVector)
    for v ∈ sss
        if bitvector[v]
            return false
        end
    end
    return true
end

"""
    get_intersection(domain1::BitVector, domain2::BitVector)::Bool

Returns all the values that are in both `domain1` and `domain2`
"""
function get_intersection(domain1::BitVector, domain2::BitVector)::Vector{Int}
    return findall(domain1 .& domain2)
end
function get_intersection(sss::Union{BitVector, StateSparseSet}, domain2::Union{BitVector, StateSparseSet})::Vector{Int}
    if !(sss isa StateSparseSet) 
        sss, domain2 = domain2, sss
        @assert sss isa StateSparseSet
    end
    intersection = Vector{Int}()
    for v ∈ sss
        if domain2[v]
            push!(intersection, v)
        end
    end
    return intersection
end
