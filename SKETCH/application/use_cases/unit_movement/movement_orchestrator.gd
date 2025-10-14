# 🎯 MOVEMENT ORCHESTRATOR
# Purpose: Orchestrate unit movement with validations and execution
# Layer: Application Use Cases - Unit Movement

extends RefCounted
class_name MovementOrchestrator

# Preload clean services
const MovementService = preload("res://application/services/movement_service.gd")
const TurnService = preload("res://application/services/turn_service_clean.gd")
const UnitMovementTracker = preload("res://core/value_objects/unit_movement_tracker.gd")

# Execute unit movement
static func execute(unit_id: int, target_position, game_state: Dictionary) -> Dictionary:
	
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
	if not validate_inputs(unit_id, target_position, game_state, result):
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
		result.message = get_movement_restriction_message(unit, target_position, game_state)
		return result
	
	# Import power manager for power calculations
	var MovementPowerManager = load("res://application/use_cases/unit_movement/movement_power_manager.gd")
	
	# Calculate power cost (check if moving outside own domain)
	var needs_power = MovementPowerManager.calculate_power_cost(unit, target_position, game_state)
	if needs_power > 0:
		if not MovementPowerManager.can_afford_power(unit, needs_power, game_state):
			result.message = "Insufficient power in natal domain"
			return result
	
	# Store original position for movement tracking
	var original_position = unit.position
	
	# Execute movement using MovementService
	if MovementService.move_unit_to(unit, target_position, game_state.grid, game_state.units, game_state):
		# Track unit movement direction for emoji effects
		UnitMovementTracker.track_unit_movement(unit_id, original_position, target_position)
		
		result.success = true
		result.action_consumed = true
		result.message = "Movement successful"
		
		# Consume power if needed (from natal domain only)
		if needs_power > 0:
			if MovementPowerManager.consume_power_from_natal_domain(unit, needs_power, game_state):
				result.power_consumed = true
			else:
				# This should not happen as we already checked can_afford_power
				result.success = false
				result.message = "Failed to consume power from natal domain"
				return result
		
		# Update domain occupations after movement
		MovementPowerManager.update_domain_occupations(game_state)
		
		# Check if unit is exhausted after movement
		result.unit_exhausted = not unit.can_move()
		
		# Clear force_revealed status when unit moves (breaks forest revelation)
		clear_force_revealed_on_movement(unit, game_state)
		
		# REMOVED: Old forest traversal revelation (replaced by blocking system)
		
		# REMOVED: Auto turn advance - now completely manual
		# Players must manually skip turn with ENTER key
	else:
		result.message = "Movement execution failed"
	
	return result

# Validate inputs
static func validate_inputs(unit_id: int, target_position, game_state: Dictionary, result: Dictionary) -> bool:
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

# Get specific movement restriction message
static func get_movement_restriction_message(unit, target_position, game_state: Dictionary) -> String:
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

# Clear force_revealed status when unit moves (breaks only related revelations)
static func clear_force_revealed_on_movement(moving_unit, game_state: Dictionary) -> void:
	if not ("units" in game_state):
		return
	
	# Initialize revelation pairs if not exists
	if not "revelation_pairs" in game_state:
		game_state.revelation_pairs = []
	
	
	# Find and remove revelation pairs involving this unit
	var pairs_to_remove = []
	for i in range(game_state.revelation_pairs.size()):
		var pair = game_state.revelation_pairs[i]
		if pair.unit_a_id == moving_unit.id or pair.unit_b_id == moving_unit.id:
			pairs_to_remove.append(i)
			# Clear force_revealed for both units in the pair
			var unit_a = game_state.units.get(pair.unit_a_id)
			var unit_b = game_state.units.get(pair.unit_b_id)
			if unit_a:
				unit_a.force_revealed = false
			if unit_b:
				unit_b.force_revealed = false
	
	# Remove pairs in reverse order to maintain indices
	for i in range(pairs_to_remove.size() - 1, -1, -1):
		game_state.revelation_pairs.remove_at(pairs_to_remove[i])

# Check for forest traversal and reveal enemy units on the other side
static func check_forest_traversal_revelation(unit, target_position, game_state: Dictionary) -> void:
	if not ("grid" in game_state and "units" in game_state):
		return
	
	# Find the edge that was just traversed
	var traversed_edge = find_edge_between_positions(unit.position, target_position, game_state.grid)
	if not traversed_edge:
		return
	
	# Check if the traversed edge is a forest
	var terrain_type = traversed_edge.get("terrain_type", 0)
	if terrain_type != 1:  # Not a forest
		return
	
	
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

# Cache for edge lookups (simple performance optimization)
static var _edge_cache: Dictionary = {}

# Find edge between two positions (with caching)
static func find_edge_between_positions(pos1, pos2, grid_data: Dictionary):
	if not ("points" in grid_data and "edges" in grid_data):
		return null
	
	# Create cache key from positions
	var cache_key = "%s-%s" % [pos1.hex_coord.get_string(), pos2.hex_coord.get_string()]
	var reverse_key = "%s-%s" % [pos2.hex_coord.get_string(), pos1.hex_coord.get_string()]
	
	# Check cache first
	if cache_key in _edge_cache:
		return _edge_cache[cache_key]
	if reverse_key in _edge_cache:
		return _edge_cache[reverse_key]
	
	# Find points at the given positions
	var point_a = null
	var point_b = null
	
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.position.equals(pos1):
			point_a = point
		elif point.position.equals(pos2):
			point_b = point
	
	if not (point_a and point_b):
		return null
	
	# Find edge connecting these points
	for edge_id in grid_data.edges:
		var edge = grid_data.edges[edge_id]
		if (edge.point_a_id == point_a.id and edge.point_b_id == point_b.id) or \
		   (edge.point_a_id == point_b.id and edge.point_b_id == point_a.id):
			# Cache the result before returning
			_edge_cache[cache_key] = edge
			return edge
	
	# Cache null result to avoid repeated searches
	_edge_cache[cache_key] = null
	return null

# Clear edge cache (for testing or memory management)
static func clear_edge_cache():
	_edge_cache.clear()