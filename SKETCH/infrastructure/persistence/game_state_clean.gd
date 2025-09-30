# 💾 GAME STATE (CLEAN)
# Purpose: Game state management, serialization and persistence
# Layer: Infrastructure/Persistence
# Dependencies: Clean entities and services

extends RefCounted

# Game state validation
static func validate_game_state(game_state: Dictionary) -> Dictionary:
	var result = {
		"valid": false,
		"errors": [],
		"warnings": []
	}
	
	# Check required top-level keys
	var required_keys = ["grid", "players", "units", "turn_data"]
	for key in required_keys:
		if not (key in game_state):
			result.errors.append("Missing required key: %s" % key)
	
	if result.errors.size() > 0:
		return result
	
	# Validate grid
	var grid_validation = _validate_grid(game_state.grid)
	for error in grid_validation.errors:
		result.errors.append(error)
	for warning in grid_validation.warnings:
		result.warnings.append(warning)
	
	# Validate players
	var players_validation = _validate_players(game_state.players)
	for error in players_validation.errors:
		result.errors.append(error)
	for warning in players_validation.warnings:
		result.warnings.append(warning)
	
	# Validate units
	var units_validation = _validate_units(game_state.units, game_state.players)
	for error in units_validation.errors:
		result.errors.append(error)
	for warning in units_validation.warnings:
		result.warnings.append(warning)
	
	# Validate turn data
	var turn_validation = _validate_turn_data(game_state.turn_data, game_state.players)
	for error in turn_validation.errors:
		result.errors.append(error)
	for warning in turn_validation.warnings:
		result.warnings.append(warning)
	
	result.valid = result.errors.size() == 0
	return result

# Serialize game state to dictionary (for saving)
static func serialize_game_state(game_state: Dictionary) -> Dictionary:
	var serialized = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"grid": _serialize_grid(game_state.grid),
		"players": _serialize_players(game_state.players),
		"units": _serialize_units(game_state.units),
		"domains": _serialize_domains(game_state.domains) if "domains" in game_state else {},
		"turn_data": game_state.turn_data.duplicate(true),
		"fog_of_war_enabled": game_state.fog_of_war_enabled if "fog_of_war_enabled" in game_state else true,
		"game_settings": game_state.game_settings.duplicate(true) if "game_settings" in game_state else {}
	}
	
	return serialized

# Deserialize game state from dictionary (for loading)
static func deserialize_game_state(serialized_data: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"game_state": {},
		"message": ""
	}
	
	# Check version compatibility
	if not ("version" in serialized_data):
		result.message = "Missing version information"
		return result
	
	# Reconstruct game state
	var game_state = {
		"grid": _deserialize_grid(serialized_data.grid),
		"players": _deserialize_players(serialized_data.players),
		"units": _deserialize_units(serialized_data.units),
		"domains": _deserialize_domains(serialized_data.domains) if "domains" in serialized_data else {},
		"turn_data": serialized_data.turn_data.duplicate(true),
		"fog_of_war_enabled": serialized_data.fog_of_war_enabled if "fog_of_war_enabled" in serialized_data else true,
		"game_settings": serialized_data.game_settings.duplicate(true) if "game_settings" in serialized_data else {}
	}
	
	# Validate reconstructed state
	var validation = validate_game_state(game_state)
	if not validation.valid:
		result.message = "Deserialized state is invalid: " + str(validation.errors)
		return result
	
	result.success = true
	result.game_state = game_state
	result.message = "Game state deserialized successfully"
	return result

# Get game state summary
static func get_game_state_summary(game_state: Dictionary) -> Dictionary:
	var summary = {
		"valid": false,
		"grid_points": 0,
		"grid_edges": 0,
		"player_count": 0,
		"unit_count": 0,
		"domain_count": 0,
		"current_turn": 0,
		"current_player": "",
		"fog_enabled": false,
		"game_active": false
	}
	
	if game_state.is_empty():
		return summary
	
	# Grid info
	if "grid" in game_state:
		summary.grid_points = game_state.grid.points.size() if "points" in game_state.grid else 0
		summary.grid_edges = game_state.grid.edges.size() if "edges" in game_state.grid else 0
	
	# Players info
	if "players" in game_state:
		summary.player_count = game_state.players.size()
	
	# Units info
	if "units" in game_state:
		summary.unit_count = game_state.units.size()
	
	# Domains info
	if "domains" in game_state:
		summary.domain_count = game_state.domains.size()
	
	# Turn info
	if "turn_data" in game_state:
		summary.current_turn = game_state.turn_data.turn_number if "turn_number" in game_state.turn_data else 0
		summary.game_active = game_state.turn_data.is_game_active if "is_game_active" in game_state.turn_data else false
		
		if "current_player_id" in game_state.turn_data and "players" in game_state:
			var player_id = game_state.turn_data.current_player_id
			if player_id in game_state.players:
				summary.current_player = game_state.players[player_id].name
	
	# Fog info
	summary.fog_enabled = game_state.fog_of_war_enabled if "fog_of_war_enabled" in game_state else false
	
	summary.valid = true
	return summary

# Create empty game state template
static func create_empty_game_state() -> Dictionary:
	return {
		"grid": {"points": {}, "edges": {}, "radius": 0},
		"players": {},
		"units": {},
		"domains": {},
		"turn_data": {"current_player_id": 1, "turn_number": 1, "is_game_active": false},
		"fog_of_war_enabled": true,
		"game_settings": {}
	}

# Helper functions for validation
static func _validate_grid(grid_data: Dictionary) -> Dictionary:
	var result = {"errors": [], "warnings": []}
	
	if not ("points" in grid_data and "edges" in grid_data):
		result.errors.append("Grid missing points or edges")
	
	if "points" in grid_data and grid_data.points.size() == 0:
		result.warnings.append("Grid has no points")
	
	return result

static func _validate_players(players_data: Dictionary) -> Dictionary:
	var result = {"errors": [], "warnings": []}
	
	if players_data.size() == 0:
		result.errors.append("No players defined")
	
	for player_id in players_data:
		var player = players_data[player_id]
		# Simple check - players from our clean classes should have these as properties
		if not player:
			result.errors.append("Player %s is null" % player_id)
	
	return result

static func _validate_units(units_data: Dictionary, players_data: Dictionary) -> Dictionary:
	var result = {"errors": [], "warnings": []}
	
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if not unit:
			result.errors.append("Unit %s is null" % unit_id)
		elif unit.owner_id not in players_data:
			result.errors.append("Unit %s has invalid owner_id" % unit_id)
	
	return result

static func _validate_turn_data(turn_data: Dictionary, players_data: Dictionary) -> Dictionary:
	var result = {"errors": [], "warnings": []}
	
	if not ("current_player_id" in turn_data):
		result.errors.append("Turn data missing current_player_id")
	elif "current_player_id" in turn_data and turn_data.current_player_id not in players_data:
		result.errors.append("Turn data has invalid current_player_id")
	
	return result

# Helper functions for serialization
static func _serialize_grid(grid_data: Dictionary) -> Dictionary:
	# Grid data is already serializable
	return grid_data.duplicate(true)

static func _serialize_players(players_data: Dictionary) -> Dictionary:
	var serialized = {}
	for player_id in players_data:
		var player = players_data[player_id]
		serialized[player_id] = {
			"id": player.id,
			"name": player.name,
			"color": {"r": player.color.r, "g": player.color.g, "b": player.color.b, "a": player.color.a},
			"unit_ids": player.unit_ids.duplicate(),
			"domain_ids": player.domain_ids.duplicate(),
			"is_active": player.is_active,
			"is_eliminated": player.is_eliminated
		}
	return serialized

static func _serialize_units(units_data: Dictionary) -> Dictionary:
	var serialized = {}
	for unit_id in units_data:
		var unit = units_data[unit_id]
		serialized[unit_id] = {
			"id": unit.id,
			"owner_id": unit.owner_id,
			"name": unit.name,
			"position": {
				"hex_coord": {"q": unit.position.hex_coord.q, "r": unit.position.hex_coord.r},
				"pixel_pos": {"x": unit.position.pixel_pos.x, "y": unit.position.pixel_pos.y}
			},
			"actions_remaining": unit.actions_remaining,
			"is_revealed": unit.is_revealed,
			"force_revealed": unit.force_revealed
		}
	return serialized

static func _serialize_domains(domains_data: Dictionary) -> Dictionary:
	# Domains are already simple dictionaries
	return domains_data.duplicate(true)

# Helper functions for deserialization
static func _deserialize_grid(grid_data: Dictionary) -> Dictionary:
	return grid_data.duplicate(true)

static func _deserialize_players(players_data: Dictionary) -> Dictionary:
	var deserialized = {}
	var Player = load("res://core/entities/player_clean.gd")
	
	for player_id in players_data:
		var player_data = players_data[player_id]
		var color = Color(player_data.color.r, player_data.color.g, player_data.color.b, player_data.color.a)
		var player = Player.new(player_data.id, player_data.name, color)
		
		player.unit_ids = player_data.unit_ids.duplicate()
		player.domain_ids = player_data.domain_ids.duplicate()
		player.is_active = player_data.is_active
		player.is_eliminated = player_data.is_eliminated
		
		deserialized[player_id] = player
	
	return deserialized

static func _deserialize_units(units_data: Dictionary) -> Dictionary:
	var deserialized = {}
	var Unit = load("res://core/entities/unit_clean.gd")
	var HexCoordinate = load("res://core/value_objects/hex_coordinate_clean.gd")
	var Position = load("res://core/value_objects/position_clean.gd")
	
	for unit_id in units_data:
		var unit_data = units_data[unit_id]
		
		# Reconstruct position
		var coord = HexCoordinate.new(unit_data.position.hex_coord.q, unit_data.position.hex_coord.r)
		var pixel_pos = Vector2(unit_data.position.pixel_pos.x, unit_data.position.pixel_pos.y)
		var position = Position.new(coord, pixel_pos)
		
		# Create unit
		var unit = Unit.new(unit_data.id, unit_data.owner_id, unit_data.name, position)
		unit.actions_remaining = unit_data.actions_remaining
		unit.is_revealed = unit_data.is_revealed
		unit.force_revealed = unit_data.force_revealed
		
		deserialized[unit_id] = unit
	
	return deserialized

static func _deserialize_domains(domains_data: Dictionary) -> Dictionary:
	return domains_data.duplicate(true)