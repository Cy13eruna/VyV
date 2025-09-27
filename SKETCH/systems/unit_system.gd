extends Node

# Unit management system for V&V game
# Handles unit positions, movement, actions, and interactions

signal unit_moved(unit_id: int, from_point: int, to_point: int)
signal unit_action_consumed(unit_id: int, remaining_actions: int)
signal unit_revealed(unit_id: int, point: int)
signal movement_blocked(unit_id: int, reason: String)

# Unit data
var unit1_position: int = 0
var unit2_position: int = 0
var unit1_actions: int = 1
var unit2_actions: int = 1
var unit1_force_revealed: bool = false
var unit2_force_revealed: bool = false

# Unit names and domains
var unit1_name: String = ""
var unit2_name: String = ""
var unit1_domain_name: String = ""
var unit2_domain_name: String = ""
var unit1_domain_center: int = 0
var unit2_domain_center: int = 0
var unit1_domain_power: int = 1
var unit2_domain_power: int = 1

# Game state
var current_player: int = 1
var fog_of_war: bool = true

# Game data references
var points: Array = []
var hex_coords: Array = []
var paths: Array = []

# Initialize unit system
func initialize(game_points: Array, game_hex_coords: Array, game_paths: Array) -> void:
	points = game_points
	hex_coords = game_hex_coords
	paths = game_paths
	print("🚶‍♀️ UnitSystem initialized with %d points, %d paths" % [points.size(), paths.size()])

# Setup units with initial positions and data
func setup_units(unit1_pos: int, unit2_pos: int, unit1_name_val: String, unit2_name_val: String, 
				unit1_domain_val: String, unit2_domain_val: String) -> void:
	unit1_position = unit1_pos
	unit2_position = unit2_pos
	unit1_domain_center = unit1_pos
	unit2_domain_center = unit2_pos
	
	unit1_name = unit1_name_val
	unit2_name = unit2_name_val
	unit1_domain_name = unit1_domain_val
	unit2_domain_name = unit2_domain_val
	
	print("🚶‍♀️ Units setup: %s (%s) at %d, %s (%s) at %d" % [
		unit1_name, unit1_domain_name, unit1_position,
		unit2_name, unit2_domain_name, unit2_position
	])

# Update game state
func update_game_state(state_data: Dictionary) -> void:
	if state_data.has("current_player"):
		current_player = state_data.current_player
	if state_data.has("fog_of_war"):
		fog_of_war = state_data.fog_of_war
	if state_data.has("unit1_domain_power"):
		unit1_domain_power = state_data.unit1_domain_power
	if state_data.has("unit2_domain_power"):
		unit2_domain_power = state_data.unit2_domain_power

# Get current unit position
func get_current_unit_position() -> int:
	return unit1_position if current_player == 1 else unit2_position

# Get enemy unit position
func get_enemy_unit_position() -> int:
	return unit2_position if current_player == 1 else unit1_position

# Get current unit actions
func get_current_unit_actions() -> int:
	return unit1_actions if current_player == 1 else unit2_actions

# Check if current unit can move to point
func can_current_unit_move_to_point(point_index: int) -> bool:
	var unit_pos = get_current_unit_position()
	return can_unit_move_to_point(point_index, unit_pos)

# Check if specific unit can move to point
func can_unit_move_to_point(point_index: int, unit_pos: int) -> bool:
	# Cannot move to itself
	if point_index == unit_pos:
		return false
	
	# Check if there's a path that allows movement
	for path in paths:
		var path_points = path.points
		if (path_points[0] == unit_pos and path_points[1] == point_index) or \
		   (path_points[1] == unit_pos and path_points[0] == point_index):
			# Field and Forest allow movement
			var field_type = GameConstants.EdgeType.FIELD if GameConstants else 0
			var forest_type = GameConstants.EdgeType.FOREST if GameConstants else 1
			if path.type == field_type or path.type == forest_type:
				return true
	return false

# Attempt unit movement
func attempt_unit_movement(target_point: int) -> Dictionary:
	# Check if current unit can move there
	if not can_current_unit_move_to_point(target_point):
		var result = {"success": false, "message": "Cannot move to that point"}
		movement_blocked.emit(current_player, result.message)
		return result
	
	# Check if has actions
	var current_actions = get_current_unit_actions()
	if current_actions <= 0:
		var result = {"success": false, "message": "No actions remaining"}
		movement_blocked.emit(current_player, result.message)
		return result
	
	# Check if domain has power
	if not has_domain_power_for_action():
		var result = {"success": false, "message": "Domain has no power"}
		movement_blocked.emit(current_player, result.message)
		return result
	
	# Check for enemy unit at destination
	var enemy_pos = get_enemy_unit_position()
	if enemy_pos == target_point:
		var movement_result = _handle_enemy_encounter(target_point)
		if not movement_result.success:
			# Still consume action and power even if movement fails
			consume_action()
			consume_domain_power()
			movement_blocked.emit(current_player, movement_result.message)
			return movement_result
	
	# Execute successful movement
	var old_pos = get_current_unit_position()
	if current_player == 1:
		unit1_position = target_point
	else:
		unit2_position = target_point
	
	# Consume action and power
	consume_action()
	consume_domain_power()
	
	print("🚶🏻‍♀️ Unit %d moved from %d to %d" % [current_player, old_pos, target_point])
	unit_moved.emit(current_player, old_pos, target_point)
	
	return {"success": true, "message": "Movement successful"}

# Handle encounter with enemy unit
func _handle_enemy_encounter(target_point: int) -> Dictionary:
	var current_unit_pos = get_current_unit_position()
	var path_type = get_path_type_between_points(current_unit_pos, target_point)
	
	# Check if enemy was visible
	var enemy_was_visible = false
	if current_player == 1:
		enemy_was_visible = not unit2_force_revealed and is_point_visible_to_current_unit(unit2_position)
	else:
		enemy_was_visible = not unit1_force_revealed and is_point_visible_to_current_unit(unit1_position)
	
	var forest_type = GameConstants.EdgeType.FOREST if GameConstants else 1
	if path_type == forest_type and not enemy_was_visible:
		# Reveal enemy unit in forest
		print("🔍 Enemy unit revealed in forest!")
		if current_player == 1:
			unit2_force_revealed = true
		else:
			unit1_force_revealed = true
		
		unit_revealed.emit(3 - current_player, target_point)
		return {"success": false, "message": "Enemy unit discovered in forest! Movement cancelled."}
	else:
		return {"success": false, "message": "Point occupied by enemy unit."}

# Get path type between two points
func get_path_type_between_points(point1: int, point2: int) -> int:
	for path in paths:
		var path_points = path.points
		if (path_points[0] == point1 and path_points[1] == point2) or \
		   (path_points[1] == point1 and path_points[0] == point2):
			return path.type
	
	# If no path found, return MOUNTAIN (blocked)
	var mountain_type = GameConstants.EdgeType.MOUNTAIN if GameConstants else 2
	return mountain_type

# Check if point is visible to current unit
func is_point_visible_to_current_unit(point_index: int) -> bool:
	var current_unit_pos = get_current_unit_position()
	return is_point_visible_to_unit(point_index, current_unit_pos)

# Check if point is visible to specific unit
func is_point_visible_to_unit(point_index: int, unit_pos: int) -> bool:
	# Check if there's a path that allows visibility
	for path in paths:
		var path_points = path.points
		if (path_points[0] == unit_pos and path_points[1] == point_index) or \
		   (path_points[1] == unit_pos and path_points[0] == point_index):
			# Field and Water allow seeing
			var field_type = GameConstants.EdgeType.FIELD if GameConstants else 0
			var water_type = GameConstants.EdgeType.WATER if GameConstants else 3
			if path.type == field_type or path.type == water_type:
				return true
	return false

# Check if domain has power for action
func has_domain_power_for_action() -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var enemy_unit_pos = get_enemy_unit_position()
	
	# If domain center is occupied by enemy, actions are free
	if enemy_unit_pos == domain_center:
		print("⚡ Domain occupied! Free actions for original units.")
		return true
	
	# Otherwise, check if has power
	var current_power = unit1_domain_power if current_player == 1 else unit2_domain_power
	return current_power > 0

# Consume domain power
func consume_domain_power() -> void:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var enemy_unit_pos = get_enemy_unit_position()
	
	# If center is occupied, don't consume power
	if enemy_unit_pos == domain_center:
		return
	
	# Consume 1 power
	if current_player == 1:
		unit1_domain_power = max(0, unit1_domain_power - 1)
		print("⚡ Domain 1 consumed 1 power (Remaining: %d)" % unit1_domain_power)
	else:
		unit2_domain_power = max(0, unit2_domain_power - 1)
		print("⚡ Domain 2 consumed 1 power (Remaining: %d)" % unit2_domain_power)

# Consume action point
func consume_action() -> void:
	if current_player == 1:
		unit1_actions -= 1
	else:
		unit2_actions -= 1
	
	var remaining = get_current_unit_actions()
	unit_action_consumed.emit(current_player, remaining)

# Switch to next player
func switch_player() -> void:
	print("⏭️ UnitSystem: Player %d switching to player %d" % [current_player, 3 - current_player])
	
	# Switch player
	current_player = 3 - current_player  # 1 -> 2, 2 -> 1
	
	# Restore actions for new player
	if current_player == 1:
		unit1_actions = 1
	else:
		unit2_actions = 1
	
	# Reset forced revelations if units are no longer visible
	check_and_reset_forced_revelations()

# Generate power for current player's domain only
func generate_power_for_current_player() -> void:
	print("🔄 UnitSystem: Player %d turn - Generating power ONLY for Player %d's domain" % [current_player, current_player])
	
	if current_player == 1:
		# Domain 1: generate power if not occupied
		if unit2_position != unit1_domain_center:
			unit1_domain_power += 1
			print("⚡ Domain 1 (%s) generated 1 power (Total: %d)" % [unit1_domain_name, unit1_domain_power])
		else:
			print("⚡ Domain 1 (%s) occupied - didn't generate power" % unit1_domain_name)
	else:
		# Domain 2: generate power if not occupied
		if unit1_position != unit2_domain_center:
			unit2_domain_power += 1
			print("⚡ Domain 2 (%s) generated 1 power (Total: %d)" % [unit2_domain_name, unit2_domain_power])
		else:
			print("⚡ Domain 2 (%s) occupied - didn't generate power" % unit2_domain_name)

# Check and reset forced revelations
func check_and_reset_forced_revelations() -> void:
	# Reset unit1_force_revealed if it's not naturally visible
	if unit1_force_revealed and current_player == 2:
		if not is_point_visible_to_current_unit(unit1_position):
			unit1_force_revealed = false
			print("🔍 Unit 1 is no longer visible - resetting forced revelation")
	
	# Reset unit2_force_revealed if it's not naturally visible
	if unit2_force_revealed and current_player == 1:
		if not is_point_visible_to_current_unit(unit2_position):
			unit2_force_revealed = false
			print("🔍 Unit 2 is no longer visible - resetting forced revelation")

# Domain checking functions
func is_point_in_current_player_domain(point_index: int) -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	return is_point_in_specific_domain(point_index, domain_center)

func is_point_in_specific_domain(point_index: int, domain_center: int) -> bool:
	# Point is in domain if it's the center or one of the 6 neighbors
	if point_index == domain_center:
		return true
	
	# Check if it's one of the 6 points around the center
	if HexGridSystem:
		var domain_coord = hex_coords[domain_center]
		var point_coord = hex_coords[point_index]
		var neighbors = HexGridSystem.get_hex_neighbors(domain_coord)
		for neighbor in neighbors:
			if point_coord.is_equal_approx(neighbor):
				return true
	else:
		# Fallback to manual calculation
		var domain_coord = hex_coords[domain_center]
		var point_coord = hex_coords[point_index]
		
		for dir in range(6):
			var neighbor_coord = domain_coord + _get_hex_direction_fallback(dir)
			if point_coord.is_equal_approx(neighbor_coord):
				return true
	
	return false

# Fallback hex direction function
func _get_hex_direction_fallback(direction: int) -> Vector2:
	var directions = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	return directions[direction % 6]

# Path checking functions
func is_path_in_current_player_domain(path: Dictionary) -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var point1 = path.points[0]
	var point2 = path.points[1]
	
	# Path is in domain if both points are in current player's domain
	return is_point_in_specific_domain(point1, domain_center) and is_point_in_specific_domain(point2, domain_center)

func is_path_adjacent_to_current_unit(path: Dictionary) -> bool:
	var current_unit_pos = get_current_unit_position()
	var path_points = path.points
	return path_points[0] == current_unit_pos or path_points[1] == current_unit_pos

# Get unit state for UI updates
func get_unit_state() -> Dictionary:
	return {
		"current_player": current_player,
		"unit1_position": unit1_position,
		"unit2_position": unit2_position,
		"unit1_actions": unit1_actions,
		"unit2_actions": unit2_actions,
		"unit1_domain_power": unit1_domain_power,
		"unit2_domain_power": unit2_domain_power,
		"unit1_name": unit1_name,
		"unit2_name": unit2_name,
		"unit1_domain_name": unit1_domain_name,
		"unit2_domain_name": unit2_domain_name,
		"unit1_domain_center": unit1_domain_center,
		"unit2_domain_center": unit2_domain_center,
		"unit1_force_revealed": unit1_force_revealed,
		"unit2_force_revealed": unit2_force_revealed,
		"fog_of_war": fog_of_war
	}

# Domain visibility checking
func is_domain_visible(domain_center: int) -> bool:
	# Domain always visible if it belongs to current player
	if (current_player == 1 and domain_center == unit1_domain_center) or \
	   (current_player == 2 and domain_center == unit2_domain_center):
		return true
	
	# Enemy domain visible if center or any adjacent point is visible
	var current_unit_pos = get_current_unit_position()
	
	# Check if domain center is visible
	if is_point_visible_to_unit(domain_center, current_unit_pos):
		return true
	
	# Check if any point adjacent to domain center is visible
	if HexGridSystem:
		var domain_coord = hex_coords[domain_center]
		var neighbors = HexGridSystem.get_hex_neighbors(domain_coord)
		for neighbor in neighbors:
			var neighbor_index = HexGridSystem.find_hex_coord_index(neighbor, hex_coords)
			if neighbor_index != -1 and is_point_visible_to_unit(neighbor_index, current_unit_pos):
				return true
	
	return false

# Set initial unit positions (for spawn logic)
func set_initial_positions(corners: Array) -> Dictionary:
	print("🏰 UnitSystem: set_initial_positions called with %d corners" % corners.size())
	print("🏰 UnitSystem: corners = " + str(corners))
	
	if corners.size() >= 2:
		# Shuffle and choose 2 random corners
		corners.shuffle()
		var corner1 = corners[0]
		var corner2 = corners[1]
		
		print("🏰 UnitSystem: Selected corners %d and %d" % [corner1, corner2])
		
		# Find adjacent point with 6 edges
		print("🏰 UnitSystem: Finding position for corner1 %d" % corner1)
		unit1_position = _find_adjacent_six_edge_point(corner1)
		print("🏰 UnitSystem: Finding position for corner2 %d" % corner2)
		unit2_position = _find_adjacent_six_edge_point(corner2)
		
		# Set domain centers
		unit1_domain_center = unit1_position
		unit2_domain_center = unit2_position
		
		print("🏰 UnitSystem: Final positions - Unit1: %d, Unit2: %d" % [unit1_position, unit2_position])
		
		return {
			"success": true,
			"unit1_position": unit1_position,
			"unit2_position": unit2_position,
			"unit1_domain_center": unit1_domain_center,
			"unit2_domain_center": unit2_domain_center
		}
	else:
		print("❌ UnitSystem: Not enough corners found (%d)" % corners.size())
		return {"success": false, "message": "Not enough corners found"}

# Find best adjacent point for domain - FIXED VERSION
func _find_adjacent_six_edge_point(corner_index: int) -> int:
	print("🚨 UnitSystem: _find_adjacent_six_edge_point called with corner %d" % corner_index)
	
	if corner_index >= hex_coords.size():
		print("❌ UnitSystem: corner_index %d >= hex_coords.size() %d" % [corner_index, hex_coords.size()])
		return corner_index
	
	print("🏰 UnitSystem FIXED: Finding best domain position for corner %d" % corner_index)
	var corner_coord = hex_coords[corner_index]
	
	# Look for best neighbor (prioritize more connections)
	var best_neighbor = -1
	var best_connections = 0
	
	# Check all 6 hexagonal neighbors of the corner
	for dir in range(6):
		var neighbor_coord = corner_coord + _get_hex_direction_fallback(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		
		if neighbor_index != -1:
			# Count paths from this neighbor
			var path_count = 0
			for path in paths:
				var path_points = path.points
				if path_points[0] == neighbor_index or path_points[1] == neighbor_index:
					path_count += 1
			
			# Accept neighbors with 4, 5, or 6 connections (not corners with 3)
			if path_count >= 4 and path_count > best_connections:
				best_neighbor = neighbor_index
				best_connections = path_count
	
	# If found a good neighbor, use it
	if best_neighbor != -1:
		print("✅ UnitSystem FIXED: Using neighbor %d with %d connections" % [best_neighbor, best_connections])
		return best_neighbor
	
	# If no good neighbor found, look for points at distance 2 (raio 1 points with 6 connections)
	for i in range(points.size()):
		var point_coord = hex_coords[i]
		var distance = _hex_distance_fallback(corner_coord, point_coord)
		
		# Look for points at distance 2 (raio 1)
		if distance == 2:
			# Count connections
			var path_count = 0
			for path in paths:
				var path_points = path.points
				if path_points[0] == i or path_points[1] == i:
					path_count += 1
			
			# Raio 1 points should have 6 connections
			if path_count == 6:
				print("✅ UnitSystem FIXED: Found raio 1 point %d with 6 connections" % i)
				return i
	
	# Ultimate fallback: return the corner itself
	print("❌ UnitSystem FIXED: No suitable point found, using corner as fallback")
	return corner_index

# Calculate hexagonal distance between two coordinates (fallback)
func _hex_distance_fallback(coord1: Vector2, coord2: Vector2) -> int:
	# Axial coordinate distance formula
	return int((abs(coord1.x - coord2.x) + abs(coord1.x + coord1.y - coord2.x - coord2.y) + abs(coord1.y - coord2.y)) / 2)

# Find hexagonal coordinate index
func _find_hex_coord_index(coord: Vector2) -> int:
	for i in range(hex_coords.size()):
		if hex_coords[i].is_equal_approx(coord):
			return i
	return -1

# Get current unit state for debugging
func get_debug_info() -> Dictionary:
	return {
		"current_player": current_player,
		"current_unit_position": get_current_unit_position(),
		"enemy_unit_position": get_enemy_unit_position(),
		"current_actions": get_current_unit_actions(),
		"can_move_points": _get_valid_move_points(),
		"domain_power": unit1_domain_power if current_player == 1 else unit2_domain_power
	}

# Get valid move points for current unit
func _get_valid_move_points() -> Array:
	var valid_points = []
	var current_pos = get_current_unit_position()
	
	for i in range(points.size()):
		if can_unit_move_to_point(i, current_pos):
			valid_points.append(i)
	
	return valid_points