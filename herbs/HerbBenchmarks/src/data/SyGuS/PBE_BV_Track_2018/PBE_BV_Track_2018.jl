module PBE_BV_Track_2018
using HerbCore
using HerbSpecification
using HerbGrammar
using HerbInterpret

using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

include("data.jl")
include("grammars.jl")

include("bit_functions.jl")

function make_bv_interpreter(g)
    return make_interpreter(g; target_module=PBE_BV_Track_2018, cache_module=PBE_BV_Track_2018)
end

function format_bit_operations_grammars(filename::AbstractString)
    lines::Vector{String} = []
    file = open(filename, "r")

    for line in eachline(file)
        if !isempty(line) && occursin(" = ", line)
            split_line = split(line, " = ")

            # Check for grammar definition
            if occursin("@cfgrammar", split_line[2])
                line = replace(line, "-" => "_")
            else
                if startswith(split_line[2], 'x')
                    line = "$(split_line[1]) = _arg_1"
                end
                if startswith(split_line[2], '(')
                    symbol_list = split(split_line[2][2:end-1], ' ')
                    func = replace(symbol_list[1],
                        "bvneg" => "bvneg_cvc",
                        "bvnot" => "bvnot_cvc",
                        "bvadd" => "bvadd_cvc",
                        "bvsub" => "bvsub_cvc",
                        "bvxor" => "bvxor_cvc",
                        "bvand" => "bvand_cvc",
                        "bvor" => "bvor_cvc",
                        "bvshl" => "bvshl_cvc",
                        "bvlshr" => "bvlshr_cvc",
                        "bvashr" => "bvashr_cvc",
                        "bvnand" => "bvnand_cvc",
                        "bvnor" => "bvnor_cvc",
                        "ehad" => "ehad_cvc",
                        "arba" => "arba_cvc",
                        "shesh" => "shesh_cvc",
                        "smol" => "bvnor_cvc",
                        "im" => "im_cvc",
                    )

                    expr = func * "(" * join(symbol_list[2:end], ", ") * ")"

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

end # module PBE_BV_Track_2018
