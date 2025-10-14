# 🎮 DIALOG MANAGER - ENHANCED CLICKABILITY RECOVERY
# Purpose: Centralized dialog management and UI coordination
# Layer: Presentation Manager

extends RefCounted
class_name DialogManager

# Import centralized dialog strings
const GameDialogStrings = preload("res://presentation/constants/game_dialog_strings.gd")

# Global dialog cleanup registry to prevent multiple cleanup attempts
static var _cleanup_registry: Dictionary = {}
static var _cleanup_lock: bool = false

# References
var main_node: Node2D
var current_dialog = null  # Track current open dialog to prevent multiple

# Enhanced state tracking
var dialog_creation_time: float = 0.0
var dialog_cleanup_count: int = 0
var forced_cleanup_count: int = 0

# Check if there's already a dialog open with enhanced validation
func has_open_dialog() -> bool:
	# First, clean up any invalid dialogs
	_cleanup_invalid_dialogs()
	
	# Check our tracked dialog
	if current_dialog != null and is_instance_valid(current_dialog):
		# Verify it's still in the scene tree
		if current_dialog.get_parent() == null:
			# Dialog is orphaned, clear it
			current_dialog = null
			return false
		return true
	
	# Also check for any AcceptDialog children in the scene
	if main_node:
		for child in main_node.get_children():
			if child is AcceptDialog:
				# Found orphaned dialog, clean it up
				print("WARNING: Found orphaned dialog, cleaning up: ", child)
				_force_cleanup_dialog(child)
				return false
	
	# If we reach here, no dialogs are open
	current_dialog = null
	return false

# Show dialog explaining why unit cannot act
func show_unit_cannot_act_dialog(unit):
	# Check if there's already a dialog open
	if current_dialog != null:
		return
	
	var reason = ""
	if unit.actions_remaining <= 0:
		reason = GameDialogStrings.UNIT_CANNOT_ACT_NO_ACTIONS
	else:
		reason = GameDialogStrings.UNIT_CANNOT_ACT_UNKNOWN
	
	# Create dialog using centralized strings
	var dialog = GameDialogStrings.create_unit_cannot_act_dialog(reason)
	dialog.get_ok_button().text = GameDialogStrings.BUTTON_OK
	
	# Add to scene tree and show
	main_node.add_child(dialog)
	current_dialog = dialog  # Track current dialog
	GameDialogStrings.center_dialog(dialog)
	
	# Connect close signal
	dialog.confirmed.connect(_on_info_dialog_closed.bind(dialog))

# Show dialog explaining lack of power
func show_unit_no_power_dialog(unit, total_power: int):
	# Check if there's already a dialog open
	if current_dialog != null:
		return
	
	# Create dialog using centralized strings
	var dialog = GameDialogStrings.create_insufficient_power_dialog(total_power)
	dialog.get_ok_button().text = GameDialogStrings.BUTTON_OK
	
	# Add to scene tree and show
	main_node.add_child(dialog)
	current_dialog = dialog  # Track current dialog
	GameDialogStrings.center_dialog(dialog)
	
	# Connect close signal
	dialog.confirmed.connect(_on_info_dialog_closed.bind(dialog))

# Close info dialog with enhanced cleanup
func _on_info_dialog_closed(dialog):
	# Use enhanced cleanup
	if dialog and is_instance_valid(dialog):
		_force_cleanup_dialog(dialog)
	
	current_dialog = null  # Clear dialog tracking
	
	# Restore focus to main game
	_restore_game_focus()

# Enhanced dialog cleanup with registry-based prevention of multiple attempts
func clear_current_dialog():
	# Enhanced cleanup with registry-based prevention
	if current_dialog and is_instance_valid(current_dialog):
		_force_cleanup_dialog(current_dialog)
	
	current_dialog = null
	dialog_cleanup_count += 1

# Force cleanup of any dialog with global registry to prevent multiple cleanup attempts
func _force_cleanup_dialog(dialog):
	if not dialog or not is_instance_valid(dialog):
		return
	
	# Get unique dialog identifier
	var dialog_id = dialog.get_instance_id()
	
	# Check if dialog is already being cleaned up
	if dialog_id in _cleanup_registry:
		print("SKIP: Dialog already being cleaned up: ", dialog)
		return
	
	# Register dialog for cleanup to prevent multiple attempts
	_cleanup_registry[dialog_id] = true
	
	print("Force cleaning up dialog: ", dialog)
	
	# CRITICAL: Disable ALL input processing FIRST to prevent "!is_inside_tree()" errors
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
	
	# Disconnect signals safely AFTER disabling input processing
	_disconnect_custom_signals_safely(dialog)
	
	# SIMPLIFIED CLEANUP: Let Godot handle parent-child relationships automatically
	# Just queue the dialog for deletion - Godot will handle removing it from parent
	dialog.call_deferred("queue_free")
	
	# Clean up registry entry after a delay
	call_deferred("_cleanup_registry_entry", dialog_id)
	
	forced_cleanup_count += 1

# Clean up registry entry after dialog is freed
func _cleanup_registry_entry(dialog_id: int):
	if dialog_id in _cleanup_registry:
		_cleanup_registry.erase(dialog_id)

# Static function to clear the entire cleanup registry (emergency use)
static func clear_cleanup_registry():
	_cleanup_registry.clear()
	print("EMERGENCY: Cleared entire dialog cleanup registry")

# Safely disconnect only custom signals to avoid internal Godot signal errors
func _disconnect_custom_signals_safely(dialog):
	if not dialog or not is_instance_valid(dialog):
		return
	
	# GDScript doesn't have try/catch, so use safer approach
	# Only disconnect signals we know we connected
	if not dialog.has_signal("confirmed"):
		return
	
	# Get all connections for the confirmed signal safely
	var connections = dialog.get_signal_connection_list("confirmed")
	if connections == null:
		return
	
	# Only disconnect connections that are clearly ours
	for connection in connections:
		if connection == null:
			continue
		
		var callable_name = str(connection.get("callable", ""))
		# Look for our specific callback patterns
		if "_on_info_dialog_closed" in callable_name or "dialog_closed" in callable_name:
			# Check if still connected before disconnecting
			if dialog.is_connected("confirmed", connection["callable"]):
				dialog.disconnect("confirmed", connection["callable"])

# Legacy function - now redirects to safer custom signal disconnection
func _disconnect_custom_signals(dialog):
	_disconnect_custom_signals_safely(dialog)

# Legacy function - now redirects to safer custom signal disconnection
func _disconnect_all_dialog_signals(dialog):
	_disconnect_custom_signals(dialog)

# Clean up any invalid or orphaned dialogs with registry protection
func _cleanup_invalid_dialogs():
	if not main_node:
		return
	
	# Find and clean up any AcceptDialog children that shouldn't be there
	var dialogs_to_remove = []
	for child in main_node.get_children():
		if child is AcceptDialog:
			# Check if dialog is already being cleaned up
			var dialog_id = child.get_instance_id()
			if dialog_id in _cleanup_registry:
				continue  # Skip dialogs already being cleaned up
			
			# If we have a tracked dialog and this isn't it, it's orphaned
			if current_dialog != child:
				dialogs_to_remove.append(child)
			# If this is our tracked dialog but it's invalid, mark for removal
			elif not is_instance_valid(child):
				dialogs_to_remove.append(child)
	
	# Remove orphaned dialogs
	for dialog in dialogs_to_remove:
		print("Cleaning up orphaned dialog: ", dialog)
		_force_cleanup_dialog(dialog)

# Enhanced dialog creation with state tracking
func create_dialog_safely() -> AcceptDialog:
	# Ensure no existing dialogs
	if has_open_dialog():
		print("WARNING: Attempted to create dialog while one exists, cleaning up first")
		clear_current_dialog()
	
	# Create new dialog
	var dialog = AcceptDialog.new()
	current_dialog = dialog
	dialog_creation_time = Time.get_time_dict_from_system()["second"]
	
	return dialog

# Get diagnostic information including cleanup registry status
func get_diagnostic_info() -> Dictionary:
	return {
		"current_dialog_exists": current_dialog != null,
		"current_dialog_valid": current_dialog != null and is_instance_valid(current_dialog),
		"current_dialog_in_tree": current_dialog != null and is_instance_valid(current_dialog) and current_dialog.get_parent() != null,
		"dialog_creation_time": dialog_creation_time,
		"dialog_cleanup_count": dialog_cleanup_count,
		"forced_cleanup_count": forced_cleanup_count,
		"orphaned_dialogs_count": _count_orphaned_dialogs(),
		"cleanup_registry_size": _cleanup_registry.size(),
		"cleanup_registry_keys": _cleanup_registry.keys()
	}

# Count orphaned dialogs in the scene
func _count_orphaned_dialogs() -> int:
	if not main_node:
		return 0
	
	var count = 0
	for child in main_node.get_children():
		if child is AcceptDialog and child != current_dialog:
			count += 1
	return count

# Restore focus to the main game after dialog closes
func _restore_game_focus():
	if main_node:
		# Use deferred call to ensure dialog is fully removed first
		main_node.call_deferred("_restore_focus_deferred")

# Deferred focus restoration to avoid timing issues
func _restore_focus_deferred():
	if not main_node:
		return
	
	# Clear any remaining GUI focus
	var viewport = main_node.get_viewport()
	if viewport:
		viewport.gui_release_focus()
		# Ensure the viewport is focused
		if viewport.has_method("grab_focus"):
			viewport.grab_focus()
	
	# Force a redraw to refresh the UI state
	main_node.queue_redraw()
	
	# Additional safety: ensure input is properly restored
	if main_node.has_method("_check_manager_integrity"):
		main_node.call_deferred("_check_manager_integrity")