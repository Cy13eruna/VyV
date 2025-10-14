# 🎮 V&V CAMERA CONTROLLER
# Purpose: Handle camera movement, zoom, and transformations
# Layer: Presentation Controller

class_name CameraController
extends RefCounted

# Camera/Zoom state
var camera_offset: Vector2 = Vector2.ZERO
var zoom_level: float = 1.0

# Drag state
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_start_offset: Vector2 = Vector2.ZERO

# Reference to main node for queue_redraw
var main_node: Node2D

func set_main_node(main_node_ref: Node2D):
	main_node = main_node_ref

# Handle camera input (zoom and drag)
func handle_camera_input(event: InputEvent) -> bool:
	var handled = false
	
	# Handle mouse wheel for zoom
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					zoom_at_point(event.position, GameConstants.ZOOM_STEP)
					handled = true
				MOUSE_BUTTON_WHEEL_DOWN:
					zoom_at_point(event.position, -GameConstants.ZOOM_STEP)
					handled = true
				MOUSE_BUTTON_MIDDLE:
					# Start dragging with middle mouse button
					start_drag(event.position)
					handled = true
				MOUSE_BUTTON_RIGHT:
					# Alternative: right mouse button for drag
					start_drag(event.position)
					handled = true
		else:
			# Stop dragging when mouse button is released
			if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
				stop_drag()
				handled = true
	
	# Handle mouse motion for dragging
	elif event is InputEventMouseMotion:
		if is_dragging:
			update_drag(event.position)
			handled = true
	
	# Handle keyboard shortcuts for zoom
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_EQUAL, KEY_PLUS:  # + key for zoom in
				zoom_at_center(GameConstants.ZOOM_STEP)
				handled = true
			KEY_MINUS:  # - key for zoom out
				zoom_at_center(-GameConstants.ZOOM_STEP)
				handled = true
			KEY_0:  # 0 key to reset zoom and position
				reset_camera()
				handled = true
			KEY_HOME:  # Home key to center camera
				center_camera()
				handled = true
			# NOVO: Setas invertidas - direita vai para esquerda, cima vai para baixo, etc.
			KEY_LEFT:
				move_camera_with_arrow(Vector2(50, 0))  # Invertido: esquerda move para direita
				handled = true
			KEY_RIGHT:
				move_camera_with_arrow(Vector2(-50, 0))  # Invertido: direita move para esquerda
				handled = true
			KEY_UP:
				move_camera_with_arrow(Vector2(0, 50))  # Invertido: cima move para baixo
				handled = true
			KEY_DOWN:
				move_camera_with_arrow(Vector2(0, -50))  # Invertido: baixo move para cima
				handled = true
	
	return handled

# Zoom at a specific point (mouse position)
func zoom_at_point(mouse_pos: Vector2, zoom_delta: float):
	var old_zoom = zoom_level
	zoom_level = clamp(zoom_level + zoom_delta, GameConstants.MIN_ZOOM, GameConstants.MAX_ZOOM)
	
	if zoom_level != old_zoom:
		# Adjust camera offset to zoom towards mouse position
		var zoom_factor = zoom_level / old_zoom
		
		# Calculate offset adjustment to zoom towards mouse
		var mouse_offset = mouse_pos - GameConstants.SCREEN_CENTER
		camera_offset = (camera_offset + mouse_offset) * zoom_factor - mouse_offset
		
		main_node.queue_redraw()

# Zoom at screen center
func zoom_at_center(zoom_delta: float):
	var old_zoom = zoom_level
	zoom_level = clamp(zoom_level + zoom_delta, GameConstants.MIN_ZOOM, GameConstants.MAX_ZOOM)
	
	if zoom_level != old_zoom:
		main_node.queue_redraw()

# Start dragging
func start_drag(mouse_pos: Vector2):
	is_dragging = true
	drag_start_pos = mouse_pos
	drag_start_offset = camera_offset
	# Change cursor to indicate dragging
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)

# Update drag position
func update_drag(mouse_pos: Vector2):
	if is_dragging:
		var drag_delta = mouse_pos - drag_start_pos
		camera_offset = drag_start_offset + drag_delta / zoom_level
		main_node.queue_redraw()

# Stop dragging
func stop_drag():
	is_dragging = false
	# Reset cursor
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# Reset camera to default position and zoom
func reset_camera():
	camera_offset = Vector2.ZERO
	zoom_level = 1.0
	main_node.queue_redraw()

# Center camera on the map with auto-zoom based on player count
func center_camera(player_count: int = 0):
	# Ajustar offset para centralizar melhor o mapa (estava muito alto)
	camera_offset = Vector2(0, 30)  # Move o mapa um pouco para baixo
	
	# NOVO: Auto-zoom baseado no número de jogadores e tamanho do mapa
	if player_count > 0:
		zoom_level = GameConstants.get_optimal_zoom(player_count)
	
	main_node.queue_redraw()

# NOVO: Mover câmera com setas (como botão direito do mouse)
func move_camera_with_arrow(direction: Vector2):
	camera_offset += direction / zoom_level
	main_node.queue_redraw()

# Apply camera transformation (zoom and offset) to a position
func apply_camera_transform(pos: Vector2) -> Vector2:
	return (pos + camera_offset) * zoom_level + GameConstants.SCREEN_CENTER * (1.0 - zoom_level)

# Apply reverse camera transformation (for input)
func apply_reverse_camera_transform(screen_pos: Vector2) -> Vector2:
	return (screen_pos - GameConstants.SCREEN_CENTER * (1.0 - zoom_level)) / zoom_level - camera_offset

# Apply 30-degree rotation to all positions
func apply_board_rotation(pos: Vector2) -> Vector2:
	var angle = deg_to_rad(GameConstants.BOARD_ROTATION)
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	
	var relative_pos = pos - GameConstants.SCREEN_CENTER
	var rotated = Vector2(
		relative_pos.x * cos_a - relative_pos.y * sin_a,
		relative_pos.x * sin_a + relative_pos.y * cos_a
	)
	return rotated + GameConstants.SCREEN_CENTER

# Apply reverse rotation to convert screen clicks back to original coordinates
func apply_reverse_board_rotation(pos: Vector2) -> Vector2:
	var angle = deg_to_rad(-GameConstants.BOARD_ROTATION)  # Negative angle for reverse
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	
	var relative_pos = pos - GameConstants.SCREEN_CENTER
	var rotated = Vector2(
		relative_pos.x * cos_a - relative_pos.y * sin_a,
		relative_pos.x * sin_a + relative_pos.y * cos_a
	)
	return rotated + GameConstants.SCREEN_CENTER

# Apply both camera transform and board rotation
func apply_full_transform(pos: Vector2) -> Vector2:
	return apply_camera_transform(apply_board_rotation(pos))

# Apply reverse of both transformations (for input)
func apply_reverse_full_transform(screen_pos: Vector2) -> Vector2:
	return apply_reverse_board_rotation(apply_reverse_camera_transform(screen_pos))