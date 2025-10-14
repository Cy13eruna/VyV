# 🎬 GAME SCENE MANAGER
# Purpose: Setup and manage game scene and managers
# Layer: Presentation - Game Coordination

extends RefCounted
class_name GameSceneManager

# Import all managers
const CameraManager = preload("res://presentation/managers/camera_manager.gd")
const RenderingManager = preload("res://presentation/managers/rendering_manager.gd")
const GameplayManager = preload("res://presentation/managers/gameplay_manager.gd")
const UIManager = preload("res://presentation/managers/ui_manager.gd")
const InputManager = preload("res://presentation/managers/input_manager.gd")
const UnitRenderer = preload("res://presentation/managers/unit_renderer.gd")

# References
var main_node: Node2D

# Managers
var camera_manager
var rendering_manager
var gameplay_manager
var ui_manager
var input_manager
var unit_renderer

# Initialize with main node reference
func initialize(main_node_ref: Node2D):
	main_node = main_node_ref

# Setup all managers
func setup_managers():
	# Create and setup all managers
	camera_manager = CameraManager.new()
	main_node.add_child(camera_manager)
	camera_manager.set("main_node", main_node)
	
	rendering_manager = RenderingManager.new()
	main_node.add_child(rendering_manager)
	# Note: rendering_manager will be properly initialized after gameplay_manager is ready
	
	gameplay_manager = GameplayManager.new()
	main_node.add_child(gameplay_manager)
	gameplay_manager.set_main_node(main_node)
	
	# Initialize rendering_manager after gameplay_manager is ready
	main_node.call_deferred("_setup_rendering_manager_deferred")
	
	ui_manager = UIManager.new()
	main_node.add_child(ui_manager)
	ui_manager.set_main_node(main_node)
	ui_manager.call("setup_ui")
	
	input_manager = InputManager.new()
	main_node.add_child(input_manager)
	input_manager.initialize(main_node, camera_manager, ui_manager, gameplay_manager)
	
	unit_renderer = UnitRenderer.new()
	main_node.add_child(unit_renderer)
	unit_renderer.set("main_node", main_node)
	unit_renderer.set("camera_manager", camera_manager)
	
	# Setup systems
	gameplay_manager.setup_game()

# Setup rendering_manager with proper initialization (called from main_node)
func setup_rendering_manager():
	if rendering_manager and gameplay_manager and gameplay_manager.unit_manager and camera_manager:
		print("[SCENE_MANAGER] Initializing rendering_manager...")
		rendering_manager.initialize(main_node, camera_manager, gameplay_manager.unit_manager)
		rendering_manager.load_terrain_textures()
		print("[SCENE_MANAGER] Rendering_manager initialized successfully")
	else:
		print("[SCENE_MANAGER] ERROR: Cannot initialize rendering_manager - missing dependencies")
		print("[SCENE_MANAGER] rendering_manager: ", rendering_manager != null)
		print("[SCENE_MANAGER] gameplay_manager: ", gameplay_manager != null)
		print("[SCENE_MANAGER] unit_manager: ", gameplay_manager.unit_manager if gameplay_manager else "N/A")
		print("[SCENE_MANAGER] camera_manager: ", camera_manager != null)

# Start periodic integrity check
func start_integrity_monitoring():
	var timer = Timer.new()
	timer.wait_time = 5.0  # Check every 5 seconds
	timer.timeout.connect(_check_manager_integrity)
	timer.autostart = true
	main_node.add_child(timer)

# Periodic check to ensure managers are still valid
func _check_manager_integrity():
	var issues = []
	var warnings = []
	
	# Check manager existence
	if not camera_manager:
		issues.append("camera_manager is null")
	if not rendering_manager:
		issues.append("rendering_manager is null")
	if not gameplay_manager:
		issues.append("gameplay_manager is null")
	if not ui_manager:
		issues.append("ui_manager is null")
	if not input_manager:
		issues.append("input_manager is null")
	if not unit_renderer:
		issues.append("unit_renderer is null")
	
	# Check input_manager's internal state
	if input_manager:
		if not input_manager.input_manager:
			issues.append("input_manager.input_manager is null")
		if not input_manager._input_manager_ref:
			warnings.append("input_manager._input_manager_ref is null")
	
	# Check gameplay_manager's internal state
	if gameplay_manager:
		var game_state = gameplay_manager.get_game_state()
		if game_state.is_empty():
			warnings.append("game_state is empty")
		else:
			if not ("grid" in game_state):
				issues.append("game_state missing grid")
			if not ("units" in game_state):
				issues.append("game_state missing units")
			if not ("players" in game_state):
				issues.append("game_state missing players")
	
	# Check if managers are still in scene tree
	if camera_manager and not camera_manager.get_parent():
		warnings.append("camera_manager not in scene tree")
	if input_manager and not input_manager.get_parent():
		warnings.append("input_manager not in scene tree")
	if gameplay_manager and not gameplay_manager.get_parent():
		warnings.append("gameplay_manager not in scene tree")
	
	# Report issues
	if issues.size() > 0:
		print("CRITICAL MANAGER INTEGRITY ISSUES: ", issues)
		# Attempt to recreate input system if that's the issue
		if input_manager and not input_manager.input_manager:
			print("Attempting to recreate input system...")
			input_manager.setup_input_system()
			if input_manager.input_manager:
				print("Input system recreation successful")
			else:
				print("Input system recreation FAILED - attempting full recreation")
				recreate_input_manager()
		
		# If we have critical issues, try full system recovery
		if issues.size() >= 3:
			print("CRITICAL: Multiple manager failures detected - attempting full system recovery")
			attempt_full_system_recovery()
	
	if warnings.size() > 0:
		print("MANAGER INTEGRITY WARNINGS: ", warnings)
	
	# Additional diagnostic info
	if issues.size() == 0 and warnings.size() == 0:
		# Only print this occasionally to avoid spam
		if randi() % 12 == 0:  # About every minute
			print("Manager integrity check: ALL SYSTEMS OPERATIONAL")

# Emergency input manager recreation
func recreate_input_manager():
	print("EMERGENCY: Recreating input manager from scratch")
	
	# Remove old input manager
	if input_manager:
		if input_manager.get_parent():
			main_node.remove_child(input_manager)
		input_manager.queue_free()
	
	# Create new input manager
	input_manager = InputManager.new()
	main_node.add_child(input_manager)
	input_manager.initialize(main_node, camera_manager, ui_manager, gameplay_manager)
	
	print("Input manager recreation complete")

# Full system recovery attempt
func attempt_full_system_recovery():
	print("CRITICAL RECOVERY: Attempting full system recovery")
	
	# This is a last resort - recreate all managers
	if not camera_manager:
		print("Recreating camera_manager")
		camera_manager = CameraManager.new()
		main_node.add_child(camera_manager)
		camera_manager.set("main_node", main_node)
	
	if not gameplay_manager:
		print("Recreating gameplay_manager")
		gameplay_manager = GameplayManager.new()
		main_node.add_child(gameplay_manager)
		gameplay_manager.set_main_node(main_node)
	
	if not ui_manager:
		print("Recreating ui_manager")
		ui_manager = UIManager.new()
		main_node.add_child(ui_manager)
		ui_manager.set_main_node(main_node)
		ui_manager.call("setup_ui")
	
	if not input_manager:
		recreate_input_manager()
	
	print("Full system recovery attempt complete")

# Check if all managers are initialized
func are_managers_ready() -> bool:
	return (camera_manager != null and 
			rendering_manager != null and 
			gameplay_manager != null and 
			ui_manager != null and 
			input_manager != null and 
			unit_renderer != null)

# Get manager references for external access
func get_camera_manager():
	return camera_manager

func get_rendering_manager():
	return rendering_manager

func get_gameplay_manager():
	return gameplay_manager

func get_ui_manager():
	return ui_manager

func get_input_manager():
	return input_manager

func get_unit_renderer():
	return unit_renderer

# Cleanup method
func cleanup():
	# Clear manager references
	camera_manager = null
	rendering_manager = null
	gameplay_manager = null
	ui_manager = null
	input_manager = null
	unit_renderer = null
	main_node = null