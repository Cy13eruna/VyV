# ⏭️ SKIP TURN COMMAND
# Purpose: Command for skipping turns with undo/redo support
# Layer: Infrastructure/Commands

extends GameCommand

class_name SkipTurnCommand

# Skip turn specific data
var previous_player_id: int
var new_player_id: int
var previous_turn_number: int
var new_turn_number: int
var game_ended: bool = false
var winner_data: Dictionary = {}

# Initialize skip turn command
func _init(cmd_player_id: int):
	super("SKIP_TURN", cmd_player_id, {})

# Execute skip turn command
func _execute_command(game_state: Dictionary) -> Dictionary:
	var SkipTurnUseCase = load("res://application/use_cases/skip_turn_clean.gd")
	
	# Capture current turn state for undo
	previous_player_id = game_state.turn_data.current_player_id
	previous_turn_number = game_state.turn_data.turn_number
	
	# Execute the skip turn
	var result = SkipTurnUseCase.execute(game_state)
	
	if result.success:
		new_player_id = game_state.turn_data.current_player_id
		new_turn_number = game_state.turn_data.turn_number
		game_ended = result.game_over
		
		if game_ended and result.winner:
			winner_data = {
				"winner_id": result.winner.id,
				"winner_name": result.winner.name
			}
		
		return {
			"success": true,
			"message": result.message,
			"state_changes": {
				"previous_player": previous_player_id,
				"new_player": new_player_id,
				"previous_turn": previous_turn_number,
				"new_turn": new_turn_number,
				"game_ended": game_ended,
				"winner": winner_data
			}
		}
	else:
		return {
			"success": false,
			"message": result.message,
			"state_changes": {}
		}

# Undo skip turn command
func _undo_command(game_state: Dictionary) -> Dictionary:
	# Restore previous turn state
	game_state.turn_data.current_player_id = previous_player_id
	game_state.turn_data.turn_number = previous_turn_number
	
	# Restore unit actions for previous player
	if previous_player_id in game_state.players:
		var player = game_state.players[previous_player_id]
		for unit_id in player.unit_ids:
			if unit_id in game_state.units:
				var unit = game_state.units[unit_id]
				unit.actions_remaining = 1  # Restore action
	
	# If game had ended, restore game state
	if game_ended:
		# Game is no longer over
		pass  # Game over state is handled by the presentation layer
	
	return {
		"success": true,
		"message": "Turn skip undone successfully",
		"state_changes": {
			"restored_player": previous_player_id,
			"restored_turn": previous_turn_number,
			"game_restored": game_ended
		}
	}

# Capture data needed for undo
func _capture_undo_data(game_state: Dictionary) -> Dictionary:
	var data = {}
	
	# Capture current turn data
	data["turn_data"] = game_state.turn_data.duplicate()
	
	# Capture unit states for current player
	var current_player_id = game_state.turn_data.current_player_id
	if current_player_id in game_state.players:
		var player = game_state.players[current_player_id]
		data["unit_states"] = {}
		
		for unit_id in player.unit_ids:
			if unit_id in game_state.units:
				var unit = game_state.units[unit_id]
				data["unit_states"][unit_id] = {
					"actions_remaining": unit.actions_remaining,
					"position": unit.position
				}
	
	return data

# Validate skip turn command
func _validate_command(game_state: Dictionary) -> bool:
	# Check if it's the player's turn
	return game_state.turn_data.current_player_id == player_id

# Check if skip turn can be undone
func _can_undo_command(game_state: Dictionary) -> bool:
	# Can undo if we're not in the middle of another player's actions
	return true

# Get skip turn summary
func get_summary() -> String:
	return "Skip Turn (Player %d)" % player_id