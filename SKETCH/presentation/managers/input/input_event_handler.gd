# 🎮 INPUT EVENT HANDLER
# Purpose: Handle input events and coordinate with game systems
# Layer: Presentation Manager - Input Events

extends RefCounted
class_name InputEventHandler

# Import dependencies
const InputManagerClean = preload("res://infrastructure/input/input_manager_clean.gd")

# References
var main_node: Node2D
var camera_manager
var ui_manager
var gameplay_manager
var parent_input_manager  # Reference to parent input manager for signal emission

# Input manager
var input_manager
var _input_manager_ref  # Keep strong reference

# Event tracking
var _click_count: int = 0
var _last_click_time: float = 0.0
var _input_failures: int = 0

# Initialize with required references
func initialize(main_node_ref: Node2D, camera_manager_ref, ui_manager_ref, gameplay_manager_ref, parent_input_manager_ref):
	main_node = main_node_ref
	camera_manager = camera_manager_ref
	ui_manager = ui_manager_ref
	gameplay_manager = gameplay_manager_ref
	parent_input_manager = parent_input_manager_ref

# Setup input system
func setup_input_system():
	print("Setting up input system...")
	
	# Clean up existing input manager if it exists
	if input_manager:
		# Disconnect existing signals
		if input_manager.is_connected("point_clicked", _on_point_clicked):
			input_manager.disconnect("point_clicked", _on_point_clicked)
		if input_manager.is_connected("point_hovered", _on_point_hovered):
			input_manager.disconnect("point_hovered", _on_point_hovered)
		if input_manager.is_connected("point_unhovered", _on_point_unhovered):
			input_manager.disconnect("point_unhovered", _on_point_unhovered)
		if input_manager.is_connected("fog_toggle_requested", _on_fog_toggle):
			input_manager.disconnect("fog_toggle_requested", _on_fog_toggle)
		if input_manager.is_connected("game_quit_requested", _on_quit_game):
			input_manager.disconnect("game_quit_requested", _on_quit_game)
	
	input_manager = InputManagerClean.new()
	_input_manager_ref = input_manager  # Keep strong reference
	
	if not input_manager:
		print("CRITICAL: Failed to create InputManagerClean instance")
		return
	
	input_manager.point_clicked.connect(_on_point_clicked)
	input_manager.point_hovered.connect(_on_point_hovered)
	input_manager.point_unhovered.connect(_on_point_unhovered)
	input_manager.empty_area_clicked.connect(_on_empty_area_clicked)
	input_manager.fog_toggle_requested.connect(_on_fog_toggle)
	input_manager.game_quit_requested.connect(_on_quit_game)
	
	input_manager.set_tolerances(25.0, 30.0)
	print("Input system setup complete. InputManager valid: ", input_manager != null)

# Handle input events
func handle_input(event: InputEvent, game_state: Dictionary) -> bool:
	var handled = false
	
	# Enhanced input system integrity checking
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click_count += 1
		_last_click_time = Time.get_time_dict_from_system()["second"]
		
		if not input_manager:
			_input_failures += 1
			print("ERROR: input_manager is null! Click #", _click_count, " Failures: ", _input_failures)
			# Attempt immediate recreation
			recreate_input_system_safely()
			if not input_manager:
				print("CRITICAL: Failed to recreate input_manager after safe recreation")
				return false
			else:
				print("SUCCESS: Input manager recreated successfully")
	
	# Handle menu input first
	if ui_manager and ui_manager.get_property("in_menu"):
		# Call menu input handling asynchronously
		ui_manager.call("handle_menu_input", event)
		return true  # Always return true for menu input
	
	# Handle camera controls
	if camera_manager:
		handled = camera_manager.call("handle_camera_input", event)
		if handled:
			return true
	
	if game_state.is_empty():
		return false
	
	if not input_manager:
		_input_failures += 1
		print("WARNING: input_manager is null during game input. Failures: ", _input_failures)
		# Attempt immediate recovery
		recreate_input_system_safely()
		if not input_manager:
			print("CRITICAL: Failed to recreate input_manager during game input")
			return false
	
	# Use InputManager for game input with full transformation correction
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			return false
		var corrected_event = event.duplicate()
		corrected_event.position = camera_manager.call("apply_reverse_full_transform", event.position)
		input_manager.call("handle_input_event", corrected_event, game_state.grid, game_state.units)
		handled = true
	elif event is InputEventMouseMotion:
		if camera_manager.get("is_dragging"):
			return false
		var corrected_event = event.duplicate()
		corrected_event.position = camera_manager.call("apply_reverse_full_transform", event.position)
		input_manager.call("handle_input_event", corrected_event, game_state.grid, game_state.units)
		handled = true
	else:
		input_manager.call("handle_input_event", event, game_state.grid, game_state.units)
		handled = true
	
	return handled

# Handle attack target clicks
func handle_attack_target_click(point_id: int) -> bool:
	if not gameplay_manager:
		return false
	
	var game_state = gameplay_manager.get_game_state()
	if game_state.is_empty():
		return false
	
	# Get the position of the clicked point
	if not ("grid" in game_state) or point_id not in game_state.grid.points:
		return false
	
	var clicked_position = game_state.grid.points[point_id].position
	
	# Debug: Check if there's a unit at this position
	var unit_at_position = null
	if "units" in game_state:
		for unit_id in game_state.units:
			var unit = game_state.units[unit_id]
			if unit.position.equals(clicked_position):
				unit_at_position = unit
				break
	
	print("[ATTACK_CLICK] Clicked point ", point_id, ", unit at position: ", unit_at_position.name if unit_at_position else "none")
	
	# Check if action dialog manager can handle this attack target click
	var action_dialog_manager = get_action_dialog_manager()
	
	print("[ATTACK_CLICK] Action dialog manager found: ", action_dialog_manager != null)
	
	if action_dialog_manager and action_dialog_manager.has_method("handle_attack_target_click"):
		var handled = action_dialog_manager.handle_attack_target_click(clicked_position, game_state)
		print("[ATTACK_CLICK] Attack handled: ", handled)
		if handled:
			return handled
	
	# Try heal target click
	if action_dialog_manager and action_dialog_manager.has_method("handle_heal_target_click"):
		var heal_handled = action_dialog_manager.handle_heal_target_click(clicked_position, game_state)
		print("[HEAL_CLICK] Heal handled: ", heal_handled)
		return heal_handled
	
	return false

# Get action dialog manager from various sources
func get_action_dialog_manager():
	var action_dialog_manager = null
	
	# Try through unit_manager (where action_dialog_manager is located)
	if gameplay_manager.has_method("unit_manager") or "unit_manager" in gameplay_manager:
		var unit_manager = gameplay_manager.unit_manager
		if unit_manager:
			if unit_manager.has_method("get_action_dialog_manager"):
				action_dialog_manager = unit_manager.get_action_dialog_manager()
			elif "action_dialog_manager" in unit_manager:
				action_dialog_manager = unit_manager.action_dialog_manager
	
	# Try through gameplay_manager directly
	if not action_dialog_manager:
		if gameplay_manager.has_method("get_action_dialog_manager"):
			action_dialog_manager = gameplay_manager.get_action_dialog_manager()
		elif "action_dialog_manager" in gameplay_manager:
			action_dialog_manager = gameplay_manager.action_dialog_manager
	
	# Try through main_node if nothing else works
	if not action_dialog_manager and main_node:
		if main_node.has_method("get_action_dialog_manager"):
			action_dialog_manager = main_node.get_action_dialog_manager()
		elif "action_dialog_manager" in main_node:
			action_dialog_manager = main_node.action_dialog_manager
	
	return action_dialog_manager

# Close any open dialogs when clicking outside them
func _close_open_dialogs() -> bool:
	var dialog_closed = false
	
	# Try to get dialog manager from various sources
	var dialog_manager = _get_dialog_manager()
	if dialog_manager and dialog_manager.has_method("has_open_dialog"):
		if dialog_manager.has_open_dialog():
			print("[DIALOG_CLOSE] Found open dialog, closing it")
			if dialog_manager.has_method("clear_current_dialog"):
				dialog_manager.clear_current_dialog()
				dialog_closed = true
	
	# Also check for any AcceptDialog children in main_node
	if main_node:
		for child in main_node.get_children():
			if child is AcceptDialog and child.visible:
				print("[DIALOG_CLOSE] Found visible AcceptDialog, closing it")
				child.hide()
				child.queue_free()
				dialog_closed = true
	
	return dialog_closed

# Get dialog manager from various sources
func _get_dialog_manager():
	var dialog_manager = null
	
	# Try through gameplay_manager
	if gameplay_manager:
		if gameplay_manager.has_method("get_dialog_manager"):
			dialog_manager = gameplay_manager.get_dialog_manager()
		elif "dialog_manager" in gameplay_manager:
			dialog_manager = gameplay_manager.dialog_manager
	
	# Try through main_node
	if not dialog_manager and main_node:
		if main_node.has_method("get_dialog_manager"):
			dialog_manager = main_node.get_dialog_manager()
		elif "dialog_manager" in main_node:
			dialog_manager = main_node.dialog_manager
	
	return dialog_manager

# Enhanced safe input system recreation
func recreate_input_system_safely():
	print("SAFE RECREATION: Recreating input system with enhanced safety")
	
	# First, try the standard setup
	setup_input_system()
	
	# If that failed, try more aggressive recreation
	if not input_manager:
		print("Standard setup failed, attempting aggressive recreation")
		
		# Clear all references
		input_manager = null
		_input_manager_ref = null
		
		# Use deferred call instead of await to avoid blocking
		main_node.call_deferred("_complete_aggressive_recreation")
	else:
		print("Standard recreation successful")

# Complete the aggressive recreation in a deferred call
func complete_aggressive_recreation():
	print("Completing aggressive input system recreation")
	
	# Try creating again
	input_manager = InputManagerClean.new()
	_input_manager_ref = input_manager
	
	if input_manager:
		# Reconnect signals
		input_manager.point_clicked.connect(_on_point_clicked)
		input_manager.point_hovered.connect(_on_point_hovered)
		input_manager.point_unhovered.connect(_on_point_unhovered)
		input_manager.empty_area_clicked.connect(_on_empty_area_clicked)
		input_manager.fog_toggle_requested.connect(_on_fog_toggle)
		input_manager.game_quit_requested.connect(_on_quit_game)
		input_manager.set_tolerances(25.0, 30.0)
		print("Aggressive recreation successful")
	else:
		print("CRITICAL: Aggressive recreation also failed")

# Input event handlers
func _on_point_clicked(point_id: int):
	# First, check if there are any open dialogs and close them
	if _close_open_dialogs():
		print("[POINT_CLICK] Closed open dialog, ignoring point click")
		return  # Don't process point click if we closed a dialog
	
	# Check if this is an attack target click first
	if handle_attack_target_click(point_id):
		return
	
	# Emit signal through parent input manager
	if parent_input_manager and parent_input_manager.has_signal("point_clicked"):
		parent_input_manager.emit_signal("point_clicked", point_id)

func _on_point_hovered(point_id: int):
	main_node.queue_redraw()

func _on_point_unhovered(point_id: int):
	main_node.queue_redraw()

# Handle clicks on empty areas (for cancellation)
func _on_empty_area_clicked(position: Vector2):
	print("[EMPTY_AREA_CLICK] Clicked on empty area at: ", position)
	
	# First, check if there are any open dialogs and close them
	if _close_open_dialogs():
		print("[EMPTY_AREA_CLICK] Closed open dialog")
		return  # Don't process other actions if we closed a dialog
	
	# Cancel any active selections/actions
	if gameplay_manager:
		var game_state = gameplay_manager.get_game_state()
		if not game_state.is_empty():
			# Clear unit selections
			gameplay_manager.clear_selections()
			
			# Cancel any active attack/heal actions
			var action_dialog_manager = get_action_dialog_manager()
			if action_dialog_manager and action_dialog_manager.has_method("cancel_active_actions"):
				action_dialog_manager.cancel_active_actions()
			
			main_node.queue_redraw()

func _on_fog_toggle():
	# Emit signal through parent input manager
	if parent_input_manager and parent_input_manager.has_signal("fog_toggle_requested"):
		parent_input_manager.emit_signal("fog_toggle_requested")

func _on_quit_game():
	main_node.get_tree().quit()

# Get hover state
func get_hover_state() -> Dictionary:
	if input_manager:
		return input_manager.call("get_hover_state")
	return {}

# Get diagnostic info
func get_diagnostic_info() -> Dictionary:
	return {
		"click_count": _click_count,
		"last_click_time": _last_click_time,
		"input_failures": _input_failures,
		"input_manager_exists": input_manager != null,
		"input_manager_ref_exists": _input_manager_ref != null
	}

# Cleanup method
func cleanup():
	# Disconnect all signals
	if input_manager:
		if input_manager.is_connected("point_clicked", _on_point_clicked):
			input_manager.disconnect("point_clicked", _on_point_clicked)
		if input_manager.is_connected("point_hovered", _on_point_hovered):
			input_manager.disconnect("point_hovered", _on_point_hovered)
		if input_manager.is_connected("point_unhovered", _on_point_unhovered):
			input_manager.disconnect("point_unhovered", _on_point_unhovered)
		if input_manager.is_connected("fog_toggle_requested", _on_fog_toggle):
			input_manager.disconnect("fog_toggle_requested", _on_fog_toggle)
		if input_manager.is_connected("game_quit_requested", _on_quit_game):
			input_manager.disconnect("game_quit_requested", _on_quit_game)
	
	# Clear references
	input_manager = null
	_input_manager_ref = null
	main_node = null
	camera_manager = null
	ui_manager = null
	gameplay_manager = null
	parent_input_manager = null
	
	# Reset counters
	_click_count = 0
	_last_click_time = 0.0
	_input_failures = 0