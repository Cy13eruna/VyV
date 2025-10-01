# 💾 SAVE/LOAD SYSTEM
# Purpose: Complete game state persistence
# Layer: Infrastructure/Persistence

extends RefCounted

class_name SaveLoadSystem

# Save file configuration
const SAVE_DIRECTORY = "user://saves/"
const SAVE_EXTENSION = ".vv"
const AUTO_SAVE_PREFIX = "autosave_"
const QUICK_SAVE_NAME = "quicksave"

# Compression and encryption
var use_compression: bool = true
var use_encryption: bool = false
var encryption_key: String = ""

# Save metadata
class SaveMetadata:
	var save_name: String
	var timestamp: float
	var game_version: String
	var player_count: int
	var turn_number: int
	var current_player: String
	var file_size: int
	var checksum: String
	
	func _init():
		timestamp = Time.get_unix_time_from_system()
		game_version = "1.0"

# Initialize save system
func _init():
	_ensure_save_directory()

# Save game state
func save_game(game_state: Dictionary, save_name: String) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"file_path": "",
		"file_size": 0
	}
	
	# Validate game state
	var GameState = load("res://infrastructure/persistence/game_state_clean.gd")
	var validation = GameState.validate_game_state(game_state)
	
	if "valid" in validation and not validation.valid:
		result.message = "Invalid game state: " + str(validation.errors)
		return result
	
	# Create save data
	var save_data = _create_save_data(game_state, save_name)
	
	# Serialize to JSON
	var json_string = JSON.stringify(save_data)
	
	# Apply compression if enabled
	if use_compression:
		json_string = _compress_data(json_string)
	
	# Apply encryption if enabled
	if use_encryption and encryption_key != "":
		json_string = _encrypt_data(json_string, encryption_key)
	
	# Write to file
	var file_path = SAVE_DIRECTORY + save_name + SAVE_EXTENSION
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null:
		result.message = "Failed to create save file: " + file_path
		return result
	
	file.store_string(json_string)
	var file_size = file.get_position()
	file.close()
	
	result.success = true
	result.message = "Game saved successfully"
	result.file_path = file_path
	result.file_size = file_size
	
	print("💾 Game saved: %s (%d bytes)" % [save_name, file_size])
	return result

# Load game state
func load_game(save_name: String) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"game_state": {},
		"metadata": null
	}
	
	var file_path = SAVE_DIRECTORY + save_name + SAVE_EXTENSION
	
	if not FileAccess.file_exists(file_path):
		result.message = "Save file not found: " + save_name
		return result
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		result.message = "Failed to open save file: " + save_name
		return result
	
	var file_content = file.get_as_text()
	file.close()
	
	# Apply decryption if enabled
	if use_encryption and encryption_key != "":
		file_content = _decrypt_data(file_content, encryption_key)
		if file_content == "":
			result.message = "Failed to decrypt save file"
			return result
	
	# Apply decompression if enabled
	if use_compression:
		file_content = _decompress_data(file_content)
		if file_content == "":
			result.message = "Failed to decompress save file"
			return result
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(file_content)
	
	if parse_result != OK:
		result.message = "Failed to parse save file: Invalid JSON"
		return result
	
	var save_data = json.data
	
	# Validate save data structure
	if not _validate_save_data(save_data):
		result.message = "Invalid save file format"
		return result
	
	# Extract game state and metadata
	result.game_state = save_data.game_state
	result.metadata = _parse_metadata(save_data.metadata)
	result.success = true
	result.message = "Game loaded successfully"
	
	print("📁 Game loaded: %s" % save_name)
	return result

# Auto-save functionality
func auto_save(game_state: Dictionary, slot: int = 0) -> Dictionary:
	var auto_save_name = AUTO_SAVE_PREFIX + str(slot)
	return save_game(game_state, auto_save_name)

# Quick save
func quick_save(game_state: Dictionary) -> Dictionary:
	return save_game(game_state, QUICK_SAVE_NAME)

# Quick load
func quick_load() -> Dictionary:
	return load_game(QUICK_SAVE_NAME)

# Get list of available saves
func get_save_list() -> Array:
	var saves = []
	var dir = DirAccess.open(SAVE_DIRECTORY)
	
	if dir == null:
		return saves
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(SAVE_EXTENSION):
			var save_name = file_name.trim_suffix(SAVE_EXTENSION)
			var metadata = get_save_metadata(save_name)
			
			saves.append({
				"name": save_name,
				"metadata": metadata
			})
		
		file_name = dir.get_next()
	
	# Sort by timestamp (newest first)
	saves.sort_custom(func(a, b): return a.metadata.timestamp > b.metadata.timestamp)
	
	return saves

# Get save file metadata without loading full game
func get_save_metadata(save_name: String) -> SaveMetadata:
	var metadata = SaveMetadata.new()
	var file_path = SAVE_DIRECTORY + save_name + SAVE_EXTENSION
	
	if not FileAccess.file_exists(file_path):
		return metadata
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return metadata
	
	# Try to read just the metadata portion
	var file_content = file.get_as_text()
	file.close()
	
	# Quick parse for metadata
	var json = JSON.new()
	var parse_result = json.parse(file_content)
	
	if parse_result == OK and "metadata" in json.data:
		metadata = _parse_metadata(json.data.metadata)
	
	# Get file stats
	var file_stats = FileAccess.get_file_as_bytes(file_path)
	metadata.file_size = file_stats.size()
	
	return metadata

# Delete save file
func delete_save(save_name: String) -> bool:
	var file_path = SAVE_DIRECTORY + save_name + SAVE_EXTENSION
	
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open(SAVE_DIRECTORY)
		if dir:
			dir.remove(save_name + SAVE_EXTENSION)
			print("🗑️ Save deleted: %s" % save_name)
			return true
	
	return false

# Export save file
func export_save(save_name: String, export_path: String) -> bool:
	var source_path = SAVE_DIRECTORY + save_name + SAVE_EXTENSION
	
	if not FileAccess.file_exists(source_path):
		return false
	
	var source_file = FileAccess.open(source_path, FileAccess.READ)
	var dest_file = FileAccess.open(export_path, FileAccess.WRITE)
	
	if source_file == null or dest_file == null:
		return false
	
	dest_file.store_string(source_file.get_as_text())
	
	source_file.close()
	dest_file.close()
	
	print("📤 Save exported: %s -> %s" % [save_name, export_path])
	return true

# Import save file
func import_save(import_path: String, save_name: String) -> bool:
	if not FileAccess.file_exists(import_path):
		return false
	
	var source_file = FileAccess.open(import_path, FileAccess.READ)
	var dest_path = SAVE_DIRECTORY + save_name + SAVE_EXTENSION
	var dest_file = FileAccess.open(dest_path, FileAccess.WRITE)
	
	if source_file == null or dest_file == null:
		return false
	
	dest_file.store_string(source_file.get_as_text())
	
	source_file.close()
	dest_file.close()
	
	print("📥 Save imported: %s -> %s" % [import_path, save_name])
	return true

# Helper functions
func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIRECTORY):
		DirAccess.open("user://").make_dir_recursive(SAVE_DIRECTORY)

func _create_save_data(game_state: Dictionary, save_name: String) -> Dictionary:
	var GameState = load("res://infrastructure/persistence/game_state_clean.gd")
	var serialized_state = GameState.serialize_game_state(game_state)
	
	var metadata = SaveMetadata.new()
	metadata.save_name = save_name
	metadata.player_count = game_state.players.size() if "players" in game_state else 0
	metadata.turn_number = game_state.turn_data.turn_number if "turn_data" in game_state else 0
	
	if "turn_data" in game_state and "current_player_id" in game_state.turn_data:
		var current_player_id = game_state.turn_data.current_player_id
		if current_player_id in game_state.players:
			metadata.current_player = game_state.players[current_player_id].name
	
	return {
		"metadata": {
			"save_name": metadata.save_name,
			"timestamp": metadata.timestamp,
			"game_version": metadata.game_version,
			"player_count": metadata.player_count,
			"turn_number": metadata.turn_number,
			"current_player": metadata.current_player,
			"checksum": _calculate_checksum(serialized_state)
		},
		"game_state": serialized_state
	}

func _validate_save_data(save_data) -> bool:
	return "metadata" in save_data and "game_state" in save_data

func _parse_metadata(metadata_dict: Dictionary) -> SaveMetadata:
	var metadata = SaveMetadata.new()
	
	if "save_name" in metadata_dict:
		metadata.save_name = metadata_dict.save_name
	if "timestamp" in metadata_dict:
		metadata.timestamp = metadata_dict.timestamp
	if "game_version" in metadata_dict:
		metadata.game_version = metadata_dict.game_version
	if "player_count" in metadata_dict:
		metadata.player_count = metadata_dict.player_count
	if "turn_number" in metadata_dict:
		metadata.turn_number = metadata_dict.turn_number
	if "current_player" in metadata_dict:
		metadata.current_player = metadata_dict.current_player
	if "checksum" in metadata_dict:
		metadata.checksum = metadata_dict.checksum
	
	return metadata

func _calculate_checksum(data) -> String:
	# Simple checksum calculation
	var json_string = JSON.stringify(data)
	return str(json_string.hash())

func _compress_data(data: String) -> String:
	# Placeholder for compression
	# In real implementation, use Godot's compression functions
	return data

func _decompress_data(data: String) -> String:
	# Placeholder for decompression
	return data

func _encrypt_data(data: String, key: String) -> String:
	# Placeholder for encryption
	return data

func _decrypt_data(data: String, key: String) -> String:
	# Placeholder for decryption
	return data