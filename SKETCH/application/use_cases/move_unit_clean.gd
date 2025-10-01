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
	print("[MOVE] Starting movement execution for unit %d" % unit_id)
	
	var result = {
		"success": false,
		"message": "",
		"action_consumed": false,
		"power_consumed": false,
		"turn_advanced": false,
		"new_player_id": -1,
		"unit_exhausted": false
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
	
	# Check for forest traversal with enemy blocking (only if unit is not already revealed)
	var forest_block_result = _check_forest_traversal_blocking(unit, target_position, game_state)
	print("[DEBUG] Forest block result: %s" % forest_block_result)
	if forest_block_result.get("blocked", false):
		print("[FOREST] Movement blocked - executing revelation and resource consumption")
		
		# Movement is blocked but action and power are consumed
		result.success = false
		result.action_consumed = true
		result.message = forest_block_result.message
		
		# Consume action and power even though movement failed
		unit.consume_action()
		print("[FOREST] Action consumed - remaining: %d" % unit.actions_remaining)
		
		var needs_power = _calculate_power_cost(unit, target_position, game_state)
		if needs_power > 0:
			_consume_power(unit.owner_id, needs_power, game_state)
			result.power_consumed = true
			print("[FOREST] Power consumed: %d" % needs_power)
		
		# Reveal both units
		_reveal_units_through_forest(unit, target_position, game_state)
		
		# Mark that unit has no more actions (for UI clearing)
		result.unit_exhausted = not unit.can_move()
		
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
		
		# Update domain occupations after movement
		_update_domain_occupations(game_state)
		
		# Check if unit is exhausted after movement
		result.unit_exhausted = not unit.can_move()
		
		# Clear force_revealed status when unit moves (breaks forest revelation)
		_clear_force_revealed_on_movement(unit, game_state)
		
		# REMOVED: Old forest traversal revelation (replaced by blocking system)
		
		# REMOVED: Auto turn advance - now completely manual
		# Players must manually skip turn with ENTER key
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

# Calculate power cost for movement
static func _calculate_power_cost(unit, target_position, game_state: Dictionary) -> int:
	# Check if unit's origin domain is occupied by enemy
	var origin_domain = _find_unit_origin_domain(unit, game_state)
	if origin_domain and origin_domain.get("is_occupied", false):
		print("Unit %s moves for FREE - origin domain %d is occupied!" % [unit.name, origin_domain.id])
		return 0  # Free movement when origin domain is occupied
	
	# Normal movement costs 1 power
	return 1

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
			print("Domain %d consumed %d power: now %d" % [domain_id, consumed, domain.power])
			if remaining_cost <= 0:
				break

# Update domain occupations based on unit positions
static func _update_domain_occupations(game_state: Dictionary) -> void:
	if not ("domains" in game_state and "units" in game_state):
		return
	
	# Reset all occupations
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		domain.is_occupied = false
		domain.occupied_by_player = -1
	
	# Check which domains are occupied by enemy units
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			
			# Only enemy units can occupy domains (not the owner)
			if unit.owner_id != domain.owner_id:
				# Check if unit is exactly at domain center
				if unit.position.equals(domain.center_position):
					domain.is_occupied = true
					domain.occupied_by_player = unit.owner_id
					print("Domain %d occupied by Player %d (enemy unit)" % [domain_id, unit.owner_id])
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

# Find the origin domain of a unit (first domain owned by the same player)
static func _find_unit_origin_domain(unit, game_state: Dictionary):
	if not ("domains" in game_state and "players" in game_state):
		return null
	
	# Get the player and their first domain as origin
	var player = game_state.players.get(unit.owner_id)
	if player and "domain_ids" in player and player.domain_ids.size() > 0:
		var origin_domain_id = player.domain_ids[0]  # First domain is origin
		if origin_domain_id in game_state.domains:
			return game_state.domains[origin_domain_id]
	
	return null

# Clear force_revealed status when any unit moves (breaks forest revelation)
static func _clear_force_revealed_on_movement(moving_unit, game_state: Dictionary) -> void:
	if not ("units" in game_state):
		return
	
	print("[FOREST] Unit %s moved - clearing all force_revealed statuses" % moving_unit.name)
	
	# Clear force_revealed for all units when any unit moves
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if "force_revealed" in unit and unit.force_revealed:
			unit.force_revealed = false
			print("[FOREST] Cleared force_revealed for unit %s" % unit.name)

# Check if forest traversal is blocked by enemy unit
static func _check_forest_traversal_blocking(unit, target_position, game_state: Dictionary) -> Dictionary:
	var result = {
		"blocked": false,
		"message": ""
	}
	
	print("[FOREST] Checking forest traversal blocking for %s" % unit.name)
	
	# If unit is already revealed, don't block forest traversal
	if "force_revealed" in unit and unit.force_revealed:
		print("[FOREST] Unit is already revealed - allowing forest traversal")
		return result
	
	if not ("grid" in game_state and "units" in game_state):
		print("[FOREST] Missing grid or units data")
		return result
	
	# Find the edge being traversed
	var traversed_edge = _find_edge_between_positions(unit.position, target_position, game_state.grid)
	if not traversed_edge:
		print("[FOREST] No edge found between positions")
		return result
	
	# Check if it's a forest
	var terrain_type = traversed_edge.get("terrain_type", 0)
	print("[FOREST] Terrain type: %d" % terrain_type)
	if terrain_type != 1:  # Not a forest
		print("[FOREST] Not a forest - no blocking")
		return result
	
	print("[FOREST] Forest detected - checking for enemy units")
	
	# Check if target position is occupied by enemy unit
	for other_unit_id in game_state.units:
		var other_unit = game_state.units[other_unit_id]
		
		# Skip own units
		if other_unit.owner_id == unit.owner_id:
			continue
		
		# Check if enemy unit is at target position
		print("[FOREST] Checking enemy unit %s at position %s vs target %s" % [other_unit.name, other_unit.position.hex_coord.get_string(), target_position.hex_coord.get_string()])
		if other_unit.position.equals(target_position):
			result.blocked = true
			result.message = "Movement blocked by enemy unit through forest - both units revealed"
			print("[FOREST] Forest traversal blocked: %s vs %s" % [unit.name, other_unit.name])
			break
	
	print("[FOREST] Blocking result: %s" % result.get("blocked", false))
	print("[FOREST] Returning result: %s" % result)
	return result

# Reveal both units when forest traversal is attempted
static func _reveal_units_through_forest(unit, target_position, game_state: Dictionary) -> void:
	print("[FOREST] Starting unit revelation process")
	
	if not ("units" in game_state):
		print("[FOREST] No units data available")
		return
	
	# Reveal the moving unit
	unit.force_revealed = true
	print("[FOREST] Unit %s revealed through forest encounter" % unit.name)
	
	# Find and reveal the blocking enemy unit
	for other_unit_id in game_state.units:
		var other_unit = game_state.units[other_unit_id]
		
		# Skip own units
		if other_unit.owner_id == unit.owner_id:
			continue
		
		# Check if enemy unit is at target position
		print("[FOREST] Revelation - checking enemy unit %s at position %s vs target %s" % [other_unit.name, other_unit.position.hex_coord.get_string(), target_position.hex_coord.get_string()])
		if other_unit.position.equals(target_position):
			other_unit.force_revealed = true
			print("[FOREST] Enemy unit %s revealed through forest encounter" % other_unit.name)
			break
	
	print("[FOREST] Unit revelation process completed")

# Check for forest traversal and reveal enemy units on the other side
static func _check_forest_traversal_revelation(unit, target_position, game_state: Dictionary) -> void:
	if not ("grid" in game_state and "units" in game_state):
		return
	
	# Find the edge that was just traversed
	var traversed_edge = _find_edge_between_positions(unit.position, target_position, game_state.grid)
	if not traversed_edge:
		return
	
	# Check if the traversed edge is a forest
	var terrain_type = traversed_edge.get("terrain_type", 0)
	if terrain_type != 1:  # Not a forest
		return
	
	print("Unit %s traversed forest - checking for enemy revelation" % unit.name)
	
	# Look for enemy units on the other side (adjacent to target position)
	for other_unit_id in game_state.units:
		var other_unit = game_state.units[other_unit_id]
		
		# Skip own units
		if other_unit.owner_id == unit.owner_id:
			continue
		
		# Check if enemy unit is adjacent to where we just moved
		if other_unit.position.is_within_distance(target_position, 1):
			# Reveal the enemy unit
			other_unit.force_revealed = true
			print("Enemy unit %s revealed by forest traversal!" % other_unit.name)

# Find edge between two positions (local helper function)
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