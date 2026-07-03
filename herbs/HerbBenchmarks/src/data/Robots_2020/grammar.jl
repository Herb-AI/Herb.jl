grammar_robots = @csgrammar begin
    Start = Sequence                   #1

    Sequence = Operation                #2
    Sequence = (Operation; Sequence)    #3
    Operation = Transformation          #4
    Operation = ControlStatement        #5

    Transformation = moveRight() | moveDown() | moveLeft() | moveUp() | drop() | grab()     #6
    ControlStatement = IF(Condition, Sequence, Sequence)        #12
    ControlStatement = WHILE(Condition, Sequence)               #13

    Condition = atTop() | atBottom() | atLeft() | atRight() | notAtTop() | notAtBottom() | notAtLeft() | notAtRight()      #14
end
