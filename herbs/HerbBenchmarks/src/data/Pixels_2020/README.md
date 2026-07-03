# Pixels

In the pixels dataset, 
every problem has a single example. The input is a blank canvas, represented by a 2d grid with boolean values.
The output is a drawing of (a combination of) ASCII characters on the same size grid.

The pixels data set contains problems on learning to draw ASCII art on a canvas.
A `PixelState` has the fields:
- `matrix`: a two-dimensional grid of boolean values to represent the canvas.
- `position`: A tuple (x, y) representing a cursor that points to the current position in the grid. 

Each problem is represented by one input-output example. The input is a `PixelState` with a blank canvas (matrix of zeros) and the cursor pointing to the top left position of the canvas. The output is a `PixelState` with a drawing of ASCII characters. The canvas size is the same for input and output. 

See
> Cropper, Andrew, and Sebastijan Dumančić. "Learning large logic programs by going beyond entailment." arXiv preprint arXiv:2004.09855 (2020).
