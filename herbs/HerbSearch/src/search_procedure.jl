"""
	@enum SynthResult optimal_program=1 suboptimal_program=2

Representation of the possible results of the synth procedure. 
At the moment there are two possible outcomes:

- `optimal_program`: The synthesized program satisfies the entire program specification.
- `suboptimal_program`: The synthesized program does not satisfy the entire program specification, but got the best score from the evaluator.
"""
@enum SynthResult optimal_program = 1 suboptimal_program = 2

"""
	synth(problem::Problem, iterator::ProgramIterator; shortcircuit::Bool=true, allow_evaluation_errors::Bool=false, mod::Module=Main)::Union{Tuple{RuleNode, SynthResult}, Nothing}

Synthesize a program that satisfies the maximum number of examples in the problem.
		- problem                 - The problem definition with IO examples
		- iterator                - The iterator that will be used
		- shortcircuit            - Whether to stop evaluating after finding a single example that fails, to speed up the [synth](@ref) procedure. If true, the returned score is an underapproximation of the actual score.
		- allow_evaluation_errors - Whether the search should crash if an exception is thrown in the evaluation
		- max_time                - Maximum time that the iterator will run 
		- max_enumerations        - Maximum number of iterations that the iterator will run 
		- mod                     - A module containing definitions for the functions in the grammar that do not exist in Main

Returns a tuple of the rulenode representing the solution program and a synthresult that indicates if that program is optimal. `synth` uses `evaluate` which returns a score in the interval [0, 1] and checks whether that score reaches 1. If not it will return the best program so far, with the proper flag
"""
function synth(
	problem::Problem,
	iterator::ProgramIterator;
	shortcircuit::Bool = true,
	allow_evaluation_errors::Bool = false,
	max_time = typemax(Int),
	max_enumerations = typemax(Int),
	mod::Module = Main)::Union{Tuple{RuleNode, SynthResult}, Nothing}
	start_time = time()
	grammar = get_grammar(iterator)
	symboltable = grammar2symboltable(grammar, mod)

	best_score = 0
	best_program = nothing

	for (i, candidate_program) ∈ enumerate(iterator)
		# Create expression from rulenode representation of AST
		expr = rulenode2expr(candidate_program, grammar)

		# Evaluate the expression
		score = evaluate(
			problem,
			expr,
			symboltable,
			shortcircuit = shortcircuit,
			allow_evaluation_errors = allow_evaluation_errors,
		)
		if score == 1
			candidate_program = freeze_state(candidate_program)
			return (candidate_program, optimal_program)
		elseif score >= best_score
			best_score = score
			candidate_program = freeze_state(candidate_program)
			best_program = candidate_program
		end

		# Check stopping criteria
		if i > max_enumerations || time() - start_time > max_time
			break
		end
	end

	# The enumeration exhausted, but an optimal problem was not found
	return (best_program, suboptimal_program)
end
