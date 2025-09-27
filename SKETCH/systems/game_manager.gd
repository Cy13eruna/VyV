extends Node

# Central game management system
# Coordinates between all game systems and manages game state

signal game_initialized
signal turn_changed(new_player: int)
signal action_consumed(player: int, remaining_actions: int)
signal power_generated(player: int, total_power: int)
signal unit_moved(player: int, from_point: int, to_point: int)
signal unit_revealed(player: int, point: int)

# Game state references
var current_player: int = 1
var unit1_actions: int = 1
var unit2_actions: int = 1
var fog_of_war: bool = true

# Unit positions and properties
var unit1_position: int = 0
var unit2_position: int = 0
var unit1_domain_center: int = 0
var unit2_domain_center: int = 0
var unit1_domain_power: int = 1
var unit2_domain_power: int = 1

# Unit and domain names
var unit1_name: String = ""
var unit2_name: String = ""
var unit1_domain_name: String = ""
var unit2_domain_name: String = ""

# Forced revelation tracking
var unit1_force_revealed: bool = false
var unit2_force_revealed: bool = false

# Game data references
var points: Array = []
var hex_coords: Array = []
var paths: Array = []

# Initialize game manager with game data
func initialize_game(game_points: Array, game_hex_coords: Array, game_paths: Array) -> void:
	points = game_points
	hex_coords = game_hex_coords
	paths = game_paths
	
	print("🎮 GameManager initialized with %d points, %d paths" % [points.size(), paths.size()])
	game_initialized.emit()

# Set unit positions and initialize domains
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
	
	print("🎮 Units setup: %s (%s) at %d, %s (%s) at %d" % [
		unit1_name, unit1_domain_name, unit1_position,
		unit2_name, unit2_domain_name, unit2_position
	])

# Get current player info
func get_current_player() -> int:
	return current_player

func get_current_player_actions() -> int:
	return unit1_actions if current_player == 1 else unit2_actions

func get_current_unit_position() -> int:
	return unit1_position if current_player == 1 else unit2_position

func get_enemy_unit_position() -> int:
	return unit2_position if current_player == 1 else unit1_position

# Check if current unit can move to specific point
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

# Check if point is visible to current player
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

# Attempt unit movement
func attempt_unit_movement(target_point: int) -> Dictionary:
	# Check if current unit can move there
	if not can_current_unit_move_to_point(target_point):
		return {"success": false, "message": "Cannot move to that point"}
	
	# Check if has actions
	var current_actions = get_current_player_actions()
	if current_actions <= 0:
		return {"success": false, "message": "No actions remaining"}
	
	# Check if domain has power
	if not has_domain_power_for_action():
		return {"success": false, "message": "Domain has no power"}
	
	# Check for enemy unit at destination
	var enemy_pos = get_enemy_unit_position()
	if enemy_pos == target_point:
		var movement_result = _handle_enemy_encounter(target_point)
		if not movement_result.success:
			# Still consume action and power even if movement fails
			consume_action()
			consume_domain_power()
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
	
	var remaining = get_current_player_actions()
	action_consumed.emit(current_player, remaining)

# Switch to next player
func switch_player() -> void:
	print("⏭️ Player %d skipping turn - Switching to player %d" % [current_player, 3 - current_player])
	
	# Switch player
	current_player = 3 - current_player  # 1 -> 2, 2 -> 1
	
	# Restore actions for new player
	if current_player == 1:
		unit1_actions = 1
	else:
		unit2_actions = 1
	
	# Reset forced revelations if units are no longer visible
	check_and_reset_forced_revelations()
	
	turn_changed.emit(current_player)

# Start turn for current player (generates power)
func start_current_player_turn() -> void:
	print("🎯 Player %d starting their turn" % current_player)
	
	# Generate power for current player's domain at start of their turn
	generate_domain_power_for_current_player()

# Generate power for current player's domain only
func generate_domain_power_for_current_player() -> void:
	print("🔄 Player %d turn - Generating power ONLY for Player %d's domain" % [current_player, current_player])
	
	if current_player == 1:
		# Domain 1: generate power if not occupied
		if unit2_position != unit1_domain_center:
			unit1_domain_power += 1
			print("⚡ Domain 1 (%s) generated 1 power (Total: %d)" % [unit1_domain_name, unit1_domain_power])
			power_generated.emit(1, unit1_domain_power)
		else:
			print("⚡ Domain 1 (%s) occupied - didn't generate power" % unit1_domain_name)
	else:
		# Domain 2: generate power if not occupied
		if unit1_position != unit2_domain_center:
			unit2_domain_power += 1
			print("⚡ Domain 2 (%s) generated 1 power (Total: %d)" % [unit2_domain_name, unit2_domain_power])
			power_generated.emit(2, unit2_domain_power)
		else:
			print("⚡ Domain 2 (%s) occupied - didn't generate power" % unit2_domain_name)

# Generate power for domains (legacy function - for fallback compatibility)
func generate_domain_power() -> void:
	print("🔄 New round - Generating power for domains")
	
	# Domain 1: generate power if not occupied
	if unit2_position != unit1_domain_center:
		unit1_domain_power += 1
		print("⚡ Domain 1 (%s) generated 1 power (Total: %d)" % [unit1_domain_name, unit1_domain_power])
		power_generated.emit(1, unit1_domain_power)
	else:
		print("⚡ Domain 1 (%s) occupied - didn't generate power" % unit1_domain_name)
	
	# Domain 2: generate power if not occupied
	if unit1_position != unit2_domain_center:
		unit2_domain_power += 1
		print("⚡ Domain 2 (%s) generated 1 power (Total: %d)" % [unit2_domain_name, unit2_domain_power])
		power_generated.emit(2, unit2_domain_power)
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

# Toggle fog of war
func toggle_fog_of_war() -> void:
	fog_of_war = not fog_of_war
	var fog_status = "ENABLED" if fog_of_war else "DISABLED"
	print("🌫️ Fog of War %s" % fog_status)

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

# Get game state for UI updates
func get_game_state() -> Dictionary:
	return {
		"current_player": current_player,
		"unit1_actions": unit1_actions,
		"unit2_actions": unit2_actions,
		"unit1_position": unit1_position,
		"unit2_position": unit2_position,
		"unit1_domain_power": unit1_domain_power,
		"unit2_domain_power": unit2_domain_power,
		"unit1_name": unit1_name,
		"unit2_name": unit2_name,
		"unit1_domain_name": unit1_domain_name,
		"unit2_domain_name": unit2_domain_name,
		"fog_of_war": fog_of_war,
		"unit1_force_revealed": unit1_force_revealed,
		"unit2_force_revealed": unit2_force_revealed
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