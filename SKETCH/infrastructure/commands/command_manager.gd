# 📚 COMMAND MANAGER
# Purpose: Manages command execution, undo/redo, and history
# Layer: Infrastructure/Commands

extends RefCounted

class_name CommandManager

# Command history
var command_history: Array = []
var current_command_index: int = -1
var max_history_size: int = 100

# Command execution state
var is_executing: bool = false
var is_undoing: bool = false
var is_redoing: bool = false

# Events
signal command_executed(command)
signal command_undone(command)
signal command_redone(command)
signal history_changed()

# Execute a command
func execute_command(command, game_state: Dictionary) -> Dictionary:
	if is_executing or is_undoing or is_redoing:
		return {"success": false, "message": "Command system busy"}
	
	if not command.can_execute(game_state):
		return {"success": false, "message": "Command cannot be executed"}
	
	is_executing = true
	var result = command.execute(game_state)
	is_executing = false
	
	if result.success:
		_add_command_to_history(command)
		command_executed.emit(command)
		history_changed.emit()
	
	return result

# Undo the last command
func undo_last_command(game_state: Dictionary) -> Dictionary:
	if not can_undo():
		return {"success": false, "message": "Nothing to undo"}
	
	if is_executing or is_undoing or is_redoing:
		return {"success": false, "message": "Command system busy"}
	
	var command = command_history[current_command_index]
	
	if not command.can_undo(game_state):
		return {"success": false, "message": "Command cannot be undone"}
	
	is_undoing = true
	var result = command.undo(game_state)
	is_undoing = false
	
	if result.success:
		current_command_index -= 1
		command_undone.emit(command)
		history_changed.emit()
	
	return result

# Redo the next command
func redo_next_command(game_state: Dictionary) -> Dictionary:
	if not can_redo():
		return {"success": false, "message": "Nothing to redo"}
	
	if is_executing or is_undoing or is_redoing:
		return {"success": false, "message": "Command system busy"}
	
	var command = command_history[current_command_index + 1]
	
	is_redoing = true
	var result = command.redo(game_state)
	is_redoing = false
	
	if result.success:
		current_command_index += 1
		command_redone.emit(command)
		history_changed.emit()
	
	return result

# Check if undo is possible
func can_undo() -> bool:
	return current_command_index >= 0 and current_command_index < command_history.size()

# Check if redo is possible
func can_redo() -> bool:
	return current_command_index + 1 < command_history.size()

# Get undo command info
func get_undo_info() -> Dictionary:
	if not can_undo():
		return {}
	
	var command = command_history[current_command_index]
	return {
		"available": true,
		"command": command.get_summary(),
		"type": command.command_type
	}

# Get redo command info
func get_redo_info() -> Dictionary:
	if not can_redo():
		return {}
	
	var command = command_history[current_command_index + 1]
	return {
		"available": true,
		"command": command.get_summary(),
		"type": command.command_type
	}

# Clear command history
func clear_history() -> void:
	command_history.clear()
	current_command_index = -1
	history_changed.emit()

# Get command history summary
func get_history_summary() -> Array:
	var summary = []
	
	for i in range(command_history.size()):
		var command = command_history[i]
		var is_current = i <= current_command_index
		
		summary.append({
			"index": i,
			"command": command.get_summary(),
			"type": command.command_type,
			"executed": is_current,
			"timestamp": command.timestamp,
			"player_id": command.player_id
		})
	
	return summary

# Get detailed command history
func get_detailed_history() -> Array:
	var detailed = []
	
	for command in command_history:
		detailed.append(command.get_info())
	
	return detailed

# Replay commands from history
func replay_commands(game_state: Dictionary, from_index: int = 0, to_index: int = -1) -> Dictionary:
	if to_index == -1:
		to_index = current_command_index
	
	var replay_result = {
		"success": true,
		"commands_replayed": 0,
		"failed_commands": []
	}
	
	for i in range(from_index, min(to_index + 1, command_history.size())):
		var command = command_history[i]
		
		# Create a fresh copy of the command for replay
		var replay_command = _create_command_copy(command)
		var result = replay_command.execute(game_state)
		
		if result.success:
			replay_result.commands_replayed += 1
		else:
			replay_result.failed_commands.append({
				"index": i,
				"command": command.get_summary(),
				"error": result.message
			})
			replay_result.success = false
	
	return replay_result

# Export command history for saving/networking
func export_history() -> Array:
	var exported = []
	
	for command in command_history:
		exported.append(command.serialize())
	
	return exported

# Import command history from save/network
func import_history(history_data: Array) -> void:
	command_history.clear()
	current_command_index = -1
	
	for cmd_data in history_data:
		var command = _deserialize_command(cmd_data)
		if command:
			command_history.append(command)
			if cmd_data.is_executed and not cmd_data.is_undone:
				current_command_index += 1
	
	history_changed.emit()

# Create specific command types
func create_move_command(player_id: int, unit_id: int, target_position) -> MoveUnitCommand:
	var MoveUnitCommand = load("res://infrastructure/commands/move_unit_command.gd")
	return MoveUnitCommand.new(player_id, unit_id, target_position)

func create_skip_turn_command(player_id: int) -> SkipTurnCommand:
	var SkipTurnCommand = load("res://infrastructure/commands/skip_turn_command.gd")
	return SkipTurnCommand.new(player_id)

func create_toggle_fog_command(player_id: int) -> ToggleFogCommand:
	var ToggleFogCommand = load("res://infrastructure/commands/toggle_fog_command.gd")
	return ToggleFogCommand.new(player_id)

# Get command manager statistics
func get_stats() -> Dictionary:
	return {
		"total_commands": command_history.size(),
		"executed_commands": current_command_index + 1,
		"undone_commands": command_history.size() - (current_command_index + 1),
		"can_undo": can_undo(),
		"can_redo": can_redo(),
		"is_busy": is_executing or is_undoing or is_redoing,
		"max_history": max_history_size
	}

# Private helper methods
func _add_command_to_history(command: GameCommand) -> void:
	# Remove any commands after current index (they become invalid after new command)
	if current_command_index + 1 < command_history.size():
		command_history = command_history.slice(0, current_command_index + 1)
	
	# Add new command
	command_history.append(command)
	current_command_index += 1
	
	# Trim history if it exceeds max size
	if command_history.size() > max_history_size:
		command_history.pop_front()
		current_command_index -= 1

func _create_command_copy(original_command: GameCommand) -> GameCommand:
	# Create a new command with the same data for replay
	var serialized = original_command.serialize()
	return _deserialize_command(serialized)

func _deserialize_command(cmd_data: Dictionary) -> GameCommand:
	# Load appropriate command class based on type
	match cmd_data.command_type:
		"MOVE_UNIT":
			var MoveUnitCommand = load("res://infrastructure/commands/move_unit_command.gd")
			return MoveUnitCommand.new(cmd_data.player_id, cmd_data.command_data.unit_id, cmd_data.command_data.target_position)
		"SKIP_TURN":
			var SkipTurnCommand = load("res://infrastructure/commands/skip_turn_command.gd")
			return SkipTurnCommand.new(cmd_data.player_id)
		"TOGGLE_FOG":
			var ToggleFogCommand = load("res://infrastructure/commands/toggle_fog_command.gd")
			return ToggleFogCommand.new(cmd_data.player_id)
		_:
			return null