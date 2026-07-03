module PBE_SLIA_Track_2019
using HerbCore
using HerbSpecification
using HerbGrammar
using HerbInterpret

using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

include("data.jl")
include("grammars.jl")

include("string_functions.jl")

function make_SLIA_interpreter(g)
    return make_interpreter(
        g;
        target_module=PBE_SLIA_Track_2019,
        cache_module=PBE_SLIA_Track_2019
    )
end

export 
    format_string_grammars

function format_string_grammars(filename::AbstractString)
    lines::Vector{String} = []
    file = open(filename, "r")

    for line in eachline(file)
        if !isempty(line) && occursin(" = ", line)
            split_line = split(line, " = ")
            
            # Check for grammar definition
            if occursin("@cfgrammar", split_line[2])
                line = replace(line, "-" => "_") 
            elseif length(split_line) == 1 # check for empty right side
                line *= "\"\""
            else
                if (occursin("ntString", split_line[1]) 
                    && !startswith(split_line[2], '(') 
                    && !occursin('"', split_line[2])
                    && !occursin("_arg", split_line[2]))
                    line = "$(split_line[1]) = \"$(split_line[2])\""
                end
                if startswith(split_line[2], '(') 
                    symbol_list = split(split_line[2][2:end-1], ' ')
                    func = replace(symbol_list[1],
                         "str.++" => "concat_cvc",
                         "str.replace" => "replace_cvc",
                         "str.at" => "at_cvc",
                         "int.to.str" => "int_to_str_cvc",
                         "str.substr" => "substr_cvc",
                         "str.len" => "len_cvc",
                         "str.to.int" => "str_to_int_cvc",
                         "str.indexof" => "indexof_cvc",
                         "str.prefixof" => "prefixof_cvc",
                         "str.suffixof" => "suffixof_cvc",
                         "str.contains" => "contains_cvc",
                         "str.<" => "lt_cvc",
                         "str.<=" => "leq_cvc",
                         "str.isdigit" => "isdigit_cvc",
                         )
                    if func ∈ ["=", "+", "-"]
                        func = func == "=" ? "==" : func
                        expr = symbol_list[2] * " $(func) " * symbol_list[3]  
                    elseif func == "ite"
                        expr = "$(symbol_list[2]) ? $(symbol_list[3]) : $(symbol_list[4])"
                    else
                        expr = func * "(" * join(symbol_list[2:end], ", ") * ")" 
                    end
                    line = "$(split_line[1]) = $(expr)"
                end
           end
        end
        push!(lines, line)
    end
    close(file)

    file = open(filename, "w")
    for line in lines
        println(file, line)
    end
    close(file)
end

end # module PBE_SLIA_Track_2019
