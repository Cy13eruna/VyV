# 🚶 MOVEMENT SERVICE (CLEAN)
# Purpose: Unit movement validation and execution
# Layer: Application/Services
# Dependencies: Clean core entities only

extends RefCounted

# Validate if unit can move to target position
static func can_unit_move_to(unit, target_position, grid_data: Dictionary, units_data: Dictionary, game_state: Dictionary = {}) -> bool:
	# Check if unit has actions
	if not unit.can_move():
		return false
	
	# Check if target is adjacent (distance = 1)
	if unit.position.distance_to(target_position) != 1:
		return false
	
	# Check if target position exists on grid
	if not _is_position_on_grid(target_position, grid_data):
		return false
	
	# Check if target position is occupied
	if _is_position_occupied(target_position, units_data):
		return false
	
	# Check terrain restrictions
	if not _can_move_through_terrain(unit, target_position, grid_data):
		return false
	
	# Check fog of war restrictions
	if not _can_move_through_fog(unit, target_position, game_state):
		return false
	
	return true

# Get all valid movement targets for a unit
static func get_valid_movement_targets(unit, grid_data: Dictionary, units_data: Dictionary, game_state: Dictionary = {}) -> Array:
	var valid_targets = []
	
	if not unit.can_move():
		return valid_targets
	
	var unit_coord = unit.position.hex_coord
	
	# Check all 6 adjacent positions
	for direction in range(6):
		var neighbor_coord = unit_coord.get_neighbor(direction)
		var neighbor_pos = load("res://core/value_objects/position_clean.gd").from_hex(neighbor_coord)
		
		if can_unit_move_to(unit, neighbor_pos, grid_data, units_data, game_state):
			valid_targets.append(neighbor_pos)
	
	return valid_targets

# Execute unit movement
static func move_unit_to(unit, target_position, grid_data: Dictionary, units_data: Dictionary) -> bool:
	if not can_unit_move_to(unit, target_position, grid_data, units_data):
		return false
	
	# Execute the movement
	return unit.move_to(target_position)

# Get movement path between two positions (for future pathfinding)
static func get_movement_path(start_position, end_position, grid_data: Dictionary, units_data: Dictionary) -> Array:
	var path = []
	
	# Simple direct path for adjacent positions
	if start_position.distance_to(end_position) == 1:
		path.append(end_position)
	
	return path

# Calculate movement cost (for future power system)
static func get_movement_cost(unit, target_position, domain_data: Dictionary = {}) -> int:
	# Base cost is 1
	var cost = 1
	
	# Future: Check if moving within own domain (free movement)
	# Future: Check terrain modifiers
	
	return cost

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
		
		if _is_position_on_grid(neighbor_pos, grid_data) and not _is_position_occupied(neighbor_pos, units_data):
			reachable.append(neighbor_pos)
	
	return reachable

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

# Get unit at position
static func get_unit_at_position(position, units_data: Dictionary):
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if unit.position.equals(position):
			return unit
	return null

# Terrain movement restrictions
static func _can_move_through_terrain(unit, target_position, grid_data: Dictionary) -> bool:
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
		2:  # MOUNTAIN - difficult terrain, requires more actions
			return unit.actions_remaining >= 2  # Requires 2 actions
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

# Get terrain movement cost
static func get_terrain_movement_cost(unit, target_position, grid_data: Dictionary) -> int:
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