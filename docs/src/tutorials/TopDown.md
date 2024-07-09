# Building Herb Iterators

The core building block in Herb is a program iterator.
A program iterator represents a walk through the program space; different iterators provide different ways of iterating through program space. 
From the program synthesis point of view, program iterators actaully represent program spaces.


### Iterator hierarchy

Program iterators are organised in a hierarchy.
The top-level abstract type is `ProgramIterator`. 
At the next level of the hierarchy lie commonly used search families:
 - `TopDownIterator` for top-down traversals
 - `StochasticSearachIterator` for traversals with stochastic search
 - `BottomUpIterator` for bottom-up search


Stochastic search further provides specific iterators:
 - `MHSearchIterator` for program traversal with Metropolis-Hastings algorithm
 - `VLNSearchIterator` for traversals with Very Large Neighbourhood Search
 - `SASearchIterator` for Simulated Annealing

 We provide generic and customiseable implementations of each of these iterators, so that users can easily tweak them by through multiple dispatch. Keep reading!


### Iterator design

Program iterators follow the standard Julia `Iterator` interface.
That is, every iterator should implement two functions:
 - `iterate(<:ProgramIterator)::(RuleNode,Any)` to get the first program. The function takes a program iterator as an input, returning the first program and a state (which can be anything)
 - `iterate(<:ProgramIterator,Any)::(RuleNode,Any)` to get the consequtive programs. The function takes the progrma iterator and the state from the previous iteration, and return the next program and the next state.







## Top Down iterator

We illustarate how to build iterators with a Top Down iterator.
The top Down iterator is build as a best-first iterator: it maintains a priority queue of programs and always pops the first element of the queue. 
The iterator is customiseable through the following functions:
- priority_function: dictating the order of programs in the priority queue
- derivation_heuristic: dictating in which order to explore the derivations rules within a single hole
- hole_heuristic: dictating which hole to expand next






The first call to `iterate(iter::TopDownIterator)`:

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

The first call steps everything up: it initiates the priority queue, the constraint solver (more on that later), and return the first program.
The function `_find_next_complete_tree(iter.solver, pq, iter)` does a lot of heavy lifting here; we will cover it later, but the only important thing is that it finds the next complete program in the priority queue (because, in case of top down enumeration, the queue also contains partial programs which we only want to expand, but not return to the user).


The subsequent call to `iterate(iter::TopDownIterator, pq::DataStructures.PriorityQueue)` are quite simple: all that is needed is to find the next complete program in the priority queue:

``` julia
function Base.iterate(iter::TopDownIterator, pq::DataStructures.PriorityQueue)
    return _find_next_complete_tree(iter.solver, pq, iter)
end
```

# Modifying the provided iterator

If you would like to, for example, modify the priority function, you don't have to implement the iterator from scratch.
You simply need to create a new type and inherit from the `TopDownIterator`:

`abstract type MyTopDown <: TopDownIterator end`.

What is left is to implement the priority function, multiple-dispatching it over the new type. 
For example, to do a random order:

```julia
function priority_function(
    ::MyTopDown, 
    ::AbstractGrammar, 
    ::AbstractRuleNode, 
    ::Union{Real, Tuple{Vararg{Real}}},
    ::Bool
)
    Random.rand();
end
```


# A note on data structures

As you have probably noticed, the priority queue some strange data structures: `SolverState` and `UniformIterator`; the top down iterator never puts `RuleNode`s into the queue.
In fact, the iterator never directly manipulates `RuleNode`s itself, but that is rather delegated to the constraint solver.
The constraint solver will do a lot of work to reduce the number of programs we have to consider.
The `SolverState` and `UniformIterator` are specialised data structure to improve the efficiency and memory usage. 

Herb uses a data structure of `UniformTrees` to represent all programs with an AST of the same shape, where each node has the same type. the `UniformIterator` is an iterator efficiently iterating over that structure.

The `SolverState` represents non-uniform trees -- ASTs whose shape we haven't compeltely determined yet. `SolverState` is used as an intermediate representation betfore we reach `UniformTree`s on which partial constraint propagation is done.

In principle, you should never construct ASTs yourself directly; you should leave that to the constraint solver.



# Extra: Find Next Complete Tree / Program

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