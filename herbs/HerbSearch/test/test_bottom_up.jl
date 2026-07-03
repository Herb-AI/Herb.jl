using Test
using DataStructures: DefaultDict, PriorityQueue, FasterForward, enqueue!
import HerbSearch: init_combine_structure
import HerbSearch: _hash_outputs_to_u64vec

grammars_to_test = Dict(
    "arity <= 1" => (@csgrammar begin
        Int = 1 | 2
        Int = 3 + Int
    end),
    "arity <= 3" => (@csgrammar begin
        Int = 1
        Int = Int + Int
        Int = f(Int, Int, Int)
    end),
    "multiple types" => (@csgrammar begin
        Int = 1 | 2
        Int = Int + Int
        Char = 'a' | 'b'
        String = Char * Char
        Int = length(String)
        Int = Int * Int
    end)
)

# helper
test_with_grammars(f, grammars) = (for (name, g) in grammars; @testset "$name" f(g); end)

general_iterator_factories = Dict(
    "SizeBased"  => (g; kwargs...) -> SizeBasedBottomUpIterator(g, :Int; kwargs...),
    "DepthBased" => (g; kwargs...) -> DepthBasedBottomUpIterator(g, :Int; kwargs...),
    "CostBased"  => (g; kwargs...) -> begin
        g2 = isprobabilistic(g) ? g : init_probabilities!(g)
        costs = HerbSearch.get_costs(g2)
        CostBasedBottomUpIterator(g2, :Int; current_costs=costs, kwargs...)
    end
)

# Use these for non-cost-specific tests (step-by-step, terminals-first, etc.)
structural_iterator_factories = Dict(
    "SizeBased"  => (g; kwargs...) -> SizeBasedBottomUpIterator(g, :Int; kwargs...),
    "DepthBased" => (g; kwargs...) -> DepthBasedBottomUpIterator(g, :Int; kwargs...)
)

# Cost-only variants (control max_cost explicitly in the tests)
cost_iterator_factory = Dict(
    "CostBased"  => (g; kwargs...) -> begin
        g2 = isprobabilistic(g) ? g : init_probabilities!(g)
        costs = HerbSearch.get_costs(g2)
        CostBasedBottomUpIterator(g, :Int; current_costs=costs, kwargs...)
    end
)

# Observational equivalence utils:
run_prog_factory(g) = function (program::AbstractRuleNode)
    res = eval(rulenode2expr(program, g))
    # repeat outputs to simulate multiple inputs.
    return [res, res]
end

# Hash the concrete outputs produced
hashed_outputs(g, prog::AbstractRuleNode) = begin
    outs = run_prog_factory(g)(prog)
    _hash_outputs_to_u64vec(outs)  # ::Vector{UInt64}
end

# Collect unique hashed output vectors from an iterator
collect_hashed_outputs(g, iter) = begin
    sigs = Set{Vector{UInt64}}()
    for p in iter
        push!(sigs, hashed_outputs(g, p))
    end
    sigs
end

@testset verbose=true "Bottom-Up Search" begin
@testset "Generic Bottom-Up Search Test" begin
    for (iter_name, make_iter) in general_iterator_factories
        @testset "$iter_name" begin
            @testset "Compare to DFS (same max_depth / max_size)" begin
                test_with_grammars(grammars_to_test) do g
                    for max_depth in 2:4
                        iter_bu  = make_iter(g; max_depth=max_depth)
                        iter_dfs = DFSIterator(g, :Int; max_depth=max_depth)
                        bu  = [freeze_state(p) for p in iter_bu]
                        dfs = [freeze_state(p) for p in iter_dfs]
                        @testset "max_depth=$max_depth" begin
                            @test issetequal(bu, dfs)
                            @test length(bu) == length(dfs)
                        end
                    end

                    for size in 2:4
                        iter_bu  = make_iter(g; max_size=size)
                        iter_dfs = DFSIterator(g, :Int; max_size=size)
                        bu  = [freeze_state(p) for p in iter_bu]
                        dfs = [freeze_state(p) for p in iter_dfs]
                        @testset "max_size=$size" begin
                            @test issetequal(bu, dfs)
                            @test length(bu) == length(dfs)
                        end
                    end
                end
            end

            @testset "Rooted correctly/No Duplicates" begin
                test_with_grammars(grammars_to_test) do g
                    iter = make_iter(g; max_depth=3, max_size=6)
                    progs = [freeze_state(p) for p in iter]
                    @test all(g.types[get_rule(pf)] == :Int for pf in progs)
                    @test length(Set(progs)) == length(progs)
                end
            end

            @testset "Respect structural limits (max_depth / max_size)" begin
                test_with_grammars(grammars_to_test) do g
                    for max_depth in 1:4
                        iter = make_iter(g; max_depth=max_depth, max_size=2*max_depth)
                        progs = [freeze_state(p) for p in iter]
                        @test all(depth(p) ≤ get_max_depth(iter) for p in progs) 
                        @test all(length(p) ≤ get_max_size(iter) for p in progs)
                    end
                end
            end

            @testset "Monotone measure" begin
                test_with_grammars(grammars_to_test) do g
                    max_depth = 3
                    iter_bu = make_iter(g; max_depth=max_depth, max_size=max_depth*2)

                    measures = [HerbSearch.calc_measure(iter_bu, p) for p in iter_bu]

                    @test all(measures[i] <= measures[i+1] for i in 1:length(measures)-1)
                end
            end

            @testset "Constraint checking" begin
                @testset "Search respects Forbidden" begin
                    g = (@csgrammar begin
                        Int = 1 | 2
                        Int = Int + Int
                    end)

                    # We forbid the binary '+' with identical children: RuleNode(3, [a, a])
                    forbidden_plus_same = Forbidden(RuleNode(3, [VarNode(:a), VarNode(:a)]))
                    HerbConstraints.addconstraint!(g, forbidden_plus_same)

                    iter = make_iter(g; max_depth=3, max_size=5)
                    progs = [freeze_state(p) for p in iter]
                    @test all(check_tree(forbidden_plus_same, p) for p in progs)
                end
            end
        end
    end
end

@testset "Structural Bottom-Up Search (Size/Depth only)" begin
    for (iter_name, make_iter) in structural_iterator_factories
        @testset "$iter_name" begin
            @testset "basic sanity" begin
                g = grammars_to_test["multiple types"]
                iter = make_iter(g; max_depth=3, max_size=6)
                expected_programs = [
                    (@rulenode 1),
                    (@rulenode 2),
                    (@rulenode 3{1,1}),
                    (@rulenode 3{2,1}),
                    (@rulenode 3{1,2}),
                    (@rulenode 3{2,2})
                ]
                progs = [freeze_state(p) for (i, p) in enumerate(iter) if i ≤ 6]
                @test issetequal(progs, expected_programs)
                @test length(expected_programs) == length(progs)
            end

            @testset "populate_bank! returns exactly one terminal per type" begin
                test_with_grammars(grammars_to_test) do g
                    iter = make_iter(g; max_depth=3, max_size=3)
                    initial_addresses = populate_bank!(iter)
                    num_uniform_trees_terminals = length(unique(g.types[g.isterminal]))
                    @test length(initial_addresses) == num_uniform_trees_terminals
                end
            end

            @testset "iterate all terminals first" begin
                test_with_grammars(grammars_to_test) do g
                    iter = make_iter(g; max_depth=3, max_size=4)
                    expected_programs = RuleNode.(findall(g.isterminal .& (g.types .== (:Int))))
                    progs = [freeze_state(p) for (i, p) in enumerate(iter) if length(p) == 1]
                    @test issetequal(progs, expected_programs)
                    @test length(expected_programs) == length(progs)
                end
            end

            @testset "combine produces work after seed" begin
                test_with_grammars(grammars_to_test) do g
                    iter = make_iter(g; max_depth=4, max_size=8)
                    solver = get_solver(iter)
                    addrs = populate_bank!(iter)
                    starting_node = deepcopy(get_tree(solver))

                    pq = PriorityQueue{AbstractAddress, Number}(FasterForward())
                    for acc in addrs
                        push!(pq, acc => HerbSearch.get_measure(acc))
                    end

                    state = GenericBUState(pq, init_combine_structure(iter), nothing, starting_node, -Inf, 0)

                    combinations, state = combine(iter, state)
                    @test !isempty(combinations)
                end
            end

            @testset "duplicates not added to bank" begin
                all_progs(bank) = (p for t in HerbSearch.get_types(bank)
                                     for m in HerbSearch.get_measures(bank, t)
                                     for p in HerbSearch.get_programs(bank, t, m))
                test_with_grammars(grammars_to_test) do g
                    iter = make_iter(g; max_depth=3, max_size=4)
                    length(iter)
                    bank = get_bank(iter)
                    @test allunique(all_progs(bank))
                end
            end
        end
    end
end

@testset "Cost-Based Bottom-Up Search" begin
    for (iter_name, make_iter) in cost_iterator_factory
        @testset "$iter_name" begin
            @testset "populate_bank! seeds and yields terminals in first horizon" begin
                test_with_grammars(grammars_to_test) do g
                    iter = make_iter(g; max_depth=3, max_cost=1e6)
                    addrs = populate_bank!(iter)
                    # Expect at least some terminals within the first horizon
                    @test !isempty(addrs)

                    pq = PriorityQueue{AbstractAddress, Number}(FasterForward())
                    for acc in addrs
                        push!(pq, acc => HerbSearch.get_measure(acc))
                    end

                    progs = [retrieve(iter, addr) for (addr, prio) in pq]
                    
                    @test all(length(p) == 1 for p in progs)
                end
            end

            @testset "max_cost prunes results (small cap)" begin
                test_with_grammars(grammars_to_test) do g
                    # Use a tiny max_cost; expect either empty or only the cheapest terminals
                    iter = make_iter(g; max_depth=3, max_cost=1.0)
                    # Enumerate a handful
                    measures = [HerbSearch.calc_measure(iter, p) for p in iter]

                    @test all(m<= get_measure_limit(iter) for m in measures)
                end
            end

            @testset "works with probabilities (init_probabilities!)" begin
                test_with_grammars(grammars_to_test) do g
                    # Use the factory: it already calls maybe_init_probabilities!
                    iter = make_iter(g; max_depth=3, max_cost=1e6)
                    # Just smoke test a few solutions
                    progs = [freeze_state(p) for (i, p) in enumerate(iter) if i ≤ 10]
                    @test !isempty(progs)
                    @test all(g.types[get_rule(pf)] == :Int for pf in progs)
                end
            end

            @testset "observational equivalence (DFS vs Cost-Based)" begin
                # Keep this on a single small grammar to limit runtime.
                g = grammars_to_test["multiple types"]
                max_size = 5

                # DFS baseline: collect hashed outputs of all programs up to max_size
                dfs_iter = DFSIterator(g, :Int; max_size=max_size)
                dfs_sigs = collect_hashed_outputs(g, dfs_iter)

                # Cost-based: same evaluator so outputs are identical
                costs = HerbSearch.get_costs(g)
                cb_iter = CostBasedBottomUpIterator(
                    g, :Int;
                    max_size=max_size,
                    current_costs=costs,
                    program_to_outputs=run_prog_factory(g),
                )
                cb_sigs = collect_hashed_outputs(g, cb_iter)

                @test issetequal(dfs_sigs, cb_sigs)
            end
        end
    end
end
end