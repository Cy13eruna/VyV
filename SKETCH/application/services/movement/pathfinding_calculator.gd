# 🗺️ PATHFINDING CALCULATOR
# Purpose: Calculate movement paths and reachable positions
# Layer: Application Services - Movement

extends RefCounted
class_name PathfindingCalculator

# Get all valid movement targets for a unit
static func get_valid_movement_targets(unit, grid_data: Dictionary, units_data: Dictionary, game_state: Dictionary = {}) -> Array:
	var valid_targets = []
	
	if not unit.can_move():
		return valid_targets
	
	# Get all adjacent positions using hex coordinates
	var unit_coord = unit.position.hex_coord
	for direction in range(6):
		var neighbor_coord = unit_coord.get_neighbor(direction)
		var neighbor_pos = load("res://core/value_objects/position_clean.gd").from_hex(neighbor_coord)
		
		# Import movement validator for validation
		var MovementValidator = load("res://application/services/movement/movement_validator.gd")
		
		# Check if this position is a valid movement target
		if MovementValidator.can_unit_move_to(unit, neighbor_pos, grid_data, units_data, game_state):
			valid_targets.append(neighbor_pos)
	
	return valid_targets

# Get valid attack targets for a fighter unit
static func get_valid_attack_targets(unit, grid: Dictionary, units: Dictionary, game_state: Dictionary) -> Array:
	var valid_targets = []
	
	if not unit.is_fighter or not unit.can_attack():
		return valid_targets
	
	# Use same logic as movement but check for enemy units instead of empty positions
	var unit_coord = unit.position.hex_coord
	for direction in range(6):
		var neighbor_coord = unit_coord.get_neighbor(direction)
		var neighbor_pos = load("res://core/value_objects/position_clean.gd").from_hex(neighbor_coord)
		
		# Check if position exists on grid
		if not _is_position_on_grid(neighbor_pos, grid):
			continue
		
		# Check if there's an enemy unit at this position
		var enemy_unit = _get_enemy_unit_at_position(neighbor_pos, unit.owner_id, units)
		if not enemy_unit:
			continue
		
		# Import movement validator for terrain checks
		var MovementValidator = load("res://application/services/movement/movement_validator.gd")
		
		# Check terrain restrictions (same as movement)
		if not MovementValidator.can_move_through_terrain(unit, neighbor_pos, grid):
			continue
		
		# Attack ignores fog of war, so no fog check needed
		
		# Position is valid for attack
		valid_targets.append(neighbor_pos)
	
	return valid_targets

# Get movement path between two positions (for future pathfinding)
static func get_movement_path(start_position, end_position, grid_data: Dictionary, units_data: Dictionary) -> Array:
	var path = []
	
	# Simple direct path for adjacent positions
	if start_position.distance_to(end_position) == 1:
		path.append(end_position)
	
	return path

# Check if position is reachable within movement range
static func is_position_reachable(unit, target_position, grid_data: Dictionary, units_data: Dictionary, max_moves: int = 1) -> bool:
	if max_moves <= 0:
		return false
	
	# For now, only adjacent positions are reachable
	return unit.position.distance_to(target_position) <= max_moves

# Get all positions reachable within movement range
static func get_reachable_positions(unit, grid_data: Dictionary, units_data: Dictionary, max_moves: int = 1) -> Array:
	var reachable = []
	
	if max_moves <= 0 or not unit.can_move():
		return reachable
	
	# For now, only get adjacent positions
	var unit_coord = unit.position.hex_coord
	
	for direction in range(6):
		var neighbor_coord = unit_coord.get_neighbor(direction)
		var neighbor_pos = load("res://core/value_objects/position_clean.gd").from_hex(neighbor_coord)
		
		if _is_position_on_grid(neighbor_pos, grid_data) and not _is_position_occupied_with_forest_exception(unit, neighbor_pos, grid_data, units_data):
			reachable.append(neighbor_pos)
	
	return reachable

# Get adjacent positions to a given position
static func get_adjacent_positions(center_position, grid: Dictionary) -> Array:
	var adjacent_positions = []
	
	if not ("points" in grid):
		return adjacent_positions
	
	# Find the center point in the grid
	var center_point = null
	for point_id in grid.points:
		var point = grid.points[point_id]
		if point.position.equals(center_position):
			center_point = point
			break
	
	if not center_point:
		return adjacent_positions
	
	# Get all connected positions
	for edge_id in center_point.get("connected_edges", []):
		if edge_id in grid.edges:
			var edge = grid.edges[edge_id]
			
			# Find the other point of this edge
			var other_point_id = -1
			if "point_a_id" in edge and "point_b_id" in edge:
				other_point_id = edge.point_a_id if edge.point_b_id == center_point.id else edge.point_b_id
			elif "point1_id" in edge and "point2_id" in edge:
				other_point_id = edge.point1_id if edge.point2_id == center_point.id else edge.point2_id
			elif "point1" in edge and "point2" in edge:
				other_point_id = edge.point1 if edge.point2 == center_point.id else edge.point2
			
			if other_point_id != -1 and other_point_id in grid.points:
				var other_point = grid.points[other_point_id]
				adjacent_positions.append(other_point.position)
	
	return adjacent_positions

# Calculate movement cost (for future power system)
static func get_movement_cost(unit, target_position, domain_data: Dictionary = {}) -> int:
	# Base cost is 1
	var cost = 1
	
	# Future: Check if moving within own domain (free movement)
	# Future: Check terrain modifiers
	
	return cost

# Get terrain movement cost
static func get_terrain_movement_cost(unit, target_position, grid_data: Dictionary, game_state: Dictionary = {}) -> int:
	# Import movement validator for domain checks
	var MovementValidator = load("res://application/services/movement/movement_validator.gd")
	
	# Check if movement is within domain (free movement)
	if not game_state.is_empty() and MovementValidator.are_positions_in_same_domain(unit, unit.position, target_position, game_state):
		return 1  # Free movement within domain
	
	var edge = _get_edge_between_positions(unit.position, target_position, grid_data)
	if not edge:
		return 1  # Default cost
	
	var terrain_type = edge.get("terrain_type", 0)  # Default to FIELD
	match terrain_type:
		0:  # FIELD
			return 1
		1:  # FOREST
			return 1  # Normal cost but could be 2 for balance
		2:  # MOUNTAIN
			return 2  # Expensive
		3:  # WATER
			return 999  # Impassable
		_:
			return 1

# Check if terrain blocks line of sight
static func does_terrain_block_sight(edge) -> bool:
	if not edge:
		return false
	
	var terrain_type = edge.get("terrain_type", 0)  # Default to FIELD
	match terrain_type:
		1:  # FOREST - blocks sight
			return true
		2:  # MOUNTAIN - blocks sight
			return true
		_:
			return false

# Helper: Check if position exists on grid
static func _is_position_on_grid(position, grid_data: Dictionary) -> bool:
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.position.equals(position):
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

# Get enemy unit at specific position
static func _get_enemy_unit_at_position(position, attacker_player_id: int, units: Dictionary):
	for unit_id in units:
		var unit = units[unit_id]
		if unit.position.equals(position) and unit.owner_id != attacker_player_id:
			return unit
	return null

# Get unit at position
static func get_unit_at_position(position, units_data: Dictionary):
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if unit.position.equals(position):
			return unit
	return null

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