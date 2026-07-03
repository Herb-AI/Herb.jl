"""
    crossover_swap_children_2(parent_1::RuleNode, parent_2::RuleNode)

Performs a random crossover of two parents of type [`RuleNode`](@ref). The subprograms are swapped and both altered parent programs are returned.
"""
function crossover_swap_children_2(parent_1::RuleNode, parent_2::RuleNode)
    copyparent_1 = deepcopy(parent_1)
    copyparent_2 = deepcopy(parent_2)
    
    node_location1::NodeLoc = sample(NodeLoc, copyparent_1)
    node_location2::NodeLoc = sample(NodeLoc, copyparent_2)
    subprogram1 = get(copyparent_1, node_location1)
    subprogram2 = get(copyparent_2, node_location2)
    
    if node_location1.i != 0
        insert!(copyparent_1, node_location1, subprogram2)
    else
        copyparent_1 = subprogram2
    end
    if node_location2.i != 0
        insert!(copyparent_2, node_location2, subprogram1)
    else 
        copyparent_2 = subprogram1
    end
    return (copyparent_1,copyparent_2)
end

"""
    crossover_swap_children_1(parent_1::RuleNode, parent_2::RuleNode)

Performs a random crossover of two parents of type [`RuleNode`](@ref). The subprograms are swapped and only one altered parent program is returned.
"""
function crossover_swap_children_1(parent_1::RuleNode, parent_2::RuleNode)
    copyparent_1 = deepcopy(parent_1)
    copyparent_2 = deepcopy(parent_2)
    
    node_location1::NodeLoc = sample(NodeLoc, copyparent_1)
    node_location2::NodeLoc = sample(NodeLoc, copyparent_2)
    subprogram1 = get(copyparent_1, node_location1)                                  
    subprogram2 = get(copyparent_2, node_location2)

    if rand() <= 0.5
        if node_location1.i != 0
            insert!(copyparent_1, node_location1, subprogram2)
        else
            copyparent_1 = subprogram2
        end
        return copyparent_1
    end
    if node_location2.i != 0
        insert!(copyparent_2, node_location2, subprogram1)
    else 
        copyparent_2 = subprogram1
    end

    return copyparent_2
end
