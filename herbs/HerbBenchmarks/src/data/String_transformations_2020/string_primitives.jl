using MLStyle

"""
Represents the state of a string, including a pointer to a specific position within the string.
"""
struct StringState
    str::String
    pointer::Union{Int,Nothing}
end

# Initialize the pointer to 1 (not 0, since Julia is 1-indexed)
StringState(s::String) = StringState(s, 1)

Base.length(st::StringState) = length(st.str)
function moveRight(state)
    StringState(state.str, min(state.pointer + 1, length(state.str)))
end
function moveLeft(state)
    StringState(state.str, max(state.pointer - 1, 1))
end
function makeUppercase(state)
    StringState(state.str[1:state.pointer-1] * uppercase(state.str[state.pointer]) * state.str[state.pointer+1:end], state.pointer)
end
function makeLowercase(state)
    StringState(state.str[1:state.pointer-1] * lowercase(state.str[state.pointer]) * state.str[state.pointer+1:end], state.pointer)
end
function drop(state)
    state.pointer < length(state.str) ? StringState(state.str[1:state.pointer-1] * state.str[state.pointer+1:end], state.pointer) : StringState(state.str[1:state.pointer-1] * state.str[state.pointer+1:end], state.pointer - 1)
end
function atEnd(state)
    state.pointer == length(state.str)
end
function notAtEnd(state)
    !atEnd(state)
end
function atStart(state)
    state.pointer == 1
end
function notAtStart(state)
    !atStart(state)
end
function isLetter(state)
    state.pointer <= length(state.str) && isletter(state.str[state.pointer])
end
function isNotLetter(state)
    !isLetter(state)
end
function isUppercase(state)
    state.pointer <= length(state.str) && isuppercase(state.str[state.pointer])
end
function isNotUppercase(state)
    !isUppercase(state)
end
isLowercase(state) = state.pointer <= length(state.str) && islowercase(state.str[state.pointer])
function isNotLowercase(state)
    !isLowercase(state)
end
function isNumber(state)
    state.pointer <= length(state.str) && isdigit(state.str[state.pointer])
end
function isNotNumber(state)
    !isNumber(state)
end
function isSpace(state)
    state.pointer <= length(state.str) && isspace(state.str[state.pointer])
end
function isNotSpace(state)
    !isSpace(state)
end

# Two instances of StringState are equal if their strings are equal and at least one of the pointers is nothing
Base.:(==)(a::StringState, b::StringState) = a.str == b.str && (a.pointer == b.pointer || a.pointer === nothing || b.pointer === nothing)
