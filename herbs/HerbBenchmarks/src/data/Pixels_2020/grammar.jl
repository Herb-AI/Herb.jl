grammar_pixels = @cfgrammar begin
    Start = Sequence

    Sequence = Operation
    Sequence = (Operation; Sequence)
    Operation = Transformation
    Operation = ControlStatement

    Transformation = moveRight() | moveLeft() | moveUp() | moveDown() | draw0() | draw1() # 6
    ControlStatement = IF(Condition, Sequence, Sequence) # 12
    ControlStatement = WHILE(Condition, Sequence)

    Condition = atTop() | atBottom() | atLeft() | atRight() | notAtTop() | notAtBottom() | notAtLeft() | notAtRight()
end
