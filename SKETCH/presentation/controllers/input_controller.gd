# 🎮 V&V INPUT CONTROLLER
# Purpose: Handle all input events and coordinate with other systems
# Layer: Presentation Controller

class_name InputController
extends RefCounted

# Preload services
const TurnService = preload("res://application/services/turn_service_clean.gd")
const MovementService = preload("res://application/services/movement_service.gd")
const UnitMovementHandler = preload("res://application/use_cases/unit_movement_handler.gd")
const FogOfWarService = preload("res://application/services/fog_of_war_service.gd")
const SkipTurnUseCase = preload("res://application/use_cases/skip_turn_clean.gd")
const InputManager = preload("res://infrastructure/input/input_manager_clean.gd")

# References
var main_node: Node2D
var camera_controller: CameraController
var ui_manager
var game_controller

# Input manager
var input_manager

# Signals
signal point_clicked(point_id: int)
signal fog_toggle_requested()
signal skip_turn_requested()
signal quit_game_requested()

func set_references(main_node_ref: Node2D, camera_ref: CameraController):
	main_node = main_node_ref
	camera_controller = camera_ref

func set_controllers(ui_ref, game_ref):
	ui_manager = ui_ref
	game_controller = game_ref

func setup_input_system():
	input_manager = InputManager.new()
	
	# Connect input signals - ONLY point clicks allowed
	input_manager.point_clicked.connect(_on_point_clicked)
	input_manager.point_hovered.connect(_on_point_hovered)
	input_manager.point_unhovered.connect(_on_point_unhovered)
	input_manager.fog_toggle_requested.connect(_on_fog_toggle)
	input_manager.game_quit_requested.connect(_on_quit_game)
	
	# Set optimal input tolerances
	input_manager.set_tolerances(25.0, 30.0)  # click, hover

func handle_input(event: InputEvent, game_state: Dictionary) -> bool:
	var handled = false
	
	# Handle menu input first
	if ui_manager and ui_manager.in_menu:
		handled = ui_manager.handle_menu_input(event)
		if handled:
			return true
	
	# Handle camera controls
	if camera_controller:
		handled = camera_controller.handle_camera_input(event)
		if handled:
			return true
	
	if game_state.is_empty() or not input_manager:
		return false
	
	# Handle debug keys
	if event is InputEventKey and event.pressed:
		handled = _handle_debug_keys(event)
		if handled:
			return true
	
	# Use InputManager for game input with full transformation correction
	if event is InputEventMouseButton and event.pressed:
		# Skip if this is a camera control event
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			return false
		# Apply reverse transformation to mouse clicks
		var corrected_event = event.duplicate()
		corrected_event.position = camera_controller.apply_reverse_full_transform(event.position)
		input_manager.handle_input_event(corrected_event, game_state.grid, game_state.units)
		handled = true
	elif event is InputEventMouseMotion:
		# Skip if dragging
		if camera_controller.is_dragging:
			return false
		# Apply reverse transformation to mouse motion
		var corrected_event = event.duplicate()
		corrected_event.position = camera_controller.apply_reverse_full_transform(event.position)
		input_manager.handle_input_event(corrected_event, game_state.grid, game_state.units)
		handled = true
	else:
		# Other events (keyboard) don't need transformation correction
		input_manager.handle_input_event(event, game_state.grid, game_state.units)
		handled = true
	
	return handled

func _handle_debug_keys(event: InputEventKey) -> bool:
	match event.keycode:
		KEY_F1:
			if ui_manager:
				ui_manager.toggle_debug_info()
			return true
		KEY_F2:
			if ui_manager:
				ui_manager.toggle_grid_stats()
			return true
		KEY_F3:
			if game_controller:
				game_controller.save_game_state()
			return true
		KEY_F4:
			if game_controller:
				game_controller.load_game_state()
			return true
		KEY_F6:
			if ui_manager:
				ui_manager.toggle_analytics_dashboard()
			return true
		KEY_F7:
			if ui_manager:
				ui_manager.toggle_debug_overlay()
			return true
		KEY_F8:
			if ui_manager:
				ui_manager.toggle_performance_graph()
			return true
		KEY_TAB:
			if ui_manager:
				ui_manager.handle_tab_navigation()
			return true
		KEY_ENTER:
			# NOVO: ENTER inicia turno na tela START, pula turno no jogo
			if ui_manager and ui_manager.in_turn_transition:
				# Na tela START: ENTER inicia o turno
				ui_manager.on_transition_start()
			else:
				# No jogo: ENTER pula o turno
				skip_turn_requested.emit()
			return true
	
	return false

# Input event handlers
func _on_point_clicked(point_id: int):
	point_clicked.emit(point_id)

func _on_point_hovered(point_id: int):
	main_node.queue_redraw()

func _on_point_unhovered(point_id: int):
	main_node.queue_redraw()

func _on_fog_toggle():
	fog_toggle_requested.emit()

func _on_quit_game():
	quit_game_requested.emit()

func get_hover_state() -> Dictionary:
	if input_manager:
		return input_manager.get_hover_state()
	return {}