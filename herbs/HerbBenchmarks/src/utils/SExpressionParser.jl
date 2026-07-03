"""
A barebones (S-Expression)[https://en.wikipedia.org/wiki/S-expression] parser
used for parsing benchmark files into `Herb`-compatible forms. Inspired by
the https://github.com/TotalVerb/SExpressions.jl/. We've created our own version
here because compat bounds from the old project are causing issues here, and it
is not currently receiving updates.
"""
module SExpressionParser
using ParserCombinator

struct Nil end

struct Cons
    car
    cdr
end

List = Union{Nil, Cons}

car(c) = c.car
cdr(c) = c.cdr
isnil(::Nil) = true
isnil(::Cons) = false

Base.length(::Nil) = 0
Base.length(α::Cons) = 1 + length(cdr(α))
Base.iterate(α::List, β=α) = isnil(β) ? nothing : (car(β), cdr(β))
Base.getindex(α::Cons, b) = b == 1 ? car(α) : getindex(cdr(α), b - 1)
Base.getindex(α::Cons, b::UnitRange) = Base.getindex.((α,), b)
Base.getindex(α::Nil, b) = throw(BoundsError(α, b))
Base.lastindex(α::Cons) = length(α)
Base.lastindex(α::Nil) = throw(BoundsError(α, 0))
Base.firstindex(α::Cons) = 1
Base.firstindex(α::Nil) = throw(BoundsError(α, 0))

function cons_or_nil(items)
	peeled = Iterators.peel(items)
	if isnothing(peeled)
		return Nil()
	end

	car, cdr = peeled
	cdr = collect(cdr)

	if isempty(cdr)
		return Cons(car, Nil())
	end

	return Cons(car, cons_or_nil(cdr))
end

"""
    function create_sexpressions_parser(; debug=false)

Create a `ParserCombinator` parser for S-Expressions.
"""
function create_sexpressions_parser(; debug=false)
    @with_names begin
		# match and discard 0 or more space characters
		spc = Alt(Star(Drop(Space())), Drop(Pattern(r"\n")))
		# match and discard a '(' followed by 0 or more spaces
		open = Drop(Seq(Equal("("), spc))
		# match and discard 0 or more spaces followed by a ')'
		close = Drop(Seq(spc, Equal(")")))
		# match a word, including '-', '_' characters allowed
		symbol = Pattern(r"[=#\.\+\_\w-]+")
        # match an opening and closing quote pair, possibly with characters inside
		open_quote = Drop(Pattern(r"\""))
		close_quote = Drop(Pattern(r"\""))
		quoted_string = Seq(open_quote, Star(Pattern(r"([^\"])+")), close_quote)
        # match either a symbol or quoted `string_item`
        # Use `App` to turn symbols into a `Symbol` and `string_item` into a `String`
        # can be followed by 0 or more spaces
		symbol_or_string = Seq(Alt(App(symbol, Symbol), App(quoted_string, string)), spc)
		
		# since the S-Expressions are nested, the cons pattern has to have a delayed
		# initialization, so that it can reference itself
		cons = Delayed()
		# an item can be a symbol or another nested cons
		item = Alt(symbol_or_string, Seq(cons, spc))

		# top level opening and closing parentheses
		# the `item[0:end] |> Cons` takes all of the `items` matched and passes the
		# list of them to the `Cons` struct's constructor
        # note the recurive `item` inside `cons`' matcher (which possibly matches `cons`)
		cons.matcher = Seq(open, (Star(item) |> cons_or_nil), close)

        # ignore empty lines
		line_end = Drop(Star(Alt(Pattern(r"\r"), Pattern(r"\n"))))
		line = Repeat(Seq(cons, line_end)) |> cons_or_nil
	end

    return debug ? Trace(line) : line
end

"""
    function parsefile(filename; debug=false)

Read `filename` and parse the (S-Expression)[https://en.wikipedia.org/wiki/S-expression]s from it.
"""
function parsefile(filename; debug=false)
    parsefile(create_sexpressions_parser, filename; debug)
end

function parsefile(parser_fn, filename; debug=false)
    only((debug ? parse_dbg : parse_one)(strip(read(filename, String)), parser_fn(; debug)))
end
end
