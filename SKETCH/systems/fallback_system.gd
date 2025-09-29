extends Node

# FallbackSystem - Centralized backward compatibility and fallback management
# Extracted from main_game.gd as part of Step 14 refactoring

# Game state references
var points = []
var hex_coords = []
var paths = []
var current_player = 1
var fog_of_war = true

# Unit positions and states
var unit1_position = 0
var unit2_position = 0
var unit1_actions = 1
var unit2_actions = 1
var unit1_domain_power = 1
var unit2_domain_power = 1
var unit1_force_revealed = false
var unit2_force_revealed = false

# Domain data
var unit1_domain_center = 0
var unit2_domain_center = 0
var unit1_domain_name = ""
var unit2_domain_name = ""
var unit1_name = ""
var unit2_name = ""

# UI references
var unit1_label: Label
var unit2_label: Label
var hovered_point = -1
var hovered_edge = -1

## Initialize the fallback system
func initialize(game_points: Array, game_hex_coords: Array, game_paths: Array) -> void:
	points = game_points
	hex_coords = game_hex_coords
	paths = game_paths
	print("🔄 FallbackSystem initialized with %d points, %d paths" % [points.size(), paths.size()])

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
	if state.has("unit1_actions"):
		unit1_actions = state.unit1_actions
	if state.has("unit2_actions"):
		unit2_actions = state.unit2_actions
	if state.has("unit1_domain_power"):
		unit1_domain_power = state.unit1_domain_power
	if state.has("unit2_domain_power"):
		unit2_domain_power = state.unit2_domain_power
	if state.has("unit1_force_revealed"):
		unit1_force_revealed = state.unit1_force_revealed
	if state.has("unit2_force_revealed"):
		unit2_force_revealed = state.unit2_force_revealed
	if state.has("unit1_domain_center"):
		unit1_domain_center = state.unit1_domain_center
	if state.has("unit2_domain_center"):
		unit2_domain_center = state.unit2_domain_center
	if state.has("unit1_label"):
		unit1_label = state.unit1_label
	if state.has("unit2_label"):
		unit2_label = state.unit2_label
	if state.has("hovered_point"):
		hovered_point = state.hovered_point
	if state.has("hovered_edge"):
		hovered_edge = state.hovered_edge

## Fallback hover processing
func process_hover_fallback(mouse_pos: Vector2) -> Dictionary:
	var old_hovered_point = hovered_point
	var old_hovered_edge = hovered_edge
	
	# Check hover on points (including non-rendered ones)
	hovered_point = -1
	for i in range(points.size()):
		if mouse_pos.distance_to(points[i]) < 20:
			hovered_point = i
			break
	
	# Check hover on paths (including non-rendered ones)
	hovered_edge = -1
	if hovered_point == -1:
		for i in range(paths.size()):
			var path = paths[i]
			var path_points = path.points
			var p1 = points[path_points[0]]
			var p2 = points[path_points[1]]
			if _point_near_line(mouse_pos, p1, p2, 10):
				hovered_edge = i
				break
	
	return {
		"hovered_point": hovered_point,
		"hovered_edge": hovered_edge,
		"point_changed": old_hovered_point != hovered_point,
		"edge_changed": old_hovered_edge != hovered_edge
	}

## Fallback input handling
func handle_input_fallback(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Note: mouse_pos should be passed from main_game.gd
		# This is a fallback system, so we'll return false for now
		print("🔄 FallbackSystem: Mouse input detected but position not available")
		return false
	
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("🔄 FallbackSystem: Fog toggle requested")
			return true
	
	return false

## Fallback movement handling
func handle_movement_fallback(point_index: int, current_actions: int, has_power: bool) -> Dictionary:
	print("🔄 FallbackSystem: Processing movement to point %d" % point_index)
	
	# Check if unit can move to the point
	if not _can_current_unit_move_to_point(point_index):
		return {
			"success": false,
			"message": "Unit %d cannot move to point %d" % [current_player, point_index],
			"consume_action": false
		}
	
	# Check if unit has actions
	if current_actions <= 0:
		return {
			"success": false,
			"message": "No actions remaining! Use 'Skip Turn' to restore.",
			"consume_action": false
		}
	
	# Check if domain has power
	if not has_power:
		return {
			"success": false,
			"message": "No power! Domain doesn't have power to perform action.",
			"consume_action": false
		}
	
	# Check if there's a hidden unit at destination
	var movement_result = _attempt_movement(point_index)
	
	if movement_result.success:
		var old_pos = unit1_position if current_player == 1 else unit2_position
		print("🔄 FallbackSystem: Unit %d moving from point %d to point %d" % [current_player, old_pos, point_index])
		
		# Update position
		if current_player == 1:
			unit1_position = point_index
		else:
			unit2_position = point_index
		
		return {
			"success": true,
			"message": "Movement successful",
			"consume_action": true,
			"new_position": point_index
		}
	else:
		# Movement failed due to hidden unit
		print("🔄 FallbackSystem: Movement blocked! %s" % movement_result.message)
		return {
			"success": false,
			"message": movement_result.message,
			"consume_action": true  # Lose action anyway
		}

## Fallback skip turn handling
func handle_skip_turn_fallback() -> Dictionary:
	print("🔄 FallbackSystem: Player %d skip turn" % current_player)
	
	# Switch player FIRST
	current_player = 3 - current_player  # 1 -> 2, 2 -> 1
	print("🔄 FallbackSystem: Switched to Player %d" % current_player)
	
	# Restore actions for new player
	if current_player == 1:
		unit1_actions = 1
	else:
		unit2_actions = 1
	
	# Reset forced revelations if units are no longer visible
	_check_and_reset_forced_revelations()
	
	# Generate power for the NEW current player
	_generate_power_for_current_player_only()
	
	return {
		"new_player": current_player,
		"unit1_actions": unit1_actions,
		"unit2_actions": unit2_actions,
		"unit1_domain_power": unit1_domain_power,
		"unit2_domain_power": unit2_domain_power,
		"unit1_force_revealed": unit1_force_revealed,
		"unit2_force_revealed": unit2_force_revealed
	}

## Fallback rendering function
func render_fallback(draw_context: Node2D) -> void:
	# Expanded white background
	draw_context.draw_rect(Rect2(-200, -200, 1200, 1000), Color.WHITE)
	
	# Draw paths (with or without fog of war)
	for i in range(paths.size()):
		var path = paths[i]
		# Render based on fog of war
		var should_render = false
		if fog_of_war:
			# With fog: adjacent to current player, hover OR within current player's domain
			should_render = _is_path_adjacent_to_current_unit(path) or hovered_edge == i or _is_path_in_current_player_domain(path)
		else:
			# Without fog: all paths
			should_render = true
		
		if should_render:
			var path_points = path.points
			var p1 = points[path_points[0]]
			var p2 = points[path_points[1]]
			var color = _get_path_color(path.type)
			if hovered_edge == i:
				color = Color.MAGENTA
			draw_context.draw_line(p1, p2, color, 8)  # Even thicker paths
	
	# Draw points (with or without fog of war)
	for i in range(points.size()):
		var current_unit_pos = unit1_position if current_player == 1 else unit2_position
		var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
		
		var should_render = false
		
		if fog_of_war:
			# With fog: render based on visibility
			# Always render current player's unit
			if i == current_unit_pos:
				should_render = true
			# Render enemy unit only if it's on a visible point
			elif i == enemy_unit_pos and _is_point_visible_to_current_unit(i):
				should_render = true
			# Render points visible to current player
			elif _is_point_visible_to_current_unit(i):
				should_render = true
			# Render points on hover
			elif hovered_point == i:
				should_render = true
			# Render points within current player's domain
			elif _is_point_in_current_player_domain(i):
				should_render = true
		else:
			# Without fog: render all points
			should_render = true
		
		if should_render:
			var color = Color.BLACK
			
			# Magenta if hovering
			if hovered_point == i:
				color = Color.MAGENTA
			# Magenta if current unit can move there
			elif _can_current_unit_move_to_point(i):
				color = Color.MAGENTA
			
			draw_context.draw_circle(points[i], 8, color)
	
	# Draw domains
	_draw_domains(draw_context)

## Get current game state
func get_game_state() -> Dictionary:
	return {
		"current_player": current_player,
		"fog_of_war": fog_of_war,
		"unit1_position": unit1_position,
		"unit2_position": unit2_position,
		"unit1_actions": unit1_actions,
		"unit2_actions": unit2_actions,
		"unit1_domain_power": unit1_domain_power,
		"unit2_domain_power": unit2_domain_power,
		"unit1_force_revealed": unit1_force_revealed,
		"unit2_force_revealed": unit2_force_revealed,
		"hovered_point": hovered_point,
		"hovered_edge": hovered_edge
	}

## Helper function: Point near line detection
func _point_near_line(point: Vector2, line_start: Vector2, line_end: Vector2, tolerance: float) -> bool:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len = line_vec.length()
	
	if line_len == 0:
		return point.distance_to(line_start) <= tolerance
	
	var t = point_vec.dot(line_vec) / (line_len * line_len)
	t = clamp(t, 0.0, 1.0)
	
	var closest_point = line_start + t * line_vec
	return point.distance_to(closest_point) <= tolerance

## Helper function: Get path color based on type
func _get_path_color(path_type: int) -> Color:
	match path_type:
		0:  # FIELD
			return Color.GREEN
		1:  # FOREST
			return Color(0.2, 0.7, 0.2)
		2:  # MOUNTAIN
			return Color(0.7, 0.7, 0.2)
		3:  # WATER
			return Color(0.2, 0.7, 0.7)
		_:
			return Color.BLACK

## Helper function: Check if path is adjacent to current unit
func _is_path_adjacent_to_current_unit(path: Dictionary) -> bool:
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	var path_points = path.points
	return path_points[0] == current_unit_pos or path_points[1] == current_unit_pos

## Helper function: Check if point is visible to current unit
func _is_point_visible_to_current_unit(point_index: int) -> bool:
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	return _is_point_visible_to_unit(point_index, current_unit_pos)

## Helper function: Check if point is visible to a specific unit
func _is_point_visible_to_unit(point_index: int, unit_pos: int) -> bool:
	for path in paths:
		var path_points = path.points
		if (path_points[0] == unit_pos and path_points[1] == point_index) or \
		   (path_points[1] == unit_pos and path_points[0] == point_index):
			# Field and Water allow seeing
			if path.type == 0 or path.type == 3:  # FIELD or WATER
				return true
	return false

## Helper function: Check if point is in current player's domain
func _is_point_in_current_player_domain(point_index: int) -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	return _is_point_in_specific_domain(point_index, domain_center)

## Helper function: Check if path is in current player's domain
func _is_path_in_current_player_domain(path: Dictionary) -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var point1 = path.points[0]
	var point2 = path.points[1]
	return _is_point_in_specific_domain(point1, domain_center) and _is_point_in_specific_domain(point2, domain_center)

## Helper function: Check if point is in specific domain
func _is_point_in_specific_domain(point_index: int, domain_center: int) -> bool:
	if point_index == domain_center:
		return true
	
	var domain_coord = hex_coords[domain_center]
	var point_coord = hex_coords[point_index]
	
	for dir in range(6):
		var neighbor_coord = domain_coord + _hex_direction(dir)
		if point_coord.is_equal_approx(neighbor_coord):
			return true
	
	return false

## Helper function: Check if current unit can move to point
func _can_current_unit_move_to_point(point_index: int) -> bool:
	var unit_pos = unit1_position if current_player == 1 else unit2_position
	return _can_unit_move_to_point(point_index, unit_pos)

## Helper function: Check if unit can move to point
func _can_unit_move_to_point(point_index: int, unit_pos: int) -> bool:
	if point_index == unit_pos:
		return false
	
	for path in paths:
		var path_points = path.points
		if (path_points[0] == unit_pos and path_points[1] == point_index) or \
		   (path_points[1] == unit_pos and path_points[0] == point_index):
			# Field and Forest allow movement
			if path.type == 0 or path.type == 1:  # FIELD or FOREST
				return true
	return false

## Helper function: Attempt movement
func _attempt_movement(target_point: int) -> Dictionary:
	var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	
	if enemy_unit_pos == target_point:
		var path_type = _get_path_type_between_points(current_unit_pos, target_point)
		
		var enemy_was_visible = false
		if current_player == 1 and unit2_label:
			enemy_was_visible = unit2_label.visible
		elif current_player == 2 and unit1_label:
			enemy_was_visible = unit1_label.visible
		
		if path_type == 1 and not enemy_was_visible:  # FOREST
			print("🔄 FallbackSystem: Enemy unit revealed in forest!")
			if current_player == 1:
				unit2_force_revealed = true
			else:
				unit1_force_revealed = true
			return {"success": false, "message": "Enemy unit discovered in forest! Movement cancelled."}
		else:
			return {"success": false, "message": "Point occupied by enemy unit."}
	
	return {"success": true, "message": ""}

## Helper function: Get path type between points
func _get_path_type_between_points(point1: int, point2: int) -> int:
	for path in paths:
		var path_points = path.points
		if (path_points[0] == point1 and path_points[1] == point2) or \
		   (path_points[1] == point1 and path_points[0] == point2):
			return path.type
	return 2  # MOUNTAIN (blocked)

## Helper function: Check and reset forced revelations
func _check_and_reset_forced_revelations() -> void:
	if unit1_force_revealed and current_player == 2:
		if not _is_point_visible_to_current_unit(unit1_position):
			unit1_force_revealed = false
			print("🔄 FallbackSystem: Unit 1 is no longer visible - resetting forced revelation")
	
	if unit2_force_revealed and current_player == 1:
		if not _is_point_visible_to_current_unit(unit2_position):
			unit2_force_revealed = false
			print("🔄 FallbackSystem: Unit 2 is no longer visible - resetting forced revelation")

## Helper function: Generate power for current player only
func _generate_power_for_current_player_only() -> void:
	print("🔄 FallbackSystem: Player %d is starting their turn" % current_player)
	
	if current_player == 1:
		if unit2_position != unit1_domain_center:
			unit1_domain_power += 1
			print("🔄 FallbackSystem: Domain 1 (%s) generated power (Total: %d)" % [unit1_domain_name, unit1_domain_power])
		else:
			print("🔄 FallbackSystem: Domain 1 (%s) occupied - no power generated" % unit1_domain_name)
	elif current_player == 2:
		if unit1_position != unit2_domain_center:
			unit2_domain_power += 1
			print("🔄 FallbackSystem: Domain 2 (%s) generated power (Total: %d)" % [unit2_domain_name, unit2_domain_power])
		else:
			print("🔄 FallbackSystem: Domain 2 (%s) occupied - no power generated" % unit2_domain_name)

## Helper function: Draw domains
func _draw_domains(draw_context: Node2D) -> void:
	# Draw unit 1's domain (red)
	if unit1_domain_center >= 0 and unit1_domain_center < points.size():
		_draw_domain_hexagon(draw_context, unit1_domain_center, Color(1.0, 0.0, 0.0))
	
	# Draw unit 2's domain (violet)
	if unit2_domain_center >= 0 and unit2_domain_center < points.size():
		_draw_domain_hexagon(draw_context, unit2_domain_center, Color(0.5, 0.0, 0.8))

## Helper function: Draw domain hexagon
func _draw_domain_hexagon(draw_context: Node2D, center_index: int, color: Color) -> void:
	if fog_of_war and not _is_domain_visible(center_index):
		return
	
	var center_pos = points[center_index]
	var radius = _get_edge_length(center_index)
	
	var vertices = []
	for i in range(6):
		var angle = (i * PI / 3.0) + (PI / 6.0)
		var x = center_pos.x + radius * cos(angle)
		var y = center_pos.y + radius * sin(angle)
		vertices.append(Vector2(x, y))
	
	for i in range(6):
		var start = vertices[i]
		var end = vertices[(i + 1) % 6]
		draw_context.draw_line(start, end, color, 4)

## Helper function: Check if domain is visible
func _is_domain_visible(domain_center: int) -> bool:
	if (current_player == 1 and domain_center == unit1_domain_center) or \
	   (current_player == 2 and domain_center == unit2_domain_center):
		return true
	
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	if _is_point_visible_to_unit(domain_center, current_unit_pos):
		return true
	
	var domain_coord = hex_coords[domain_center]
	for dir in range(6):
		var neighbor_coord = domain_coord + _hex_direction(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1 and _is_point_visible_to_unit(neighbor_index, current_unit_pos):
			return true
	
	var distance = _hex_distance(hex_coords[current_unit_pos], hex_coords[domain_center])
	if distance <= 2:
		return true
	
	return false

## Helper function: Get edge length
func _get_edge_length(point_index: int) -> float:
	var point_coord = hex_coords[point_index]
	for dir in range(6):
		var neighbor_coord = point_coord + _hex_direction(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1:
			var distance = points[point_index].distance_to(points[neighbor_index])
			return distance
	return 40.0

## Helper function: Hex direction
func _hex_direction(direction: int) -> Vector2:
	var directions = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	return directions[direction]

## Helper function: Find hex coord index
func _find_hex_coord_index(coord: Vector2) -> int:
	for i in range(hex_coords.size()):
		if hex_coords[i].is_equal_approx(coord):
			return i
	return -1

## Helper function: Hex distance
func _hex_distance(coord1: Vector2, coord2: Vector2) -> int:
	return int((abs(coord1.x - coord2.x) + abs(coord1.x + coord1.y - coord2.x - coord2.y) + abs(coord1.y - coord2.y)) / 2)