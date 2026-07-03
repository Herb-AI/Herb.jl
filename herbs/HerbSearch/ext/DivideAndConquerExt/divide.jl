"""
	$(TYPEDSIGNATURES)

Breaks the problem specification into individual problems with each of them being a single input-output example.
Returns a vector containing all individual subproblems. 

# Arguments 
- `problem` : Specification of the program synthesis problem, with the problem consisting  
  consisting of one or more `IOExample`s.
"""
function divide(problem::Problem{Vector{T}}) where T <: IOExample
	subproblems = Vector()
	for p in problem.spec
		push!(subproblems, Problem([p]))
	end
	return subproblems
end
