"""
    mutate_random!(program::RuleNode, grammar::AbstractGrammar, max_depth::Int64 = 2)

Mutates the given program by inserting a randomly generated sub-program at a random location.
"""
function mutate_random!(program::RuleNode, grammar::AbstractGrammar, max_depth::Int64 = 2)
    node_location::NodeLoc = sample(NodeLoc, program)
    subprogram = get(program, node_location)
    symbol = return_type(grammar, subprogram)

    random_program = rand(RuleNode, grammar, symbol,  max_depth)
    insert!(program, node_location, random_program)
end

