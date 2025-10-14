# 🌫️ FOG STATE MANAGER
# Purpose: Manage fog of war state and remembered terrain
# Layer: Application Services - Fog of War

extends RefCounted
class_name FogStateManager

# Execute fog of war toggle
static func execute_toggle(game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"fog_enabled": false,
		"previous_state": false
	}
	
	# Validate game state
	if not _validate_game_state(game_state, result):
		return result
	
	# Store previous state
	result.previous_state = game_state.fog_of_war_enabled
	
	# Toggle fog of war
	game_state.fog_of_war_enabled = not game_state.fog_of_war_enabled
	result.fog_enabled = game_state.fog_of_war_enabled
	result.success = true
	
	# Set appropriate message
	if result.fog_enabled:
		result.message = "Fog of war enabled - limited visibility"
	else:
		result.message = "Fog of war disabled - full visibility"
	
	return result

# Enable fog of war
static func enable_fog(game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"fog_enabled": false,
		"was_already_enabled": false
	}
	
	if not _validate_game_state(game_state, result):
		return result
	
	result.was_already_enabled = game_state.fog_of_war_enabled
	
	if result.was_already_enabled:
		result.message = "Fog of war was already enabled"
	else:
		game_state.fog_of_war_enabled = true
		result.message = "Fog of war enabled"
	
	result.fog_enabled = true
	result.success = true
	
	return result

# Disable fog of war
static func disable_fog(game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"fog_enabled": false,
		"was_already_disabled": false
	}
	
	if not _validate_game_state(game_state, result):
		return result
	
	result.was_already_disabled = not game_state.fog_of_war_enabled
	
	if result.was_already_disabled:
		result.message = "Fog of war was already disabled"
	else:
		game_state.fog_of_war_enabled = false
		result.message = "Fog of war disabled"
	
	result.fog_enabled = false
	result.success = true
	
	return result

# Set fog of war to specific state
static func set_fog_state(game_state: Dictionary, enabled: bool) -> Dictionary:
	if enabled:
		return enable_fog(game_state)
	else:
		return disable_fog(game_state)

# Get fog of war status
static func get_fog_status(game_state: Dictionary) -> Dictionary:
	var status = {
		"valid": false,
		"fog_enabled": false,
		"visibility_mode": "",
		"affected_elements": []
	}
	
	if not _validate_game_state_simple(game_state):
		return status
	
	status.valid = true
	status.fog_enabled = game_state.fog_of_war_enabled
	
	if status.fog_enabled:
		status.visibility_mode = "Limited - based on unit positions and terrain"
		status.affected_elements = [
			"Enemy units (hidden unless revealed)",
			"Grid points (limited to visible areas)",
			"Domain information (own domains always visible)",
			"Terrain details (limited to explored areas)"
		]
	else:
		status.visibility_mode = "Full - all elements visible"
		status.affected_elements = [
			"All units visible",
			"Complete grid visible",
			"All domain information visible",
			"Full terrain details visible"
		]
	
	return status

# Get visibility settings for current player
static func get_visibility_settings(game_state: Dictionary, player_id: int) -> Dictionary:
	# Initialize remembered terrain if not exists
	if not "remembered_terrain" in game_state:
		game_state.remembered_terrain = {}
	
	if not player_id in game_state.remembered_terrain:
		game_state.remembered_terrain[player_id] = {
			"points": {},
			"edges": {}
		}
	
	# Update remembered terrain based on current visibility
	update_remembered_terrain(game_state, player_id)
	
	return {
		"fog_enabled": game_state.get("fog_of_war_enabled", false),
		"player_id": player_id,
		"remembered_terrain": game_state.remembered_terrain[player_id]
	}

# Update remembered terrain for player based on current visibility
static func update_remembered_terrain(game_state: Dictionary, player_id: int) -> void:
	if not ("grid" in game_state and "remembered_terrain" in game_state):
		return
	
	var remembered = game_state.remembered_terrain[player_id]
	
	# Import visibility calculator for position checks
	var FogVisibilityCalculator = load("res://application/services/fog_of_war/fog_visibility_calculator.gd")
	
	# Check all points and edges for current visibility
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if FogVisibilityCalculator.is_position_visible_to_player(point.position, player_id, game_state):
			# Point is currently visible - remember it
			remembered.points[point_id] = {
				"position": point.position,
				"is_corner": point.get("is_corner", false)
			}
	
	for edge_id in game_state.grid.edges:
		var edge = game_state.grid.edges[edge_id]
		if FogVisibilityCalculator.is_edge_visible_to_player(edge, player_id, game_state):
			# Edge is currently visible - remember it
			remembered.edges[edge_id] = {
				"point_a_id": edge.point_a_id,
				"point_b_id": edge.point_b_id,
				"terrain_type": edge.get("terrain_type", 0)
			}

# Check if point/edge is remembered by player
static func is_remembered_by_player(element_type: String, element_id: int, player_id: int, game_state: Dictionary) -> bool:
	if not ("remembered_terrain" in game_state and player_id in game_state.remembered_terrain):
		return false
	
	var remembered = game_state.remembered_terrain[player_id]
	
	match element_type:
		"point":
			return element_id in remembered.points
		"edge":
			return element_id in remembered.edges
		_:
			return false

# Initialize fog of war system for new game
static func initialize_fog_system(game_state: Dictionary) -> void:
	# Set default fog state
	if not "fog_of_war_enabled" in game_state:
		game_state.fog_of_war_enabled = false
	
	# Initialize remembered terrain structure
	if not "remembered_terrain" in game_state:
		game_state.remembered_terrain = {}

# Clear remembered terrain for all players (for new game)
static func clear_all_remembered_terrain(game_state: Dictionary) -> void:
	if "remembered_terrain" in game_state:
		game_state.remembered_terrain.clear()

# Clear remembered terrain for specific player
static func clear_player_remembered_terrain(game_state: Dictionary, player_id: int) -> void:
	if "remembered_terrain" in game_state and player_id in game_state.remembered_terrain:
		game_state.remembered_terrain[player_id] = {
			"points": {},
			"edges": {}
		}

# Get remembered terrain data for player
static func get_player_remembered_terrain(game_state: Dictionary, player_id: int) -> Dictionary:
	if not ("remembered_terrain" in game_state and player_id in game_state.remembered_terrain):
		return {"points": {}, "edges": {}}
	
	return game_state.remembered_terrain[player_id]

# Export fog settings for rendering systems
static func export_fog_settings_for_rendering(game_state: Dictionary, player_id: int) -> Dictionary:
	return {
		"fog_of_war_enabled": game_state.get("fog_of_war_enabled", false),
		"player_id": player_id,
		"remembered_terrain": get_player_remembered_terrain(game_state, player_id)
	}

# Validate game state
static func _validate_game_state(game_state: Dictionary, result: Dictionary) -> bool:
	if not _validate_game_state_simple(game_state):
		result.message = "Invalid game state - missing fog_of_war_enabled field"
		return false
	
	return true

# Simple validation
static func _validate_game_state_simple(game_state: Dictionary) -> bool:
	return "fog_of_war_enabled" in game_state

# Get fog system statistics
static func get_fog_statistics(game_state: Dictionary) -> Dictionary:
	var stats = {
		"fog_enabled": game_state.get("fog_of_war_enabled", false),
		"players_with_remembered_terrain": 0,
		"total_remembered_points": 0,
		"total_remembered_edges": 0,
		"player_details": {}
	}
	
	if "remembered_terrain" in game_state:
		stats.players_with_remembered_terrain = game_state.remembered_terrain.size()
		
		for player_id in game_state.remembered_terrain:
			var player_data = game_state.remembered_terrain[player_id]
			var points_count = player_data.get("points", {}).size()
			var edges_count = player_data.get("edges", {}).size()
			
			stats.total_remembered_points += points_count
			stats.total_remembered_edges += edges_count
			
			stats.player_details[player_id] = {
				"remembered_points": points_count,
				"remembered_edges": edges_count
			}
	
	return stats