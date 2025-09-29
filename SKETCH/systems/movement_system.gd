extends Node

# MovementSystem - Centralized movement validation and collision detection
# Extracted from main_game.gd as part of Step 11 refactoring

# Game state references
var points = []
var hex_coords = []
var paths = []
var current_player = 1

# Unit positions
var unit1_position = 0
var unit2_position = 0

# Unit labels for visibility checks
var unit1_label: Label
var unit2_label: Label

# Forced revelation flags
var unit1_force_revealed = false
var unit2_force_revealed = false

## Initialize the movement system
func initialize(game_points: Array, game_hex_coords: Array, game_paths: Array) -> void:
	points = game_points
	hex_coords = game_hex_coords
	paths = game_paths
	print("🚶‍♂️ MovementSystem initialized with %d points, %d paths" % [points.size(), paths.size()])

## Update game state
func update_game_state(state: Dictionary) -> void:
	if state.has("current_player"):
		current_player = state.current_player
	if state.has("unit1_position"):
		unit1_position = state.unit1_position
	if state.has("unit2_position"):
		unit2_position = state.unit2_position
	if state.has("unit1_force_revealed"):
		unit1_force_revealed = state.unit1_force_revealed
	if state.has("unit2_force_revealed"):
		unit2_force_revealed = state.unit2_force_revealed
	if state.has("unit1_label"):
		unit1_label = state.unit1_label
	if state.has("unit2_label"):
		unit2_label = state.unit2_label

## Check if current unit can move to point
func can_current_unit_move_to_point(point_index: int) -> bool:
	var unit_pos = unit1_position if current_player == 1 else unit2_position
	return can_unit_move_to_point(point_index, unit_pos)

## Check if a specific unit can move to point
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
			var field_type = GameConstants.EdgeType.FIELD if GameConstants else 0  # EdgeType.FIELD
			var forest_type = GameConstants.EdgeType.FOREST if GameConstants else 1  # EdgeType.FOREST
			if path.type == field_type or path.type == forest_type:
				return true
	return false

## Attempt movement and check for hidden units
func attempt_movement(target_point: int) -> Dictionary:
	# Check if there's an enemy unit at the destination point
	var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	
	# If enemy unit is at destination point
	if enemy_unit_pos == target_point:
		# Check if movement is through forest
		var path_type = get_path_type_between_points(current_unit_pos, target_point)
		
		# Check if enemy unit was hidden (not visible)
		var enemy_was_visible = false
		if current_player == 1 and unit2_label:
			enemy_was_visible = unit2_label.visible
		elif current_player == 2 and unit1_label:
			enemy_was_visible = unit1_label.visible
		
		var forest_type = GameConstants.EdgeType.FOREST if GameConstants else 1  # EdgeType.FOREST
		if path_type == forest_type and not enemy_was_visible:
			# Reveal enemy unit in forest
			print("🔍 MovementSystem: Enemy unit revealed in forest!")
			# Mark enemy unit as forcefully revealed
			if current_player == 1:
				unit2_force_revealed = true
			else:
				unit1_force_revealed = true
			return {"success": false, "message": "Enemy unit discovered in forest! Movement cancelled.", "unit_revealed": true}
		else:
			# Movement blocked by visible unit or non-forest terrain
			return {"success": false, "message": "Point occupied by enemy unit.", "unit_revealed": false}
	
	# Successful movement
	return {"success": true, "message": "", "unit_revealed": false}

## Get path type between two points
func get_path_type_between_points(point1: int, point2: int) -> int:
	for path in paths:
		var path_points = path.points
		if (path_points[0] == point1 and path_points[1] == point2) or \
		   (path_points[1] == point1 and path_points[0] == point2):
			return path.type
	
	# If no path found, return MOUNTAIN (blocked)
	var mountain_type = GameConstants.EdgeType.MOUNTAIN if GameConstants else 2  # EdgeType.MOUNTAIN
	return mountain_type

## Validate movement request
func validate_movement(point_index: int, unit_actions: int, has_power: bool) -> Dictionary:
	# Check if unit can move to the point
	if not can_current_unit_move_to_point(point_index):
		return {
			"valid": false,
			"message": "Unit %d cannot move to point %d" % [current_player, point_index]
		}
	
	# Check if unit has actions
	if unit_actions <= 0:
		return {
			"valid": false,
			"message": "No actions remaining! Use 'Skip Turn' to restore."
		}
	
	# Check if domain has power
	if not has_power:
		return {
			"valid": false,
			"message": "No power! Domain doesn't have power to perform action."
		}
	
	return {"valid": true, "message": "Movement valid"}

## Get movement state for synchronization
func get_movement_state() -> Dictionary:
	return {
		"unit1_force_revealed": unit1_force_revealed,
		"unit2_force_revealed": unit2_force_revealed
	}

## Set forced revelation for a unit
func set_unit_force_revealed(unit_id: int, revealed: bool) -> void:
	if unit_id == 1:
		unit1_force_revealed = revealed
		print("🚶‍♂️ MovementSystem: Unit 1 forced revelation set to %s" % revealed)
	elif unit_id == 2:
		unit2_force_revealed = revealed
		print("🚶‍♂️ MovementSystem: Unit 2 forced revelation set to %s" % revealed)

## Check if path is adjacent to current player
func is_path_adjacent_to_current_unit(path: Dictionary) -> bool:
	# Path is adjacent if one of the points has the current player's unit
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	var path_points = path.points
	return path_points[0] == current_unit_pos or path_points[1] == current_unit_pos

## Get all valid movement targets for current unit
func get_valid_movement_targets() -> Array:
	var valid_targets = []
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	
	for i in range(points.size()):
		if can_unit_move_to_point(i, current_unit_pos):
			valid_targets.append(i)
	
	return valid_targets

## Check if two points are adjacent (connected by a path)
func are_points_adjacent(point1: int, point2: int) -> bool:
	for path in paths:
		var path_points = path.points
		if (path_points[0] == point1 and path_points[1] == point2) or \
		   (path_points[1] == point1 and path_points[0] == point2):
			return true
	return false

## Get path between two adjacent points
func get_path_between_points(point1: int, point2: int) -> Dictionary:
	for path in paths:
		var path_points = path.points
		if (path_points[0] == point1 and path_points[1] == point2) or \
		   (path_points[1] == point1 and path_points[0] == point2):
			return path
	return {}

## Check if movement would reveal enemy unit
func would_movement_reveal_enemy(target_point: int) -> Dictionary:
	var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	
	if enemy_unit_pos != target_point:
		return {"would_reveal": false, "enemy_unit": 0}
	
	# Check if movement is through forest
	var path_type = get_path_type_between_points(current_unit_pos, target_point)
	var forest_type = GameConstants.EdgeType.FOREST if GameConstants else 1  # EdgeType.FOREST
	
	if path_type == forest_type:
		# Check if enemy unit is currently hidden
		var enemy_was_visible = false
		if current_player == 1 and unit2_label:
			enemy_was_visible = unit2_label.visible
		elif current_player == 2 and unit1_label:
			enemy_was_visible = unit1_label.visible
		
		if not enemy_was_visible:
			var enemy_unit_id = 2 if current_player == 1 else 1
			return {"would_reveal": true, "enemy_unit": enemy_unit_id}
	
	return {"would_reveal": false, "enemy_unit": 0}