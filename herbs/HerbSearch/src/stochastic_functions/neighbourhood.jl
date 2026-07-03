"""
A neighbourhood function returns a tuple of two elements: 
- the node location of the neighbourhood 
- the dictionary with additional properties of the neighbourhood.
"""



"""
    constructNeighbourhood(current_program::RuleNode, grammar::AbstractGrammar)

The neighbourhood node location is chosen at random.
The dictionary is nothing.
# Arguments
- `current_program::RuleNode`: the current program.
- `grammar::AbstractGrammar`: the grammar.
"""
function constructNeighbourhood(current_program::RuleNode, grammar::AbstractGrammar)
    # get a random position in the tree (parent,child index)
    node_location::NodeLoc = sample(NodeLoc, current_program)
    return node_location, nothing
end

"""
    constructNeighbourhoodRuleSubset(current_program::RuleNode, grammar::AbstractGrammar)
The neighbourhood node location is chosen at random.
The dictionary is contains one entry with key "rule_subset" and value of type Vector{Any} being a random subset of grammar rules.
# Arguments
- `current_program::RuleNode`: the current program.
- `grammar::AbstractGrammar`: the grammar.
"""
function constructNeighbourhoodRuleSubset(current_program::RuleNode, grammar::AbstractGrammar)
    # get a random position in the tree (parent,child index)
    node_location::NodeLoc = sample(NodeLoc, current_program)
    rule_subset_size = rand((1, length(grammar.rules)))
    rule_subset = sample(collect(grammar.rules), rule_subset_size, replace=false)
    dict = Dict(:rule_subset => rule_subset)
    return node_location, dict
end
