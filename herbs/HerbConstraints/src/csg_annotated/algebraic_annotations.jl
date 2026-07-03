## Defined by https://en.wikipedia.org/wiki/Algebraic_structure

## Ideas for future annotations
# - minus multiplication relationship (cancellation?
# - minus over plus (unary distributive_over) - propogare down?
# - allow location based labels

function _identity_constraints!(
    annotated_grammar::AnnotatedGrammar,
    rule_index::Int,
    label_index::Int,
)
    num_label_children = length(get_grammar(annotated_grammar).childtypes[label_index])
    label_children = [VarNode(Symbol("y_$(i)")) for i in 1:num_label_children]
    label_node = RuleNode(label_index, label_children)

    num_rule_children = length(get_grammar(annotated_grammar).childtypes[rule_index])
    rule_non_label_children = [VarNode(Symbol("x_$(i)")) for i in 1:num_rule_children-1]
    for i in 1:num_rule_children
        rule_children = Vector{AbstractRuleNode}(copy(rule_non_label_children))
        insert!(rule_children, i,label_node)
        addconstraint!(annotated_grammar,
            Forbidden(RuleNode(rule_index, rule_children))
        )
    end
end

function _annihilator_constraints!(
    annotated_grammar::AnnotatedGrammar,
    rule_index::Int,
    label_index::Int,
)
    addconstraint!(annotated_grammar,
        Forbidden(RuleNode(rule_index, [VarNode(:x), RuleNode(label_index)]))
    )
    addconstraint!(annotated_grammar,
        Forbidden(RuleNode(rule_index, [RuleNode(label_index), VarNode(:x)]))
    )
end

function _commutative_constraints!(
    annotated_grammar::AnnotatedGrammar,
    rule_index::Int,
)
    #TODO: preformance wise, add one domain constraint for all commutative rules
    addconstraint!(annotated_grammar,
        Ordered(
        RuleNode(rule_index, [VarNode(:x), VarNode(:y)]),
        [:x, :y],
        )
    ) 
end

function _associativity_constraints!(
    annotated_grammar::AnnotatedGrammar,
    rule_index::Int,
)
    if :commutative ∈ get_rule_annotations(annotated_grammar)[rule_index]
        # allow only to repeat the operation in a path formation with ordered operands
        #   * will lean right while smaller then the rule, and then left
        addconstraint!(annotated_grammar, 
            Forbidden(RuleNode(rule_index, [
                RuleNode(rule_index, [VarNode(:a), VarNode(:b)]),
                RuleNode(rule_index, [VarNode(:c), VarNode(:d)])
            ]))
            )
        child = RuleNode(rule_index, [VarNode(:x), VarNode(:y)])
        addconstraint!(annotated_grammar, 
            Ordered(
                RuleNode(rule_index, [VarNode(:w), child]),
                [:w, :x],
            ))
        addconstraint!(annotated_grammar, 
            Ordered(
                RuleNode(rule_index, [child, VarNode(:w)]),
                [:y, :w],
            ))
        if :idempotent ∈get_rule_annotations(annotated_grammar)[rule_index]
            addconstraint!(annotated_grammar, 
                Forbidden(RuleNode(rule_index, [VarNode(:x), child]))
                )
            addconstraint!(annotated_grammar, 
                Forbidden(RuleNode(rule_index, [child, VarNode(:y)]))
                )
        end
        # TODO: combine to one constraint when we allow constraints on VarNodes
        num_children = length.(get_grammar(annotated_grammar).childtypes)
        for n in Set(num_children[1:rule_index-1])
            dom = BitVector([i<rule_index && n == num_children[i] for i in 1:length(get_grammar(annotated_grammar).rules)])
            addconstraint!(annotated_grammar, 
                Forbidden(RuleNode(rule_index, [
                    RuleNode(rule_index, [
                        DomainRuleNode(dom, [VarNode(Symbol("var_$(i)")) for i in 1:n]),
                        VarNode(:y)
                    ]),
                    VarNode(:w)
                ]))
                )
        end
        # TODO: if we also have an unary inverse, make the inverse invisible to the ordering
    else
        # allow only to repeat the operation in a left leaning path formation
        child = RuleNode(rule_index, [VarNode(:a), VarNode(:b)])
        addconstraint!(annotated_grammar, 
            Forbidden(RuleNode(rule_index, [VarNode(:c), child]))
            )
        if :idempotent ∈get_rule_annotations(annotated_grammar)[rule_index]
            addconstraint!(annotated_grammar, 
                Forbidden(RuleNode(rule_index, [child, VarNode(:b)]))
                )
        end
    end
end

function _distributive_over_constraints!(
    annotated_grammar::AnnotatedGrammar,
    rule_index::Int,
    label_index::Int,
)
    rulenode_ax = RuleNode(rule_index, [VarNode(:a), VarNode(:x)])
    rulenode_bx = RuleNode(rule_index, [VarNode(:b), VarNode(:x)])
    rulenode_xa = RuleNode(rule_index, [VarNode(:x), VarNode(:a)])
    rulenode_xb = RuleNode(rule_index, [VarNode(:x), VarNode(:b)])

    addconstraint!(annotated_grammar,
        Forbidden(RuleNode(label_index, [rulenode_ax, rulenode_bx]))
    )
    addconstraint!(annotated_grammar,
        Forbidden(RuleNode(label_index, [rulenode_xa, rulenode_xb]))
    )
    if :commutative ∈ get_rule_annotations(annotated_grammar)[rule_index]
        addconstraint!(annotated_grammar,
            Forbidden(RuleNode(label_index, [rulenode_ax, rulenode_xb]))
        )
        addconstraint!(annotated_grammar,
            Forbidden(RuleNode(label_index, [rulenode_xa, rulenode_bx]))
        )
    end
    # TODO: we should add this only if the 2(*identity) is in the grammar
    # if :identity ∈ get_rule_annotations(annotated_grammar)[rule_index]
    #     addconstraint!(annotated_grammar,
    #         Forbidden(RuleNode(label_index, [VarNode(:x), VarNode(:x)]))
    #     )
    # end
end

function _absorptive_over_constraints!(
    annotated_grammar::AnnotatedGrammar,
    rule_index::Int,
    label_index::Int,
)
    rulenode_xy = RuleNode(label_index, [VarNode(:x), VarNode(:y)])
    rulenode_yx = RuleNode(label_index, [VarNode(:y), VarNode(:x)])

    addconstraint!(annotated_grammar,
        Forbidden(RuleNode(rule_index, [rulenode_xy, VarNode(:x)]))
    )
    addconstraint!(annotated_grammar,
        Forbidden(RuleNode(rule_index, [rulenode_yx, VarNode(:x)]))
    )
    
    addconstraint!(annotated_grammar,
        Forbidden(RuleNode(rule_index, [VarNode(:x), rulenode_xy]))
    )
    addconstraint!(annotated_grammar,
        Forbidden(RuleNode(rule_index, [VarNode(:x), rulenode_yx]))
    )
end

function _idempotent_constraints!(
    annotated_grammar::AnnotatedGrammar,
    rule_index::Int
)
    #TODO: preformance wise, add one domain constraint for all idempotent rules
    addconstraint!(annotated_grammar,
        Forbidden(RuleNode(rule_index, [VarNode(:x), VarNode(:x)]))
    )
end

function _inverse_constraints!(
    annotated_grammar::AnnotatedGrammar,
    rule_index::Int,
    label_index::Int,
)
    addconstraint!(annotated_grammar,
        Forbidden(RuleNode(rule_index, [RuleNode(label_index, [VarNode(:x)]), VarNode(:x)]))
    )
    addconstraint!(annotated_grammar,
        Forbidden(RuleNode(rule_index, [VarNode(:x), RuleNode(label_index, [VarNode(:x)])]))
    )
    #TODO: make sure this always holds (mathematically, by definition)
    addconstraint!(annotated_grammar,
        Forbidden(RuleNode(label_index, [RuleNode(label_index, [VarNode(:a)])]))
    )
    # TODO: if has identity, add constraint for inverse of identity
    # TODO: if associative, any hierarchy of rule of :x and inverse(:x) is forbidden
end
