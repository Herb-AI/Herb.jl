global const runs::Int16 = 1000

function test_is_true_on_percentage(function_call::Function, percentage::Real)
    count = 0
    for _ in 1:runs
        outcome = function_call()
        if outcome 
            count = count + 1
        end
    end
    @test count >= (percentage - 0.2) * runs 
end

@testset "Accept function" begin
parametrized_test(
    [
        [1, 1, 0.5],
        [1, 3, 0.25],
        [1, 9, 0.1],
        [10, 1, 1]
    ],
    function probabilistic_accept_on_percentage(current_cost, next_cost, percentage)
        test_is_true_on_percentage(() -> HerbSearch.probabilistic_accept(current_cost, next_cost, 0), percentage)
    end
)



parametrized_test(
    [   
        # (current_cost, next_cost, temperature, percentage)
        # temperature equal to 1
        [1, 1,  1, 0.5],
        [1, 3,  1, 0.25],
        [1, 9,  1, 0.1],
        [10, 1, 1, 1],
        # temperature not 1
        [4, 2, 5, 1],
        [4, 5, 9, 1],
        [4, 5, 3, 0.3],
        [4, 5, 0, 0],
        [4, 5, 0.1, 1/9 * 0.1]
    ],
    function probabilistic_accept_with_temperature(current_cost, next_cost, temperature, percentage)
        test_is_true_on_percentage(() -> HerbSearch.probabilistic_accept_with_temperature(current_cost, next_cost, temperature), percentage)
    end
)

parametrized_test(
    [
        # if cost strictly decreases it means it is better
        [1, 1, false],
        [1, 3, false],
        [2, 1, true],
        [10, 1, true]
    ],
    function best_accept(current_cost, next_cost, outcome)
        @test HerbSearch.best_accept(current_cost, next_cost, 0) == outcome
    end
)
end
@testset "Cost functions" begin
    parametrized_test(
        [
            # no mistakes
            ([(1, 1)], 0),
            ([(1.2, 1.2), (1, 1)], 0),
            ([(1, 1), (2, 2), (3, 3)], 0),
            ([(1, 1), (2, 2), (3.5, 3.5)], 0),

            
            # mistakes
            ([(1, 1), (1, 2)], 1 / 2),
            ([(1, 2), (1, 2), (1, 3) ], 3 / 3),
            ([(1, 1), (2, 2), (1, 3) ], 1 / 3),
        ],
        function miclassification(list_of_tuples, misclassified)
            @test HerbSearch.misclassification(list_of_tuples) == misclassified
        end
    )

    parametrized_test(
        [
            # no mistakes
            ([(1, 1)], 0),
            ([(1.2, 1.2), (1, 1)], 0),
            ([(1, 1), (2, 2), (3, 3)], 0),
            ([(1, 1), (2, 2), (3.5, 3.5)], 0),

            
            # mistakes
            ([(1, 1), (1, 2)], 1 / 2),
            ([(1, 2), (1, 2), (1, 3) ], (1 + 1 + 2 * 2) / 3),
            ([(1, 1), (2, 2), (1, 3) ], 2 * 2 / 3),
        ],
        function mean_squared_error(list_of_tuples, error)
            @test HerbSearch.mean_squared_error(list_of_tuples) == error
        end
    )

end
