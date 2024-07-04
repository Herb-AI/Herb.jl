# Top Down Iterator

## Base Iterator

This function describes the iteration for a Top Down Iterator. A priority queue is created to determine the order. The solver is checked for the constraints, if it violates the constraints, it is considered infeasible, and if it is feasible, it is added to the queue. This function then returns the next complete tree, that is a tree without holes.
This function creates a priority queue, and is therefore called once during the initialisation.

``` julia
function Base.iterate(iter::TopDownIterator)
    # Priority queue with `SolverState`s (for variable shaped trees) and `UniformIterator`s (for fixed shaped trees)
    pq :: PriorityQueue{Union{SolverState, UniformIterator}, Union{Real, Tuple{Vararg{Real}}}} = PriorityQueue()

    solver = iter.solver

    if isfeasible(solver)
        enqueue!(pq, get_state(solver), priority_function(iter, get_grammar(solver), get_tree(solver), 0, false))
    end
    return _find_next_complete_tree(iter.solver, pq, iter)
end
```

## Base Iterator With a Given Priority Queue

This function describes the iteration for a Top Down Iterator, and a priority queue is given as an argument. This function then returns the next complete tree, that is a tree without holes.
After a priority queue is created, this is the function that will be called.

``` julia
function Base.iterate(iter::TopDownIterator, pq::DataStructures.PriorityQueue)
    return _find_next_complete_tree(iter.solver, pq, iter)
end
```

# Find Next Complete Tree / Program

This function pops an element from the priority queue whilst it is not empty, and then checks what kind of iterator it is.

``` julia
function _find_next_complete_tree(
    solver::Solver,
    pq::PriorityQueue,
    iter::TopDownIterator
)
    while length(pq) ≠ 0
        (item, priority_value) = dequeue_pair!(pq)

```

If it is a Uniform Iterator, that is an interator where all the holes have the same shape, then it iterates over the solutions.

``` julia

        if item isa UniformIterator
            #the item is a fixed shaped solver, we should get the next solution and re-enqueue it with a new priority value
            uniform_iterator = item
            solution = next_solution!(uniform_iterator)
            if !isnothing(solution)
                enqueue!(pq, uniform_iterator, priority_function(iter, get_grammar(solver), solution, priority_value, true))
                return (solution, pq)
            end

```
If it is not a Uniform Iterator, we find a hole to branch on. If the holes are all uniform, a Uniform Iterator is created, and is enqueued. If iterating on the holes would exceed a maximum depth, nothing new is enqueued. Lastly, if the holes aren't the same shape, we branch / partition on the holes, to create new partial domains to enqueue.

``` julia
        elseif item isa SolverState
            #the item is a solver state, we should find a variable shaped hole to branch on
            state = item
            load_state!(solver, state)

            hole_res = hole_heuristic(iter, get_tree(solver), get_max_depth(solver))
            if hole_res ≡ already_complete
                uniform_solver = UniformSolver(get_grammar(solver), get_tree(solver), with_statistics=solver.statistics)
                uniform_iterator = UniformIterator(uniform_solver, iter)
                solution = next_solution!(uniform_iterator)
                if !isnothing(solution)
                    enqueue!(pq, uniform_iterator, priority_function(iter, get_grammar(solver), solution, priority_value, true))
                    return (solution, pq)
                end
            elseif hole_res ≡ limit_reached
                # The maximum depth is reached
                continue
            elseif hole_res isa HoleReference
                # Variable Shaped Hole was found
                (; hole, path) = hole_res
        
                partitioned_domains = partition(hole, get_grammar(solver))
                number_of_domains = length(partitioned_domains)
                for (i, domain) ∈ enumerate(partitioned_domains)
                    if i < number_of_domains
                        state = save_state!(solver)
                    end
                    @assert isfeasible(solver) "Attempting to expand an infeasible tree: $(get_tree(solver))"
                    remove_all_but!(solver, path, domain)
                    if isfeasible(solver)
                        enqueue!(pq, get_state(solver), priority_function(iter, get_grammar(solver), get_tree(solver), priority_value, false))
                    end
                    if i < number_of_domains
                        load_state!(solver, state)
                    end
                end
            end


```
Otherwise, throw an exception, because we came across an unexpected iterator type.

``` julia
        else
            throw("BadArgument: PriorityQueue contains an item of unexpected type '$(typeof(item))'")
        end
    end
    return nothing
end
```