# 🔄 COMMAND INTERFACE
# Purpose: Base interface for all game commands (Command Pattern)
# Layer: Infrastructure/Commands

extends RefCounted

class_name GameCommand

# Command metadata
var command_id: String
var timestamp: float
var player_id: int
var command_type: String
var is_executed: bool = false
var is_undone: bool = false

# Command data
var command_data: Dictionary = {}
var undo_data: Dictionary = {}

# Initialize command
func _init(cmd_type: String, cmd_player_id: int, cmd_data: Dictionary = {}):
	command_type = cmd_type
	player_id = cmd_player_id
	command_data = cmd_data
	timestamp = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	command_id = _generate_command_id()

# Execute the command
func execute(game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "Command not implemented",
		"state_changes": {}
	}
	
	if is_executed:
		result.message = "Command already executed"
		return result
	
	# Store state for undo before execution
	undo_data = _capture_undo_data(game_state)
	
	# Execute the actual command (override in subclasses)
	result = _execute_command(game_state)
	
	if result.success:
		is_executed = true
		is_undone = false
	
	return result

# Undo the command
func undo(game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "Cannot undo command",
		"state_changes": {}
	}
	
	if not is_executed:
		result.message = "Command not executed yet"
		return result
	
	if is_undone:
		result.message = "Command already undone"
		return result
	
	# Restore state from undo data
	result = _undo_command(game_state)
	
	if result.success:
		is_undone = true
	
	return result

# Redo the command (re-execute)
func redo(game_state: Dictionary) -> Dictionary:
	if not is_undone:
		return {"success": false, "message": "Command not undone"}
	
	is_undone = false
	is_executed = false
	return execute(game_state)

# Check if command can be executed
func can_execute(game_state: Dictionary) -> bool:
	return not is_executed and _validate_command(game_state)

# Check if command can be undone
func can_undo(game_state: Dictionary) -> bool:
	return is_executed and not is_undone and _can_undo_command(game_state)

# Get command summary for display
func get_summary() -> String:
	return "%s by Player %d" % [command_type, player_id]

# Get detailed command info
func get_info() -> Dictionary:
	return {
		"id": command_id,
		"type": command_type,
		"player_id": player_id,
		"timestamp": timestamp,
		"executed": is_executed,
		"undone": is_undone,
		"data": command_data,
		"summary": get_summary()
	}

# Serialize command for replay/network
func serialize() -> Dictionary:
	return {
		"command_id": command_id,
		"command_type": command_type,
		"player_id": player_id,
		"timestamp": timestamp,
		"command_data": command_data,
		"is_executed": is_executed,
		"is_undone": is_undone
	}

# Deserialize command from data
static func deserialize(data: Dictionary) -> GameCommand:
	var cmd = GameCommand.new(data.command_type, data.player_id, data.command_data)
	cmd.command_id = data.command_id
	cmd.timestamp = data.timestamp
	cmd.is_executed = data.is_executed
	cmd.is_undone = data.is_undone
	return cmd

# Virtual methods to override in subclasses
func _execute_command(game_state: Dictionary) -> Dictionary:
	return {"success": false, "message": "Command execution not implemented"}

func _undo_command(game_state: Dictionary) -> Dictionary:
	return {"success": false, "message": "Command undo not implemented"}

func _capture_undo_data(game_state: Dictionary) -> Dictionary:
	return {}

func _validate_command(game_state: Dictionary) -> bool:
	return true

func _can_undo_command(game_state: Dictionary) -> bool:
	return true

# Helper methods
func _generate_command_id() -> String:
	return "CMD_%d_%d_%d" % [player_id, timestamp, randi() % 1000]