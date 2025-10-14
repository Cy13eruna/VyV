# 🎯 ACTION DIALOG CORE
# Purpose: Core dialog creation and management logic
# Layer: Presentation Manager - Dialog Core

extends RefCounted
class_name ActionDialogCore

# Import dependencies
const MovementService = preload("res://application/services/movement_service.gd")
# DialogConstants removed - now using GameDialogStrings
const GameDialogStrings = preload("res://presentation/constants/game_dialog_strings.gd")

# References
var main_node: Node2D
var dialog_manager
var unit_manager
var validation_module
var training_module
var settlement_module
var current_dialog = null
var current_unit = null
var selected_action = ""

# Initialize with required references
func initialize(main_node_ref: Node2D, dialog_manager_ref, unit_manager_ref, validation_module_ref, training_module_ref = null, settlement_module_ref = null):
	main_node = main_node_ref
	dialog_manager = dialog_manager_ref
	unit_manager = unit_manager_ref
	validation_module = validation_module_ref
	training_module = training_module_ref
	settlement_module = settlement_module_ref

# Show action selection dialog (multiple actions available)
func show_action_selection_dialog(unit, available_actions: Array, game_state: Dictionary):
	# Create dialog using centralized strings
	var dialog = GameDialogStrings.create_action_selection_dialog(unit.name)
	
	# Hide default OK button
	dialog.get_ok_button().visible = false
	
	# Get the main container from the dialog (created by create_styled_dialog)
	var main_container = null
	for child in dialog.get_children():
		if child is VBoxContainer:
			main_container = child
			break
	
	# Create action buttons
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", GameDialogStrings.BUTTON_SPACING)
	for action in available_actions:
		# Create action button
		var action_button = Button.new()
		action_button.text = _get_action_display_name(action)
		action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Apply black text styling
		GameDialogStrings.apply_button_style(action_button)
		action_button.pressed.connect(_on_action_selected.bind(dialog, action, unit, game_state))
		button_container.add_child(action_button)
	
	# Add button container to main container (if found) or dialog directly
	if main_container:
		main_container.add_child(button_container)
	else:
		dialog.add_child(button_container)
	
	# Add to scene and track
	main_node.add_child(dialog)
	dialog_manager.current_dialog = dialog
	current_dialog = dialog
	
	# Center dialog with universal constants
	GameDialogStrings.center_dialog(dialog)
	
	# Focus first action button
	if button_container.get_child_count() > 0:
		button_container.get_child(0).grab_focus()

# Handle action selection from dialog
func _on_action_selected(dialog, action: String, unit, game_state: Dictionary):
	selected_action = action
	current_unit = unit
	_close_current_dialog(dialog)
	show_action_specific_ui(action, unit, game_state)

# Show UI specific to the selected action
func show_action_specific_ui(action: String, unit, game_state: Dictionary):
	match action:
		"MOVE":
			_show_movement_ui(unit, game_state)
		"ATTACK":
			_show_attack_ui(unit, game_state)
		"HEAL":
			_show_heal_ui(unit, game_state)
		"TRAIN":
			_show_training_ui(unit, game_state)
		"SETTLE":
			_show_settle_ui(unit, game_state)
		_:
			print("Unknown action: ", action)

# Show movement UI (existing movement system)
func _show_movement_ui(unit, game_state: Dictionary):
	print("[ACTION_DIALOG] _show_movement_ui called for unit: ", unit.name)
	
	# FIXED: Don't call _set_unit_selection_for_movement as it causes recursion
	# Instead, directly set up movement targets without triggering selection again
	if unit_manager and unit_manager.selection_manager:
		# Set the unit as selected (it already is, but ensure consistency)
		if unit_manager.selection_manager.has_method("_set_movement_targets_only"):
			unit_manager.selection_manager._set_movement_targets_only(unit.id, game_state)
		else:
			# Fallback: access selection_core directly
			if unit_manager.selection_manager.selection_core:
				unit_manager.selection_manager.selection_core.selected_unit_id = unit.id
				unit_manager.selection_manager.selection_core.valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units, game_state)
				main_node.queue_redraw()
	
	# Clear current action state
	clear_action_state()

# Show training UI
func _show_training_ui(unit, game_state: Dictionary):
	print("[ACTION_DIALOG] _show_training_ui called for unit: ", unit.name)
	
	if training_module and training_module.has_method("show_training_dialog"):
		training_module.show_training_dialog(unit, game_state)
	else:
		print("[ACTION_DIALOG] ERROR: training_module not available")
	
	# Clear current action state
	clear_action_state()

# Show settlement UI
func _show_settle_ui(unit, game_state: Dictionary):
	print("[ACTION_DIALOG] _show_settle_ui called for unit: ", unit.name)
	
	if settlement_module and settlement_module.has_method("show_settle_ui"):
		settlement_module.show_settle_ui(unit, game_state)
	else:
		print("[ACTION_DIALOG] ERROR: settlement_module not available")
	
	# Clear current action state
	clear_action_state()

# Show attack UI with visual target indicators
func _show_attack_ui(unit, game_state: Dictionary):
	# Use the new attack targeting system
	var valid_attack_targets = MovementService.get_valid_attack_targets(unit, game_state.grid, game_state.units, game_state)
	
	if valid_attack_targets.is_empty():
		clear_action_state()
		return
	
	# Set up attack targeting mode (similar to movement)
	current_unit = unit
	selected_action = "ATTACK"
	
	# Store valid attack targets for rendering using API
	if unit_manager and unit_manager.selection_manager:
		# Use the public API instead of direct access
		if unit_manager.selection_manager.has_method("_set_attack_targets"):
			unit_manager.selection_manager._set_attack_targets(unit.id, valid_attack_targets)
		else:
			# Fallback: try to access selection_core directly
			if unit_manager.selection_manager.selection_core:
				unit_manager.selection_manager.selection_core.selected_unit_id = unit.id
				unit_manager.selection_manager.selection_core.valid_attack_targets = valid_attack_targets
		# Emit signal to trigger visual update
		unit_manager.unit_selected.emit(unit.id)
	main_node.queue_redraw()
	
	# Clear dialog state since we're using visual targeting
	current_dialog = null

# Show heal UI with visual target indicators
func _show_heal_ui(unit, game_state: Dictionary):
	print("[HEAL] Showing heal UI for unit: ", unit.name)
	
	# Get valid heal targets (injured units in range + self if injured)
	var valid_heal_targets = _get_valid_heal_targets(unit, game_state)
	
	if valid_heal_targets.is_empty():
		print("[HEAL] No valid heal targets")
		clear_action_state()
		return
	
	# Set up heal targeting mode (similar to attack)
	current_unit = unit
	selected_action = "HEAL"
	
	# Store valid heal targets for rendering using API
	if unit_manager and unit_manager.selection_manager:
		# Use the public API instead of direct access
		if unit_manager.selection_manager.has_method("_set_heal_targets"):
			unit_manager.selection_manager._set_heal_targets(unit.id, valid_heal_targets)
		else:
			# Fallback: try to access selection_core directly
			if unit_manager.selection_manager.selection_core:
				unit_manager.selection_manager.selection_core.selected_unit_id = unit.id
				unit_manager.selection_manager.selection_core.valid_heal_targets = valid_heal_targets
		# Emit signal to trigger visual update
		unit_manager.unit_selected.emit(unit.id)
	main_node.queue_redraw()
	
	# Clear dialog state since we're using visual targeting
	current_dialog = null

# Get valid heal targets for a healer unit
func _get_valid_heal_targets(unit, game_state: Dictionary) -> Array:
	var heal_targets = []
	print("[HEAL_DEBUG] Getting heal targets for unit: ", unit.name, " (owner: ", unit.owner_id, ")")
	
	# Can heal self if injured
	if unit.is_injured():
		heal_targets.append(unit.position)
		print("[HEAL_DEBUG] Added self as heal target (injured)")
	
	# Get adjacent positions for heal targets
	var adjacent_positions = validation_module.get_adjacent_positions(unit.position, game_state)
	print("[HEAL_DEBUG] Found ", adjacent_positions.size(), " adjacent positions")
	
	# Check each adjacent position for injured units
	for pos in adjacent_positions:
		var target_unit = validation_module.get_unit_at_position(pos, game_state.units)
		print("[HEAL_DEBUG] Checking position ", pos, " - unit: ", target_unit.name if target_unit else "none")
		if target_unit:
			print("[HEAL_DEBUG] Unit ", target_unit.name, " (owner: ", target_unit.owner_id, ", health: ", target_unit.health, ", injured: ", target_unit.is_injured(), ")")
		if target_unit and target_unit.is_injured():
			print("[HEAL_DEBUG] Unit is injured, checking terrain...")
			# Check if path to target crosses blocking terrain
			if validation_module.can_heal_without_crossing_blocking_terrain(unit.position, pos, game_state):
				print("[HEAL_DEBUG] No blocking terrain, adding as heal target")
				# Allow healing any injured unit (including enemies) - no visibility restriction
				heal_targets.append(pos)
			else:
				print("[HEAL_DEBUG] Blocked by terrain")
		else:
			if target_unit:
				print("[HEAL_DEBUG] Unit not injured (health: ", target_unit.health, ")")
			else:
				print("[HEAL_DEBUG] No unit at position")
	
	print("[HEAL_DEBUG] Total heal targets found: ", heal_targets.size())
	return heal_targets

# Handle attack target click (called from input manager)
func handle_attack_target_click(clicked_position, game_state: Dictionary):
	print("[ACTION_DIALOG] handle_attack_target_click called")
	
	if selected_action != "ATTACK" or not current_unit:
		return false
	
	# Check if clicked position is a valid attack target
	if not unit_manager or not unit_manager.selection_manager:
		return false
	
	var valid_attack_targets = unit_manager.selection_manager.get_valid_attack_targets()
	
	var is_valid_target = false
	for target_position in valid_attack_targets:
		if target_position.equals(clicked_position):
			is_valid_target = true
			break
	
	if not is_valid_target:
		# Cancel attack action when clicking on invalid target
		print("[ACTION_DIALOG] Invalid attack target clicked - canceling attack action")
		clear_action_state()
		return true  # Return true to indicate we handled the click (cancellation)
	
	# Find enemy unit at clicked position
	var target_unit = validation_module.get_unit_at_position(clicked_position, game_state.units)
	
	if not target_unit or target_unit.owner_id == current_unit.owner_id:
		return false
	
	# Execute attack
	_execute_attack(current_unit, target_unit, game_state)
	
	# Clear action state
	clear_action_state()
	
	return true

# Handle heal target click (called from input manager)
func handle_heal_target_click(clicked_position, game_state: Dictionary):
	print("[ACTION_DIALOG] handle_heal_target_click called")
	
	if selected_action != "HEAL" or not current_unit:
		return false
	
	# Check if clicked position is a valid heal target
	if not unit_manager or not unit_manager.selection_manager:
		return false
	
	var valid_heal_targets = unit_manager.selection_manager.get_valid_heal_targets()
	
	var is_valid_target = false
	for target_position in valid_heal_targets:
		if target_position.equals(clicked_position):
			is_valid_target = true
			break
	
	if not is_valid_target:
		# Cancel heal action when clicking on invalid target
		print("[ACTION_DIALOG] Invalid heal target clicked - canceling heal action")
		clear_action_state()
		return true  # Return true to indicate we handled the click (cancellation)
	
	# Find unit at clicked position (could be self or other unit)
	var target_unit = validation_module.get_unit_at_position(clicked_position, game_state.units)
	
	if not target_unit or not target_unit.is_injured():
		return false
	
	# Allow healing any injured unit (including enemies) - no visibility check needed
	
	# Execute heal
	_execute_heal(current_unit, target_unit, game_state)
	
	# Clear action state
	clear_action_state()
	
	return true

# Execute attack action
func _execute_attack(attacker_unit, target_unit, game_state: Dictionary):
	# Deduct 1 power from attacker's natal domain
	var natal_domain = validation_module.find_natal_domain(attacker_unit, game_state)
	if natal_domain and natal_domain.power > 0:
		natal_domain.power -= 1
		print("[ATTACK] Consumed 1 power from natal domain. Remaining power: ", natal_domain.power)
	
	# Connect to damage signal for immediate visual feedback
	if not target_unit.is_connected("damage_applied", _on_damage_applied):
		target_unit.damage_applied.connect(_on_damage_applied)
	
	# Deal 1 damage to target
	target_unit.damage_unit(1)
	
	# Consume attacker's action
	attacker_unit.consume_action()
	
	print("[ATTACK] ", attacker_unit.name, " attacked ", target_unit.name, " for 1 damage. Target health: ", target_unit.health)

# Execute heal action
func _execute_heal(healer_unit, target_unit, game_state: Dictionary):
	# Deduct 1 power from healer's natal domain
	var natal_domain = validation_module.find_natal_domain(healer_unit, game_state)
	if natal_domain and natal_domain.power > 0:
		natal_domain.power -= 1
		print("[HEAL] Consumed 1 power from natal domain. Remaining power: ", natal_domain.power)
	
	# Heal the target unit
	target_unit.heal_unit(1)
	
	# Consume healer's action
	healer_unit.consume_action()
	
	print("[HEAL] ", healer_unit.name, " healed ", target_unit.name, ". Target health: ", target_unit.health)
	
	# Trigger redraw for immediate visual update
	main_node.queue_redraw()

# Handle damage applied signal for immediate visual update
func _on_damage_applied(damaged_unit):
	print("[DAMAGE] Unit ", damaged_unit.name, " took damage! Health: ", damaged_unit.health)
	
	# Check if unit died and add skull emoji
	if damaged_unit.is_dead():
		print("[DEATH] Unit ", damaged_unit.name, " died! Adding skull emoji...")
		_add_skull_emoji_at_position(damaged_unit.position)
		# BUGFIX: Remove dead unit immediately to free the star position
		_remove_dead_unit_immediately(damaged_unit)
	
	# Force immediate redraw when damage is applied
	main_node.queue_redraw()
	main_node.call_deferred("queue_redraw")
	
	# Disconnect the signal to avoid memory leaks
	if damaged_unit.is_connected("damage_applied", _on_damage_applied):
		damaged_unit.damage_applied.disconnect(_on_damage_applied)

# Remove dead unit immediately from game state
func _remove_dead_unit_immediately(dead_unit):
	# Try to get game state through unit_manager
	var game_state = null
	if unit_manager and unit_manager.has_method("get_current_game_state"):
		game_state = unit_manager.get_current_game_state()
	elif main_node and main_node.has_method("get_game_state"):
		game_state = main_node.get_game_state()
	elif main_node and main_node.scene_manager:
		var gameplay_manager = main_node.scene_manager.get_gameplay_manager()
		if gameplay_manager and gameplay_manager.has_method("get_game_state"):
			game_state = gameplay_manager.get_game_state()
	
	if not game_state or not ("units" in game_state):
		return
	
	# Remove from units data
	if dead_unit.id in game_state.units:
		game_state.units.erase(dead_unit.id)
		print("[DEATH] Removed unit ", dead_unit.name, " (ID: ", dead_unit.id, ") from units data")
	
	# Remove from player's unit list if exists
	if "players" in game_state and dead_unit.owner_id in game_state.players:
		var player = game_state.players[dead_unit.owner_id]
		if "unit_ids" in player and dead_unit.id in player.unit_ids:
			player.unit_ids.erase(dead_unit.id)
			print("[DEATH] Removed unit from player ", dead_unit.owner_id, " unit list")
	
	# Force immediate visual update
	main_node.queue_redraw()

# Add skull emoji at position where unit died
func _add_skull_emoji_at_position(position):
	# Try to get game state through various sources
	var game_state = _get_current_game_state()
	if not game_state or game_state.is_empty():
		return
	
	# Initialize skull_emojis array if it doesn't exist
	if not ("skull_emojis" in game_state):
		game_state.skull_emojis = []
	
	# Get current turn number for expiration tracking
	var current_turn = 0
	if "turn_data" in game_state and "turn_number" in game_state.turn_data:
		current_turn = game_state.turn_data.turn_number
	
	# Add skull emoji with expiration after 1 turn
	var skull_data = {
		"position": position,
		"emoji": "💀",
		"created_turn": current_turn,
		"expires_turn": current_turn + 1
	}
	
	game_state.skull_emojis.append(skull_data)
	print("[SKULL] Added skull emoji at ", position, " (expires turn ", current_turn + 1, ")")

# Get current game state from various sources
func _get_current_game_state() -> Dictionary:
	var game_state = {}
	
	# Try through unit_manager
	if unit_manager and unit_manager.has_method("get_current_game_state"):
		game_state = unit_manager.get_current_game_state()
	elif main_node and main_node.has_method("get_game_state"):
		game_state = main_node.get_game_state()
	elif main_node and main_node.scene_manager:
		var gameplay_manager = main_node.scene_manager.get_gameplay_manager()
		if gameplay_manager and gameplay_manager.has_method("get_game_state"):
			game_state = gameplay_manager.get_game_state()
	
	return game_state

# Get display name for action
func _get_action_display_name(action: String) -> String:
	match action:
		"MOVE":
			return GameDialogStrings.ACTION_MOVE_DISPLAY
		"SETTLE":
			return GameDialogStrings.ACTION_SETTLE_DISPLAY
		"ATTACK":
			return GameDialogStrings.ACTION_ATTACK_DISPLAY
		"TRAIN":
			return GameDialogStrings.ACTION_TRAIN_DISPLAY
		"HEAL":
			return GameDialogStrings.ACTION_HEAL_DISPLAY
		_:
			return action

# Clear action state
func clear_action_state():
	current_unit = null
	selected_action = ""

# Cancel any active actions (called from empty area clicks)
func cancel_active_actions():
	print("[ACTION_DIALOG] Canceling active actions")
	clear_action_state()
	
	# Clear attack/heal targets if unit_manager is available
	if unit_manager and unit_manager.selection_manager:
		if unit_manager.selection_manager.has_method("clear_attack_targets"):
			unit_manager.selection_manager.clear_attack_targets()
		if unit_manager.selection_manager.has_method("clear_heal_targets"):
			unit_manager.selection_manager.clear_heal_targets()
	
	# Clear attack and heal targets from selection manager using API
	if unit_manager and unit_manager.selection_manager:
		# Use the public API to clear targets
		if unit_manager.selection_manager.has_method("_clear_attack_targets"):
			unit_manager.selection_manager._clear_attack_targets()
		if unit_manager.selection_manager.has_method("_clear_heal_targets"):
			unit_manager.selection_manager._clear_heal_targets()
		# Fallback: try to access selection_core directly
		elif unit_manager.selection_manager.selection_core:
			unit_manager.selection_manager.selection_core.valid_attack_targets.clear()
			unit_manager.selection_manager.selection_core.valid_heal_targets.clear()
		main_node.queue_redraw()
	
	# Clear any active dialogs
	if current_dialog:
		_close_current_dialog(current_dialog)
		current_dialog = null

# Close current dialog and clean up
func _close_current_dialog(dialog):
	if dialog and is_instance_valid(dialog):
		# Use the enhanced dialog manager cleanup
		dialog_manager._force_cleanup_dialog(dialog)
	
	# Clear tracking immediately
	current_dialog = null
	if dialog_manager:
		dialog_manager.clear_current_dialog()

# Getters for external access
func get_current_unit():
	return current_unit

func get_selected_action() -> String:
	return selected_action

# Cleanup method
func cleanup():
	# Force close any existing dialog
	if current_dialog and is_instance_valid(current_dialog):
		_close_current_dialog(current_dialog)
	
	# Clear all references
	main_node = null
	dialog_manager = null
	unit_manager = null
	validation_module = null
	current_dialog = null
	current_unit = null
	selected_action = ""