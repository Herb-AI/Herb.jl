import DocStringExtensions: Abbreviation

"""
Custom docstring abbreviation that rewrites `julia,jldoctest` code blocks to
`jldoctest`. This means that the README still highlights the code as Julia code
(because the "language" in the README code blocks starts with `julia`), while
`Documenter` still picks up the doctest from the docstring that is inserted
into the module's docstring (because the "language" of the code block is
rewritten to be just `jldoctest`).
"""
struct TestableReadme <: Abbreviation end

const TESTABLEREADME = TestableReadme()

function DocStringExtensions.format(::TestableReadme, buf, doc)
    @show
    m = get(doc.data, :module, nothing)
    m === nothing && return
    path = pathof(m)
    path === nothing && return
    try # wrap in try/catch since we shouldn't error in case some IO operation goes wrong
        r = r"(?i)readme(?-i)"
        # assume README/LICENSE is located in the root of the repo
        root = normpath(joinpath(path, "..", ".."))
        for file in readdir(root)
            if occursin(r, file)
                str = read(joinpath(root, file), String)
                str = replace(str, "```julia,jldoctest" => "```jldoctest")
                write(buf, str)
                return
            end
        end
    catch
    end
end
