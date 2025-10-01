# 📚 SIMPLE COMMAND MANAGER
# Purpose: Simplified command manager without complex dependencies
# Layer: Infrastructure/Commands

extends RefCounted

class_name SimpleCommandManager

# Simple command structure
class SimpleCommand:
	var command_type: String
	var player_id: int
	var data: Dictionary
	var timestamp: float
	var is_executed: bool = false
	
	func _init(type: String, pid: int, cmd_data: Dictionary = {}):
		command_type = type
		player_id = pid
		data = cmd_data
		timestamp = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	
	func get_summary() -> String:
		return "%s by Player %d" % [command_type, player_id]

# Command history
var command_history: Array = []
var current_command_index: int = -1  # Points to last executed command
var max_history_size: int = 50

# Events
signal command_executed(command)
signal command_undone(command)
signal command_redone(command)
signal history_changed()

# Execute a command
func execute_command(command_type: String, player_id: int, data: Dictionary, game_state: Dictionary) -> Dictionary:
	var command = SimpleCommand.new(command_type, player_id, data)
	var result = {"success": false, "message": "Unknown command"}
	
	match command_type:
		"MOVE_UNIT":
			result = _execute_move_unit(data, game_state)
		"SKIP_TURN":
			result = _execute_skip_turn(data, game_state)
		"TOGGLE_FOG":
			result = _execute_toggle_fog(data, game_state)
	
	if result.success:
		command.is_executed = true
		_add_command_to_history(command)
		command_executed.emit(command)
		history_changed.emit()
	
	return result

# Simple undo with basic state restoration
func undo_last_command(game_state: Dictionary) -> Dictionary:
	print("DEBUG: Undo check - Index: %d, History size: %d, Can undo: %s" % [current_command_index, command_history.size(), can_undo()])
	
	if not can_undo():
		return {"success": false, "message": "Nothing to undo (Index: %d, Size: %d)" % [current_command_index, command_history.size()]}
	
	var command = command_history[current_command_index]
	current_command_index -= 1
	
	# Basic undo logic based on command type
	match command.command_type:
		"MOVE_UNIT":
			return _undo_move_unit(command, game_state)
		"SKIP_TURN":
			return _undo_skip_turn(command, game_state)
		"TOGGLE_FOG":
			return _undo_toggle_fog(command, game_state)
		_:
			command_undone.emit(command)
			history_changed.emit()
			return {"success": true, "message": "Command undone (basic)"}

# Simple redo
func redo_next_command(game_state: Dictionary) -> Dictionary:
	if not can_redo():
		return {"success": false, "message": "Nothing to redo"}
	
	current_command_index += 1
	var command = command_history[current_command_index]
	
	command_redone.emit(command)
	history_changed.emit()
	
	return {"success": true, "message": "Command redone (simplified)"}

# Check if undo is possible
func can_undo() -> bool:
	# Can undo if we have commands and current_command_index points to a valid command
	return current_command_index >= 0 and current_command_index < command_history.size()

# Check if redo is possible
func can_redo() -> bool:
	return current_command_index + 1 < command_history.size()

# Get stats
func get_stats() -> Dictionary:
	return {
		"total_commands": command_history.size(),
		"current_index": current_command_index,
		"executed_commands": current_command_index + 1,
		"can_undo": can_undo(),
		"can_redo": can_redo(),
		"last_command": command_history[current_command_index].get_summary() if current_command_index >= 0 and current_command_index < command_history.size() else "None"
	}

# Get history summary
func get_history_summary() -> Array:
	var summary = []
	for i in range(command_history.size()):
		var cmd = command_history[i]
		summary.append({
			"index": i,
			"command": "%s by Player %d" % [cmd.command_type, cmd.player_id],
			"type": cmd.command_type,
			"executed": i <= current_command_index
		})
	return summary

# Execute specific commands
func _execute_move_unit(data: Dictionary, game_state: Dictionary) -> Dictionary:
	var MoveUnitUseCase = load("res://application/use_cases/move_unit_clean.gd")
	var result = MoveUnitUseCase.execute(data.unit_id, data.target_position, game_state)
	
	# Add state_changes for compatibility
	if result.success:
		result["state_changes"] = {
			"unit_moved": data.unit_id,
			"power_consumed": result.get("power_consumed", false),
			"turn_advanced": result.get("turn_advanced", false)
		}
	
	return result

func _execute_skip_turn(data: Dictionary, game_state: Dictionary) -> Dictionary:
	var SkipTurnUseCase = load("res://application/use_cases/skip_turn_clean.gd")
	var result = SkipTurnUseCase.execute(game_state)
	
	# Add state_changes for compatibility
	if result.success:
		result["state_changes"] = {
			"game_ended": result.get("game_over", false),
			"winner": result.get("winner", null)
		}
	
	return result

func _execute_toggle_fog(data: Dictionary, game_state: Dictionary) -> Dictionary:
	var ToggleFogUseCase = load("res://application/use_cases/toggle_fog_clean.gd")
	var result = ToggleFogUseCase.execute(game_state)
	
	# Add state_changes for compatibility
	if result.success:
		result["state_changes"] = {
			"fog_toggled": true
		}
	
	return result

# Undo specific commands
func _undo_move_unit(command, game_state: Dictionary) -> Dictionary:
	# For now, just emit the event - full undo would require storing previous state
	command_undone.emit(command)
	history_changed.emit()
	return {"success": true, "message": "Move command undone (position not restored)"}

func _undo_skip_turn(command, game_state: Dictionary) -> Dictionary:
	# For now, just emit the event - full undo would require complex state restoration
	command_undone.emit(command)
	history_changed.emit()
	return {"success": true, "message": "Skip turn undone (turn not restored)"}

func _undo_toggle_fog(command, game_state: Dictionary) -> Dictionary:
	# Toggle fog again to undo
	var ToggleFogUseCase = load("res://application/use_cases/toggle_fog_clean.gd")
	var result = ToggleFogUseCase.execute(game_state)
	
	command_undone.emit(command)
	history_changed.emit()
	
	if result.success:
		return {"success": true, "message": "Fog toggle undone"}
	else:
		return {"success": false, "message": "Failed to undo fog toggle"}

# Helper methods
func _add_command_to_history(command) -> void:
	# Remove commands after current index
	if current_command_index + 1 < command_history.size():
		command_history = command_history.slice(0, current_command_index + 1)
	
	command_history.append(command)
	current_command_index += 1
	
	print("DEBUG: Command added - Index: %d, History size: %d, Command: %s" % [current_command_index, command_history.size(), command.get_summary()])
	
	# Trim history if too large
	if command_history.size() > max_history_size:
		command_history.pop_front()
		current_command_index -= 1