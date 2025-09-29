extends Node

# DrawingSystem - Centralized visual rendering utilities and drawing functions
# Extracted from main_game.gd as part of Step 15 refactoring (FINAL STEP!)

# Game state references
var points = []
var hex_coords = []
var paths = []
var current_player = 1
var fog_of_war = true

# Domain data
var unit1_domain_center = 0
var unit2_domain_center = 0
var unit1_domain_name = ""
var unit2_domain_name = ""

## Initialize the drawing system
func initialize(game_points: Array, game_hex_coords: Array, game_paths: Array) -> void:
	points = game_points
	hex_coords = game_hex_coords
	paths = game_paths
	print("🎨 DrawingSystem initialized with %d points, %d paths" % [points.size(), paths.size()])

## Update game state
func update_game_state(state: Dictionary) -> void:
	if state.has("current_player"):
		current_player = state.current_player
	if state.has("fog_of_war"):
		fog_of_war = state.fog_of_war
	if state.has("unit1_domain_center"):
		unit1_domain_center = state.unit1_domain_center
	if state.has("unit2_domain_center"):
		unit2_domain_center = state.unit2_domain_center
	if state.has("unit1_domain_name"):
		unit1_domain_name = state.unit1_domain_name
	if state.has("unit2_domain_name"):
		unit2_domain_name = state.unit2_domain_name

## Draw hexagonal domains
func draw_domains(draw_context: Node2D) -> void:
	print("🎨 DrawingSystem: Drawing domains")
	
	# Draw unit 1's domain (red)
	if unit1_domain_center >= 0 and unit1_domain_center < points.size():
		draw_domain_hexagon(draw_context, unit1_domain_center, Color(1.0, 0.0, 0.0))
	
	# Draw unit 2's domain (violet)
	if unit2_domain_center >= 0 and unit2_domain_center < points.size():
		draw_domain_hexagon(draw_context, unit2_domain_center, Color(0.5, 0.0, 0.8))

## Draw domain hexagon
func draw_domain_hexagon(draw_context: Node2D, center_index: int, color: Color) -> void:
	# Check if domain should be visible (fog of war)
	if fog_of_war and not is_domain_visible(center_index):
		return
	
	var center_pos = points[center_index]
	# Calculate radius based on real distance between adjacent points
	var radius = get_edge_length(center_index)
	
	# Calculate the 6 vertices of the hexagon
	var vertices = []
	for i in range(6):
		var angle = (i * PI / 3.0) + (PI / 6.0)  # Start with point up
		var x = center_pos.x + radius * cos(angle)
		var y = center_pos.y + radius * sin(angle)
		vertices.append(Vector2(x, y))
	
	# Draw the 6 edges of the hexagon
	for i in range(6):
		var start = vertices[i]
		var end = vertices[(i + 1) % 6]
		draw_context.draw_line(start, end, color, 4)  # Thicker line

## Get real length of an edge
func get_edge_length(point_index: int) -> float:
	# Find an adjacent point and calculate distance
	var point_coord = hex_coords[point_index]
	for dir in range(6):
		var neighbor_coord = point_coord + hex_direction(dir)
		var neighbor_index = find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1:
			# Calculate distance between points
			var distance = points[point_index].distance_to(points[neighbor_index])
			return distance
	
	# Fallback to hex_size if no neighbor found
	return 40.0

## Get path color based on type (more saturated colors)
func get_path_color(path_type: int) -> Color:
	match path_type:
		0:  # FIELD
			return Color.GREEN          # Green: field
		1:  # FOREST
			return Color(0.2, 0.7, 0.2) # More saturated green: forest
		2:  # MOUNTAIN
			return Color(0.7, 0.7, 0.2) # More saturated yellow: mountain
		3:  # WATER
			return Color(0.2, 0.7, 0.7) # More saturated cyan: water
		_:
			return Color.BLACK

## Check if point is near line (utility for hover detection)
func point_near_line(point: Vector2, line_start: Vector2, line_end: Vector2, tolerance: float) -> bool:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len = line_vec.length()
	
	if line_len == 0:
		return point.distance_to(line_start) <= tolerance
	
	var t = point_vec.dot(line_vec) / (line_len * line_len)
	t = clamp(t, 0.0, 1.0)
	
	var closest_point = line_start + t * line_vec
	return point.distance_to(closest_point) <= tolerance

## Draw background
func draw_background(draw_context: Node2D) -> void:
	# Expanded white background
	draw_context.draw_rect(Rect2(-200, -200, 1200, 1000), Color.WHITE)

## Draw paths with visibility logic
func draw_paths(draw_context: Node2D, hovered_edge: int, visibility_check_func: Callable, domain_check_func: Callable) -> void:
	for i in range(paths.size()):
		var path = paths[i]
		# Render based on fog of war
		var should_render = false
		if fog_of_war:
			# With fog: adjacent to current player, hover OR within current player's domain
			should_render = visibility_check_func.call(path) or hovered_edge == i or domain_check_func.call(path)
		else:
			# Without fog: all paths
			should_render = true
		
		if should_render:
			var path_points = path.points
			var p1 = points[path_points[0]]
			var p2 = points[path_points[1]]
			var color = get_path_color(path.type)
			if hovered_edge == i:
				color = Color.MAGENTA
			draw_context.draw_line(p1, p2, color, 8)  # Even thicker paths

## Draw points with visibility logic
func draw_points(draw_context: Node2D, hovered_point: int, unit1_position: int, unit2_position: int, visibility_check_func: Callable, movement_check_func: Callable, domain_check_func: Callable) -> void:
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
			elif i == enemy_unit_pos and visibility_check_func.call(i):
				should_render = true
			# Render points visible to current player
			elif visibility_check_func.call(i):
				should_render = true
			# Render points on hover
			elif hovered_point == i:
				should_render = true
			# Render points within current player's domain
			elif domain_check_func.call(i):
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
			elif movement_check_func.call(i):
				color = Color.MAGENTA
			
			draw_context.draw_circle(points[i], 8, color)

## Complete rendering pipeline
func render_complete_scene(draw_context: Node2D, render_state: Dictionary, visibility_funcs: Dictionary) -> void:
	print("🎨 DrawingSystem: Rendering complete scene")
	
	# Update internal state
	update_game_state(render_state)
	
	# Draw background
	draw_background(draw_context)
	
	# Draw paths
	draw_paths(draw_context, render_state.hovered_edge, visibility_funcs.path_visibility, visibility_funcs.path_domain)
	
	# Draw points
	draw_points(draw_context, render_state.hovered_point, render_state.unit1_position, render_state.unit2_position, visibility_funcs.point_visibility, visibility_funcs.point_movement, visibility_funcs.point_domain)
	
	# Draw domains
	draw_domains(draw_context)

## Draw grid lines (debug utility)
func draw_grid_lines(draw_context: Node2D, grid_color: Color = Color.GRAY, line_width: float = 1.0) -> void:
	for path in paths:
		var path_points = path.points
		var p1 = points[path_points[0]]
		var p2 = points[path_points[1]]
		draw_context.draw_line(p1, p2, grid_color, line_width)

## Draw point indices (debug utility)
func draw_point_indices(draw_context: Node2D, font_size: int = 12, text_color: Color = Color.BLACK) -> void:
	for i in range(points.size()):
		var pos = points[i]
		# Note: In a real implementation, you'd need a font resource
		# This is a placeholder for the concept
		print("🎨 DrawingSystem: Would draw index %d at %s" % [i, pos])

## Draw coordinate system (debug utility)
func draw_coordinate_system(draw_context: Node2D, show_axial: bool = true, text_color: Color = Color.BLUE) -> void:
	if show_axial:
		for i in range(hex_coords.size()):
			var coord = hex_coords[i]
			var pos = points[i]
			print("🎨 DrawingSystem: Would draw coord (%d,%d) at %s" % [coord.x, coord.y, pos])

## Draw domain boundaries (enhanced visualization)
func draw_domain_boundaries(draw_context: Node2D, domain_center: int, boundary_color: Color, line_width: float = 2.0) -> void:
	if domain_center < 0 or domain_center >= points.size():
		return
	
	var center_coord = hex_coords[domain_center]
	
	# Draw lines to all 6 neighbors
	for dir in range(6):
		var neighbor_coord = center_coord + hex_direction(dir)
		var neighbor_index = find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1:
			var center_pos = points[domain_center]
			var neighbor_pos = points[neighbor_index]
			draw_context.draw_line(center_pos, neighbor_pos, boundary_color, line_width)

## Draw movement range (utility for showing valid moves)
func draw_movement_range(draw_context: Node2D, unit_position: int, range_color: Color = Color.YELLOW, alpha: float = 0.3) -> void:
	# This would highlight all points the unit can move to
	var highlight_color = Color(range_color.r, range_color.g, range_color.b, alpha)
	
	# Draw circles around valid movement points
	for i in range(points.size()):
		if can_unit_move_to_point(i, unit_position):
			draw_context.draw_circle(points[i], 12, highlight_color)

## Helper function: Check if domain is visible (enhanced)
func is_domain_visible(domain_center: int) -> bool:
	print("🎨 DrawingSystem: Checking domain visibility for center=%d, current_player=%d" % [domain_center, current_player])
	
	# Domain always visible if it belongs to current player
	if (current_player == 1 and domain_center == unit1_domain_center) or \
	   (current_player == 2 and domain_center == unit2_domain_center):
		print("🎨 DrawingSystem: Domain belongs to current player - VISIBLE")
		return true
	
	# For enemy domains, use more complex visibility logic
	# This is a simplified version - in practice, you'd call VisibilitySystem
	var current_unit_pos = 0  # Would get from game state
	var distance = hex_distance(hex_coords[current_unit_pos], hex_coords[domain_center])
	if distance <= 2:
		print("🎨 DrawingSystem: Domain within 2 hexes - VISIBLE")
		return true
	
	print("🎨 DrawingSystem: Domain not visible - HIDDEN")
	return false

## Helper function: Check if unit can move to point (simplified)
func can_unit_move_to_point(point_index: int, unit_pos: int) -> bool:
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

## Helper function: Get hexagonal direction
func hex_direction(direction: int) -> Vector2:
	var directions = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	return directions[direction]

## Helper function: Find hexagonal coordinate index
func find_hex_coord_index(coord: Vector2) -> int:
	for i in range(hex_coords.size()):
		if hex_coords[i].is_equal_approx(coord):
			return i
	return -1

## Helper function: Calculate hexagonal distance
func hex_distance(coord1: Vector2, coord2: Vector2) -> int:
	return int((abs(coord1.x - coord2.x) + abs(coord1.x + coord1.y - coord2.x - coord2.y) + abs(coord1.y - coord2.y)) / 2)

## Get drawing capabilities info
func get_drawing_info() -> Dictionary:
	return {
		"system_name": "DrawingSystem",
		"version": "1.0",
		"capabilities": [
			"Domain rendering",
			"Path visualization", 
			"Point rendering",
			"Background drawing",
			"Debug utilities",
			"Movement range display",
			"Coordinate visualization"
		],
		"points_count": points.size(),
		"paths_count": paths.size()
	}