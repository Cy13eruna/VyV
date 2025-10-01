# 👁️ TOGGLE FOG COMMAND
# Purpose: Command for toggling fog of war with undo/redo support
# Layer: Infrastructure/Commands

extends GameCommand

class_name ToggleFogCommand

# Fog toggle specific data
var previous_fog_state: bool
var new_fog_state: bool

# Initialize toggle fog command
func _init(cmd_player_id: int):
	super("TOGGLE_FOG", cmd_player_id, {})

# Execute toggle fog command
func _execute_command(game_state: Dictionary) -> Dictionary:
	var ToggleFogUseCase = load("res://application/use_cases/toggle_fog_clean.gd")
	
	# Capture current fog state for undo
	previous_fog_state = game_state.fog_enabled if "fog_enabled" in game_state else false
	
	# Execute the fog toggle
	var result = ToggleFogUseCase.execute(game_state)
	
	if result.success:
		new_fog_state = game_state.fog_enabled
		
		return {
			"success": true,
			"message": result.message,
			"state_changes": {
				"previous_fog": previous_fog_state,
				"new_fog": new_fog_state
			}
		}
	else:
		return {
			"success": false,
			"message": result.message,
			"state_changes": {}
		}

# Undo toggle fog command
func _undo_command(game_state: Dictionary) -> Dictionary:
	# Restore previous fog state
	game_state.fog_enabled = previous_fog_state
	
	return {
		"success": true,
		"message": "Fog toggle undone successfully",
		"state_changes": {
			"restored_fog": previous_fog_state
		}
	}

# Capture data needed for undo
func _capture_undo_data(game_state: Dictionary) -> Dictionary:
	return {
		"fog_enabled": game_state.fog_enabled if "fog_enabled" in game_state else false
	}

# Validate toggle fog command
func _validate_command(game_state: Dictionary) -> bool:
	# Fog toggle is always valid (could add restrictions if needed)
	return true

# Check if fog toggle can be undone
func _can_undo_command(game_state: Dictionary) -> bool:
	return true

# Get fog toggle summary
func get_summary() -> String:
	var state_text = "ON" if new_fog_state else "OFF"
	return "Toggle Fog of War %s" % state_text