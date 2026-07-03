grammar_string = @cfgrammar begin
    Start = Sequence        #1

    Sequence = Operation        #2
    Sequence = (Operation; Sequence)  #3
    Operation = Transformation      #4
    Operation = ControlStatement    #5

    Transformation = moveRight() | moveLeft() | makeUppercase() | makeLowercase() | drop()      #6
    ControlStatement = IF(Condition, Sequence, Sequence)    #11
    ControlStatement = WHILE(Condition, Sequence)       #12

    Condition = atEnd() | notAtEnd() | atStart() | notAtStart() | isLetter() | isNotLetter() | isUppercase() | isNotUppercase() | isLowercase() | isNotLowercase() | isNumber() | isNotNumber() | isSpace() | isNotSpace()
end
