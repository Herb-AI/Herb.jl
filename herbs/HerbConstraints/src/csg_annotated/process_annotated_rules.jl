function _process_expression(expression)::Tuple{
        ContextSensitiveGrammar, 
        Dict{String,Vector{Int}},
        Dict{Int,Vector{Any}},
        }
    grammar = ContextSensitiveGrammar()
    bylabel = Dict{String,Vector{Int}}()
    rule_annotations = Dict{Int,Vector{Any}}()

    expr = deepcopy(expression)
    Base.remove_linenums!(expr)
    for e in expr.args
        label, annotations, rule_lhs, rule_rhs = @match e begin
            :($lhs = $rhs) => begin
                label, rule_lhs = _get_label(lhs)
                annotations, rule_rhs = _get_annotations(rhs)
                label, annotations, rule_lhs, rule_rhs
            end
            _ => error("Expected rule definition of the form lhs = rhs, got: $e (rule $(length(grammar.rules)+1))")
        end

        numrules_before = length(grammar.rules)
        add_rule!(grammar, :($rule_lhs = $rule_rhs))
        numrules_after = length(grammar.rules)
        new_rules = collect(numrules_before+1:numrules_after)

        if !isnothing(label)
            if label ∈ keys(bylabel)
                error("Label $label used for multiple rules!")
            end
            bylabel[label] = new_rules
        end

        for rule in new_rules
            rule_annotations[rule] = annotations
        end
    end
    return grammar, bylabel, rule_annotations
end

# gets the label from an expression
function _get_label(lhs) #::Tuple{Union{String, Nothing}, Any}
    @match lhs begin
        :($label_name :: $rule_lhs) => return string(label_name), rule_lhs
        _ => return nothing, lhs
    end
end

# gets the annotation from an expression
function _get_annotations(rhs) #::Tuple{Vector{Any}, Any}
    @match rhs begin
        :($rule_rhs := ($(annotations...),)) => return [annotations...], rule_rhs
        :($rule_rhs := $annotations) => return [annotations], rule_rhs
        _ => return [], rhs
    end
end

function _annotation2constraints!(
    annotated_grammar::AnnotatedGrammar,
    rule_index::Int,
    annotation::Any,
)
    @match annotation begin
        Expr(:call, name_, arg_) => begin
            annotation_name = name_
            label_index = only(get_bylabel(annotated_grammar)[String(arg_)])
            @match annotation_name begin
                :identity => _identity_constraints!(annotated_grammar, rule_index, label_index)
                :annihilator => _annihilator_constraints!(annotated_grammar, rule_index, label_index)
                :inverse => _inverse_constraints!(annotated_grammar, rule_index, label_index)
                :distributive_over => _distributive_over_constraints!(annotated_grammar, rule_index, label_index)
                :absorptive_over => _absorptive_over_constraints!(annotated_grammar, rule_index, label_index)
                _ => throw(ArgumentError("Annotation call $(annotation) not found! (rule $(rule_index))")) 
            end
        end
        :commutative => _commutative_constraints!(annotated_grammar, rule_index)
        :associative => _associativity_constraints!(annotated_grammar, rule_index)
        :idempotent => _idempotent_constraints!(annotated_grammar, rule_index)
        _ => throw(ArgumentError("Annotation $(annotation) not found! (rule $(rule_index))"))
    end
end