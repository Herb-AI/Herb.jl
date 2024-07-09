# Getting started with HerbConstraints

When enumerating programs using a grammar, we will encounter many redundant programs. For example, `x`, `-(-x)` and `1 * x` are syntactically different programs, but they have the same semantics. Grammar constraints aim to speed up synthesis by eliminating such redundant programs and thereby reducing the size of the program space.

### Setup

For this tutorial, we need to import the following modules of the Herb.jl framework:

* `HerbCore` for the necessary data strucutes, like `Hole`s and `RuleNode`s
* `HerbGrammar` to define the grammar
* `HerbConstraints` to define the constraints
* `HerbSearch` to execute a constrained enumeration

We will also redefine the simple arithmetic grammar from the previous tutorial.


```julia
using HerbCore, HerbGrammar, HerbConstraints, HerbSearch

grammar = @cfgrammar begin
    Int = 1
    Int = x
    Int = - Int
    Int = Int + Int
    Int = Int * Int
end
```


    1: Int = 1
    2: Int = x
    3: Int = -Int
    4: Int = Int + Int
    5: Int = Int * Int
    


### Working with constraints

To show the effects of constraints, we will first enumerate all programs without constraints (up to a maximum size of 3 AST nodes).

(To make sure the grammar doesn't have any constraints, we can clear the constraints using `clearconstraints!`. This is not needed at this point, but could come in handy if your REPL holds a reference to a constrained version of the grammar)


```julia
clearconstraints!(grammar)
iter = BFSIterator(grammar, :Int, max_size=3)

for program ∈ iter
    println(rulenode2expr(program, grammar))
end

```

    1
    x
    -1
    -x
    1 * 1
    -(-1)
    1x
    -(-x)
    x * x
    x * 1
    x + 1
    x + x
    1 + x
    1 + 1
    

Upon inspection, we can already see some redundant programs, like `1 * 1` and `-(-1)`. To eliminate these redundant programs, we will set up some constraints that prevent these patterns from appearing. Then we will create another iteratator to enumerate all programs that satisfy the defined grammar constraints.

To make the forbidden pattern constraint general, we will use a special type of rulenode: `VarNode(:A)`. This node matches with any subtree and can be used to forbid multiple forbidden patterns using a single constraint. For example, `Forbidden(RuleNode(minus, [RuleNode(minus, [VarNode(:A)])])))` forbids:

* `-(-1)`
* `-(-X)`
* `-(-(1 + 1))`
* `1 + -(-(1 + 1))`
* etc


```julia
one = 1
x = 2
minus = 3
plus = 4
times = 5

addconstraint!(grammar, Forbidden(RuleNode(times, [RuleNode(one), VarNode(:A)])))        # forbid 1*A
addconstraint!(grammar, Forbidden(RuleNode(minus, [RuleNode(minus, [VarNode(:A)])])))    # forbid -(-A)

iter = BFSIterator(grammar, :Int, max_size=3)

for program ∈ iter
    println(rulenode2expr(program, grammar))
end
```

    1
    x
    -1
    -x
    x * 1
    x * x
    x + x
    x + 1
    1 + 1
    1 + x
    

### Forbidden Constraint

The `Forbidden` constraint forbids any subtree in the program that matches a given template tree. Such a template tree can consist of 3 node types:
* `RuleNode(1)`. Matches exactly the given rule.
* `DomainRuleNode(BitVector((0, 0, 0, 1, 1)), children)`. Matches any rule in its bitvector domain. In this case, rule 4 and 5.
* `VarNode(:A)`. Matches any subtree. If another VarNode of the same name is used, the subtrees have to be the same.


```julia
#this constraint forbids A+A and A*A
constraint = Forbidden(DomainRuleNode(BitVector((0, 0, 0, 1, 1)), [VarNode(:A), VarNode(:A)]))

# Without this constraint, we encounter 154 programs
clearconstraints!(grammar)
iter = BFSIterator(grammar, :Int, max_size=5)
println(length(iter))

# With this constraint, we encounter 106 programs
clearconstraints!(grammar)
addconstraint!(grammar, constraint)
iter = BFSIterator(grammar, :Int, max_size=5)
println(length(iter))

```

    154
    106
    

### Contains Constraint

The `Contains` constraint enforces that a given rule appears in the program tree at least once. 

In the arithmetic grammar, this constraint can be used to ensure the input symbol `x` is used in the program. Otherwise, the program is just a constant.


```julia
clearconstraints!(grammar)
addconstraint!(grammar, Contains(2)) #rule 2 should be used in the program
iter = BFSIterator(grammar, :Int, max_size=3)

for program ∈ iter
    println(rulenode2expr(program, grammar))
end
```

    x
    -x
    -(-x)
    1x
    x * x
    x * 1
    x + 1
    x + x
    1 + x
    

### Contains Subtree Constraint

Similarly to the `Contains` constraint, the `ContainsSubtree` can be used to enforce a given template tree is used in the program at least once.


```julia
clearconstraints!(grammar)
addconstraint!(grammar, ContainsSubtree(RuleNode(times, [RuleNode(x), RuleNode(x)]))) #x*x should be in the program tree
iter = BFSIterator(grammar, :Int, max_size=4)

for program ∈ iter
    println(rulenode2expr(program, grammar))
end
```

    x * x
    -(x * x)
    

### Ordered Constraint

The `Ordered` constraint enforces an `<=` ordering on a provided list of variables. With this constraint, we can break symmetries based on commutativity. For example, `1+x` and `x+1` are semantically equivalent. By imposing an `Ordered` constraint, we can eliminate one of the symmetric variants.

To define an `Ordered` constraint, we need to provide it with a template tree including at least two differently named `VarNode`s. And additionally, an ordering of the variables in the tree.

In the upcoming example we will set up a template tree representing `a+b` and `a*b`.
Then, we will impose an ordering `a<=b` on all the subtrees that match the template.

The result is that our iterator skips the redundant programs `x+1` and `x*1`, as they are already represented by `1+x` and `1*x`.



```julia
clearconstraints!(grammar)

template_tree = DomainRuleNode(BitVector((0, 0, 0, 1, 1)), [VarNode(:a), VarNode(:b)])
order = [:a, :b]

addconstraint!(grammar, Ordered(template_tree, order))
iter = BFSIterator(grammar, :Int, max_size=3)

for program ∈ iter
    println(rulenode2expr(program, grammar))
end

```

    1
    x
    -1
    -x
    1 * 1
    -(-1)
    1x
    -(-x)
    x * x
    x + x
    1 + x
    1 + 1
    

### Forbidden Sequence Constraint

The `ForbiddenSequence` constraints forbids a given sequence of rule nodes in a vertical path of the tree. 

An optional second argument, `ignore_if`, can be used to overrule the constraint in case any of the rules on the `ignore_if` list are present. 

Below we will define the constraint `ForbiddenSequence([plus, one], ignore_if=[times])`. It forbids an `1` after an `+` unless an `*` disrupts the sequence.

This constraint will **forbid** the following programs:

* x + 1
* x + -1
* x + -(-1)
* x + (x + 1)
* x * (x + 1)

But it will **allow** the following program (as * disrupts the sequence):

* x + (x * 1)



```julia
constraint = ForbiddenSequence([plus, one], ignore_if=[times])
addconstraint!(grammar, constraint)
iter = BFSIterator(grammar, :Int, max_size=3)

for program ∈ iter
    println(rulenode2expr(program, grammar))
end

```

    1
    x
    -1
    -x
    1 * 1
    -(-1)
    1x
    -(-x)
    x * x
    x + x
    

### Custom Constraint

To implement a new constraint, we need to define two structs: an `AbstractGrammarConstraint` and an `AbstractLocalConstraint`.

A **grammar constraint** is a high-level constraint on the grammar itself and does not refer to a location in the tree. For example, the `Forbidden` constraint is responsible for forbidding a template tree everywhere in the tree. To divide the work of constraint propagation, the grammar constraint will post several local constraints that are responsible for propagating the constraint at each particular location.

A **local constraint** is a rooted version of a grammar constraint. Each local constraint holds a `path` field that points to a location in the tree where this constraint applies.

Suppose we want to implement a simple custom constraint that forbids a given `rule` twice in a row. 

Each time a new AST node is added to a tree, the `on_new_node` function is called to notify that an unseen node has been added to the tree at path `path`. Our grammar constraint has the opportunity to react to this event. In this example, we will post a new local constraint at the new location using the `post!` function.

(Don't worry about the `HerbConstraints.` prefixes. Normally, constraints are defined within the HerbConstraints repository, so there is no need to specify the namespace)


```julia
"""
Forbids the consecutive application of the specified rule.
For example, CustomConstraint(4) forbids the tree 4(1, 4(1, 1)) as it applies rule 4 twice in a row.
"""
struct ForbidConsecutive <: AbstractGrammarConstraint
    rule::Int
end

"""
Post a local constraint on each new node that appears in the tree
"""
function HerbConstraints.on_new_node(solver::Solver, constraint::ForbidConsecutive, path::Vector{Int})
    HerbConstraints.post!(solver, LocalForbidConsecutive(path, constraint.rule))
end
```


    HerbConstraints.on_new_node


Next, we will define our local constraint. This constraint is responsible for propagating the constraint at a given path. The `propagate!` method can use several solver functions to manipulate the tree. The following **tree manipulations** can be used to remove rules from the domain of a hole at a given path:

* `remove!(solver::Solver, path::Vector{Int}, rule_index::Int)`
* `remove!(solver::Solver, path::Vector{Int}, rules::Vector{Int})`
* `remove_all_but!(solver::Solver, path::Vector{Int}, new_domain::BitVector)`
* `remove_above!(solver::Solver, path::Vector{Int}, rule_index::Int)`
* `remove_below!(solver::Solver, path::Vector{Int}, rule_index::Int)`
* `make_equal!(solver::Solver, node1::AbstractRuleNode, node2::AbstractRuleNode)` (a high level manipulation that requires `node1` and `node2` to be in the tree)

In addition to tree manipulations, the following solver functions can be used to communicate new information to the solver:

* `set_infeasible!(solver)`. If a propagator detects an inconsistency, the solver should be notified and cancel any other scheduled propagators.
* `deactivate!(solver, constraint)`.  If a constraint is satisfied, it should deactivate itself to prevent re-propagation.
* `post!(solver, constraint)`  A constraint is allowed to post new local constraints. This might be helpful if a constraint can be reduced to a smaller constraint.

The solver manages all constraints and the program tree we propagate on. Applying tree manipulations might cause a chain reaction of other propagators, so the shape of the tree might update as we propagate. The get the latest information about the tree, we should use the following getter functions:

* `get_tree(solver)` returns the root node of the current (partial) program tree
* `isfeasible(solver)` returns the a flag indicating if the solver is not violating any (other) constriants.
* `get_path(solver, node)` returns the path at which the node is located.
* `get_node_at_location(solver, path)` returns the node that is currently at the given path (be aware that this instance might be replaced by manipulations).
* `get_hole_at_location(solver, path)` same as get node at location, but asserts the node is a hole (domain size >= 2).

To get information about a node, we can use the following getter functions:

* `isfilled(node)`. Returns true if the node is a `RuleNode` or has domain size 1.
* `get_rule(node)`. Get the rule of a filled node.
* `get_children(node)`. Get the children of a node.
* `node.domain[rule]`. Given the node is a hole, return true if `rule` is in the domain.

Finally, another useful function for propagators is `pattern_match(node1, node2)`. This function compares two trees and returns a `PatternMatchResult` that indicates if the nodes match, and potentially indicate which holes need to be filled to complete the match.



```julia
"""
Forbids the consecutive application of the specified rule at path `path`.
"""
struct LocalForbidConsecutive <: AbstractLocalConstraint
    path::Vector{Int}
    rule::Int
end

"""
Propagates the constraints by preventing a consecutive application of the specified rule.
"""
function HerbConstraints.propagate!(solver::Solver, constraint::LocalForbidConsecutive)
    node = get_node_at_location(solver, constraint.path)
    if isfilled(node)
        if get_rule(node) == constraint.rule
            #the specified rule is used, make sure the rule will not be used by any of the children
            for (i, child) ∈ enumerate(get_children(node))
                if isfilled(child)
                    if get_rule(child) == constraint.rule
                        #the specified rule was used twice in a row, which is violating the constraint
                        set_infeasible!(solver)
                        return
                    end
                elseif child.domain[constraint.rule]
                    child_path = push!(copy(constraint.path), i)
                    remove!(solver, child_path, constraint.rule) # remove the rule from the domain of the child
                end
            end
        end
    elseif node.domain[constraint.rule]
        #our node is a hole with the specified rule in its domain
        #we will now check if any of the children already uses the specified rule
        softfail = false
        for (i, child) ∈ enumerate(get_children(node))
            if isfilled(child)
                if get_rule(child) == constraint.rule
                    #the child holds the specified rule, so the parent cannot have this rule
                    remove!(solver, constraint.path, constraint.rule)
                end
            elseif child.domain[constraint.rule]
                #the child is a hole and contains the specified node. since there are 2 holes involved, we will softfail.
                softfail = true
            end
        end
        if softfail
            #we cannot deactivate the constraint, because it needs to be repropagated
            return
        end
    end

    #the constraint is satisfied and can be deactivated
    HerbConstraints.deactivate!(solver, constraint)
end
```


    HerbConstraints.propagate!


Posting a local constraint will trigger the initial propagation. To re-propagate, the constraint needs to be rescheduled for propagation.

Whenever the tree is manipulated, we will make a `shouldschedule` check to see if our constraint needs to be rescheduled for propagation based on the manipulation.

In our case, we want to repropagate if either:
* a tree manipulation occured at the `constraint.path`
* a tree manipulation occured at the child of the `constraint.path`


```julia

"""
Gets called whenever an tree manipulation occurs at the given `path`.
Returns true iff the `constraint` should be rescheduled for propagation.
"""
function HerbConstraints.shouldschedule(solver::Solver, constraint::LocalForbidConsecutive, path::Vector{Int})::Bool
    return (path == constraint.path) || (path == constraint.path[1:end-1])
end

```


    HerbConstraints.shouldschedule


With all the components implemented, we can do a constrained enumeration using our new `ForbidConsecutive` constraint.


```julia
clearconstraints!(grammar)

addconstraint!(grammar, ForbidConsecutive(minus))
addconstraint!(grammar, ForbidConsecutive(plus))
addconstraint!(grammar, ForbidConsecutive(times))

iter = BFSIterator(grammar, :Int, max_size=6)

for program ∈ iter
    println(rulenode2expr(program, grammar))
end
```

    1
    x
    -1
    -x
    1 * 1
    1x
    x * x
    x * 1
    x + 1
    x + x
    1 + x
    1 + 1
    1 * -1
    1 * -x
    x * -x
    x * -1
    x + -1
    x + -x
    1 + -x
    -(1 * 1)
    1 + -1
    -(1x)
    -(x * x)
    -(x * 1)
    -((x + 1))
    -((x + x))
    -1 * 1
    -((1 + x))
    -1 * x
    -((1 + 1))
    -x * x
    -x * 1
    -x + 1
    -x + x
    -1 + x
    -1 + 1
    (1 + 1) * 1
    -(1 * -1)
    (1 + 1) * x
    -(1 * -x)
    (1 + x) * x
    -(x * -x)
    (1 + x) * 1
    -(x * -1)
    (x + x) * 1
    -((x + -1))
    (x + x) * x
    -((x + -x))
    (x + 1) * x
    -((1 + -x))
    (x + 1) * 1
    -((1 + -1))
    x * 1 + 1
    x * 1 + x
    x * x + x
    x * x + 1
    1x + 1
    1x + x
    -(-1 * 1)
    1 * 1 + x
    -(-1 * x)
    1 * 1 + 1
    -(-x * x)
    -(-x * 1)
    -((-x + 1))
    1 * (1 + 1)
    -((-x + x))
    1 * (1 + x)
    -((-1 + x))
    1 * (x + x)
    -((-1 + 1))
    1 * (x + 1)
    x * (x + 1)
    x * (x + x)
    x * (1 + x)
    x * (1 + 1)
    -1 * -1
    x + 1 * 1
    -1 * -x
    x + 1x
    -x * -x
    x + x * x
    -x * -1
    x + x * 1
    -x + -1
    1 + x * 1
    -x + -x
    1 + x * x
    -1 + -x
    1 + 1x
    -1 + -1
    1 + 1 * 1
    -1 * (1 + 1)
    1 * (1 + -1)
    -1 * (1 + x)
    1 * (1 + -x)
    -1 * (x + x)
    1 * (x + -x)
    -1 * (x + 1)
    1 * (x + -1)
    -x * (x + 1)
    x * (x + -1)
    -x * (x + x)
    x * (x + -x)
    -x * (1 + x)
    x * (1 + -x)
    -x * (1 + 1)
    x * (1 + -1)
    -x + 1 * 1
    x + 1 * -1
    -x + 1x
    x + 1 * -x
    -x + x * x
    x + x * -x
    -x + x * 1
    x + x * -1
    -1 + x * 1
    1 + x * -1
    -1 + x * x
    1 + x * -x
    -1 + 1x
    1 + 1 * -x
    -1 + 1 * 1
    1 + 1 * -1
    1 * -(1 * 1)
    (1 + -1) * 1
    1 * -(1x)
    (1 + -1) * x
    1 * -(x * x)
    (1 + -x) * x
    1 * -(x * 1)
    (1 + -x) * 1
    1 * -((x + 1))
    (x + -x) * 1
    1 * -((x + x))
    (x + -x) * x
    1 * -((1 + x))
    (x + -1) * x
    1 * -((1 + 1))
    (x + -1) * 1
    x * -((1 + 1))
    x * -1 + 1
    x * -((1 + x))
    x * -1 + x
    x * -((x + x))
    x * -x + x
    x * -((x + 1))
    x * -x + 1
    x * -(x * 1)
    1 * -x + 1
    x * -(x * x)
    1 * -x + x
    x * -(1x)
    1 * -1 + x
    x * -(1 * 1)
    1 * -1 + 1
    x + -(1 * 1)
    x + -(1x)
    1 * (-1 + 1)
    x + -(x * x)
    1 * (-1 + x)
    x + -(x * 1)
    1 * (-x + x)
    x + -((x + 1))
    1 * (-x + 1)
    x + -((x + x))
    x * (-x + 1)
    x + -((1 + x))
    x * (-x + x)
    x + -((1 + 1))
    x * (-1 + x)
    1 + -((1 + 1))
    x * (-1 + 1)
    1 + -((1 + x))
    x + -1 * 1
    1 + -((x + x))
    x + -1 * x
    1 + -((x + 1))
    x + -x * x
    1 + -(x * 1)
    x + -x * 1
    1 + -(x * x)
    1 + -x * 1
    1 + -(1x)
    1 + -x * x
    1 + -(1 * 1)
    1 + -1 * x
    1 + -1 * 1
    -(1 * 1) * 1
    -(1 * 1) * x
    -((1 + 1) * 1)
    -(1x) * x
    -((1 + 1) * x)
    -(1x) * 1
    -((1 + x) * x)
    -(x * x) * 1
    -((1 + x) * 1)
    -(x * x) * x
    -((x + x) * 1)
    -(x * 1) * x
    -((x + x) * x)
    -(x * 1) * 1
    -((x + 1) * x)
    -((x + 1)) * 1
    -((x + 1) * 1)
    -((x + 1)) * x
    -((x * 1 + 1))
    -((x + x)) * x
    -((x * 1 + x))
    -((x + x)) * 1
    -((x * x + x))
    -((1 + x)) * 1
    -((x * x + 1))
    -((1 + x)) * x
    -((1x + 1))
    -((1 + 1)) * x
    -((1x + x))
    -((1 + 1)) * 1
    -((1 * 1 + x))
    -((1 + 1)) + 1
    -((1 * 1 + 1))
    -((1 + 1)) + x
    -((1 + x)) + x
    -(-1 * -1)
    -((1 + x)) + 1
    -(-1 * -x)
    -((x + x)) + 1
    -(-x * -x)
    -((x + x)) + x
    -(-x * -1)
    -((x + 1)) + x
    -((-x + -1))
    -((x + 1)) + 1
    -((-x + -x))
    -(x * 1) + 1
    -((-1 + -x))
    -(x * 1) + x
    -((-1 + -1))
    -(x * x) + x
    -(x * x) + 1
    (-1 + 1) * 1
    -(1x) + 1
    (-1 + 1) * x
    -(1x) + x
    (-1 + x) * x
    -(1 * 1) + x
    (-1 + x) * 1
    -(1 * 1) + 1
    (-x + x) * 1
    (-x + x) * x
    (1 + 1) * -1
    (-x + 1) * x
    (1 + 1) * -x
    (-x + 1) * 1
    (1 + x) * -x
    -x * 1 + 1
    (1 + x) * -1
    -x * 1 + x
    (x + x) * -1
    -x * x + x
    (x + x) * -x
    -x * x + 1
    (x + 1) * -x
    -1 * x + 1
    (x + 1) * -1
    -1 * x + x
    x * 1 + -1
    -1 * 1 + x
    x * 1 + -x
    -1 * 1 + 1
    x * x + -x
    x * x + -1
    -(1 * (1 + 1))
    1x + -1
    -(1 * (1 + x))
    1x + -x
    -(1 * (x + x))
    1 * 1 + -x
    -(1 * (x + 1))
    1 * 1 + -1
    -(x * (x + 1))
    -(x * (x + x))
    -(x * (1 + x))
    -(x * (1 + 1))
    -((x + 1 * 1))
    -((x + 1x))
    -((x + x * x))
    -((x + x * 1))
    -((1 + x * 1))
    -((1 + x * x))
    -((1 + 1x))
    -((1 + 1 * 1))
    
