"""
	ForbiddenSequence <: AbstractGrammarConstraint

This [`AbstractGrammarConstraint`] forbids the given `sequence` of rule nodes.
Sequences are strictly vertical and may include gaps. Consider the tree `1{a, 2{b, 3{c, d}}}`:
- `[2, 3, d]` is a sequence
- `[1, 3, d]` is a sequence
- `[3, c, d]` is not a sequence since c and d are siblings (horizontal)

Examples:
- `ForbiddenSequence([3, 4])` enforces that rule `4` cannot be applied at `c` or `d`.
- `ForbiddenSequence([1, 2, 4])` enforces that rule `4` cannot be applied at `b`, `c` or `d`.
- `ForbiddenSequence([1, 4])` enforces that rule `4` cannot be applied anywhere.

If any of the rules in `ignore_if` appears in the sequence, the constraint is ignored.
Suppose the forbidden `sequence = [1, 2, 3]` and `ignore_if = [99]`
Consider the following paths from the root:
- `[1, 2, 2, 3]` is forbidden, as the sequence does not contain `99`
- `[1, 99, 2, 3]` is NOT forbidden, as the sequence does contain `99`
- `[1, 99, 1, 2, 3]` is forbidden, as there is a subsequence that does not contain `99`
"""
struct ForbiddenSequence <: AbstractGrammarConstraint
    sequence::Vector{Int}
    ignore_if::Vector{Int}
end

ForbiddenSequence(sequence::Vector{Int}; ignore_if=Vector{Int}()) =
    ForbiddenSequence(sequence, ignore_if)

function on_new_node(solver::Solver, c::ForbiddenSequence, path::Vector{Int})
    #minor optimization: prevent the first hardfail (https://github.com/orgs/Herb-AI/projects/6/views/1?pane=issue&itemId=55570518)
    @match get_node_at_location(solver, path) begin
        hole::AbstractHole => if !hole.domain[c.sequence[end]]
            return
        end
        node::RuleNode => if node.ind != c.sequence[end]
            return
        end
    end
    post!(solver, LocalForbiddenSequence(path, c.sequence, c.ignore_if))
end

"""
	check_tree(c::ForbiddenSequence, tree::AbstractRuleNode; sequence_started=false)::Bool

Checks if the given [`AbstractRuleNode`](@ref) tree abides the [`ForbiddenSequence`](@ref) constraint.
"""
function check_tree(c::ForbiddenSequence, tree::AbstractRuleNode; sequence_started=false)::Bool
    @assert isfilled(tree) "check_tree does not support checking trees that contain holes. $(tree) is a hole."

    # attempt to start the sequence on the any node in the tree
    if !sequence_started
        for child ∈ tree.children
            if !check_tree(c, child, sequence_started=false)
                return false
            end
        end
    end

    # add the current node to the current sequence if possible
    if (get_rule(tree) == c.sequence[1])
        remaining_sequence = c.sequence[2:end]
        sequence_started = true
    else
        remaining_sequence = c.sequence
    end

    # the empty sequence is in any tree, so the constraint is violated
    if isempty(remaining_sequence)
        return false
    end

    if sequence_started
        # the sequence contains one of the `ignore_if` rules, and therefore is satisfied
        if get_rule(tree) ∈ c.ignore_if
            return true
        end

        # continue the current sequence
        smaller_constraint = ForbiddenSequence(remaining_sequence, c.ignore_if)
        for child ∈ tree.children
            if !check_tree(smaller_constraint, child, sequence_started=true)
                return false
            end
        end
    end
    return true
end

"""
	update_rule_indices!(c::ForbiddenSequence, n_rules::Integer)

Updates a `ForbiddenSequence` constraint to reflect grammar changes. Errors if rule indices exceeds `n_rules`.

# Arguments
- `c`: The `ForbiddenSequence` constraint to be updated
- `n_rules`: The new number of rules in the grammar
"""
function HerbCore.update_rule_indices!(c::ForbiddenSequence, n_rules::Integer)
    if any(i -> i > n_rules, c.sequence) || any(i -> i > n_rules, c.ignore_if)
        error("Rule index exceeds the number of grammar rules ($n_rules).")
    end
    # no update required
end

"""
	update_rule_indices!(c::ForbiddenSequence, grammar::AbstractGrammar)

Updates a `ForbiddenSequence` constraint to reflect grammar changes. Errors if rule indices exceeds number of grammar rules.
# Arguments
- `c`: The `ForbiddenSequence` constraint to be updated
- `grammar`: The grammar that changed
"""
function HerbCore.update_rule_indices!(c::ForbiddenSequence, grammar::AbstractGrammar)
    HerbCore.update_rule_indices!(c, length(grammar.rules))
end

"""
	update_rule_indices!(c::ForbiddenSequence, n_rules::Integer, mapping::AbstractDict{<:Integer, <:Integer}, ::Vector{<:AbstractConstraint})

Updates the rule indices in a `ForbiddenSequence` constraint by applying the given mapping to both the `sequence` and `ignore_if` fields.
Errors if rule indices exceeds number of grammar rules.

# Arguments
- `c`: The `ForbiddenSequence` constraint to be updated
- `n_rules`: The new number of rules in the grammar  
- `mapping`: Dictionary mapping old rule indices to new rule indices
"""
function HerbCore.update_rule_indices!(
    c::ForbiddenSequence, n_rules::Integer,
    mapping::AbstractDict{<:Integer,<:Integer},
    ::Vector{<:AbstractConstraint}
)
    if any(i -> i > n_rules, c.sequence) || any(i -> i > n_rules, c.ignore_if)
        error("Rule index $(i) exceeds the number of grammar rules ($n_rules).")
    end
    c.sequence .= get.(Ref(mapping), c.sequence, c.sequence) # keep rule index if no matching entry found in mapping
    c.ignore_if .= get.(Ref(mapping), c.ignore_if, c.ignore_if)
    return c
end

"""
	update_rule_indices!(c::ForbiddenSequence, grammar::AbstractGrammar, mapping::AbstractDict{<:Integer, <:Integer})

Updates the rule indices in a `ForbiddenSequence` constraint by applying the given mapping to both the `sequence` and `ignore_if` fields.
Errors if rule indices exceeds number of grammar rules.
# Arguments
- `c`: The `ForbiddenSequence` constraint to be updated
- `grammar`: The grammar that changed
- `mapping`: Dictionary mapping old rule indices to new rule indices
"""
function HerbCore.update_rule_indices!(
    c::ForbiddenSequence,
    grammar::AbstractGrammar,
    mapping::AbstractDict{<:Integer,<:Integer},
)
    HerbCore.update_rule_indices!(c, length(grammar.rules), mapping, grammar.constraints)
end

HerbCore.is_domain_valid(c::ForbiddenSequence, n_rules::Integer) = all(i -> i <= n_rules, c.sequence) && all(i -> i <= n_rules, c.ignore_if)
HerbCore.is_domain_valid(c::ForbiddenSequence, grammar::ContextSensitiveGrammar) = HerbCore.is_domain_valid(c, length(grammar.rules))

Base.:(==)(c1::ForbiddenSequence, c2::ForbiddenSequence) = (c1.sequence == c2.sequence) && (c1.ignore_if == c2.ignore_if)

function HerbGrammar.is_constraint_valid(c::ForbiddenSequence, grammar::AbstractGrammar; allow_empty_children::Bool)
    n_rules = length(grammar.rules)
    all(1 <= x <= n_rules for x in c.ignore_if) || return false
    function _search_helper(cur::Int, target::Int, grammar::AbstractGrammar)

        target_type = grammar.types[target]
        visited = falses(n_rules)
        queue = Int[cur]
        visited[cur] = true
        head = 1

        while head <= length(queue)
            rid = queue[head]
            head += 1

            rid_children = grammar.childtypes[rid]
            if target_type in rid_children
                return true
            end

            for next_type in rid_children
                for next_rid in findall(==(next_type), grammar.types)
                    if !visited[next_rid]
                        visited[next_rid] = true
                        push!(queue, next_rid)
                    end
                end
            end
        end

        return false
    end
    sequence = c.sequence
    rid = first(sequence)
    for next_rid in sequence[2:end]
        1 <= rid && rid <= n_rules || return false
        _search_helper(rid, next_rid, grammar) || return false
        rid = next_rid
    end
    return true
end