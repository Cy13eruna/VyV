extends Node

# Rendering system for V&V game
# Handles all drawing operations including paths, points, and domains

signal render_requested

# Game data references (set by main scene)
var points: Array = []
var hex_coords: Array = []
var paths: Array = []

# Rendering state
var fog_of_war: bool = true
var current_player: int = 1
var hovered_point: int = -1
var hovered_edge: int = -1

# Unit positions
var unit1_position: int = 0
var unit2_position: int = 0
var unit1_domain_center: int = 0
var unit2_domain_center: int = 0

# Unit and domain names
var unit1_name: String = ""
var unit2_name: String = ""
var unit1_domain_name: String = ""
var unit2_domain_name: String = ""

# Domain power
var unit1_domain_power: int = 1
var unit2_domain_power: int = 1

# Unit labels for visibility check
var unit1_label: Label
var unit2_label: Label

# Initialize render system with game data
func initialize(game_points: Array, game_hex_coords: Array, game_paths: Array) -> void:
	points = game_points
	hex_coords = game_hex_coords
	paths = game_paths
	print("🎨 RenderSystem initialized with %d points, %d paths" % [points.size(), paths.size()])

# Update rendering state
func update_state(state_data: Dictionary) -> void:
	if state_data.has("fog_of_war"):
		fog_of_war = state_data.fog_of_war
	if state_data.has("current_player"):
		current_player = state_data.current_player
	if state_data.has("hovered_point"):
		hovered_point = state_data.hovered_point
	if state_data.has("hovered_edge"):
		hovered_edge = state_data.hovered_edge
	if state_data.has("unit1_position"):
		unit1_position = state_data.unit1_position
	if state_data.has("unit2_position"):
		unit2_position = state_data.unit2_position
	if state_data.has("unit1_domain_center"):
		unit1_domain_center = state_data.unit1_domain_center
	if state_data.has("unit2_domain_center"):
		unit2_domain_center = state_data.unit2_domain_center
	if state_data.has("unit1_name"):
		unit1_name = state_data.unit1_name
	if state_data.has("unit2_name"):
		unit2_name = state_data.unit2_name
	if state_data.has("unit1_domain_name"):
		unit1_domain_name = state_data.unit1_domain_name
	if state_data.has("unit2_domain_name"):
		unit2_domain_name = state_data.unit2_domain_name
	if state_data.has("unit1_domain_power"):
		unit1_domain_power = state_data.unit1_domain_power
	if state_data.has("unit2_domain_power"):
		unit2_domain_power = state_data.unit2_domain_power
	if state_data.has("unit1_label"):
		unit1_label = state_data.unit1_label
	if state_data.has("unit2_label"):
		unit2_label = state_data.unit2_label

# Main rendering function
func render_game(canvas: CanvasItem) -> void:
	# Draw background
	_draw_background(canvas)
	
	# Draw paths
	_draw_paths(canvas)
	
	# Draw points
	_draw_points(canvas)
	
	# Draw domains
	_draw_domains(canvas)
	
	# Draw unit names directly as part of rendering
	_draw_unit_names(canvas)

# Draw white background
func _draw_background(canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(-200, -200, 1200, 1000), Color.WHITE)

# Draw all paths with fog of war logic
func _draw_paths(canvas: CanvasItem) -> void:
	for i in range(paths.size()):
		var path = paths[i]
		
		# Determine if path should be rendered
		var should_render = _should_render_path(path, i)
		
		if should_render:
			var path_points = path.points
			var p1 = points[path_points[0]]
			var p2 = points[path_points[1]]
			
			# Get path color
			var color = _get_path_color(path.type)
			
			# Highlight hovered edge
			if hovered_edge == i:
				color = Color.MAGENTA
			
			canvas.draw_line(p1, p2, color, 8)

# Draw all points with fog of war logic
func _draw_points(canvas: CanvasItem) -> void:
	for i in range(points.size()):
		# Determine if point should be rendered
		var should_render = _should_render_point(i)
		
		if should_render:
			var color = _get_point_color(i)
			canvas.draw_circle(points[i], 8, color)

# Draw domain hexagons
func _draw_domains(canvas: CanvasItem) -> void:
	# Draw unit 1's domain (red)
	if unit1_domain_center >= 0 and unit1_domain_center < points.size():
		_draw_domain_hexagon(canvas, unit1_domain_center, Color(1.0, 0.0, 0.0))
	
	# Draw unit 2's domain (violet)
	if unit2_domain_center >= 0 and unit2_domain_center < points.size():
		_draw_domain_hexagon(canvas, unit2_domain_center, Color(0.5, 0.0, 0.8))

# Determine if path should be rendered based on fog of war
func _should_render_path(path: Dictionary, path_index: int) -> bool:
	if not fog_of_war:
		return true
	
	# With fog: adjacent to current player, hover OR within current player's domain
	return _is_path_adjacent_to_current_unit(path) or hovered_edge == path_index or _is_path_in_current_player_domain(path)

# Determine if point should be rendered based on fog of war
func _should_render_point(point_index: int) -> bool:
	if not fog_of_war:
		return true
	
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
	
	# Always render current player's unit
	if point_index == current_unit_pos:
		return true
	
	# Render enemy unit only if it's on a visible point
	if point_index == enemy_unit_pos and _is_point_visible_to_current_unit(point_index):
		return true
	
	# Render points visible to current player
	if _is_point_visible_to_current_unit(point_index):
		return true
	
	# Render points on hover
	if hovered_point == point_index:
		return true
	
	# Render points within current player's domain
	if _is_point_in_current_player_domain(point_index):
		return true
	
	return false

# Get color for a point based on state
func _get_point_color(point_index: int) -> Color:
	# Magenta if hovering
	if hovered_point == point_index:
		return Color.MAGENTA
	
	# Magenta if current unit can move there
	if _can_current_unit_move_to_point(point_index):
		return Color.MAGENTA
	
	return Color.BLACK

# Get color for a path based on type
func _get_path_color(path_type: int) -> Color:
	# Use TerrainSystem if available
	if TerrainSystem:
		return TerrainSystem.get_path_color(path_type)
	
	# Fallback color logic
	match path_type:
		0: return Color.GREEN          # FIELD
		1: return Color(0.2, 0.7, 0.2) # FOREST
		2: return Color(0.7, 0.7, 0.2) # MOUNTAIN
		3: return Color(0.2, 0.7, 0.7) # WATER
		_: return Color.BLACK

# Draw a domain hexagon
func _draw_domain_hexagon(canvas: CanvasItem, center_index: int, color: Color) -> void:
	# Check if domain should be visible (fog of war)
	if fog_of_war and not _is_domain_visible(center_index):
		return
	
	var center_pos = points[center_index]
	# Calculate radius based on real distance between adjacent points
	var radius = _get_edge_length(center_index)
	
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
		canvas.draw_line(start, end, color, 4)
	
	# Draw domain name and power as part of domain rendering
	_draw_domain_text(canvas, center_index, center_pos, color)

# Draw domain text directly on screen (FRONT END)
func _draw_domain_text(canvas: CanvasItem, center_index: int, center_pos: Vector2, color: Color) -> void:
	print("🎨 RenderSystem: Drawing domain text for center_index=%d" % center_index)
	
	# Get current power values from PowerSystem (DYNAMIC UPDATE)
	var current_unit1_power = unit1_domain_power
	var current_unit2_power = unit2_domain_power
	if PowerSystem and PowerSystem.has_method("get_player_power"):
		current_unit1_power = PowerSystem.get_player_power(1)
		current_unit2_power = PowerSystem.get_player_power(2)
		print("🎨 RenderSystem: Power from PowerSystem - P1=%d, P2=%d" % [current_unit1_power, current_unit2_power])
	else:
		print("🎨 RenderSystem: Using local power values - P1=%d, P2=%d" % [current_unit1_power, current_unit2_power])
	
	# Determine which domain this is and draw its name/power directly
	if center_index == unit1_domain_center and unit1_domain_name != "":
		# Domain 1 - draw name and power directly on screen
		var text = "%s ⚡%d" % [unit1_domain_name, current_unit1_power]
		var text_pos = center_pos + Vector2(-30, 35)  # Below domain
		# REMOVED: Text background - now transparent
		# Draw the actual text using Godot's built-in font
		var font = ThemeDB.fallback_font
		var font_size = 12
		canvas.draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.RED)
		print("🎨 RenderSystem: Drew Domain1 text '%s' at %s" % [text, text_pos])
	
	elif center_index == unit2_domain_center and unit2_domain_name != "":
		# Domain 2 - draw name and power directly on screen
		var text = "%s ⚡%d" % [unit2_domain_name, current_unit2_power]
		var text_pos = center_pos + Vector2(-30, 35)  # Below domain
		# REMOVED: Text background - now transparent
		# Draw the actual text using Godot's built-in font
		var font = ThemeDB.fallback_font
		var font_size = 12
		canvas.draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.5, 0.0, 0.8))
		print("🎨 RenderSystem: Drew Domain2 text '%s' at %s" % [text, text_pos])

# Draw unit names directly on screen (FRONT END)
func _draw_unit_names(canvas: CanvasItem) -> void:
	print("🔍 RenderSystem: _draw_unit_names called")
	
	# Draw unit 1 name ONLY if unit is visible
	print("🔍 RenderSystem: unit1_label exists=%s, visible=%s" % [unit1_label != null, unit1_label.visible if unit1_label else false])
	if unit1_label and unit1_label.visible and unit1_name != "":
		var unit1_pos = points[unit1_position]
		var text_pos = unit1_pos + Vector2(-15, 15)  # Below unit
		# Draw the actual text using Godot's built-in font
		var font = ThemeDB.fallback_font
		var font_size = 10
		canvas.draw_string(font, text_pos, unit1_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.RED)
		print("🎨 RenderSystem: Drew Unit1 name '%s' at %s" % [unit1_name, text_pos])
	
	# Draw unit 2 name ONLY if unit is visible
	print("🔍 RenderSystem: unit2_label exists=%s, visible=%s" % [unit2_label != null, unit2_label.visible if unit2_label else false])
	if unit2_label and unit2_label.visible and unit2_name != "":
		var unit2_pos = points[unit2_position]
		var text_pos = unit2_pos + Vector2(-15, 15)  # Below unit
		# Draw the actual text using Godot's built-in font
		var font = ThemeDB.fallback_font
		var font_size = 10
		canvas.draw_string(font, text_pos, unit2_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.5, 0.0, 0.8))
		print("🎨 RenderSystem: Drew Unit2 name '%s' at %s" % [unit2_name, text_pos])

# Utility functions for rendering logic
func _is_path_adjacent_to_current_unit(path: Dictionary) -> bool:
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	var path_points = path.points
	return path_points[0] == current_unit_pos or path_points[1] == current_unit_pos

func _is_path_in_current_player_domain(path: Dictionary) -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var point1 = path.points[0]
	var point2 = path.points[1]
	
	return _is_point_in_specific_domain(point1, domain_center) and _is_point_in_specific_domain(point2, domain_center)

func _is_point_in_current_player_domain(point_index: int) -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	return _is_point_in_specific_domain(point_index, domain_center)

func _is_point_in_specific_domain(point_index: int, domain_center: int) -> bool:
	if point_index == domain_center:
		return true
	
	var domain_coord = hex_coords[domain_center]
	var point_coord = hex_coords[point_index]
	
	for dir in range(6):
		var neighbor_coord = domain_coord + _get_hex_direction(dir)
		if point_coord.is_equal_approx(neighbor_coord):
			return true
	
	return false

func _is_point_visible_to_current_unit(point_index: int) -> bool:
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	return _is_point_visible_to_unit(point_index, current_unit_pos)

func _is_point_visible_to_unit(point_index: int, unit_pos: int) -> bool:
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

func _can_current_unit_move_to_point(point_index: int) -> bool:
	var unit_pos = unit1_position if current_player == 1 else unit2_position
	return _can_unit_move_to_point(point_index, unit_pos)

func _can_unit_move_to_point(point_index: int, unit_pos: int) -> bool:
	if point_index == unit_pos:
		return false
	
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

func _is_domain_visible(domain_center: int) -> bool:
	# Domain always visible if it belongs to current player
	if (current_player == 1 and domain_center == unit1_domain_center) or \
	   (current_player == 2 and domain_center == unit2_domain_center):
		return true
	
	# Enemy domain visible if center or any adjacent point is visible
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	
	# Check if domain center is visible
	if _is_point_visible_to_unit(domain_center, current_unit_pos):
		return true
	
	# Check if any point adjacent to domain center is visible
	var domain_coord = hex_coords[domain_center]
	for dir in range(6):
		var neighbor_coord = domain_coord + _get_hex_direction(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1 and _is_point_visible_to_unit(neighbor_index, current_unit_pos):
			return true
	
	return false

func _get_edge_length(point_index: int) -> float:
	var point_coord = hex_coords[point_index]
	for dir in range(6):
		var neighbor_coord = point_coord + _get_hex_direction(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1:
			var distance = points[point_index].distance_to(points[neighbor_index])
			return distance
	
	return 40.0  # Fallback hex_size

func _get_hex_direction(direction: int) -> Vector2:
	var directions = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	return directions[direction % 6]

func _find_hex_coord_index(coord: Vector2) -> int:
	for i in range(hex_coords.size()):
		if hex_coords[i].is_equal_approx(coord):
			return i
	return -1

# Get current rendering state for debugging
func get_render_state() -> Dictionary:
	return {
		"fog_of_war": fog_of_war,
		"current_player": current_player,
		"hovered_point": hovered_point,
		"hovered_edge": hovered_edge,
		"points_count": points.size(),
		"paths_count": paths.size()
	}