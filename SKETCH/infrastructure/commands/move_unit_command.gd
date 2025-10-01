# 🚶 MOVE UNIT COMMAND
# Purpose: Command for moving units with undo/redo support
# Layer: Infrastructure/Commands

extends GameCommand

class_name MoveUnitCommand

# Move-specific data
var unit_id: int
var from_position
var to_position
var power_consumed: bool = false
var turn_advanced: bool = false
var previous_turn_data: Dictionary = {}

# Initialize move command
func _init(cmd_player_id: int, cmd_unit_id: int, target_position):
	super("MOVE_UNIT", cmd_player_id, {
		"unit_id": cmd_unit_id,
		"target_position": target_position
	})
	unit_id = cmd_unit_id
	to_position = target_position

# Execute move command
func _execute_command(game_state: Dictionary) -> Dictionary:
	var MoveUnitUseCase = load("res://application/use_cases/move_unit_clean.gd")
	
	# Capture current unit position for undo
	if unit_id in game_state.units:
		from_position = game_state.units[unit_id].position
	
	# Execute the move
	var result = MoveUnitUseCase.execute(unit_id, to_position, game_state)
	
	if result.success:
		power_consumed = result.power_consumed
		turn_advanced = result.turn_advanced
		
		return {
			"success": true,
			"message": "Unit moved successfully",
			"state_changes": {
				"unit_moved": unit_id,
				"from": from_position,
				"to": to_position,
				"power_consumed": power_consumed,
				"turn_advanced": turn_advanced
			}
		}
	else:
		return {
			"success": false,
			"message": result.message,
			"state_changes": {}
		}

# Undo move command
func _undo_command(game_state: Dictionary) -> Dictionary:
	if unit_id not in game_state.units:
		return {"success": false, "message": "Unit not found for undo"}
	
	var unit = game_state.units[unit_id]
	
	# Restore unit position
	unit.position = from_position
	
	# Restore power if it was consumed
	if power_consumed:
		unit.actions_remaining = 1
	
	# Restore turn data if turn was advanced
	if turn_advanced and "previous_turn_data" in undo_data:
		game_state.turn_data = undo_data.previous_turn_data.duplicate()
	
	return {
		"success": true,
		"message": "Move undone successfully",
		"state_changes": {
			"unit_moved": unit_id,
			"from": to_position,
			"to": from_position,
			"power_restored": power_consumed,
			"turn_restored": turn_advanced
		}
	}

# Capture data needed for undo
func _capture_undo_data(game_state: Dictionary) -> Dictionary:
	var data = {}
	
	if unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		data["unit_position"] = unit.position
		data["unit_actions"] = unit.actions_remaining
	
	# Capture turn data in case turn advances
	data["previous_turn_data"] = game_state.turn_data.duplicate()
	
	return data

# Validate move command
func _validate_command(game_state: Dictionary) -> bool:
	# Check if unit exists
	if unit_id not in game_state.units:
		return false
	
	var unit = game_state.units[unit_id]
	
	# Check if unit belongs to player
	if unit.owner_id != player_id:
		return false
	
	# Check if unit can move
	if not unit.can_move():
		return false
	
	# Validate target position using MovementService
	var MovementService = load("res://application/services/movement_service_clean.gd")
	var valid_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units)
	
	for target in valid_targets:
		if target.equals(to_position):
			return true
	
	return false

# Check if move can be undone
func _can_undo_command(game_state: Dictionary) -> bool:
	return unit_id in game_state.units

# Get move summary
func get_summary() -> String:
	return "Move Unit %d to %s" % [unit_id, to_position]