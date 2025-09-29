extends Node

# VisibilitySystem - Centralized fog of war and domain visibility management
# Extracted from main_game.gd as part of Step 10 refactoring

# Game state references
var points = []
var hex_coords = []
var paths = []
var current_player = 1
var fog_of_war = true

# Unit positions
var unit1_position = 0
var unit2_position = 0

# Domain centers
var unit1_domain_center = 0
var unit2_domain_center = 0

# Forced revelation flags
var unit1_force_revealed = false
var unit2_force_revealed = false

## Initialize the visibility system
func initialize(game_points: Array, game_hex_coords: Array, game_paths: Array) -> void:
	points = game_points
	hex_coords = game_hex_coords
	paths = game_paths
	print("👁️ VisibilitySystem initialized with %d points, %d paths" % [points.size(), paths.size()])

## Update game state
func update_game_state(state: Dictionary) -> void:
	if state.has("current_player"):
		current_player = state.current_player
	if state.has("fog_of_war"):
		fog_of_war = state.fog_of_war
	if state.has("unit1_position"):
		unit1_position = state.unit1_position
	if state.has("unit2_position"):
		unit2_position = state.unit2_position
	if state.has("unit1_domain_center"):
		unit1_domain_center = state.unit1_domain_center
	if state.has("unit2_domain_center"):
		unit2_domain_center = state.unit2_domain_center
	if state.has("unit1_force_revealed"):
		unit1_force_revealed = state.unit1_force_revealed
	if state.has("unit2_force_revealed"):
		unit2_force_revealed = state.unit2_force_revealed

## Check if point is visible to current player
func is_point_visible_to_current_unit(point_index: int) -> bool:
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	return is_point_visible_to_unit(point_index, current_unit_pos)

## Check if point is visible to a specific unit
func is_point_visible_to_unit(point_index: int, unit_pos: int) -> bool:
	# Check if there's a path that allows visibility
	for path in paths:
		var path_points = path.points
		if (path_points[0] == unit_pos and path_points[1] == point_index) or \
		   (path_points[1] == unit_pos and path_points[0] == point_index):
			# Field and Water allow seeing
			var field_type = GameConstants.EdgeType.FIELD if GameConstants else 0  # EdgeType.FIELD
			var water_type = GameConstants.EdgeType.WATER if GameConstants else 3  # EdgeType.WATER
			if path.type == field_type or path.type == water_type:
				return true
	return false

## Check if domain is visible to current player (ENHANCED)
func is_domain_visible(domain_center: int) -> bool:
	print("👁️ VisibilitySystem: Checking domain visibility for center=%d, current_player=%d" % [domain_center, current_player])
	
	# Domain always visible if it belongs to current player
	if (current_player == 1 and domain_center == unit1_domain_center) or \
	   (current_player == 2 and domain_center == unit2_domain_center):
		print("👁️ VisibilitySystem: Domain belongs to current player - VISIBLE")
		return true
	
	# Enemy domain visible if center or any adjacent point is visible
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	print("👁️ VisibilitySystem: Checking enemy domain visibility from unit pos=%d" % current_unit_pos)
	
	# Check if domain center is visible
	if is_point_visible_to_unit(domain_center, current_unit_pos):
		print("👁️ VisibilitySystem: Domain center is visible - VISIBLE")
		return true
	
	# Check if any point adjacent to domain center is visible
	var domain_coord = hex_coords[domain_center]
	for dir in range(6):
		var neighbor_coord = domain_coord + _hex_direction(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1 and is_point_visible_to_unit(neighbor_index, current_unit_pos):
			print("👁️ VisibilitySystem: Adjacent point %d is visible - VISIBLE" % neighbor_index)
			return true
	
	# ENHANCED: Check if current unit is within 2 hexes of domain center
	var distance = _hex_distance(hex_coords[current_unit_pos], hex_coords[domain_center])
	if distance <= 2:
		print("👁️ VisibilitySystem: Domain within 2 hexes (distance=%d) - VISIBLE" % distance)
		return true
	
	print("👁️ VisibilitySystem: Domain not visible - HIDDEN")
	return false

## Check if point is within current player's domain
func is_point_in_current_player_domain(point_index: int) -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	return is_point_in_specific_domain(point_index, domain_center)

## Check if path is within current player's domain
func is_path_in_current_player_domain(path: Dictionary) -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var point1 = path.points[0]
	var point2 = path.points[1]
	
	# Path is in domain if both points are in current player's domain
	return is_point_in_specific_domain(point1, domain_center) and is_point_in_specific_domain(point2, domain_center)

## Check if point is within a specific domain
func is_point_in_specific_domain(point_index: int, domain_center: int) -> bool:
	# Point is in domain if it's the center or one of the 6 neighbors
	if point_index == domain_center:
		return true
	
	# Check if it's one of the 6 points around the center
	var domain_coord = hex_coords[domain_center]
	var point_coord = hex_coords[point_index]
	
	for dir in range(6):
		var neighbor_coord = domain_coord + _hex_direction(dir)
		if point_coord.is_equal_approx(neighbor_coord):
			return true
	
	return false

## Check and reset forced revelations
func check_and_reset_forced_revelations() -> Dictionary:
	var changes = {"unit1_changed": false, "unit2_changed": false}
	
	# Reset unit1_force_revealed if it's not naturally visible
	if unit1_force_revealed and current_player == 2:
		if not is_point_visible_to_current_unit(unit1_position):
			unit1_force_revealed = false
			changes.unit1_changed = true
			print("👁️ VisibilitySystem: Unit 1 is no longer visible - resetting forced revelation")
	
	# Reset unit2_force_revealed if it's not naturally visible
	if unit2_force_revealed and current_player == 1:
		if not is_point_visible_to_current_unit(unit2_position):
			unit2_force_revealed = false
			changes.unit2_changed = true
			print("👁️ VisibilitySystem: Unit 2 is no longer visible - resetting forced revelation")
	
	return changes

## Get current visibility state
func get_visibility_state() -> Dictionary:
	return {
		"unit1_force_revealed": unit1_force_revealed,
		"unit2_force_revealed": unit2_force_revealed,
		"fog_of_war": fog_of_war
	}

## Set forced revelation for a unit
func set_unit_force_revealed(unit_id: int, revealed: bool) -> void:
	if unit_id == 1:
		unit1_force_revealed = revealed
		print("👁️ VisibilitySystem: Unit 1 forced revelation set to %s" % revealed)
	elif unit_id == 2:
		unit2_force_revealed = revealed
		print("👁️ VisibilitySystem: Unit 2 forced revelation set to %s" % revealed)

## Helper function: Get hexagonal direction
func _hex_direction(direction: int) -> Vector2:
	var directions = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	return directions[direction]

## Helper function: Find hexagonal coordinate index
func _find_hex_coord_index(coord: Vector2) -> int:
	for i in range(hex_coords.size()):
		if hex_coords[i].is_equal_approx(coord):
			return i
	return -1

## Helper function: Calculate hexagonal distance between two coordinates
func _hex_distance(coord1: Vector2, coord2: Vector2) -> int:
	# Axial coordinate distance formula
	return int((abs(coord1.x - coord2.x) + abs(coord1.x + coord1.y - coord2.x - coord2.y) + abs(coord1.y - coord2.y)) / 2)