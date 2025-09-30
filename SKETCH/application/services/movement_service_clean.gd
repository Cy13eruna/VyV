# 🚶 MOVEMENT SERVICE (CLEAN)
# Purpose: Unit movement validation and execution
# Layer: Application/Services
# Dependencies: Clean core entities only

extends RefCounted

# Validate if unit can move to target position
static func can_unit_move_to(unit, target_position, grid_data: Dictionary, units_data: Dictionary) -> bool:
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
	
	return true

# Get all valid movement targets for a unit
static func get_valid_movement_targets(unit, grid_data: Dictionary, units_data: Dictionary) -> Array:
	var valid_targets = []
	
	if not unit.can_move():
		return valid_targets
	
	var unit_coord = unit.position.hex_coord
	
	# Check all 6 adjacent positions
	for direction in range(6):
		var neighbor_coord = unit_coord.get_neighbor(direction)
		var neighbor_pos = load("res://core/value_objects/position_clean.gd").from_hex(neighbor_coord)
		
		if can_unit_move_to(unit, neighbor_pos, grid_data, units_data):
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