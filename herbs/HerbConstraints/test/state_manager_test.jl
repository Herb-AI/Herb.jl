@testitem "StateManager" begin
    @testset "1 int, 1 update, 1 backup" begin
        sm = HerbConstraints.StateManager()
        a = StateInt(sm, 10)
        @test get_value(a) == 10
        save_state!(sm)
        set_value!(a, 9)
        @test get_value(a) == 9
        @test length(sm.current_backups) == 1
        restore!(sm)
        @test get_value(a) == 10
    end

    @testset "1 int, 3 updates, 1 backup" begin
        sm = HerbConstraints.StateManager()
        a = StateInt(sm, 10)
        save_state!(sm)
        @test get_value(a) == 10
        set_value!(a, 9)
        set_value!(a, 8)
        set_value!(a, 7)
        @test get_value(a) == 7
        @test length(sm.current_backups) == 1
        restore!(sm)
        @test get_value(a) == 10
    end

    @testset "2 ints, 1 update, 1 backup" begin
        sm = HerbConstraints.StateManager()
        a = StateInt(sm, 10)
        b = StateInt(sm, 100)
        save_state!(sm)
        set_value!(a, 9)
        @test get_value(a) == 9
        @test get_value(b) == 100
        @test length(sm.current_backups) == 1
        restore!(sm)
        @test get_value(a) == 10
        @test get_value(b) == 100
    end

    @testset "2 ints, 6 updates, 2 backups" begin
        sm = HerbConstraints.StateManager()
        a = StateInt(sm, 10)
        b = StateInt(sm, 100)
        save_state!(sm)
        set_value!(a, 9)
        set_value!(b, 90)
        set_value!(a, 8)
        set_value!(a, 7)
        set_value!(b, 80)
        set_value!(b, 70)
        @test get_value(a) == 7
        @test get_value(b) == 70
        @test length(sm.current_backups) == 2
        restore!(sm)
        @test get_value(a) == 10
        @test get_value(b) == 100
    end

    @testset "multiple backup layers" begin
        sm = HerbConstraints.StateManager()
        a = StateInt(sm, 10)
        b = StateInt(sm, 100)

        save_state!(sm)
        set_value!(a, 9)
        set_value!(b, 90)
        save_state!(sm)
        set_value!(a, 8)
        set_value!(b, 80)
        save_state!(sm)
        set_value!(a, 7)
        set_value!(b, 70)

        @test get_value(a) == 7
        @test get_value(b) == 70
        restore!(sm)
        @test get_value(a) == 8
        @test get_value(b) == 80
        restore!(sm)
        @test get_value(a) == 9
        @test get_value(b) == 90
        restore!(sm)
        @test get_value(a) == 10
        @test get_value(b) == 100
    end

    @testset "restore without backup" begin
        sm = HerbConstraints.StateManager()
        a = StateInt(sm, 10)
        b = StateInt(sm, 100)
        restore!(sm)
        restore!(sm)
        restore!(sm)
        @test get_value(a) == 10
        @test get_value(b) == 100
    end

    @testset "behavior needed for constraint unposting" begin
        sm = HerbConstraints.StateManager()
        save_state!(sm)
        a = StateInt(sm, 0)         # initialize a new state int, set its value to 0 (post a new constraint)
        set_value!(a, 1)            # immediately update the state int to 1 (activate the newly posted constraint)
        restore!(sm)            
        @test get_value(a) == 0     # on backtrack, the new constraint should be deactivated
    end
end
