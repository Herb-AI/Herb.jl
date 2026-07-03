DivideAndConquerExt = Base.get_extension(HerbSearch, :DivideAndConquerExt)
using .DivideAndConquerExt: divide_and_conquer

# Example problem, grammar bit functions taken from HerbBenchmarks: src/data/SyGuS/PBE_BV_Track_2018
# 
# HerbBenchmarks.jl is not a released package yet and can't be included as dependency
# in test/Project.toml.
# Hence, relevant definitions and functionality is hardcoded.
# 
grammar = @cfgrammar begin
	Start = 0x0000000000000000
	Start = 0x0000000000000001
	Start = Input
	Input = _arg_1
	Start = Bool
	Bool = bvugt_cvc(Start, Start) # n1 > n2
	Bool = bveq1_cvc(Start) # n == 1
	Start = bvnot_cvc(Start)
	Start = smol_cvc(Start)
	Start = ehad_cvc(Start)
	Start = arba_cvc(Start)
	Start = shesh_cvc(Start)
	Start = bvand_cvc(Start, Start)
	Start = bvor_cvc(Start, Start)
	Start = bvxor_cvc(Start, Start)
	Start = bvadd_cvc(Start, Start)
	Start = im_cvc(Start, Start, Start) # if-else statement
end

# from HerbBenchmarks: src/data/SyGuS/PBE_BV_Track_2018/bit_functions.jl
# Defined in SMT-LIB

bvneg_cvc(n::UInt) = -n
bvnot_cvc(n::UInt) = ~n
bvadd_cvc(n1::UInt, n2::UInt) = n1 + n2
bvsub_cvc(n1::UInt, n2::UInt) = n1 - n2
bvxor_cvc(n1::UInt, n2::UInt) = n1 ⊻ n2 #xor
bvand_cvc(n1::UInt, n2::UInt) = n1 & n2
bvor_cvc(n1::UInt, n2::UInt) = n1 | n2
bvshl_cvc(n1::UInt, n2::Int) = n1 << n2
bvlshr_cvc(n1::UInt, n2::Int) = n1 >>> n2
bvashr_cvc(n1::UInt, n2::Int) = n1 >> n2
bvnand_cvc(n1::UInt, n2::UInt) = n1 ⊼ n2 #nand
bvnor_cvc(n1::UInt, n2::UInt) = n1 ⊽ n2 #nor

# additional bitoperations for modified grammar
bvugt_cvc(n1::UInt, n2::UInt) = n1 > n2 ? UInt(1) : UInt(0) # returns whether n1 > n2
bveq1_cvc(n::UInt) = n == UInt(1) ? UInt(1) : UInt(0)

problem = Problem(
	"problem_PRE_100_10",
	[
		IOExample(Dict{Symbol, Any}(:_arg_1 => 0xb3cac86be739e234), 0xb3cac86be739e236),
		IOExample(Dict{Symbol, Any}(:_arg_1 => 0x51a9d52072e4b62d), 0x000051a9d52072e5),
		IOExample(Dict{Symbol, Any}(:_arg_1 => 0x2130169dedcdee86), 0x2130169dedcdee88),
		IOExample(Dict{Symbol, Any}(:_arg_1 => 0x990de8de31db2e84), 0x990de8de31db2e86),
		IOExample(Dict{Symbol, Any}(:_arg_1 => 0x58e5b9739d2daea6), 0x58e5b9739d2daea8),
		IOExample(Dict{Symbol, Any}(:_arg_1 => 0x42952532650e6962), 0x42952532650e6964),
		IOExample(Dict{Symbol, Any}(:_arg_1 => 0xcc69c62112c1d09e), 0xcc69c62112c1d0a0),
		IOExample(Dict{Symbol, Any}(:_arg_1 => 0x210a64857152e648), 0x210a64857152e64a),
		IOExample(Dict{Symbol, Any}(:_arg_1 => 0xce111bea931328d4), 0xce111bea931328d6),
		IOExample(Dict{Symbol, Any}(:_arg_1 => 0xbeb187cd6ed5b4bd), 0x0000beb187cd6ed6)],
)

# CUSTOM functions

ehad_cvc(n::UInt) = bvlshr_cvc(n, 1)
arba_cvc(n::UInt) = bvlshr_cvc(n, 4)
shesh_cvc(n::UInt) = bvlshr_cvc(n, 16)
smol_cvc(n::UInt) = bvshl_cvc(n, 1)
im_cvc(x::UInt, y::UInt, z::UInt) = x == UInt(1) ? y : z
if0_cvc(x::UInt, y::UInt, z::UInt) = x == UInt(0) ? y : z

@testset verbose = true "Benchmark BV example for divide and conquer" begin
	# input arguments
	n_predicates = 5
	sym_bool = :Bool
	sym_start = :Start
	sym_constraint = :Input
	max_enumerations = 10

	iterator = BFSIterator(grammar, :Start)
	idx_ifelse = findfirst(r -> r == :($sym_bool ? $sym_start : $sym_start), grammar.rules)
	@test_throws DivideAndConquerExt.ConditionalIfElseError divide_and_conquer(
		problem,
		iterator,
		sym_bool,
		sym_start,
		sym_constraint,
		n_predicates,
		max_enumerations,
	)

	# add if-else rule to grammar
	add_rule!(grammar, :($sym_start = $sym_bool ? $sym_start : $sym_start))
	iterator = BFSIterator(grammar, :Start)

	final_program = divide_and_conquer(
		problem,
		iterator,
		sym_bool,
		sym_start,
		sym_constraint,
		n_predicates,
		max_enumerations,
	)
end

