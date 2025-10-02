# 👁️ TOGGLE FOG USE CASE (CLEAN)
# Purpose: Control fog of war visibility system
# Layer: Application/UseCases
# Dependencies: None (simple state toggle)

extends RefCounted

# Execute fog of war toggle
static func execute(game_state: Dictionary) -> Dictionary:
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

# Set fog of war to specific state
static func set_fog_state(game_state: Dictionary, enabled: bool) -> Dictionary:
	if enabled:
		return enable_fog(game_state)
	else:
		return disable_fog(game_state)

# Get visibility settings for rendering
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
	_update_remembered_terrain(game_state, player_id)
	
	return {
		"fog_enabled": game_state.get("fog_of_war_enabled", false),
		"player_id": player_id,
		"remembered_terrain": game_state.remembered_terrain[player_id]
	}

# Check if element should be visible to player
static func is_visible_to_player(element_type: String, element_data, player_id: int, game_state: Dictionary) -> bool:
	if not _validate_game_state_simple(game_state):
		return true  # Default to visible if invalid state
	
	# If fog is disabled, everything is visible
	if not game_state.fog_of_war_enabled:
		return true
	
	# Fog is enabled - check visibility rules
	match element_type:
		"unit":
			return _is_unit_visible(element_data, player_id, game_state)
		"domain":
			return _is_domain_visible(element_data, player_id, game_state)
		"grid_point":
			return _is_grid_point_visible(element_data, player_id, game_state)
		_:
			return true  # Unknown elements default to visible

# Helper: Check if unit is visible to player
static func _is_unit_visible(unit, player_id: int, game_state: Dictionary) -> bool:
	# Safety check
	if unit == null:
		return false
	
	# Own units are always visible (special case)
	if unit.owner_id == player_id:
		return true
	
	# Enemy units are visible if force revealed (forest traversal)
	if "force_revealed" in unit and unit.force_revealed:
		return true
	
	# Enemy units are visible only if their position is within visibility
	if _is_position_visible_to_player(unit.position, player_id, game_state):
		return true
	
	return false

# Update remembered terrain for player based on current visibility
static func _update_remembered_terrain(game_state: Dictionary, player_id: int) -> void:
	if not ("grid" in game_state and "remembered_terrain" in game_state):
		return
	
	var remembered = game_state.remembered_terrain[player_id]
	
	# Check all points and edges for current visibility
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if _is_position_visible_to_player(point.position, player_id, game_state):
			# Point is currently visible - remember it
			remembered.points[point_id] = {
				"position": point.position,
				"is_corner": point.get("is_corner", false)
			}
	
	for edge_id in game_state.grid.edges:
		var edge = game_state.grid.edges[edge_id]
		if _is_edge_visible_to_player(edge, player_id, game_state):
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

# Check if vision is blocked by terrain (mountains/forests)
static func _is_vision_blocked_by_terrain(from_position, to_position, game_state: Dictionary) -> bool:
	if not ("grid" in game_state):
		return false
	
	# Find the edge between the two positions
	var blocking_edge = _find_edge_between_positions(from_position, to_position, game_state.grid)
	if not blocking_edge:
		return false
	
	# Check if the edge has blocking terrain
	var terrain_type = blocking_edge.get("terrain_type", 0)
	match terrain_type:
		2:  # MOUNTAIN - blocks vision
			return true
		1:  # FOREST - blocks vision
			return true
		_:  # FIELD, WATER - don't block vision
			return false

# Find edge between two positions
static func _find_edge_between_positions(pos_a, pos_b, grid_data: Dictionary):
	if not ("points" in grid_data and "edges" in grid_data):
		return null
	
	# Find points at the given positions
	var point_a = null
	var point_b = null
	
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.position.equals(pos_a):
			point_a = point
		elif point.position.equals(pos_b):
			point_b = point
	
	if not (point_a and point_b):
		return null
	
	# Find edge connecting these points
	for edge_id in grid_data.edges:
		var edge = grid_data.edges[edge_id]
		if (edge.point_a_id == point_a.id and edge.point_b_id == point_b.id) or \
		   (edge.point_a_id == point_b.id and edge.point_b_id == point_a.id):
			return edge
	
	return null

# Helper: Check if domain is visible to player
static func _is_domain_visible(domain, player_id: int, game_state: Dictionary) -> bool:
	# Own domains are always visible
	if domain.owner_id == player_id:
		return true
	
	# Enemy domains are visible if their center is visible
	if _is_position_visible_to_player(domain.center_position, player_id, game_state):
		return true
	
	return false

# Helper: Check if grid point is visible to player
static func _is_grid_point_visible(point, player_id: int, game_state: Dictionary) -> bool:
	# Check if point is visible through normal visibility rules
	if _is_position_visible_to_player(point.position, player_id, game_state):
		return true
	
	# Special case: point is visible if a player's unit is standing on it
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id == player_id and unit.position.equals(point.position):
			return true
	
	return false

# Validate game state
static func _validate_game_state(game_state: Dictionary, result: Dictionary) -> bool:
	if not _validate_game_state_simple(game_state):
		result.message = "Invalid game state - missing fog_of_war_enabled field"
		return false
	
	return true

# Simple validation
static func _validate_game_state_simple(game_state: Dictionary) -> bool:
	return "fog_of_war_enabled" in game_state

# Check if a position is visible to a specific player
static func _is_position_visible_to_player(position, player_id: int, game_state: Dictionary) -> bool:
	if not ("units" in game_state and "domains" in game_state and "grid" in game_state):
		return false
	
	# Check visibility from player's units (7 points: own position + 6 adjacent)
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id == player_id:
			# Unit can see its own position AND 6 adjacent hexes (7 total)
			if unit.position.equals(position):
				# Unit can always see its own position
				return true
			elif unit.position.is_within_distance(position, 1):
				# Check if vision is blocked by terrain (mountains/forests)
				if not _is_vision_blocked_by_terrain(unit.position, position, game_state):
					return true
	
	# Check visibility from player's domains (ONLY 7 internal points)
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == player_id:
			# Domain can see ONLY its internal 7 points (center + 6 that COMPOSE the domain)
			if domain.center_position.equals(position):
				return true
			
			# Domain can see ONLY 6 points that COMPOSE the domain (internal, not external)
			if domain.center_position.is_within_distance(position, 1):
				return true
	
	return false

# Check if an edge/path is visible to a specific player
static func _is_edge_visible_to_player(edge, player_id: int, game_state: Dictionary) -> bool:
	if not ("units" in game_state and "domains" in game_state and "grid" in game_state):
		return false
	
	# Get the two points connected by this edge
	var point_a = game_state.grid.points.get(edge.point_a_id)
	var point_b = game_state.grid.points.get(edge.point_b_id)
	
	if not (point_a and point_b):
		return false
	
	# Check if this edge is visible from units (6 paths from unit position + paths within unit's visibility)
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id == player_id:
			# Edge is visible if it connects unit's position to an adjacent point
			if (unit.position.equals(point_a.position) and unit.position.is_within_distance(point_b.position, 1)) or \
			   (unit.position.equals(point_b.position) and unit.position.is_within_distance(point_a.position, 1)):
				return true
			# Edge is also visible if both endpoints are visible to the unit
			if _is_position_visible_to_player(point_a.position, player_id, game_state) and \
			   _is_position_visible_to_player(point_b.position, player_id, game_state):
				return true
	
	# Check if this edge is visible from domains (12 internal paths)
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == player_id:
			# Edge is visible if both endpoints are within the domain (internal paths only)
			var a_in_domain = domain.center_position.equals(point_a.position) or domain.center_position.is_within_distance(point_a.position, 1)
			var b_in_domain = domain.center_position.equals(point_b.position) or domain.center_position.is_within_distance(point_b.position, 1)
			
			if a_in_domain and b_in_domain:
				return true
	
	return false