@testitem "ARC 2019" begin
    import HerbBenchmarks.Abstract_Reasoning_2019 as ARC

    @testset "Abstract_Reasoning_2019" begin
        @testset "Initialize and resize grid" begin
            # Test Grid struct
            mat = [1 2 3; 4 5 6; 7 8 9]
            grid = ARC.Grid(mat)
            @test (grid.width, grid.height) == (3, 3)
            @test grid.data == mat

            # Test initialise grid state
            vec = collect(1:9)
            grid = ARC.initState(vec)
            @test (grid.width, grid.height) == (3, 3)
            @test grid.data == mat

            # Test array_to_matrix
            vec = collect(1:10)
            mat = ARC.array_to_matrix(vec)
            @test size(mat) == (3, 4)

            # Test initialise grid with zeros
            grid = ARC.init_grid(3, 3)
            @test (grid.width, grid.height) == (3, 3)
            @test all(grid.data .== 0)

            # Test resize grid
            mat = [0 1 0; 1 0 1; 1 1 1]
            grid = ARC.Grid(mat)
            # Make grid larger
            new_grid = ARC.resize_grid(grid, 5, 5)
            @test (new_grid.width, new_grid.height) == (5, 5)
            @test new_grid.data[1:3, 1:3] == mat
            @test all(new_grid.data[end-1:end, end-1:end] .== 0)
            # Shrink grid
            new_grid = ARC.resize_grid(grid, 2, 2)
            @test (new_grid.width, new_grid.height) == (2, 2)
            @test new_grid.data == mat[1:2, 1:2]
            # Keep grid the same size
            new_grid = ARC.resize_grid(grid, 3, 3)
            @test (new_grid.width, new_grid.height) == (3, 3)
            @test new_grid.data == mat
        end

        @testset "Clone, copy and reset grid" begin
            mat = [1 2 3; 4 5 6; 7 8 9]
            grid = ARC.Grid(mat)
            # Test clone grid
            new_grid = ARC.clone_grid(grid)
            @test (new_grid.width, new_grid.height) == (3, 3)
            @test new_grid.data == mat

            # Test copy from input
            # TODO: Why clone and copy_from_input?
            new_grid = ARC.copy_from_input(grid)
            @test (new_grid.width, new_grid.height) == (3, 3)
            @test new_grid.data == mat

            # Test reset grid to zeros
            new_grid = ARC.reset_grid(grid)
            @test (new_grid.width, new_grid.height) == (3, 3)
            @test all(new_grid.data .== 0)
        end

        @testset "Manipulate cells" begin
            @testset "Select cells" begin
                mat = [1 2 3; 4 5 6; 7 8 9]
                grid = ARC.Grid(mat)
                another_grid = ARC.init_grid(5, 5)

                # Test set cell value 
                new_grid = ARC.set_cell(grid, 3, 3, 0)
                @test new_grid.data[end, end] == 0
                @test_throws BoundsError ARC.set_cell(grid, 4, 3, 0)

                # Test select  
                start_row, start_col, end_row, end_col = 1, 1, 2, 2
                selected_cells = ARC.select(grid, start_row, start_col, end_row, end_col)
                @test selected_cells == [(1, 1), (1, 2), (2, 1), (2, 2)]
                # ... with invalid start and end values
                start_row, start_col, end_row, end_col = 2, 2, 1, 1
                selected_cells = ARC.select(grid, start_row, start_col, end_row, end_col)
                @test selected_cells == []
                # ... with out of bounds end values
                start_row, start_col, end_row, end_col = 1, 1, 4, 4
                selected_cells = ARC.select(grid, start_row, start_col, end_row, end_col)
                @test selected_cells == [(1, 1), (1, 2), (1, 3), (2, 1), (2, 2), (2, 3), (3, 1), (3, 2), (3, 3)]
            end
            @testset "Select and paste cells" begin
                # Test case: same input and target grid
                mat = [1 2 3; 4 5 6; 7 8 9]
                grid_1 = ARC.Grid(mat)
                start_row, start_col, end_row, end_col = 3, 1, 3, 3
                paste_row, paste_col = 1, 1
                new_grid = ARC.select_and_paste(grid_1, start_row, start_col, end_row, end_col, paste_row, paste_col)
                @test new_grid.data == [7 8 9; 4 5 6; 7 8 9]
                # ... on a bigger grid
                mat = Matrix{Int}(transpose(reshape(Int.(1:100), 10, 10)))
                grid_2 = ARC.Grid(mat)
                expected_data = copy(mat)
                expected_data[10, 8:10] = (12:14)
                start_row, start_col, end_row, end_col = 2, 2, 2, 4
                paste_row, paste_col = 10, 8
                new_grid = ARC.select_and_paste(grid_2, start_row, start_col, end_row, end_col, paste_row, paste_col)
                @test new_grid.data == expected_data
                # ... errors when paste indices out of bounds 
                start_row, start_col, end_row, end_col = 2, 2, 2, 4
                paste_row, paste_col = 10, 9
                @test_throws BoundsError ARC.select_and_paste(grid_2, start_row, start_col, end_row, end_col, paste_row, paste_col)

                # Test case: different input and target grid
                grid_3 = ARC.Grid(zeros(Int, 3, 3))
                expected_data = copy(mat)
                expected_data[4:6, 3:5] .= 0
                start_row, start_col, end_row, end_col = 1, 1, 3, 3
                paste_row, paste_col = 4, 3
                new_grid = ARC.select_and_paste(grid_3, start_row, start_col, end_row, end_col, grid_2, paste_row, paste_col)
                @test new_grid.data == expected_data
                # ... errors when paste indices out of bounds
                start_row, start_col, end_row, end_col = 1, 1, 3, 3
                paste_row, paste_col = 10, 8
                @test_throws BoundsError ARC.select_and_paste(grid_3, start_row, start_col, end_row, end_col, grid_2, paste_row, paste_col)
            end
            @testset "flood fill cells" begin
                mat = [0 2 9 0; 2 2 1 3; 2 0 7 2; 2 2 2 5]
                # [0 2 9 0]
                # [2 2 1 3]
                # [2 0 7 2]
                [2 2 2 5]

                grid = ARC.Grid(mat)
                row, col = 2, 2
                color = 4
                expected_data = [0 4 9 0; 4 4 1 3; 4 0 7 2; 4 4 4 5]
                new_grid = ARC.floodfill(grid, row, col, color)
                @test new_grid.data == expected_data
                # no connected cells
                row, col = 1, 1
                color = 4
                expected_data = [4 2 9 0; 2 2 1 3; 2 0 7 2; 2 2 2 5]
                new_grid = ARC.floodfill(grid, row, col, color)
                @test new_grid.data == expected_data
            end
        end
    end
end
