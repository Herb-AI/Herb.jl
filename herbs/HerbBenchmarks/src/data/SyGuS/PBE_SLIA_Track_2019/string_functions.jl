using MLStyle
# CVC5 functions

## String typed
concat_cvc(str1::String, str2::String) = str1 * str2

replace_cvc(mainstr::String, to_replace::String, replace_with::String) = replace(mainstr, to_replace => replace_with)

at_cvc(str::String, index::Int) = string(str[index])

int_to_str_cvc(n::Int) = "$n"

substr_cvc(str::String, start_index::Int, end_index::Int) = str[start_index:end_index]

# Int typed
len_cvc(str::String) = length(str)

str_to_int_cvc(str::String) = parse(Int64, str)

indexof_cvc(str::String, substring::String, index::Int) = (n = findfirst(substring, str); n == nothing ? -1 : (n[1] >= index ? n[1] : -1))

# Bool typed
prefixof_cvc(prefix::String, str::String) = startswith(str, prefix)

suffixof_cvc(suffix::String, str::String) = endswith(str, suffix)

contains_cvc(str::String, contained::String) = contains(str, contained)

lt_cvc(str1::String, str2::String) = cmp(str1, str2) < 0

leq_cvc(str1::String, str2::String) = cmp(str1, str2) <= 0

isdigit_cvc(str::String) = tryparse(Int, str) !== nothing

"""
Gets the relevant symbol to easily match grammar rules to operations in `interpret` function
"""
function get_relevant_tags(grammar::ContextSensitiveGrammar)
        tags = Dict{Int,Any}()
        for (ind, r) in pairs(grammar.rules)
                tags[ind] = if typeof(r) != Expr
                        r
                else
                        @match r.head begin
                                :block => :OpSeq
                                :call => r.args[1]
                                :if => :IF
                        end
                end
        end
        return tags
end

function interpret_sygus(prog::AbstractRuleNode, grammar_tags::Dict{Int,Any})
    r = get_rule(prog)
    c = get_children(prog)

    MLStyle.@match grammar_tags[r] begin
        :concat_cvc => concat_cvc(interpret_sygus(c[1], grammar_tags), interpret_sygus(c[2], grammar_tags))
        :replace_cvc => replace_cvc(interpret_sygus(c[1], grammar_tags), interpret_sygus(c[2], grammar_tags), interpret_sygus(c[3], grammar_tags))
        :at_cvc => at_cvc(interpret_sygus(c[1], grammar_tags), interpret_sygus(c[2], grammar_tags))
        :int_to_str_cvc => int_to_str_cvc(interpret_sygus(c[1], grammar_tags))
        :substr_cvc => substr_cvc(interpret_sygus(c[1], grammar_tags), interpret_sygus(c[2], grammar_tags), interpret_sygus(c[3], grammar_tags))
        :len_cvc => len_cvc(interpret_sygus(c[1], grammar_tags))
        :str_to_int_cvc => str_to_int_cvc(interpret_sygus(c[1], grammar_tags))
        :indexof_cvc => indexof_cvc(interpret_sygus(c[1], grammar_tags), interpret_sygus(c[2], grammar_tags), interpret_sygus(c[3], grammar_tags))
        :prefixof_cvc => prefixof_cvc(interpret_sygus(c[1], grammar_tags), interpret_sygus(c[2], grammar_tags))
        :suffixof_cvc => suffixof_cvc(interpret_sygus(c[1], grammar_tags), interpret_sygus(c[2], grammar_tags))
        :contains_cvc => contains_cvc(interpret_sygus(c[1], grammar_tags), interpret_sygus(c[2], grammar_tags))

        :+ => interpret_sygus(c[1], grammar_tags) + interpret_sygus(c[2], grammar_tags)
        :- => interpret_sygus(c[1], grammar_tags) - interpret_sygus(c[2], grammar_tags)
        :(==) => interpret_sygus(c[1], grammar_tags) == interpret_sygus(c[2], grammar_tags)

        :IF => interpret_sygus(c[1], grammar_tags) ? interpret_sygus(c[2], grammar_tags) : interpret_sygus(c[3], grammar_tags)

        _ => grammar_tags[r]
    end
end
