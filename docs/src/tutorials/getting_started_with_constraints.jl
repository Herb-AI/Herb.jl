### A Pluto.jl notebook ###
# v0.20.5

using Markdown
using InteractiveUtils

# ╔═╡ c5cb3782-c9af-4cf5-9e28-e1892c6442a2
using Herb

# ╔═╡ c5509a19-43bc-44d3-baa9-9af83717b6e6
md"""
# Getting started with HerbConstraints

When enumerating programs using a grammar, we will encounter many redundant programs. For example, `x`, `-(-x)` and `1 * x` are syntactically different programs, but they have the same semantics. Grammar constraints aim to speed up synthesis by eliminating such redundant programs and thereby reducing the size of the program space.
"""

# ╔═╡ 864bc658-9612-4439-9024-74668ba3f971
md"""
### Setup

For this tutorial, we need to import the following modules of the Herb.jl framework:

* `HerbCore` for the necessary data structures, like `Hole`s and `RuleNode`s
* `HerbGrammar` to define the grammar
* `HerbConstraints` to define the constraints
* `HerbSearch` to execute a constrained enumeration

We will also redefine the simple arithmetic grammar from the previous tutorial.
"""

# ╔═╡ aacedef3-08d6-4bc0-a2c3-dd9a9aac340d
grammar = @csgrammar begin
    Int = 1
    Int = x
    Int = - Int
    Int = Int + Int
    Int = Int * Int
end

# ╔═╡ 1ff2dd58-01df-4cab-93d9-aabe1d07cc85
md"""
### Working with constraints

To show the effects of constraints, we will first enumerate all programs without constraints (up to a maximum size of 3 AST nodes).

(To make sure the grammar doesn't have any constraints, we can clear the constraints using `clearconstraints!`. This is not needed at this point, but could come in handy if your REPL holds a reference to a constrained version of the grammar)
"""

# ╔═╡ 62e41031-6866-46fc-b160-fb2f81f75c04
begin
	clearconstraints!(grammar)
	iter_1 = BFSIterator(grammar, :Int, max_size=3)
	
	for program ∈ iter_1
	    println(rulenode2expr(program, grammar))
	end
	
end

# ╔═╡ 76478bc7-e1b0-44f7-b1e0-95573db9f0e3
md"""
Upon inspection, we can already see some redundant programs, like `1 * 1` and `-(-1)`. To eliminate these redundant programs, we will set up some constraints that prevent these patterns from appearing. Then we will create another iterator to enumerate all programs that satisfy the defined grammar constraints.

To make the forbidden pattern constraint general, we will use a special type of rulenode: `VarNode(:A)`. This node matches with any subtree and can be used to forbid multiple forbidden patterns using a single constraint. For example, `Forbidden(RuleNode(minus, [RuleNode(minus, [VarNode(:A)])])))` forbids:

* `-(-1)`
* `-(-X)`
* `-(-(1 + 1))`
* `1 + -(-(1 + 1))`
* etc
"""

# ╔═╡ 4d94057f-0b69-4d7d-8bde-900e6eb3e53f
begin
	one = 1
	x = 2
	minus = 3
	plus = 4
	times = 5
	
	addconstraint!(grammar, Forbidden(RuleNode(times, [RuleNode(one), VarNode(:A)])))        # forbid 1*A
	addconstraint!(grammar, Forbidden(RuleNode(minus, [RuleNode(minus, [VarNode(:A)])])))    # forbid -(-A)
	
	iter_2 = BFSIterator(grammar, :Int, max_size=3)
	
	for program ∈ iter_2
	    println(rulenode2expr(program, grammar))
	end
end

# ╔═╡ 1f0ba3c1-d160-44f5-85c4-4089cbd6f284
md"""
### Forbidden Constraint

The `Forbidden` constraint forbids any subtree in the program that matches a given template tree. Such a template tree can consist of 3 node types:
* `RuleNode(1)`. Matches exactly the given rule.
* `DomainRuleNode(BitVector((0, 0, 0, 1, 1)), children)`. Matches any rule in its bitvector domain. In this case, rule 4 and 5.
* `VarNode(:A)`. Matches any subtree. If another VarNode of the same name is used, the subtrees have to be the same.
"""

# ╔═╡ 030a150e-84ac-4aa6-9a08-5639538fb981
begin
	#this constraint forbids A+A and A*A
	constraint_1 = Forbidden(DomainRuleNode(BitVector((0, 0, 0, 1, 1)), [VarNode(:A), VarNode(:A)]))
	
	# Without this constraint, we encounter 154 programs
	clearconstraints!(grammar)
	iter_3 = BFSIterator(grammar, :Int, max_size=5)
	println(length(iter_3))
	
	# With this constraint, we encounter 106 programs
	clearconstraints!(grammar)
	addconstraint!(grammar, constraint_1)
	iter_4 = BFSIterator(grammar, :Int, max_size=5)
	println(length(iter_4))
	
end

# ╔═╡ 4e1e76b3-b6b2-4a1d-a749-9226a283522d
md"""
### Contains Constraint

The `Contains` constraint enforces that a given rule appears in the program tree at least once. 

In the arithmetic grammar, this constraint can be used to ensure the input symbol `x` is used in the program. Otherwise, the program is just a constant.
"""

# ╔═╡ 92eb7f60-88df-4212-a50b-b31bf386c720
begin
	clearconstraints!(grammar)
	addconstraint!(grammar, Contains(2)) #rule 2 should be used in the program
	iter_5 = BFSIterator(grammar, :Int, max_size=3)
	
	for program ∈ iter_5
	    println(rulenode2expr(program, grammar))
	end
end

# ╔═╡ 6c6becfb-1a7f-403a-9b04-6c4334c9f489
md"""
### Contains Subtree Constraint

Similarly to the `Contains` constraint, the `ContainsSubtree` can be used to enforce a given template tree is used in the program at least once.
"""

# ╔═╡ ada60cc5-7aa1-41c4-828b-3d73c29fd087
begin
	clearconstraints!(grammar)
	addconstraint!(grammar, ContainsSubtree(RuleNode(times, [RuleNode(x), RuleNode(x)]))) #x*x should be in the program tree
	iter_6 = BFSIterator(grammar, :Int, max_size=4)
	
	for program ∈ iter_6
	    println(rulenode2expr(program, grammar))
	end
end

# ╔═╡ 3f42462a-0be0-42bd-a428-a666769054dd
md"""
### Ordered Constraint

The `Ordered` constraint enforces an `<=` ordering on a provided list of variables. With this constraint, we can break symmetries based on commutativity. For example, `1+x` and `x+1` are semantically equivalent. By imposing an `Ordered` constraint, we can eliminate one of the symmetric variants.

To define an `Ordered` constraint, we need to provide it with a template tree including at least two differently named `VarNode`s. And additionally, an ordering of the variables in the tree.

In the upcoming example we will set up a template tree representing `a+b` and `a*b`.
Then, we will impose an ordering `a<=b` on all the subtrees that match the template.

The result is that our iterator skips the redundant programs `x+1` and `x*1`, as they are already represented by `1+x` and `1*x`.

"""

# ╔═╡ 4e76bb87-c429-4547-accc-e304d4220f2d
begin
	clearconstraints!(grammar)
	
	template_tree = DomainRuleNode(BitVector((0, 0, 0, 1, 1)), [VarNode(:a), VarNode(:b)])
	order = [:a, :b]
	
	addconstraint!(grammar, Ordered(template_tree, order))
	iter_7 = BFSIterator(grammar, :Int, max_size=3)
	
	for program ∈ iter_7
	    println(rulenode2expr(program, grammar))
	end
	
end

# ╔═╡ 00f62b26-a15d-4525-bef0-857d37bb0d85
md"""
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

"""

# ╔═╡ 19d0a61b-46a3-4d53-b1d2-2b0e2650b56a
begin
	constraint_2 = ForbiddenSequence([plus, one], ignore_if=[times])
	addconstraint!(grammar, constraint_2)
	iter_8 = BFSIterator(grammar, :Int, max_size=3)
	
	for program ∈ iter_8
	    println(rulenode2expr(program, grammar))
	end
	
end

# ╔═╡ 2bea7a99-c46a-4200-9ba8-1227a5806f2f
md"""
### Custom Constraint

To implement a new constraint, we need to define two structs: an `AbstractGrammarConstraint` and an `AbstractLocalConstraint`.

A **grammar constraint** is a high-level constraint on the grammar itself and does not refer to a location in the tree. For example, the `Forbidden` constraint is responsible for forbidding a template tree everywhere in the tree. To divide the work of constraint propagation, the grammar constraint will post several local constraints that are responsible for propagating the constraint at each particular location.

A **local constraint** is a rooted version of a grammar constraint. Each local constraint holds a `path` field that points to a location in the tree where this constraint applies.
"""

# ╔═╡ f4c15b60-5d45-4b75-9100-a7be2969d7ca
md"""
Suppose we want to implement a simple custom constraint that forbids a given `rule` twice in a row. 

Each time a new AST node is added to a tree, the `on_new_node` function is called to notify that an unseen node has been added to the tree at path `path`. Our grammar constraint has the opportunity to react to this event. In this example, we will post a new local constraint at the new location using the `post!` function.

(Don't worry about the `HerbConstraints.` prefixes. Normally, constraints are defined within the HerbConstraints repository, so there is no need to specify the namespace)
"""

# ╔═╡ b00b039b-63ee-40d0-8f4b-d25539e596d5
begin
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
end

# ╔═╡ bacc917b-2706-412d-9b85-deb4b6685323
md"""
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
* `isfeasible(solver)` returns the a flag indicating if the solver is not violating any (other) constraints.
* `get_path(solver, node)` returns the path at which the node is located.
* `get_node_at_location(solver, path)` returns the node that is currently at the given path (be aware that this instance might be replaced by manipulations).
* `get_hole_at_location(solver, path)` same as get node at location, but asserts the node is a hole (domain size >= 2).

To get information about a node, we can use the following getter functions:

* `isfilled(node)`. Returns true if the node is a `RuleNode` or has domain size 1.
* `get_rule(node)`. Get the rule of a filled node.
* `get_children(node)`. Get the children of a node.
* `node.domain[rule]`. Given the node is a hole, return true if `rule` is in the domain.

Finally, another useful function for propagators is `pattern_match(node1, node2)`. This function compares two trees and returns a `PatternMatchResult` that indicates if the nodes match, and potentially indicate which holes need to be filled to complete the match.

"""

# ╔═╡ fef62621-716a-4f8a-85b4-d92e48b30bc6
begin
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
end

# ╔═╡ e40e09fc-c697-4c83-90eb-2b758254128e
md"""
Posting a local constraint will trigger the initial propagation. To re-propagate, the constraint needs to be rescheduled for propagation.

Whenever the tree is manipulated, we will make a `shouldschedule` check to see if our constraint needs to be rescheduled for propagation based on the manipulation.

In our case, we want to repropagate if either:
* a tree manipulation occurred at the `constraint.path`
* a tree manipulation occurred at the child of the `constraint.path`
"""

# ╔═╡ 4e0989a8-7e63-45eb-80c9-a3a2f97c357c

"""
Gets called whenever an tree manipulation occurs at the given `path`.
Returns true iff the `constraint` should be rescheduled for propagation.
"""
function HerbConstraints.shouldschedule(solver::Solver, constraint::LocalForbidConsecutive, path::Vector{Int})::Bool
    return (path == constraint.path) || (path == constraint.path[1:end-1])
end


# ╔═╡ ce9ae2a2-f3e3-4693-9e6d-60e91128de34
md"""
With all the components implemented, we can do a constrained enumeration using our new `ForbidConsecutive` constraint.
"""

# ╔═╡ 89c165c6-3e04-4887-924f-364b25b21bcd
begin
	clearconstraints!(grammar)
	
	addconstraint!(grammar, ForbidConsecutive(minus))
	addconstraint!(grammar, ForbidConsecutive(plus))
	addconstraint!(grammar, ForbidConsecutive(times))
	
	iter = BFSIterator(grammar, :Int, max_size=6)
	
	for program ∈ iter
	    println(rulenode2expr(program, grammar))
	end
end

# ╔═╡ bb9d6664-b494-4aff-ba65-9c7ac2bf1116
md"""
### Uniform Solver

When the solver state of a Generic Solver becomes uniform (i.e., the tree structure is fixed and will not change further), it is converted into a Uniform Solver. The Uniform Solver is then used to explore all possible domain values that the uniform tree can take.

In contrast to the Generic Solver, the Uniform Solver does not generate additional SolverStates to add to the priority queue. Instead, it uses a specialized structure called SparseStateSet to define and manage the domains within its tree. This structure efficiently tracks domain changes and supports backtracking to previous states.

Additionally, when a Generic Solver transitions to a Uniform Solver, all constraints are regenerated specifically for the Uniform Solver. This means that any values previously stored in your constraints will not be copied over.


#### Propagation

The propagation process is identical between the Uniform Solver and the Generic Solver. However, since the Uniform Solver only operates on uniform nodes, it can infer more precise information about the tree.

Moreover, because each Uniform Solver maintains its own set of constraints, it can safely store information about the tree without conflicts with other tree structures, such as a node no longer existing at a specific path.



"""

# ╔═╡ b1f5a1fd-69a2-4d23-868f-96b551ea0236


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HerbConstraints = "1fa96474-3206-4513-b4fa-23913f296dfc"
HerbCore = "2b23ba43-8213-43cb-b5ea-38c12b45bd45"
HerbGrammar = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"
HerbSearch = "3008d8e8-f9aa-438a-92ed-26e9c7b4829f"

[compat]
HerbConstraints = "~0.2.4"
HerbCore = "~0.3.0"
HerbGrammar = "~0.5.0"
HerbSearch = "~0.4.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.2"
manifest_format = "2.0"
project_hash = "2cb4333ec6c631795a776e5362ad7f7eae695dd8"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.AutoHashEquals]]
git-tree-sha1 = "4ec6b48702dacc5994a835c1189831755e4e76ef"
uuid = "15f4f7f2-30c1-5605-9d31-71845cf9641f"
version = "2.2.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.HerbConstraints]]
deps = ["DataStructures", "HerbCore", "HerbGrammar", "MLStyle"]
git-tree-sha1 = "a89c7d2ef3283b8feb846822505722a0a0c50a91"
uuid = "1fa96474-3206-4513-b4fa-23913f296dfc"
version = "0.2.4"

[[deps.HerbCore]]
deps = ["AbstractTrees"]
git-tree-sha1 = "7af906201c6d701957b9d061c58940a28bfa4b83"
uuid = "2b23ba43-8213-43cb-b5ea-38c12b45bd45"
version = "0.3.4"

[[deps.HerbGrammar]]
deps = ["HerbCore", "Serialization"]
git-tree-sha1 = "3c667987e8a27d9b697993fab68dfc602b3a18e6"
uuid = "4ef9e186-2fe5-4b24-8de7-9f7291f24af7"
version = "0.5.0"

[[deps.HerbInterpret]]
deps = ["HerbCore", "HerbGrammar", "HerbSpecification"]
git-tree-sha1 = "6dd2913b88e0cbd0bc5ed78e67d4d406df61ddda"
uuid = "5bbddadd-02c5-4713-84b8-97364418cca7"
version = "0.1.6"

[[deps.HerbSearch]]
deps = ["DataStructures", "HerbConstraints", "HerbCore", "HerbGrammar", "HerbInterpret", "HerbSpecification", "MLStyle", "Random", "StatsBase"]
git-tree-sha1 = "95a5c1e87cd61b14cf9785f293e5633b39a69fc5"
uuid = "3008d8e8-f9aa-438a-92ed-26e9c7b4829f"
version = "0.4.1"

[[deps.HerbSpecification]]
deps = ["AutoHashEquals"]
git-tree-sha1 = "4a153a24694d4d91cf811d63581c9115087f06fc"
uuid = "6d54aada-062f-46d8-85cf-a1ceaf058a06"
version = "0.2.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.MLStyle]]
git-tree-sha1 = "bc38dff0548128765760c79eb7388a4b37fae2c8"
uuid = "d8e11817-5142-5d16-987a-aa16d5891078"
version = "0.4.17"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OrderedCollections]]
git-tree-sha1 = "12f1439c4f986bb868acda6ea33ebc78e19b95ad"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.7.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.PtrArrays]]
git-tree-sha1 = "1d36ef11a9aaf1e8b74dacc6a731dd1de8fd493d"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.3.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "29321314c920c26684834965ec2ce0dacc9cf8e5"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.4"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.7.0+0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"
"""

# ╔═╡ Cell order:
# ╟─c5509a19-43bc-44d3-baa9-9af83717b6e6
# ╟─864bc658-9612-4439-9024-74668ba3f971
# ╠═c5cb3782-c9af-4cf5-9e28-e1892c6442a2
# ╠═aacedef3-08d6-4bc0-a2c3-dd9a9aac340d
# ╟─1ff2dd58-01df-4cab-93d9-aabe1d07cc85
# ╠═62e41031-6866-46fc-b160-fb2f81f75c04
# ╟─76478bc7-e1b0-44f7-b1e0-95573db9f0e3
# ╠═4d94057f-0b69-4d7d-8bde-900e6eb3e53f
# ╟─1f0ba3c1-d160-44f5-85c4-4089cbd6f284
# ╠═030a150e-84ac-4aa6-9a08-5639538fb981
# ╟─4e1e76b3-b6b2-4a1d-a749-9226a283522d
# ╠═92eb7f60-88df-4212-a50b-b31bf386c720
# ╟─6c6becfb-1a7f-403a-9b04-6c4334c9f489
# ╠═ada60cc5-7aa1-41c4-828b-3d73c29fd087
# ╟─3f42462a-0be0-42bd-a428-a666769054dd
# ╠═4e76bb87-c429-4547-accc-e304d4220f2d
# ╟─00f62b26-a15d-4525-bef0-857d37bb0d85
# ╠═19d0a61b-46a3-4d53-b1d2-2b0e2650b56a
# ╟─2bea7a99-c46a-4200-9ba8-1227a5806f2f
# ╟─f4c15b60-5d45-4b75-9100-a7be2969d7ca
# ╠═b00b039b-63ee-40d0-8f4b-d25539e596d5
# ╟─bacc917b-2706-412d-9b85-deb4b6685323
# ╠═fef62621-716a-4f8a-85b4-d92e48b30bc6
# ╟─e40e09fc-c697-4c83-90eb-2b758254128e
# ╠═4e0989a8-7e63-45eb-80c9-a3a2f97c357c
# ╟─ce9ae2a2-f3e3-4693-9e6d-60e91128de34
# ╠═89c165c6-3e04-4887-924f-364b25b21bcd
# ╟─bb9d6664-b494-4aff-ba65-9c7ac2bf1116
# ╠═b1f5a1fd-69a2-4d23-868f-96b551ea0236
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
