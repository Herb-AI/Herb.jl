
"""
    abstract type MakeEqualResult end

A result of the `make_equal!` function. Can be one of 3 cases:
- [`MakeEqualSuccess`](@ref)
- [`MakeEqualHardFail`](@ref)
- [`MakeEqualSoftFail`](@ref)
"""
abstract type MakeEqualResult end

"""
    struct MakeEqualSuccess <: MakeEqualResult end

`node1` == `node2` is guaranteed under all possible assignments of the holes involved.
"""
struct MakeEqualSuccess <: MakeEqualResult end

"""
    struct MakeEqualHardFail <: MakeEqualResult end

`node1` != `node2` is guaranteed under all possible assignments of the holes involved.
"""
struct MakeEqualHardFail <: MakeEqualResult end

"""
    struct MakeEqualSoftFail <: MakeEqualResult end

Making `node1` == `node2` is ambiguous.
Examples:
- `RuleNode(1, [Hole({1, 2, 3})]) == RuleNode(1, [VarNode(:a)])`. The hole can be filled with any rule.
- `Hole({1, 2, 3}) == DomainRuleNode({1, 2, 3})`. The hole can be filled with any rule.
"""
struct MakeEqualSoftFail <: MakeEqualResult end

"""
    function make_equal!(solver::Solver, node1::AbstractRuleNode, node2::AbstractRuleNode)::MakeEqualResult

Tree manipulation that enforces `node1` == `node2` if unambiguous.
"""
function make_equal!(
    solver::Solver, 
    hole1::Union{RuleNode, AbstractHole},
    hole2::Union{RuleNode, AbstractHole, DomainRuleNode}
)::MakeEqualResult
    make_equal!(solver, hole1, hole2, Dict{Symbol, AbstractRuleNode}())
end

function make_equal!(
    solver::Solver, 
    hole1::Union{RuleNode, AbstractHole},
    hole2::Union{RuleNode, AbstractHole},
    vars::Dict{Symbol, AbstractRuleNode}
)::MakeEqualResult
    @assert isfeasible(solver)
    @match (isfilled(hole1), isfilled(hole2)) begin
        (true, true) => begin
            #(RuleNode, RuleNode)
            if get_rule(hole1) != get_rule(hole2)
                set_infeasible!(solver)
                return MakeEqualHardFail()
            end
        end
        (true, false) => begin
            #(RuleNode, AbstractHole)
            if !hole2.domain[get_rule(hole1)]
                set_infeasible!(solver)
                return MakeEqualHardFail()
            end
            path2 = get_path(solver, hole2)
            remove_all_but!(solver, path2, get_rule(hole1))
            hole2 = get_node_at_location(solver, path2)
        end
        (false, true) => begin
            #(AbstractHole, RuleNode)
            if !hole1.domain[get_rule(hole2)]
                set_infeasible!(solver)
                return MakeEqualHardFail()
            end
            path1 = get_path(solver, hole1)
            remove_all_but!(solver, path1, get_rule(hole2))
            hole1 = get_node_at_location(solver, path1)
        end
        (false, false) => begin
            #(AbstractHole, AbstractHole)
            rules = get_intersection(hole1.domain, hole2.domain)
            if length(rules) == 0
                return MakeEqualHardFail()
            elseif length(rules) == 1
                rule = rules[1]
                path1 = get_path(solver, hole1)
                path2 = get_path(solver, hole2)
                remove_all_but!(solver, path1, rule)
                remove_all_but!(solver, path2, rule)
                hole1 = get_node_at_location(solver, path1)
                hole2 = get_node_at_location(solver, path2)
            else
                return MakeEqualSoftFail()
            end
        end
    end

    softfailed = false
    for (child1, child2) ∈ zip(get_children(hole1), get_children(hole2))
        result = make_equal!(solver, child1, child2, vars)
        @match result begin
            ::MakeEqualSuccess => ();
            ::MakeEqualHardFail => return result;
            ::MakeEqualSoftFail => begin
                softfailed = true
            end
        end
    end
    return softfailed ? MakeEqualSoftFail() : MakeEqualSuccess()
end

function make_equal!(
    solver::Solver, 
    node::Union{RuleNode, AbstractHole},
    var::VarNode,
    vars::Dict{Symbol, AbstractRuleNode}
)::MakeEqualResult
    if var.name ∈ keys(vars) 
        return make_equal!(solver, node, vars[var.name], vars)
    end
    vars[var.name] = node
    return MakeEqualSuccess()
end

function make_equal!(
    solver::Solver, 
    node::Union{RuleNode, AbstractHole},
    domainrulenode::DomainRuleNode,
    vars::Dict{Symbol, AbstractRuleNode}
)::MakeEqualResult
    softfailed = false 
    if isfilled(node)
        #(RuleNode, DomainRuleNode)
        if !domainrulenode.domain[get_rule(node)]
            set_infeasible!(solver)
            return MakeEqualHardFail()
        end
    else
        #(AbstractHole, DomainRuleNode)
        rules = get_intersection(node.domain, domainrulenode.domain)
        if length(rules) == 0
            return MakeEqualHardFail()
        elseif length(rules) == 1
            path = get_path(solver, node)
            remove_all_but!(solver, path, rules[1])
            node = get_node_at_location(solver, path)
        else
            softfailed = true
        end
    end

    for (child1, child2) ∈ zip(get_children(node), get_children(domainrulenode))
        result = make_equal!(solver, child1, child2, vars)
        @match result begin
            ::MakeEqualSuccess => ();
            ::MakeEqualHardFail => return result;
            ::MakeEqualSoftFail => begin
                softfailed = true
            end
        end
    end
    return softfailed ? MakeEqualSoftFail() : MakeEqualSuccess()
end
