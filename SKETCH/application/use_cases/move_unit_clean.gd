# 🚶 MOVE UNIT USE CASE (CLEAN)
# Purpose: Orchestrate unit movement with all validations
# Layer: Application/UseCases
# Dependencies: Clean services

extends RefCounted

# Preload clean services
const MovementService = preload("res://application/services/movement_service_clean.gd")
const TurnService = preload("res://application/services/turn_service_clean.gd")

# Execute unit movement
static func execute(unit_id: int, target_position, game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"action_consumed": false,
		"power_consumed": false,
		"turn_advanced": false,
		"new_player_id": -1
	}
	
	# Validate inputs
	if not _validate_inputs(unit_id, target_position, game_state, result):
		return result
	
	var unit = game_state.units[unit_id]
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	
	# Check if it's player's turn
	if not current_player or current_player.id != unit.owner_id:
		result.message = "Not your turn"
		return result
	
	# Check if unit can move
	if not unit.can_move():
		result.message = "Unit has no actions remaining"
		return result
	
	# Validate movement using MovementService with terrain and fog restrictions
	if not MovementService.can_unit_move_to(unit, target_position, game_state.grid, game_state.units, game_state):
		result.message = _get_movement_restriction_message(unit, target_position, game_state)
		return result
	
	# Calculate power cost (future: check if moving outside own domain)
	var needs_power = _calculate_power_cost(unit, target_position, game_state)
	if needs_power > 0:
		if not _can_afford_power(unit.owner_id, needs_power, game_state):
			result.message = "Insufficient power"
			return result
	
	# Execute movement using MovementService
	if MovementService.move_unit_to(unit, target_position, game_state.grid, game_state.units):
		result.success = true
		result.action_consumed = true
		result.message = "Movement successful"
		
		# Consume power if needed
		if needs_power > 0:
			_consume_power(unit.owner_id, needs_power, game_state)
			result.power_consumed = true
		
		# Update domain occupations (future implementation)
		_update_domain_occupations(game_state)
		
		# Check if turn should advance
		if not TurnService.can_current_player_act(game_state.turn_data, game_state.players, game_state.units):
			if TurnService.advance_to_next_turn(game_state.turn_data, game_state.players, game_state.units, game_state.domains):
				result.turn_advanced = true
				result.new_player_id = game_state.turn_data.current_player_id
	else:
		result.message = "Movement execution failed"
	
	return result

# Validate inputs
static func _validate_inputs(unit_id: int, target_position, game_state: Dictionary, result: Dictionary) -> bool:
	# Check game state structure
	if not ("units" in game_state and "players" in game_state and "turn_data" in game_state):
		result.message = "Invalid game state"
		return false
	
	# Check unit exists
	if unit_id not in game_state.units:
		result.message = "Unit not found"
		return false
	
	# Check target position is valid
	if not target_position:
		result.message = "Invalid target position"
		return false
	
	return true

# Calculate power cost for movement (future implementation)
static func _calculate_power_cost(unit, target_position, game_state: Dictionary) -> int:
	# Future: Check if moving outside own domain
	# For now, all movement is free
	return 0

# Check if player can afford power cost
static func _can_afford_power(player_id: int, cost: int, game_state: Dictionary) -> bool:
	if cost <= 0:
		return true
	
	# Future: Check player's total power from domains
	var total_power = _get_player_total_power(player_id, game_state)
	return total_power >= cost

# Get player's total power from domains
static func _get_player_total_power(player_id: int, game_state: Dictionary) -> int:
	var total_power = 0
	
	if "domains" in game_state:
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			if domain.owner_id == player_id:
				total_power += domain.power
	
	return total_power

# Consume power from player's domains
static func _consume_power(player_id: int, cost: int, game_state: Dictionary) -> void:
	if cost <= 0 or not ("domains" in game_state):
		return
	
	var remaining_cost = cost
	
	# Consume power from player's domains
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == player_id and remaining_cost > 0:
			var consumed = min(domain.power, remaining_cost)
			domain.power -= consumed
			remaining_cost -= consumed

# Update domain occupations based on unit positions
static func _update_domain_occupations(game_state: Dictionary) -> void:
	if not ("domains" in game_state and "units" in game_state):
		return
	
	# Reset all occupations
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		domain.is_occupied = false
		domain.occupied_by_player = -1
	
	# Check which domains are occupied by units
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			
			# Check if unit is close to domain center (simple distance check)
			var distance = unit.position.distance_to(domain.center_position)
			if distance <= 1:  # Adjacent or same position
				domain.is_occupied = true
				domain.occupied_by_player = unit.owner_id
				break

# Get specific movement restriction message
static func _get_movement_restriction_message(unit, target_position, game_state: Dictionary) -> String:
	# Check specific restrictions to give better feedback
	
	# Check if position is occupied
	if MovementService._is_position_occupied(target_position, game_state.units):
		return "Position is occupied by another unit"
	
	# Check if position is on grid
	if not MovementService._is_position_on_grid(target_position, game_state.grid):
		return "Position is outside the game area"
	
	# Check terrain restrictions
	var edge = MovementService._get_edge_between_positions(unit.position, target_position, game_state.grid)
	if edge:
		var terrain_type = edge.get("terrain_type", 0)
		match terrain_type:
			2:  # MOUNTAIN
				if unit.actions_remaining < 2:
					return "Cannot cross mountain - requires 2 actions"
			3:  # WATER
				return "Cannot cross water - impassable terrain"
	
	# Check distance
	if unit.position.distance_to(target_position) != 1:
		return "Can only move to adjacent positions"
	
	return "Invalid movement"

# Get movement summary for logging
static func get_movement_summary(unit_id: int, target_position, game_state: Dictionary) -> String:
	if unit_id not in game_state.units:
		return "Invalid unit"
	
	var unit = game_state.units[unit_id]
	var from_coord = unit.position.hex_coord.get_string()
	var to_coord = target_position.hex_coord.get_string()
	
	return "%s moves from %s to %s" % [unit.name, from_coord, to_coord]