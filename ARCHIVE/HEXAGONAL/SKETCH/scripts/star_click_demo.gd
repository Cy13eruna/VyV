## Star Click Demo - Sistema de Zoom de Duas Etapas Original
## Implementação restaurada baseada na sessão 20250922

extends Node2D

# Zoom system constants
const ZOOM_FACTOR: float = 1.3
const MIN_ZOOM: float = 0.3
const MAX_ZOOM: float = 5.0
const INVALID_STAR_ID: int = -1

# Zoom system state
var current_centered_star_id: int = INVALID_STAR_ID
var zoom_mode_active: bool = false

# References
@onready var hex_grid = get_parent().get_node("HexGrid")

func _ready() -> void:
	print("🎯 Star Click Demo inicializado - Sistema de Zoom de Duas Etapas")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed:
			match mouse_event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					_handle_zoom_in()
					get_viewport().set_input_as_handled()
				MOUSE_BUTTON_WHEEL_DOWN:
					_handle_zoom_out()
					get_viewport().set_input_as_handled()
				MOUSE_BUTTON_LEFT:
					_reset_zoom_mode()

## Handle zoom in with two-stage system
func _handle_zoom_in() -> void:
	_handle_zoom(true)

## Handle zoom out with two-stage system
func _handle_zoom_out() -> void:
	_handle_zoom(false)

## Unified zoom handler with two-stage system: center first, then zoom
func _handle_zoom(zoom_in: bool) -> void:
	# Validate system state
	if not _validate_zoom_system():
		return
	
	var camera = get_viewport().get_camera_2d()
	
	# Get nearest star under cursor
	var nearest_star_data = _get_nearest_star_under_cursor(camera)
	if nearest_star_data.star_id == INVALID_STAR_ID:
		print("⚠️ Zoom: No star found under cursor")
		return
	
	# Two-stage zoom system
	if _should_center_star(nearest_star_data.star_id):
		_center_star(camera, nearest_star_data)
	else:
		_apply_zoom(camera, nearest_star_data, zoom_in)

## Check if we should center the star (stage 1) or zoom (stage 2)
func _should_center_star(star_id: int) -> bool:
	return not zoom_mode_active or current_centered_star_id != star_id

## Stage 1: Center star without zooming
func _center_star(camera: Camera2D, star_data: Dictionary) -> void:
	current_centered_star_id = star_data.star_id
	zoom_mode_active = true
	
	# Center camera and cursor without zoom
	camera.global_position = star_data.world_pos
	get_viewport().warp_mouse(star_data.screen_center)
	
	print("⭐ Stage 1: Star %d centered (next scroll will zoom)" % star_data.star_id)

## Stage 2: Apply zoom while maintaining centering
func _apply_zoom(camera: Camera2D, star_data: Dictionary, zoom_in: bool) -> void:
	# Check zoom limits
	var current_zoom = camera.zoom.x
	if zoom_in and current_zoom >= MAX_ZOOM:
		print("🚫 Maximum zoom reached")
		return
	elif not zoom_in and current_zoom <= MIN_ZOOM:
		print("🚫 Minimum zoom reached")
		return
	
	# Apply zoom
	var old_zoom = current_zoom
	var zoom_factor = ZOOM_FACTOR if zoom_in else (1.0 / ZOOM_FACTOR)
	camera.zoom *= zoom_factor
	camera.zoom = camera.zoom.clamp(Vector2(MIN_ZOOM, MIN_ZOOM), Vector2(MAX_ZOOM, MAX_ZOOM))
	
	# Maintain centering
	camera.global_position = star_data.world_pos
	get_viewport().warp_mouse(star_data.screen_center)
	
	var zoom_direction = "IN" if zoom_in else "OUT"
	var zoom_icon = "🔍" if zoom_in else "🔎"
	print("%s Stage 2: ZOOM %s %.1fx→%.1fx (star %d centered)" % [zoom_icon, zoom_direction, old_zoom, camera.zoom.x, star_data.star_id])

## Get nearest star under cursor
func _get_nearest_star_under_cursor(camera: Camera2D) -> Dictionary:
	if not hex_grid:
		return {"star_id": INVALID_STAR_ID}
	
	var mouse_pos = get_global_mouse_position()
	var hex_grid_pos = hex_grid.to_local(mouse_pos)
	var dot_positions = hex_grid.get_dot_positions()
	
	var closest_star = INVALID_STAR_ID
	var closest_distance = 999999.0
	
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = hex_grid_pos.distance_to(star_pos)
		
		if distance < closest_distance:
			closest_distance = distance
			closest_star = i
	
	if closest_star == INVALID_STAR_ID:
		return {"star_id": INVALID_STAR_ID}
	
	var star_world_pos = hex_grid.to_global(dot_positions[closest_star])
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2
	
	return {
		"star_id": closest_star,
		"world_pos": star_world_pos,
		"screen_center": screen_center
	}

## Validate zoom system
func _validate_zoom_system() -> bool:
	if not hex_grid:
		print("❌ HexGrid not found")
		return false
	
	if not hex_grid.is_grid_ready():
		print("❌ HexGrid not ready")
		return false
	
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("❌ Camera not found")
		return false
	
	return true

## Reset zoom mode
func _reset_zoom_mode() -> void:
	zoom_mode_active = false
	current_centered_star_id = INVALID_STAR_ID
	print("🔄 Zoom mode reset")