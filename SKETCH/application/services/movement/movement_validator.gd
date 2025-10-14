# ✅ MOVEMENT VALIDATOR
# Purpose: Validate movement rules and restrictions
# Layer: Application Services - Movement

extends RefCounted
class_name MovementValidator

# Validate if unit can move to target position
static func can_unit_move_to(unit, target_position, grid_data: Dictionary, units_data: Dictionary, game_state: Dictionary = {}) -> bool:
	# Check if unit has actions
	if not unit.can_move():
		return false
	
	# Check if target position exists on grid
	if not _is_position_on_grid(target_position, grid_data):
		return false
	
	# Check if target position is occupied (with forest exception)
	var is_occupied = _is_position_occupied_with_forest_exception(unit, target_position, grid_data, units_data)
	if is_occupied:
		return false
	
	# Check if target is adjacent (distance = 1) - required for all movement
	var distance = unit.position.distance_to(target_position)
	if distance != 1:
		return false
	
	# FREE MOVEMENT WITHIN DOMAIN: Check if both positions are in the same domain
	var is_domain_movement = are_positions_in_same_domain(unit, unit.position, target_position, game_state)
	if is_domain_movement:
		# Allow free movement within domain - ignore terrain restrictions but keep adjacency
		return true
	
	# Check terrain restrictions
	if not can_move_through_terrain(unit, target_position, grid_data):
		return false
	
	# Check fog of war restrictions
	if not _can_move_through_fog(unit, target_position, game_state):
		return false
	
	return true

# Execute unit movement
static func move_unit_to(unit, target_position, grid_data: Dictionary, units_data: Dictionary, game_state: Dictionary = {}) -> bool:
	if not can_unit_move_to(unit, target_position, grid_data, units_data, game_state):
		return false
	
	# Execute the movement
	return unit.move_to(target_position)

# Check if position is within unit's domain (for free movement)
static func is_position_in_unit_domain(unit, position, game_state: Dictionary) -> bool:
	if game_state.is_empty() or not "domains" in game_state:
		return false
	
	# Find unit's domain
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == unit.owner_id:
			# Check if position is the domain center
			if domain.center_position.equals(position):
				return true
			
			# Check if position is within domain radius (adjacent to center)
			if domain.center_position.is_within_distance(position, 1):
				return true
	
	return false

# Check if both positions are within the same domain
static func are_positions_in_same_domain(unit, from_position, to_position, game_state: Dictionary) -> bool:
	var from_in_domain = is_position_in_unit_domain(unit, from_position, game_state)
	var to_in_domain = is_position_in_unit_domain(unit, to_position, game_state)
	return from_in_domain and to_in_domain

# Terrain movement restrictions
static func can_move_through_terrain(unit, target_position, grid_data: Dictionary) -> bool:
	# Get the edge between current position and target position
	var edge = _get_edge_between_positions(unit.position, target_position, grid_data)
	if not edge:
		return true  # No edge found, allow movement
	
	# Check terrain type restrictions
	var terrain_type = edge.get("terrain_type", 0)  # Default to FIELD
	match terrain_type:
		0:  # FIELD - passable
			return true
		1:  # FOREST - passable but slower
			return true
		2:  # MOUNTAIN - difficult terrain
			# Climbers can traverse mountains freely
			if unit.is_climber:
				return true
			# Non-climbers require 2 actions
			return unit.actions_remaining >= 2
		3:  # WATER - impassable for land units
			return false  # Cannot cross water
		_:
			return true  # Unknown terrain, allow movement

# Fog of war movement restrictions
static func _can_move_through_fog(unit, target_position, game_state: Dictionary) -> bool:
	# If no game state or fog disabled, allow movement
	if game_state.is_empty() or not game_state.get("fog_of_war_enabled", false):
		return true
	
	# Units can always move to positions they can see
	# For now, allow movement to adjacent positions (basic visibility)
	# Future: Implement proper line-of-sight calculations
	return true

# Check if unit is visible and accessible for attack
static func is_unit_visible_and_accessible_for_attack(target_unit, attacker_player_id: int, game_state: Dictionary) -> bool:
	# For combat purposes, adjacent enemy units are always attackable
	# Attack ignores fog of war - you can attack what's adjacent regardless of visibility
	return true

# Helper: Check if position exists on grid
static func _is_position_on_grid(position, grid_data: Dictionary) -> bool:
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.position.equals(position):
			return true
	return false

# Helper: Check if position is occupied by a unit
static func _is_position_occupied(position, units_data: Dictionary) -> bool:
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if unit.position.equals(position):
			return true
	return false

# Helper: Check if position is occupied
static func _is_position_occupied_with_forest_exception(moving_unit, target_position, grid_data: Dictionary, units_data: Dictionary) -> bool:
	# Check if there's a unit at target position
	var occupying_unit = null
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if unit.position.equals(target_position):
			occupying_unit = unit
			break
	
	# If no unit at target, position is free
	if not occupying_unit:
		return false
	
	# Position is occupied by any unit (own or enemy)
	return true

# Get edge between two adjacent positions
static func _get_edge_between_positions(pos1, pos2, grid_data: Dictionary):
	if not "edges" in grid_data or not "points" in grid_data:
		return null
	
	if not pos1 or not pos2:
		return null
	
	# Find edge that connects these two positions
	for edge_id in grid_data.edges:
		var edge = grid_data.edges[edge_id]
		
		# Verify edge has required properties
		if not ("point_a_id" in edge and "point_b_id" in edge):
			continue
		
		# Check if this edge connects the two positions
		var point_a = grid_data.points.get(edge.point_a_id)
		var point_b = grid_data.points.get(edge.point_b_id)
		
		if point_a and point_b:
			if (point_a.position.equals(pos1) and point_b.position.equals(pos2)) or \
			   (point_a.position.equals(pos2) and point_b.position.equals(pos1)):
				return edge
	
	return null

# Validate movement parameters
static func validate_movement_parameters(unit, target_position, grid_data: Dictionary, units_data: Dictionary) -> Dictionary:
	var result = {
		"valid": false,
		"errors": []
	}
	
	# Check unit
	if not unit:
		result.errors.append("Unit is null")
		return result
	
	# Check target position
	if not target_position:
		result.errors.append("Target position is null")
		return result
	
	# Check grid data
	if not grid_data or grid_data.is_empty():
		result.errors.append("Grid data is invalid")
		return result
	
	# Check units data
	if not units_data:
		result.errors.append("Units data is null")
		return result
	
	result.valid = true
	return result