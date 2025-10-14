# 📡 GAME EVENT DISPATCHER
# Purpose: Distribute events between managers and handle signal connections
# Layer: Presentation - Game Coordination

extends RefCounted
class_name GameEventDispatcher

# References
var main_node: Node2D
var scene_manager

# Initialize with references
func initialize(main_node_ref: Node2D, scene_manager_ref):
	main_node = main_node_ref
	scene_manager = scene_manager_ref

# Setup all signal connections
func setup_connections():
	var ui_manager = scene_manager.get_ui_manager()
	var input_manager = scene_manager.get_input_manager()
	var gameplay_manager = scene_manager.get_gameplay_manager()
	
	# Check if managers are ready before connecting signals
	if not ui_manager or not input_manager or not gameplay_manager:
		return
	
	# Connect UI signals
	ui_manager.game_started.connect(_on_game_started)
	ui_manager.transition_started.connect(_on_transition_started)
	ui_manager.new_game_requested.connect(_on_new_game_requested)
	ui_manager.skip_turn_requested.connect(_on_skip_turn_requested)
	
	# Connect input signals
	input_manager.point_clicked.connect(_on_point_clicked)
	input_manager.fog_toggle_requested.connect(_on_fog_toggle)
	
	# Connect gameplay signals
	gameplay_manager.game_over_occurred.connect(_on_game_over)
	gameplay_manager.turn_advanced.connect(_on_turn_advanced)

# Handle unhandled input events
func handle_unhandled_input(event):
	var input_manager = scene_manager.get_input_manager()
	var gameplay_manager = scene_manager.get_gameplay_manager()
	
	if input_manager and gameplay_manager:
		var game_state = gameplay_manager.get_game_state()
		if game_state:
			input_manager.call("handle_input", event, game_state)
		else:
			input_manager.call("handle_input", event, {})

# Deferred focus restoration method called by dialog manager
func restore_focus_deferred():
	# This method is called by dialog manager after dialog cleanup
	# Ensure the main game has proper focus
	var viewport = main_node.get_viewport()
	if viewport:
		viewport.gui_release_focus()
	
	# Force a redraw to refresh the UI state
	main_node.queue_redraw()
	
	# Check manager integrity to ensure everything is working (with delay to avoid conflicts)
	var timer = Timer.new()
	timer.wait_time = 0.1  # Small delay to ensure cleanup is complete
	timer.one_shot = true
	timer.timeout.connect(scene_manager._check_manager_integrity)
	timer.timeout.connect(timer.queue_free)  # Clean up timer after use
	main_node.add_child(timer)
	timer.start()

# Signal handlers
func _on_game_started(player_count: int):
	var gameplay_manager = scene_manager.get_gameplay_manager()
	var input_manager = scene_manager.get_input_manager()
	var camera_manager = scene_manager.get_camera_manager()
	
	if not gameplay_manager or not input_manager or not camera_manager:
		return
	
	gameplay_manager.initialize_game_with_count(player_count)
	input_manager.call("setup_input_system")
	camera_manager.call("center_camera", player_count)
	main_node.queue_redraw()

func _on_transition_started():
	var camera_manager = scene_manager.get_camera_manager()
	var ui_manager = scene_manager.get_ui_manager()
	var gameplay_manager = scene_manager.get_gameplay_manager()
	
	if not camera_manager or not ui_manager or not gameplay_manager:
		return
	
	camera_manager.call("center_camera", ui_manager.get_property("selected_player_count"))
	ui_manager.call("hide_transition")
	var game_state = gameplay_manager.get_game_state()
	if game_state:
		ui_manager.call("update_skip_button_color", game_state)
	main_node.queue_redraw()

func _on_new_game_requested():
	var gameplay_manager = scene_manager.get_gameplay_manager()
	var ui_manager = scene_manager.get_ui_manager()
	
	if not gameplay_manager or not ui_manager:
		return
	
	print("[EVENT_DISPATCHER] New game requested - resetting game but keeping buttons visible")
	gameplay_manager.reset_game()
	# Don't call reset_to_menu() - that hides the buttons
	# Instead, just reset the menu state but keep buttons visible
	if ui_manager.menu_manager and ui_manager.menu_manager.has_method("reset_to_menu"):
		ui_manager.menu_manager.reset_to_menu()
	# Ensure buttons remain visible after reset
	if ui_manager.game_interface and ui_manager.game_interface.has_method("show_game_buttons"):
		ui_manager.game_interface.show_game_buttons()
	main_node.queue_redraw()

func _on_skip_turn_requested():
	var gameplay_manager = scene_manager.get_gameplay_manager()
	if gameplay_manager:
		gameplay_manager.on_skip_turn()

func _on_point_clicked(point_id: int):
	var gameplay_manager = scene_manager.get_gameplay_manager()
	if gameplay_manager:
		gameplay_manager.on_point_clicked(point_id)

func _on_fog_toggle():
	var gameplay_manager = scene_manager.get_gameplay_manager()
	if gameplay_manager:
		gameplay_manager.on_fog_toggle()

func _on_game_over(winner):
	var ui_manager = scene_manager.get_ui_manager()
	if not ui_manager:
		return
	
	var skip_button = ui_manager.get_property("skip_turn_button")
	if skip_button:
		skip_button.visible = false

func _on_turn_advanced():
	var ui_manager = scene_manager.get_ui_manager()
	var gameplay_manager = scene_manager.get_gameplay_manager()
	
	if not ui_manager or not gameplay_manager:
		return
	
	var game_state = gameplay_manager.get_game_state()
	if game_state:
		ui_manager.call("show_turn_transition", game_state)

# Cleanup method to prevent memory leaks
func cleanup():
	var ui_manager = scene_manager.get_ui_manager()
	var input_manager = scene_manager.get_input_manager()
	var gameplay_manager = scene_manager.get_gameplay_manager()
	
	# Disconnect all signals to prevent reference cycles
	if ui_manager:
		if ui_manager.is_connected("game_started", _on_game_started):
			ui_manager.disconnect("game_started", _on_game_started)
		if ui_manager.is_connected("transition_started", _on_transition_started):
			ui_manager.disconnect("transition_started", _on_transition_started)
		if ui_manager.is_connected("new_game_requested", _on_new_game_requested):
			ui_manager.disconnect("new_game_requested", _on_new_game_requested)
		if ui_manager.is_connected("skip_turn_requested", _on_skip_turn_requested):
			ui_manager.disconnect("skip_turn_requested", _on_skip_turn_requested)
	
	if input_manager:
		if input_manager.is_connected("point_clicked", _on_point_clicked):
			input_manager.disconnect("point_clicked", _on_point_clicked)
		if input_manager.is_connected("fog_toggle_requested", _on_fog_toggle):
			input_manager.disconnect("fog_toggle_requested", _on_fog_toggle)
	
	if gameplay_manager:
		if gameplay_manager.is_connected("game_over_occurred", _on_game_over):
			gameplay_manager.disconnect("game_over_occurred", _on_game_over)
		if gameplay_manager.is_connected("turn_advanced", _on_turn_advanced):
			gameplay_manager.disconnect("turn_advanced", _on_turn_advanced)
	
	# Clear references
	main_node = null
	scene_manager = null