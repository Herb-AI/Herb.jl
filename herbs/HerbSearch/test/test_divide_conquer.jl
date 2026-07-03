DivideAndConquerExt = Base.get_extension(HerbSearch, :DivideAndConquerExt)
using .DivideAndConquerExt:
	divide, decide, conquer, get_labels, get_predicates, get_features, construct_final_program

# using DecisionTree: Leaf, Node

@testset verbose = true "Search procedure divide and conquer" begin
	@testset verbose = true "divide, stopping criteria" begin
		spec::Vector{IOExample} = [
			IOExample(Dict(:var1 => 1), 1),
			IOExample(Dict(:var1 => 2), 2),
			IOExample(Dict(:var1 => 3), 3),
		]
		problem = Problem(spec)
		subproblems = divide(problem)
		@test length(subproblems) == 3

		# Stopping criteria: stop search once we have a solution to each subproblem
		solutions = [RuleNode(3), RuleNode(4)]
		problems_to_solutions::Dict{Problem, Vector{Int}} = Dict(p => [] for p in subproblems)

		push!(problems_to_solutions[subproblems[1]], 1)
		@test all(!isempty, values(problems_to_solutions)) == false

		push!(problems_to_solutions[subproblems[1]], 2)
		push!(problems_to_solutions[subproblems[2]], 1)
		@test all(!isempty, values(problems_to_solutions)) == false

		push!(problems_to_solutions[subproblems[3]], 1)
		@test all(!isempty, values(problems_to_solutions)) == true

	end

	@testset verbose = true "decide" begin
		grammar = @csgrammar begin
			Number = |(1:2)
			Number = x
			Number = Number + Number
			Number = Number * Number
		end
		symboltable = grammar2symboltable(grammar)
		problem1 = Problem([IOExample(Dict(:x => 1), 3)])
		problem2 = Problem([IOExample(Dict(:x => 1), 4)])
		program = RuleNode(4, [RuleNode(3), RuleNode(2)])
		expr = rulenode2expr(program, grammar)
		@test decide(problem1, expr, symboltable) == true
		@test decide(problem2, expr, symboltable) == false
	end
	@testset verbose = true "conquer" begin
		grammar = @csgrammar begin
			Start = Integer
			Integer = Condition ? Integer : Integer
			Integer = 0
			Integer = 1
			Input = _arg_1
			Input = _arg_2
			Integer = Input
			Integer = Integer + Integer
			Condition = Integer <= Integer
			Condition = Condition && Condition
			Condition = !Condition
		end

		symboltable::SymbolTable = grammar2symboltable(grammar)

		subproblems = [
			Problem([IOExample(Dict(:_arg_1 => 1, :_arg_2 => 2), 2)]),
			Problem([IOExample(Dict(:_arg_1 => 3, :_arg_2 => 0), 3)]),
			Problem([IOExample(Dict(:_arg_1 => -3, :_arg_2 => 0), 0)]),
			Problem([IOExample(Dict(:_arg_1 => 1, :_arg_2 => 1), 1)]),
		]
		solutions = [
			RuleNode(6),
			RuleNode(3),
			RuleNode(2, [RuleNode(9, [RuleNode(3), RuleNode(5)]), RuleNode(5), RuleNode(3)]),
			RuleNode(8, [RuleNode(5), RuleNode(6)]),
			RuleNode(4),
		]
		problems_to_solutions = Dict(p => Vector{Int}() for p in subproblems)
		# problems_to_solutions::Dict{Problem, Vector{Int}} = Dict(p => [] for p in subproblems)
		push!(problems_to_solutions[subproblems[1]], 1)
		push!(problems_to_solutions[subproblems[2]], 2)
		push!(
			problems_to_solutions[subproblems[3]],
			3)
		push!(problems_to_solutions[subproblems[4]], 4)
		push!(problems_to_solutions[subproblems[4]], 5)
		# solution program for subproblems[3]
		# if 0 <= _arg_1
		#    _arg_1
		# else
		#    0
		# RuleNode(2, [RuleNode(9, [RuleNode(3), RuleNode(5)]), RuleNode(5), RuleNode(3)])

		# hardcoding for test purposes (we cannot predict order when converting problems_to_solutions to vec)
		ioexamples = [
			IOExample(Dict(:_arg_1 => 1, :_arg_2 => 2), 2),
			IOExample(Dict(:_arg_1 => 3, :_arg_2 => 0), 3),
			IOExample(Dict(:_arg_1 => -3, :_arg_2 => 0), 0),
			IOExample(Dict(:_arg_1 => 1, :_arg_2 => 1), 1),
		]
		solutions_idx = [[1], [2], [3], [4, 5]]

		# parameters
		sym_start = :Integer
		sym_bool = :Condition
		sym_constraint = :Input
		n_predicates = 100

		@testset verbose = true "conquer()" begin
			final_program = conquer(
				problems_to_solutions,
				solutions,
				grammar,
				n_predicates,
				sym_bool,
				sym_start,
				sym_constraint,
				symboltable,
			)
			@test typeof(final_program) == RuleNode
			expr = rulenode2expr(final_program, grammar)
			input_example = ioexamples[1].in
			expected_output = ioexamples[1].out
			output = execute_on_input(symboltable, expr, input_example)
			@test typeof(output) == typeof(expected_output)
			@test output == expected_output
		end

		@testset verbose = true "conquer related functionality" begin
			# convert expected labels to set => no guarantee of order in vec_problems_solutions
			@testset verbose = true "labels" begin
				expected_labels = Set([1, 2, 3, 4])
				labels = get_labels(solutions_idx)
				@test length(labels) == 4
				@test Set(labels) == expected_labels
			end

			@testset verbose = true "predicates" begin
				# use symbol for constraint
				predicates = get_predicates(grammar, sym_bool, sym_constraint, n_predicates)
				rules = grammar.bytype[sym_constraint]
				@test length(predicates) == n_predicates
				# pick a few random predicates and check if they contain rule we expect
				@test !isempty(rulesoftype(predicates[23], Set(rules)))
				@test !isempty(rulesoftype(predicates[99], Set(rules)))

				# use rule indices for clearconstraints
				predicates = get_predicates(grammar, sym_bool, rules, n_predicates)
				@test !isempty(rulesoftype(predicates[12], Set(rules)))
				@test !isempty(rulesoftype(predicates[71], Set(rules)))
			end

			@testset verbose = true "features" begin
				predicates = [
					RuleNode(9, [RuleNode(5), RuleNode(6)]),
					RuleNode(9, [RuleNode(6), RuleNode(5)]),
					RuleNode(
						10,
						[
							RuleNode(9, [RuleNode(5), RuleNode(6)]),
							RuleNode(9, [RuleNode(4), RuleNode(6)]),
						],
					),
				]

				expressions = [rulenode2expr(p, grammar) for p in predicates]
				expected_expressions =
					[:(_arg_1 <= _arg_2), :(_arg_2 <= _arg_1), :(_arg_1 <= _arg_2 && 1 <= _arg_2)]
				@test expressions == expected_expressions

				expected_features =
					BitArray([true false true; false true false; true false false; true true true])
				features = get_features(
					ioexamples,
					predicates, grammar, symboltable,
				)
				@test features == expected_features
				@test_throws HerbSearch.EvaluationError get_features(
					ioexamples,
					[RuleNode(11, [RuleNode(4)])], # ehad_cvc(_arg_1)
					grammar,
					symboltable,
					false,
				)
			end


		end
		@testset verbose = true "Construct final program" begin
			# Left: Feature == false, right: Feature == true
			#             Feature 1 < 0.5 
			#              /      \\
			#   Feature 2 < 0.5      "1 - x"
			#     /        \\
			#   3-x"       "2-x"
			#
			# Notes: DecisionTree.jl compares feature against a threshold (0.5 for Boolean features). Hence left edge
			# corresponds to feature == false.
			# Feature 1: x < 2
			# Feature 2: x < 4

			grammar = HerbGrammar.@csgrammar begin
				Number = |(0:8)
				Number = x
				Number = Number - Number
				Bool = Number < Number
				Condition = Bool ? Number : Number
			end

			# predicates vector => index corresponds to feature id
			predicates = [
				RuleNode(12, [RuleNode(10), RuleNode(3)]), # x < 2
				RuleNode(12, [RuleNode(10), RuleNode(5)]), # x < 4
			]

			program_1 = RuleNode(11, [RuleNode(2), RuleNode(10)]) # 1 - x
			program_2 = RuleNode(11, [RuleNode(3), RuleNode(10)]) # 2 - x
			program_3 = RuleNode(11, [RuleNode(4), RuleNode(10)]) # 3 - x
			solutions = [program_1, program_2, program_3]

			expected_program = RuleNode(
				13,
				[predicates[1], program_1, RuleNode(13, [predicates[2], program_2, program_3])],
			)

			# create simple tree for testing
			right_1 = Leaf(
				1,  # majority (label)
				[], # samples
			)
			right_2 = Leaf(
				2,
				[],
			)
			left_2 = Leaf(
				3,
				[],
			)

			left_1 = Node(2, 0.5, left_2, right_2) # Node(featid, featval, left::Union{Leaf, Node}, right::Union{Leaf, Node})
			root_node = Node(1, 0.5, left_1, right_1)


			# construct final program from decision tree
			idx_ifelse = 13
			final_program = construct_final_program(
				root_node,
				idx_ifelse,
				solutions,
				predicates,
			)
			@test final_program == expected_program
		end

	end

end
