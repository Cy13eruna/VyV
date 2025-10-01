# 🎮 INPUT MANAGER (CLEAN)
# Purpose: Centralized input handling and event distribution
# Layer: Infrastructure/Input
# Dependencies: Clean services for validation

extends RefCounted

# Preload clean services
const GridService = preload("res://application/services/grid_service_clean.gd")

# Signals for input events
signal point_clicked(point_id: int)
signal point_hovered(point_id: int)
signal point_unhovered(point_id: int)
signal unit_clicked(unit_id: int)
signal unit_hovered(unit_id: int)
signal unit_unhovered(unit_id: int)
signal fog_toggle_requested()
signal skip_turn_requested()
signal game_quit_requested()

# Input state
var mouse_position: Vector2 = Vector2.ZERO
var hovered_point_id: int = -1
var hovered_unit_id: int = -1
var click_tolerance: float = 20.0
var hover_tolerance: float = 25.0

# Handle input events
func handle_input_event(event: InputEvent, grid_data: Dictionary, units_data: Dictionary = {}) -> void:
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event, grid_data, units_data)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event, grid_data, units_data)
	elif event is InputEventKey:
		_handle_keyboard(event)

# Handle mouse motion for hover effects
func _handle_mouse_motion(event: InputEventMouseMotion, grid_data: Dictionary, units_data: Dictionary) -> void:
	mouse_position = event.position
	
	# Check for point hover
	var new_hovered_point = GridService.find_point_at_pixel(grid_data, mouse_position, hover_tolerance)
	
	if new_hovered_point != hovered_point_id:
		# Unhover previous point
		if hovered_point_id != -1:
			point_unhovered.emit(hovered_point_id)
		
		# Hover new point
		hovered_point_id = new_hovered_point
		if hovered_point_id != -1:
			point_hovered.emit(hovered_point_id)
	
	# Check for unit hover
	var new_hovered_unit = _find_unit_at_mouse(mouse_position, units_data)
	
	if new_hovered_unit != hovered_unit_id:
		# Unhover previous unit
		if hovered_unit_id != -1:
			unit_unhovered.emit(hovered_unit_id)
		
		# Hover new unit
		hovered_unit_id = new_hovered_unit
		if hovered_unit_id != -1:
			unit_hovered.emit(hovered_unit_id)

# Handle mouse button clicks
func _handle_mouse_button(event: InputEventMouseButton, grid_data: Dictionary, units_data: Dictionary) -> void:
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	var click_position = event.position
	
	# REMOVED: Unit click functionality - only point clicks allowed
	# Check for point click only
	var clicked_point = GridService.find_point_at_pixel(grid_data, click_position, click_tolerance)
	if clicked_point != -1:
		point_clicked.emit(clicked_point)

# Handle keyboard input
func _handle_keyboard(event: InputEventKey) -> void:
	if not event.pressed:
		return
	
	match event.keycode:
		KEY_SPACE:
			fog_toggle_requested.emit()
		KEY_ENTER:
			skip_turn_requested.emit()
		KEY_ESCAPE:
			game_quit_requested.emit()

# Find unit at mouse position
func _find_unit_at_mouse(mouse_pos: Vector2, units_data: Dictionary) -> int:
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if unit.is_mouse_over(mouse_pos, hover_tolerance):
			return unit_id
	return -1

# Get current hover state
func get_hover_state() -> Dictionary:
	return {
		"mouse_position": mouse_position,
		"hovered_point_id": hovered_point_id,
		"hovered_unit_id": hovered_unit_id,
		"has_point_hover": hovered_point_id != -1,
		"has_unit_hover": hovered_unit_id != -1
	}

# Set input tolerances
func set_tolerances(click_tol: float, hover_tol: float) -> void:
	click_tolerance = click_tol
	hover_tolerance = hover_tol

# Clear hover state
func clear_hover_state() -> void:
	if hovered_point_id != -1:
		point_unhovered.emit(hovered_point_id)
		hovered_point_id = -1
	
	if hovered_unit_id != -1:
		unit_unhovered.emit(hovered_unit_id)
		hovered_unit_id = -1

# Check if position is clickable
func is_position_clickable(position: Vector2, grid_data: Dictionary, units_data: Dictionary) -> Dictionary:
	var result = {
		"clickable": false,
		"type": "",
		"target_id": -1,
		"position": position
	}
	
	# REMOVED: Unit click checking - only points are clickable
	# Check for point only
	var point_id = GridService.find_point_at_pixel(grid_data, position, click_tolerance)
	if point_id != -1:
		result.clickable = true
		result.type = "point"
		result.target_id = point_id
		return result
	
	return result