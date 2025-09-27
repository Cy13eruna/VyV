extends Node

# Input handling system for V&V game
# Handles mouse clicks, keyboard input, and coordinates with GameManager

signal point_clicked(point_index: int)
signal fog_toggle_requested
signal movement_attempted(target_point: int)

# Game data references (set by main scene)
var points: Array = []
var paths: Array = []

# Current hover state
var hovered_point: int = -1
var hovered_edge: int = -1

# Initialize input system with game data
func initialize(game_points: Array, game_paths: Array) -> void:
	points = game_points
	paths = game_paths
	print("🎮 InputSystem initialized with %d points, %d paths" % [points.size(), paths.size()])

# Process mouse position for hover detection
func process_mouse_hover(mouse_pos: Vector2) -> Dictionary:
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
	
	# Return hover state changes
	return {
		"point_changed": old_hovered_point != hovered_point,
		"edge_changed": old_hovered_edge != hovered_edge,
		"hovered_point": hovered_point,
		"hovered_edge": hovered_edge
	}

# Handle input events
func handle_input_event(event: InputEvent) -> bool:
	var handled = false
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handled = _handle_mouse_click(event.global_position)
	elif event is InputEventKey and event.pressed:
		handled = _handle_key_press(event)
	
	return handled

# Handle mouse click events
func _handle_mouse_click(mouse_pos: Vector2) -> bool:
	# Check click on points
	for i in range(points.size()):
		if mouse_pos.distance_to(points[i]) < 20:
			print("🖱️ InputSystem: Point %d clicked" % i)
			point_clicked.emit(i)
			return true
	
	return false

# Handle keyboard events
func _handle_key_press(event: InputEventKey) -> bool:
	if event.keycode == KEY_SPACE:
		print("🖱️ InputSystem: SPACE pressed - requesting fog toggle")
		fog_toggle_requested.emit()
		return true
	
	return false

# Get current hover state
func get_hover_state() -> Dictionary:
	return {
		"hovered_point": hovered_point,
		"hovered_edge": hovered_edge
	}

# Utility function for line proximity detection
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

# Check if point can be clicked (for movement validation)
func can_click_point(point_index: int) -> bool:
	# Basic validation - point exists
	return point_index >= 0 and point_index < points.size()

# Get point at mouse position
func get_point_at_position(mouse_pos: Vector2) -> int:
	for i in range(points.size()):
		if mouse_pos.distance_to(points[i]) < 20:
			return i
	return -1

# Get path at mouse position
func get_path_at_position(mouse_pos: Vector2) -> int:
	for i in range(paths.size()):
		var path = paths[i]
		var path_points = path.points
		var p1 = points[path_points[0]]
		var p2 = points[path_points[1]]
		if _point_near_line(mouse_pos, p1, p2, 10):
			return i
	return -1