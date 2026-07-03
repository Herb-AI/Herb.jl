base_grammar_deepcoder = @csgrammar begin
    Int = |(-3:3)

    ExprNum = Int

    ExprNum = maximum(ExprArr)              := (length(x1) > 1, maximum(y) == maximum(x1), minimum(y) > minimum(x1))
    ExprNum = minimum(ExprArr)              := (length(x1) > 1, maximum(y) < maximum(x1), minimum(y) == minimum(x1))
    ExprNum = sum(ExprArr)                  := (length(x1) > 1)
    ExprNum = first(ExprArr)                := (length(x1) > 1, maximum(y) <= maximum(x1), minimum(y) >= minimum(x1), first(y) == first(x1), last(y) == first(x1))
    ExprNum = last(ExprArr)                 := (length(x1) > 1, maximum(y) <= maximum(x1), minimum(y) >= minimum(x1), first(y) == last(x1), last(y) == last(x1))
    ExprNum = getindex(ExprArr, ExprNum)    := (length(x1) > 1, maximum(y) <= maximum(x1), minimum(y) >= minimum(x1), first(x2) > 0, length(x1) > first(x2))

    ExprNum = countSt(ExprArr, Int)         := (length(x1) > 1, last(y) <= length(x1), last(y) >= 0)
    ExprNum = countGt(ExprArr, Int)         := (length(x1) > 1, last(y) <= length(x1), last(y) >= 0)
    ExprNum = countEq(ExprArr, Int)         := (length(x1) > 1, last(y) <= length(x1), last(y) >= 0)
    ExprNum = countNeq(ExprArr, Int)        := (length(x1) > 1, last(y) <= length(x1), last(y) >= 0)
    ExprNum = countMod(ExprArr, Int)        := (length(x1) > 1, last(y) <= length(x1), last(y) >= 0)
    ExprNum = countNmod(ExprArr, Int)       := (length(x1) > 1, last(y) <= length(x1), last(y) >= 0)

    ExprArr = drop(ExprArr, ExprNum)        := (length(y) < length(x1), maximum(y) <= maximum(x1), minimum(y) >= minimum(x1), last(y) == last(x1), first(x2) > 0, length(x1) > maximum(x2))
    ExprArr = take(ExprArr, ExprNum)        := (length(y) < length(x1), maximum(y) <= maximum(x1), minimum(y) >= minimum(x1), first(y) == first(x1), first(x2) > 0, length(x1) > maximum(x2))
    ExprArr = sort(ExprArr)                 := (length(y) == length(x1), maximum(y) == maximum(x1), minimum(y) == minimum(x1), first(y) == minimum(x1), last(y) == maximum(x1))
    ExprArr = reverse(ExprArr)              := (length(y) == length(x1), maximum(y) == maximum(x1), minimum(y) == minimum(x1), first(y) == last(x1), last(y) == first(x1))

    ExprArr = filterSt(ExprArr, Int)        := (length(y) < length(x1), maximum(y) <= maximum(x1), minimum(y) >= minimum(x1))
    ExprArr = filterGt(ExprArr, Int)        := (length(y) < length(x1), maximum(y) <= maximum(x1), minimum(y) >= minimum(x1))
    ExprArr = filterEq(ExprArr, Int)        := (length(y) < length(x1), maximum(y) <= maximum(x1), minimum(y) >= minimum(x1))
    ExprArr = filterNeq(ExprArr, Int)       := (length(y) < length(x1), maximum(y) <= maximum(x1), minimum(y) >= minimum(x1))
    ExprArr = filterMod(ExprArr, Int)       := (length(y) < length(x1), maximum(y) <= maximum(x1), minimum(y) >= minimum(x1))
    ExprArr = filterNmod(ExprArr, Int)      := (length(y) < length(x1), maximum(y) <= maximum(x1), minimum(y) >= minimum(x1))

    ExprArr = mapPlus(ExprArr, Int)         := (length(y) == length(x1))
    ExprArr = mapMult(ExprArr, Int)         := (length(y) == length(x1))
    ExprArr = mapDiv(ExprArr, Int)          := (length(y) == length(x1))
    ExprArr = mapPow(ExprArr, Int)          := (length(y) == length(x1))

    ExprArr = zipwithMax(ExprArr, ExprArr)      := (length(y) == length(x1), length(y) == length(x2))
    ExprArr = zipwithMin(ExprArr, ExprArr)      := (length(y) == length(x1), length(y) == length(x2))
    ExprArr = zipwithPlus(ExprArr, ExprArr)     := (length(y) == length(x1), length(y) == length(x2))
    ExprArr = zipwithMinus(ExprArr, ExprArr)    := (length(y) == length(x1), length(y) == length(x2))
    ExprArr = zipwithMult(ExprArr, ExprArr)     := (length(y) == length(x1), length(y) == length(x2))

    ExprArr = scanl1Plus(ExprArr)           := (length(y) == length(x1), first(y) == first(x1))
    ExprArr = scanl1Minus(ExprArr)          := (length(y) == length(x1), first(y) == first(x1))
    ExprArr = scanl1Mult(ExprArr)           := (length(y) == length(x1), first(y) == first(x1))
    ExprArr = scanl1Max(ExprArr)            := (length(y) == length(x1), first(y) == first(x1), maximum(y) == maximum(x1), minimum(y) >= minimum(x1), last(y) == maximum(x1))
    ExprArr = scanl1Min(ExprArr)            := (length(y) == length(x1), first(y) == first(x1), maximum(y) <= maximum(x1), minimum(y) == minimum(x1), last(y) == minimum(x1))
end