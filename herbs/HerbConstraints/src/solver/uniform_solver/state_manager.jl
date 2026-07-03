"""
Manages all changes made to StateInts using StateIntBackups.
Support the following functions:
- `StateInt` Creates a new stateful integer
- `save_state!` Creates a checkpoint for all stateful integers
- `restore!` Restores the values to the latest checkpoint
"""
abstract type AbstractStateManager end

AbstractStateManager() = StateManager()

"""
Stateful integer that can be saved and restored by the [`StateManager`](@Ref).
Supports the following functions:
- `get_value`
- `set_value!`
- `increment!`
- `decrement!`
"""
mutable struct StateInt
    sm::AbstractStateManager
    val::Int
    last_state_id::Int
end

function StateInt(sm, val)
    return StateInt(sm, val, sm.current_state_id-1)
end


"""
Get the value of the stateful integer
"""
function get_value(int::StateInt)
    return int.val
end


"""
Set the value of the integer to the given `val`
"""
function set_value!(int::StateInt, val::Int)
    if int.val != val
        backup!(int)
        int.val = val
    end
end


"""
Increase the value of the integer by 1
"""
function increment!(int::StateInt)
    backup!(int)
    int.val += 1
end


"""
Decrease the value of the integer by 1
"""
function decrement!(int::StateInt)
    backup!(int)
    int.val -= 1
end


"""
Backup entry for the given [`StateInt`](@ref)
"""
struct StateIntBackup
    state_int::StateInt
    original_val::Int
end


"""
Should be called whenever the state of a `StateInt` is modified.
Creates a `StateIntBackup` for the given `StateInt`.
Only backup the value if this integer has not been stored during this state before
Example usecase:
```
a = StateInt(sm, 10)
save_state!(sm)
set_value!(a, 9) #backup value 10
set_value!(a, 8) #no need to backup again
set_value!(a, 3) #no need to backup again
restore!(sm) #restores a to value 10
```
"""
function backup!(int::StateInt)
    state_id = int.sm.current_state_id
    if int.last_state_id != state_id
        int.last_state_id = state_id
        push!(int.sm.current_backups, StateIntBackup(int, int.val))
    end
end


"""
Restores the `StateInt` stored in the `StateIntBackup` to its original value
"""
function restore!(backup::StateIntBackup)
    backup.state_int.val = backup.original_val
end

###############################################
###############################################
#####                                     #####
#####            STATE MANAGER            #####
#####                                     #####
###############################################
###############################################

"""
Manages all changes made to StateInts using StateIntBackups
"""
mutable struct StateManager <: AbstractStateManager
    prior_backups::Vector{Vector{StateIntBackup}}       # backups of previous save points
    current_backups::Vector{StateIntBackup}             # backups of changes made since the last save point
    current_state_id::Int
end

function StateManager()
    prior_backups = Vector{Vector{StateIntBackup}}()
    current_backups = Vector{StateIntBackup}()
    current_state_id = 1
    return StateManager(prior_backups, current_backups, current_state_id)
end


"""
Make a backup of the current state. Return to this state by calling `restore!`.
"""
function save_state!(sm::StateManager)
    push!(sm.prior_backups, sm.current_backups)
    sm.current_backups = Vector{StateIntBackup}()
    sm.current_state_id += 1
end


"""
Reverts all the backups since the last `save_state!`.
"""
function restore!(sm::StateManager)
    while !isempty(sm.current_backups)
        stateintbackup = pop!(sm.current_backups)
        restore!(stateintbackup)
    end
    if !isempty(sm.prior_backups)
        sm.current_backups = pop!(sm.prior_backups)
    end
    sm.current_state_id += 1
end
