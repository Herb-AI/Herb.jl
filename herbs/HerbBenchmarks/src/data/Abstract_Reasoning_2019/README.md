# Abstraction and Reasoning Corpus (ARC) 2019

A benchmark on ARC. ARC tasks are pairs of coloured input-output grids. The size of a grid vary from a single cell to 30 x 30 cells, with each cell having one of 10 possible values (colours).

The `Grid` contains:
- `width` of the grid.
- `height` of the grid.
- `data`: A two-dimensional matrix representing the grid. Grid cells can have values from 0 to 9.

Each `Problem` is a list of examples, with each example consisting of an input `Grid` and an output `Grid`.

For more information please, see the full description mentioned in the [ARC repo](https://github.com/fchollet/ARC/tree/master).


