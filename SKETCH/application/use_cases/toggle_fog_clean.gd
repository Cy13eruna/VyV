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
static func get_visibility_settings(game_state: Dictionary, player_id: int) -> Dictionary:
	var settings = {
		"fog_enabled": false,
		"show_all_units": true,
		"show_all_grid": true,
		"show_all_domains": true,
		"player_id": player_id
	}
	
	if _validate_game_state_simple(game_state):
		settings.fog_enabled = game_state.fog_of_war_enabled
		
		if settings.fog_enabled:
			settings.show_all_units = false
			settings.show_all_grid = false
			settings.show_all_domains = false
	
	return settings

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
	# Own units are always visible
	if unit.owner_id == player_id:
		return true
	
	# Enemy units are visible if revealed or force revealed
	return unit.is_revealed or unit.force_revealed

# Helper: Check if domain is visible to player
static func _is_domain_visible(domain, player_id: int, game_state: Dictionary) -> bool:
	# Own domains are always visible
	if domain.owner_id == player_id:
		return true
	
	# Enemy domains are visible if adjacent to own units (future implementation)
	return true  # For now, all domains are visible

# Helper: Check if grid point is visible to player
static func _is_grid_point_visible(point, player_id: int, game_state: Dictionary) -> bool:
	# For now, all grid points are visible
	# Future: Implement exploration-based visibility
	return true

# Validate game state
static func _validate_game_state(game_state: Dictionary, result: Dictionary) -> bool:
	if not _validate_game_state_simple(game_state):
		result.message = "Invalid game state - missing fog_of_war_enabled field"
		return false
	
	return true

# Simple validation
static func _validate_game_state_simple(game_state: Dictionary) -> bool:
	return "fog_of_war_enabled" in game_state