# 🚩 ACTION DIALOG SETTLEMENT
# Purpose: Settlement system for units (Settler technology)
# Layer: Presentation Manager - Dialog Settlement

extends RefCounted
class_name ActionDialogSettlement

# Import dependencies
# DialogConstants removed - now using GameDialogStrings
const GameDialogStrings = preload("res://presentation/constants/game_dialog_strings.gd")

# References
var main_node: Node2D
var dialog_manager
var unit_manager
var current_dialog = null

# Initialize with required references
func initialize(main_node_ref: Node2D, dialog_manager_ref, unit_manager_ref):
	main_node = main_node_ref
	dialog_manager = dialog_manager_ref
	unit_manager = unit_manager_ref

# Show settle confirmation UI
func show_settle_ui(unit, game_state: Dictionary):
	# Create dialog using centralized strings
	var dialog = GameDialogStrings.create_settlement_dialog(unit.name)
	
	# Hide default OK button
	dialog.get_ok_button().visible = false
	
	# Get the main container from the dialog (created by create_styled_dialog)
	var main_container = null
	for child in dialog.get_children():
		if child is VBoxContainer:
			main_container = child
			break
	
	# Create custom buttons
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", GameDialogStrings.BUTTON_SPACING)
	
	var settle_button = Button.new()
	settle_button.text = GameDialogStrings.SETTLEMENT_BUTTON
	settle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Apply black text styling
	GameDialogStrings.apply_button_style(settle_button)
	
	button_container.add_child(settle_button)
	
	# Add button container to main container (if found) or dialog directly
	if main_container:
		main_container.add_child(button_container)
	else:
		dialog.add_child(button_container)
	
	# Add to scene and track
	main_node.add_child(dialog)
	current_dialog = dialog
	dialog_manager.current_dialog = dialog
	
	# Center dialog with universal constants
	GameDialogStrings.center_dialog(dialog)
	
	# Focus settle button by default
	settle_button.grab_focus()
	
	# Connect signals
	settle_button.pressed.connect(_on_settle_confirmed.bind(dialog, unit))

# Handle settle confirmation
func _on_settle_confirmed(dialog, unit):
	_close_current_dialog(dialog)
	
	# Execute the establish domain action through unit manager
	if unit_manager.has_method("execute_settler_action"):
		unit_manager.execute_settler_action(unit)
	elif unit_manager.has_method("_execute_settler_action"):
		unit_manager._execute_settler_action(unit)

# Close current dialog and clean up
func _close_current_dialog(dialog):
	if dialog and is_instance_valid(dialog):
		# Use the enhanced dialog manager cleanup
		dialog_manager._force_cleanup_dialog(dialog)
	
	# Clear tracking immediately
	current_dialog = null
	if dialog_manager:
		dialog_manager.clear_current_dialog()

# Cleanup method
func cleanup():
	# Force close any existing dialog
	if current_dialog and is_instance_valid(current_dialog):
		_close_current_dialog(current_dialog)
	
	# Clear all references
	main_node = null
	dialog_manager = null
	unit_manager = null
	current_dialog = null