module HerbTest

using HerbConstraints
using HerbCore
using HerbData
using HerbInterpret
using HerbGrammar
using HerbSearch

using Test
import Pkg

@testset verbose=false "Herb" begin
   @test 1==1 # dummy test
   println("\n--- HerbConstraints tests ---")
   Pkg.test("HerbConstraints")
   println("\n--- HerbCore tests ---")
   Pkg.test("HerbCore")
   println("\n--- HerbData tests ---")
   Pkg.test("HerbData")
   println("\n--- HerbInterpret tests ---")
   Pkg.test("HerbInterpret")
   println("\n--- HerbGrammar tests ---")
   Pkg.test("HerbGrammar")
   println("\n--- HerbSearch tests ---")
   Pkg.test("HerbSearch")
end

end # module
