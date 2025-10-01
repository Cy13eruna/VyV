# 🚶 MOVEMENT SERVICE (CLEAN)
# Purpose: Unit movement validation and execution
# Layer: Application/Services
# Dependencies: Clean core entities only

extends RefCounted

# Validate if unit can move to target position
static func can_unit_move_to(unit, target_position, grid_data: Dictionary, units_data: Dictionary, game_state: Dictionary = {}) -> bool:
	var target_coord = target_position.hex_coord.get_string() if target_position else "null"
	print("[MOVEMENT] Validating move to %s" % target_coord)
	
	# Check if unit has actions
	if not unit.can_move():
		print("[MOVEMENT] Unit has no actions")
		return false
	
	# Check if target is adjacent (distance = 1)
	var distance = unit.position.distance_to(target_position)
	if distance != 1:
		print("[MOVEMENT] Distance is %d, not adjacent" % distance)
		return false
	
	# Check if target position exists on grid
	if not _is_position_on_grid(target_position, grid_data):
		print("[MOVEMENT] Position not on grid")
		return false
	
	# Check if target position is occupied (with forest exception)
	var is_occupied = _is_position_occupied_with_forest_exception(unit, target_position, grid_data, units_data)
	if is_occupied:
		print("[MOVEMENT] Position is occupied (no forest exception)")
		return false
	
	# Check terrain restrictions
	if not _can_move_through_terrain(unit, target_position, grid_data):
		print("[MOVEMENT] Terrain blocks movement")
		return false
	
	# Check fog of war restrictions
	if not _can_move_through_fog(unit, target_position, game_state):
		print("[MOVEMENT] Fog of war blocks movement")
		return false
	
	print("[MOVEMENT] Movement validated successfully")
	return true

# Get all valid movement targets for a unit
static func get_valid_movement_targets(unit, grid_data: Dictionary, units_data: Dictionary, game_state: Dictionary = {}) -> Array:
	var valid_targets = []
	
	print("[MOVEMENT] Getting valid targets for %s" % unit.name)
	
	if not unit.can_move():
		print("[MOVEMENT] Unit cannot move - no actions remaining")
		return valid_targets
	
	var unit_coord = unit.position.hex_coord
	print("[MOVEMENT] Unit position: %s" % unit_coord.get_string())
	
	# Check all 6 adjacent positions
	for direction in range(6):
		var neighbor_coord = unit_coord.get_neighbor(direction)
		var neighbor_pos = load("res://core/value_objects/position_clean.gd").from_hex(neighbor_coord)
		
		print("[MOVEMENT] Checking direction %d: %s" % [direction, neighbor_coord.get_string()])
		
		if can_unit_move_to(unit, neighbor_pos, grid_data, units_data, game_state):
			print("[MOVEMENT] Valid target found: %s" % neighbor_coord.get_string())
			valid_targets.append(neighbor_pos)
		else:
			print("[MOVEMENT] Invalid target: %s" % neighbor_coord.get_string())
	
	print("[MOVEMENT] Total valid targets: %d" % valid_targets.size())
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
		
		if _is_position_on_grid(neighbor_pos, grid_data) and not _is_position_occupied_with_forest_exception(unit, neighbor_pos, grid_data, units_data):
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

# Helper: Check if position is occupied with forest exception
static func _is_position_occupied_with_forest_exception(moving_unit, target_position, grid_data: Dictionary, units_data: Dictionary) -> bool:
	print("[MOVEMENT] Checking occupation with forest exception")
	
	# Check if there's a unit at target position
	var occupying_unit = null
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if unit.position.equals(target_position):
			occupying_unit = unit
			print("[MOVEMENT] Found unit %s at target position" % unit.name)
			break
	
	# If no unit at target, position is free
	if not occupying_unit:
		print("[MOVEMENT] No unit at target - position free")
		return false
	
	# If it's own unit, position is occupied
	if occupying_unit.owner_id == moving_unit.owner_id:
		print("[MOVEMENT] Own unit at target - position occupied")
		return true
	
	# If it's enemy unit, check if separated by forest AND unit is not revealed
	var edge = _get_edge_between_positions(moving_unit.position, target_position, grid_data)
	if edge:
		var terrain_type = edge.get("terrain_type", 0)
		print("[MOVEMENT] Enemy unit found, terrain type: %d" % terrain_type)
		if terrain_type == 1:  # FOREST
			# Only allow movement if the moving unit is not already revealed
			var is_revealed = "force_revealed" in moving_unit and moving_unit.force_revealed
			if not is_revealed:
				print("[MOVEMENT] Forest detected and unit not revealed - allowing movement (will be blocked later)")
				# Allow movement through forest even with enemy unit (will be handled by blocking system)
				return false
			else:
				print("[MOVEMENT] Forest detected but unit is revealed - blocking movement")
				return true
	else:
		print("[MOVEMENT] No edge found between positions")
	
	# Normal occupation rules apply
	print("[MOVEMENT] Normal occupation rules - position occupied")
	return true

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