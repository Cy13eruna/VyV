# 🔧 INPUT DEBUG HANDLER
# Purpose: Handle debug keys, diagnostics, and emergency recovery
# Layer: Presentation Manager - Input Debug

extends RefCounted
class_name InputDebugHandler

# References
var main_node: Node2D
var ui_manager
var gameplay_manager
var parent_input_manager  # Reference to parent input manager for signal emission

# Debug tracking
var _dialog_related_failures: int = 0
var _last_dialog_cleanup_time: float = 0.0

# Initialize with required references
func initialize(main_node_ref: Node2D, ui_manager_ref, gameplay_manager_ref, parent_input_manager_ref):
	main_node = main_node_ref
	ui_manager = ui_manager_ref
	gameplay_manager = gameplay_manager_ref
	parent_input_manager = parent_input_manager_ref

# Handle debug keys
func handle_debug_keys(event: InputEventKey) -> bool:
	match event.keycode:
		KEY_F1:
			if ui_manager:
				ui_manager.call("toggle_debug_info")
			return true
		KEY_F2:
			if ui_manager:
				ui_manager.call("toggle_grid_stats")
			return true
		KEY_F6:
			if ui_manager:
				ui_manager.call("toggle_analytics_dashboard")
			return true
		KEY_F7:
			if ui_manager:
				ui_manager.call("toggle_debug_overlay")
			return true
		KEY_F8:
			if ui_manager:
				ui_manager.call("toggle_performance_graph")
			return true
		KEY_TAB:
			if ui_manager:
				ui_manager.call("handle_tab_navigation")
			return true
		KEY_ENTER:
			if ui_manager and ui_manager.get_property("in_turn_transition"):
				# Emit transition signal directly
				if ui_manager.has_signal("transition_started"):
					ui_manager.transition_started.emit()
			else:
				gameplay_manager.call("on_skip_turn")
			return true
		KEY_SPACE:
			# Emit fog toggle signal through parent input manager
			if parent_input_manager and parent_input_manager.has_signal("fog_toggle_requested"):
				parent_input_manager.emit_signal("fog_toggle_requested")
			return true
		KEY_F11:
			# Enhanced diagnostic key - print system status
			print_system_diagnostics()
			return true
		KEY_F12:
			# Emergency dialog cleanup key
			print("F12: Emergency dialog cleanup requested")
			emergency_dialog_cleanup()
			return true
		KEY_F9:
			# DEBUG: Force spawn a test unit
			print("F9: Force spawning test unit")
			debug_spawn_test_unit()
			return true
		KEY_F10:
			# DEBUG: List all units and their positions
			print("F10: Listing all units")
			debug_list_all_units()
			return true
	
	return false

# Print comprehensive system diagnostics
func print_system_diagnostics():
	var diag = get_diagnostic_info()
	print("=== ENHANCED INPUT SYSTEM DIAGNOSTIC ===")
	for key in diag:
		print(key, ": ", diag[key])
	
	# Also print dialog manager diagnostics if available
	if main_node and main_node.has_method("get_dialog_manager"):
		var dialog_manager = main_node.get_dialog_manager()
		if dialog_manager and dialog_manager.has_method("get_diagnostic_info"):
			var dialog_diag = dialog_manager.get_diagnostic_info()
			print("--- DIALOG MANAGER DIAGNOSTIC ---")
			for key in dialog_diag:
				print(key, ": ", dialog_diag[key])
	
	print("=========================================")

# Check for dialog-related input blockage
func check_dialog_input_blockage() -> bool:
	# Check if there are orphaned dialogs that might be blocking input
	if count_orphaned_dialogs() > 0:
		return true
	
	# Check if dialog manager is in an inconsistent state
	if has_dialog_manager():
		var dialog_manager = get_dialog_manager()
		if dialog_manager and dialog_manager.has_method("get_diagnostic_info"):
			var diag = dialog_manager.get_diagnostic_info()
			# Check for inconsistent dialog state
			if diag.get("current_dialog_exists", false) and not diag.get("current_dialog_in_tree", false):
				return true
			# Check for orphaned dialogs
			if diag.get("orphaned_dialogs_count", 0) > 0:
				return true
	
	return false

# Clean up dialog-related input blockage
func cleanup_dialog_blockage():
	print("Cleaning up dialog-related input blockage...")
	_last_dialog_cleanup_time = Time.get_time_dict_from_system()["second"]
	
	# Emergency cleanup of all dialogs
	emergency_dialog_cleanup()
	
	# Clear dialog manager state if available
	if has_dialog_manager():
		var dialog_manager = get_dialog_manager()
		if dialog_manager and dialog_manager.has_method("clear_current_dialog"):
			dialog_manager.clear_current_dialog()

# Emergency dialog cleanup with enhanced safety
func emergency_dialog_cleanup():
	print("EMERGENCY: Performing enhanced dialog cleanup")
	
	if not main_node:
		return
	
	# Find and remove all AcceptDialog children
	var dialogs_to_remove = []
	for child in main_node.get_children():
		if child is AcceptDialog:
			dialogs_to_remove.append(child)
	
	print("Found ", dialogs_to_remove.size(), " dialogs to clean up")
	
	# Remove all found dialogs with enhanced safety
	for dialog in dialogs_to_remove:
		print("Removing dialog: ", dialog)
		
		# CRITICAL: Disable ALL input processing FIRST
		if dialog.has_method("set_process_unhandled_input"):
			dialog.set_process_unhandled_input(false)
		if dialog.has_method("set_process_input"):
			dialog.set_process_input(false)
		if dialog.has_method("set_process_unhandled_key_input"):
			dialog.set_process_unhandled_key_input(false)
		if dialog.has_method("set_process_shortcut_input"):
			dialog.set_process_shortcut_input(false)
		
		# Disable mouse filter to prevent any mouse events
		if dialog.has_method("set_mouse_filter"):
			dialog.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		
		# Immediately hide the dialog
		dialog.visible = false
		
		# Use deferred removal to prevent "!is_inside_tree()" errors
		if dialog.get_parent():
			# Store parent reference to avoid issues with deferred calls
			var dialog_parent = dialog.get_parent()
			dialog_parent.call_deferred("remove_child", dialog)
			dialog.call_deferred("queue_free")
		else:
			dialog.call_deferred("queue_free")
	
	# Use deferred focus restoration to avoid timing issues
	main_node.call_deferred("_restore_focus_deferred")

# Count orphaned dialogs
func count_orphaned_dialogs() -> int:
	if not main_node:
		return 0
	
	var count = 0
	for child in main_node.get_children():
		if child is AcceptDialog:
			count += 1
	return count

# Check if dialog manager is available
func has_dialog_manager() -> bool:
	if not main_node:
		return false
	
	# Check if main_node has a dialog manager
	if main_node.has_method("get_dialog_manager"):
		return true
	
	# Check if gameplay_manager has a dialog manager
	if gameplay_manager and gameplay_manager.has_method("get_dialog_manager"):
		return true
	
	return false

# Get dialog manager reference
func get_dialog_manager():
	if not main_node:
		return null
	
	# Try main_node first
	if main_node.has_method("get_dialog_manager"):
		return main_node.get_dialog_manager()
	
	# Try gameplay_manager
	if gameplay_manager and gameplay_manager.has_method("get_dialog_manager"):
		return gameplay_manager.get_dialog_manager()
	
	return null

# DEBUG: Force spawn a test unit
func debug_spawn_test_unit():
	if not gameplay_manager:
		print("[DEBUG SPAWN] No gameplay_manager available")
		return
	
	var game_state = gameplay_manager.get_game_state()
	if game_state.is_empty():
		print("[DEBUG SPAWN] Game state is empty")
		return
	
	# Get current player
	var current_player = gameplay_manager.get_current_player()
	if not current_player:
		print("[DEBUG SPAWN] No current player")
		return
	
	print("[DEBUG SPAWN] Current player: ", current_player.id)
	
	# Find a random empty position
	var empty_positions = []
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		var position = point.position
		
		# Check if position is empty (no unit)
		var unit_at_pos = -1
		for unit_id in game_state.units:
			var unit = game_state.units[unit_id]
			if unit.position.equals(position):
				unit_at_pos = unit_id
				break
		
		if unit_at_pos == -1:
			empty_positions.append(position)
	
	if empty_positions.is_empty():
		print("[DEBUG SPAWN] No empty positions found")
		return
	
	# Pick a random empty position
	var spawn_position = empty_positions[randi() % empty_positions.size()]
	print("[DEBUG SPAWN] Spawning at position: ", spawn_position.hex_coord.get_string())
	
	# Get next unit ID
	var new_unit_id = 1
	while new_unit_id in game_state.units:
		new_unit_id += 1
	
	# Create test unit with proper natal domain name
	var test_unit_name = "TestUnit"  # Default fallback
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == current_player.id:
			var domain_initial = domain.get("initial", "")
			if domain_initial != "":
				# Use a name with the same initial as an existing domain
				var UnitNameGenerator = load("res://presentation/managers/unit/unit_name_generator.gd")
				var available_names = UnitNameGenerator.UNIT_NAMES.get(domain_initial, ["Test"])
				if available_names.size() > 0:
					test_unit_name = available_names[0] + "Test"  # Add "Test" suffix
				break
	
	var UnitClean = load("res://core/entities/unit_clean.gd")
	var test_unit = UnitClean.new(new_unit_id, current_player.id, test_unit_name, spawn_position)
	
	print("[DEBUG SPAWN] Test unit position after creation: ", test_unit.position.hex_coord.get_string())
	print("[DEBUG SPAWN] Test unit position q=", test_unit.position.hex_coord.q, " r=", test_unit.position.hex_coord.r)
	
	# Add to game state
	game_state.units[new_unit_id] = test_unit
	current_player.add_unit(new_unit_id)
	
	print("[DEBUG SPAWN] Created test unit ", new_unit_id, " at ", spawn_position.hex_coord.get_string())
	print("[DEBUG SPAWN] Total units in game: ", game_state.units.size())
	
	# Verify unit is in game state
	if new_unit_id in game_state.units:
		var stored_unit = game_state.units[new_unit_id]
		print("[DEBUG SPAWN] Verification: Unit stored at ", stored_unit.position.hex_coord.get_string())
	else:
		print("[DEBUG SPAWN] ERROR: Unit not found in game_state after adding!")
	
	# Force redraw
	main_node.queue_redraw()

# DEBUG: List all units and their positions
func debug_list_all_units():
	if not gameplay_manager:
		print("[DEBUG LIST] No gameplay_manager available")
		return
	
	var game_state = gameplay_manager.get_game_state()
	if game_state.is_empty():
		print("[DEBUG LIST] Game state is empty")
		return
	
	print("[DEBUG LIST] === ALL UNITS IN GAME ===")
	print("[DEBUG LIST] Total units: ", game_state.units.size())
	
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		print("[DEBUG LIST] Unit ", unit_id, " (", unit.name, ") - Player ", unit.owner_id)
		print("[DEBUG LIST]   Position: ", unit.position.hex_coord.get_string())
		print("[DEBUG LIST]   Coordinates: q=", unit.position.hex_coord.q, " r=", unit.position.hex_coord.r)
		print("[DEBUG LIST]   Actions: ", unit.actions_remaining)
		print("[DEBUG LIST]   ---")
	
	print("[DEBUG LIST] === END OF UNIT LIST ===")

# Get diagnostic info
func get_diagnostic_info() -> Dictionary:
	return {
		"dialog_related_failures": _dialog_related_failures,
		"last_dialog_cleanup_time": _last_dialog_cleanup_time,
		"main_node_exists": main_node != null,
		"ui_manager_exists": ui_manager != null,
		"gameplay_manager_exists": gameplay_manager != null,
		"orphaned_dialogs_count": count_orphaned_dialogs(),
		"dialog_manager_available": has_dialog_manager()
	}

# Cleanup method
func cleanup():
	main_node = null
	ui_manager = null
	gameplay_manager = null
	parent_input_manager = null
	
	# Reset counters
	_dialog_related_failures = 0
	_last_dialog_cleanup_time = 0.0