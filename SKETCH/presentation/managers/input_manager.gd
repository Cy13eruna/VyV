# 🎮 V&V INPUT MANAGER (REFATORADO)
# Purpose: Coordenador principal para eventos de entrada
# Layer: Presentation Manager

extends Node
class_name InputManager

# Import modular components
const InputEventHandler = preload("res://presentation/managers/input/input_event_handler.gd")
const InputDebugHandler = preload("res://presentation/managers/input/input_debug_handler.gd")

# Import dependencies
const CameraManager = preload("res://presentation/managers/camera_manager.gd")
const UIManager = preload("res://presentation/managers/ui_manager.gd")
const GameplayManager = preload("res://presentation/managers/gameplay_manager.gd")

# References
var main_node: Node2D
var camera_manager: CameraManager
var ui_manager: UIManager
var gameplay_manager: GameplayManager

# Modular components
var event_handler: InputEventHandler
var debug_handler: InputDebugHandler

# Keep a strong reference to prevent garbage collection
var input_manager
var _input_manager_ref

# Signals
signal point_clicked(point_id: int)
signal fog_toggle_requested()

# Initialize with required references
func initialize(main_node_ref: Node2D, camera_manager_ref, ui_manager_ref, gameplay_manager_ref):
	main_node = main_node_ref
	camera_manager = camera_manager_ref
	ui_manager = ui_manager_ref
	gameplay_manager = gameplay_manager_ref
	
	print("[INPUT_MANAGER] Initializing modular components...")
	
	# Initialize modular components
	event_handler = InputEventHandler.new()
	event_handler.initialize(main_node, camera_manager, ui_manager, gameplay_manager, self)
	
	debug_handler = InputDebugHandler.new()
	debug_handler.initialize(main_node, ui_manager, gameplay_manager, self)
	
	print("[INPUT_MANAGER] Components initialized successfully")

# Setup input system (delegated to event handler)
func setup_input_system():
	if event_handler:
		event_handler.setup_input_system()
		# Keep references for compatibility
		input_manager = event_handler.input_manager
		_input_manager_ref = event_handler._input_manager_ref
	else:
		print("[INPUT_MANAGER] ERROR: Event handler not initialized")

# Handle input events (delegated to appropriate handlers)
func handle_input(event: InputEvent, game_state: Dictionary) -> bool:
	var handled = false
	
	# Check for dialog-related input blockage first
	if debug_handler and debug_handler.check_dialog_input_blockage():
		debug_handler._dialog_related_failures += 1
		print("WARNING: Dialog-related input blockage detected, attempting cleanup")
		debug_handler.cleanup_dialog_blockage()
		return false
	
	# Handle debug keys first
	if event is InputEventKey and event.pressed:
		if debug_handler:
			handled = debug_handler.handle_debug_keys(event)
			if handled:
				return true
	
	# Handle regular input events
	if event_handler:
		handled = event_handler.handle_input(event, game_state)
	
	return handled

# Get hover state (delegated to event handler)
func get_hover_state() -> Dictionary:
	if event_handler:
		return event_handler.get_hover_state()
	return {}

# Enhanced diagnostic function to check input system health
func get_diagnostic_info() -> Dictionary:
	var combined_diag = {}
	
	# Get diagnostics from both handlers
	if event_handler:
		var event_diag = event_handler.get_diagnostic_info()
		for key in event_diag:
			combined_diag["event_" + key] = event_diag[key]
	
	if debug_handler:
		var debug_diag = debug_handler.get_diagnostic_info()
		for key in debug_diag:
			combined_diag["debug_" + key] = debug_diag[key]
	
	# Add manager-level diagnostics
	combined_diag["in_scene_tree"] = get_parent() != null
	combined_diag["event_handler_exists"] = event_handler != null
	combined_diag["debug_handler_exists"] = debug_handler != null
	
	return combined_diag

# Emergency input system recreation (delegated to event handler)
func _complete_aggressive_recreation():
	if event_handler:
		event_handler.complete_aggressive_recreation()
		# Update references
		input_manager = event_handler.input_manager
		_input_manager_ref = event_handler._input_manager_ref

# Cleanup method to prevent memory leaks
func _exit_tree():
	# Cleanup all modules
	if event_handler:
		event_handler.cleanup()
		event_handler = null
	
	if debug_handler:
		debug_handler.cleanup()
		debug_handler = null
	
	# Clear all references
	input_manager = null
	_input_manager_ref = null
	main_node = null
	camera_manager = null
	ui_manager = null
	gameplay_manager = null