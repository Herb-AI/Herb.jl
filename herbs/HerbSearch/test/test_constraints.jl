using HerbCore, HerbGrammar, HerbConstraints

@testset verbose=true "Constraints" begin

    function new_grammar()
        grammar = @csgrammar begin
            Int = 1
            Int = x
            Int = -Int
            Int = Int + Int
            Int = Int * Int
        end
        clearconstraints!(grammar)
        return grammar
    end

    contains_subtree = ContainsSubtree(RuleNode(4, [
        RuleNode(1),
        RuleNode(1)
    ]))

    contains_subtree2 = ContainsSubtree(RuleNode(4, [
        RuleNode(4, [
            VarNode(:a),
            RuleNode(2)
        ]),
        VarNode(:a)
    ]))

    contains = Contains(2)

    forbidden_sequence = ForbiddenSequence([4, 5])

    forbidden_sequence2 = ForbiddenSequence([4, 5], ignore_if=[3])

    forbidden_sequence3 = ForbiddenSequence([4, 1], ignore_if=[5])

    forbidden = Forbidden(RuleNode(3, [RuleNode(3, [VarNode(:a)])]))

    forbidden2 = Forbidden(RuleNode(4, [
        VarNode(:a),
        VarNode(:a)
    ]))

    ordered = Ordered(RuleNode(5, [
        VarNode(:a),
        VarNode(:b)
    ]), [:a, :b])

    unique = Unique(2)

    @testset "fix_point_running related bug" begin
        # post contains_subtree2
        # propagate contains_subtree2
        #     schedule forbidden2
        # propagate forbidden2

        grammar = new_grammar()
        addconstraint!(grammar, contains_subtree)
        addconstraint!(grammar, contains_subtree2)
        addconstraint!(grammar, forbidden2)

        partial_program = UniformHole(BitVector((0, 0, 0, 1, 1)), [
            UniformHole(BitVector((0, 0, 0, 1, 1)), [
                UniformHole(BitVector((1, 1, 0, 0, 0)), []),
                UniformHole(BitVector((1, 1, 0, 0, 0)), [])
            ]),
            UniformHole(BitVector((0, 0, 0, 1, 1)), [
                UniformHole(BitVector((0, 0, 0, 1, 1)), [
                    UniformHole(BitVector((1, 1, 0, 0, 0)), []),
                    UniformHole(BitVector((1, 1, 0, 0, 0)), [])
                ])
                UniformHole(BitVector((1, 1, 0, 0, 0)), [])
            ])
        ])

        iterator = BFSIterator(grammar, partial_program, max_size=9) 
        @test length(iterator) == 0
    end

    all_constraints = [
        ("ContainsSubtree", contains_subtree),
        ("ContainsSubtree2", contains_subtree2),
        ("Contains", contains),
        ("ForbiddenSequence", forbidden_sequence),
        ("ForbiddenSequence2", forbidden_sequence2),
        ("ForbiddenSequence3", forbidden_sequence3),
        ("Forbidden", forbidden),
        ("Forbidden2", forbidden2),
        ("Ordered", ordered),
        ("Unique", unique)
    ]

    @testset "1 constraint" begin
        # test all constraints individually, the constraints are chosen to prune the program space non-trivially
        @testset "$name" for (name, constraint) ∈ all_constraints
            test_constraint!(new_grammar(), constraint, max_size=6, allow_trivial=false)
        end
    end

    @testset "$n constraints" for n ∈ 2:5
        # test constraint interactions by randomly sampling constraints
        for _ ∈ 1:10
            indices = randperm(length(all_constraints))[1:n]
            names = [name for (name, _) ∈ all_constraints[indices]]
            constraints = [constraint for (_, constraint) ∈ all_constraints[indices]]
            
            @testset "$names" begin
                test_constraints!(new_grammar(), constraints, max_size=6, allow_trivial=true)
            end
        end
    end

    @testset "all constraints" begin
        # all constraints combined, no valid solution exists
        grammar = new_grammar()
        for (_, constraint) ∈ all_constraints
            addconstraint!(grammar, constraint)
        end
        iter = BFSIterator(grammar, :Int, max_size=10)
        @test length(iter) == 0
    end
end
