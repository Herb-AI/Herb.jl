module HerbTest

using HerbConstraints
using HerbCore
using HerbInterpret
using HerbGrammar
using HerbSearch
using HerbSpecification

using Test
using Pkg

@testset verbose=false "Herb" begin
   @test 1==1 # dummy test
   println("\n--- HerbConstraints tests ---")
   Pkg.test("HerbConstraints")
   println("\n--- HerbCore tests ---")
   Pkg.test("HerbCore")
   println("\n--- HerbInterpret tests ---")
   Pkg.test("HerbInterpret")
   println("\n--- HerbGrammar tests ---")
   Pkg.test("HerbGrammar")
   println("\n--- HerbSearch tests ---")
   Pkg.test("HerbSearch")
   println("\n--- HerbSpecification tests ---")
   Pkg.test("HerbSpecification")
end

end # module
