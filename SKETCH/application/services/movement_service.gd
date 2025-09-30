# 🚶 MOVEMENT SERVICE
# Purpose: Unit movement validation and execution
# Layer: Application/Services
# Dependencies: Core entities (Unit, HexPoint, HexEdge, Position)

extends RefCounted

# Validate if unit can move to target position
static func can_unit_move_to(unit: Unit, target_position: Position, grid_data: Dictionary, units_data: Dictionary) -> bool:
	# Check if unit has actions
	if not unit.can_move():
		return false
	
	# Check if target is adjacent
	if not unit.position.is_within_distance(target_position, 1):
		return false
	
	# Check if target is occupied by another unit
	if _is_position_occupied(target_position, units_data, unit.id):
		return false
	
	# Check terrain movement rules
	var edge = _find_edge_between_positions(unit.position, target_position, grid_data)
	if edge == null:
		return false
	
	return edge.allows_movement()

# Execute unit movement
static func move_unit_to(unit: Unit, target_position: Position, grid_data: Dictionary, units_data: Dictionary) -> bool:
	if can_unit_move_to(unit, target_position, grid_data, units_data):
		# Check for forest revelation mechanics
		var edge = _find_edge_between_positions(unit.position, target_position, grid_data)
		if edge.terrain_type == GameConstants.TerrainType.FOREST:
			_handle_forest_movement(unit, target_position, units_data)
		
		# Execute movement
		unit.move_to(target_position)
		return true
	
	return false

# Get valid movement targets for unit
static func get_valid_movement_targets(unit: Unit, grid_data: Dictionary, units_data: Dictionary) -> Array[Position]:
	var valid_targets: Array[Position] = []
	
	if not unit.can_move():
		return valid_targets
	
	# Get adjacent positions
	var adjacent_coords = unit.position.hex_coord.get_neighbors()
	
	for coord in adjacent_coords:
		var target_position = Position.from_hex(coord)
		if can_unit_move_to(unit, target_position, grid_data, units_data):
			valid_targets.append(target_position)
	
	return valid_targets

# Handle forest movement and revelation
static func _handle_forest_movement(moving_unit: Unit, target_position: Position, units_data: Dictionary) -> void:
	# Check if enemy unit is hidden in target forest
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if unit.id != moving_unit.id and unit.owner_id != moving_unit.owner_id:
			if unit.position.equals(target_position) and not unit.is_revealed:
				# Reveal enemy unit
				unit.force_reveal()
				# Moving unit loses action for discovery
				moving_unit.consume_action()
				break

# Check if position is occupied by another unit
static func _is_position_occupied(position: Position, units_data: Dictionary, excluding_unit_id: int = -1) -> bool:
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if unit.id != excluding_unit_id and unit.position.equals(position):
			return true
	return false

# Find edge between two adjacent positions
static func _find_edge_between_positions(pos_a: Position, pos_b: Position, grid_data: Dictionary) -> HexEdge:
	var point_a = _find_point_at_position(pos_a, grid_data)
	var point_b = _find_point_at_position(pos_b, grid_data)
	
	if point_a == null or point_b == null:
		return null
	
	# Find common edge
	for edge_id in point_a.connected_edges:
		if edge_id in point_b.connected_edges:
			return grid_data.edges[edge_id]
	
	return null

# Find point at specific position
static func _find_point_at_position(position: Position, grid_data: Dictionary) -> HexPoint:
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.position.equals(position):
			return point
	return null

# Get path between two positions (simple adjacent check for now)
static func get_path_between_positions(start: Position, end: Position, grid_data: Dictionary) -> Array[Position]:
	var path: Array[Position] = []
	
	# For now, only support adjacent movement
	if start.is_within_distance(end, 1):
		path.append(start)
		path.append(end)
	
	return path

# Calculate movement cost (for future power system integration)
static func calculate_movement_cost(unit: Unit, target_position: Position, grid_data: Dictionary) -> int:
	var edge = _find_edge_between_positions(unit.position, target_position, grid_data)
	if edge == null:
		return -1  # Invalid movement
	
	# Base cost is 1 action
	var cost = GameConstants.POWER_COST_PER_ACTION
	
	# Terrain modifiers can be added here
	match edge.terrain_type:
		GameConstants.TerrainType.MOUNTAIN:
			cost = -1  # Cannot move through mountains
		GameConstants.TerrainType.WATER:
			cost = -1  # Cannot move through water
		_:
			pass  # Standard cost
	
	return cost