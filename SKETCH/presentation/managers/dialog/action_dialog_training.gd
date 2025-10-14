# 📚 ACTION DIALOG TRAINING
# Purpose: Training system for units (Fighter/Healer)
# Layer: Presentation Manager - Dialog Training

extends RefCounted
class_name ActionDialogTraining

# Import dependencies
const TurnService = preload("res://application/services/turn_service_clean.gd")
# DialogConstants removed - now using GameDialogStrings
const GameDialogStrings = preload("res://presentation/constants/game_dialog_strings.gd")

# References
var main_node: Node2D
var dialog_manager
var validation_module
var current_dialog = null

# Initialize with required references
func initialize(main_node_ref: Node2D, dialog_manager_ref, validation_module_ref):
	main_node = main_node_ref
	dialog_manager = dialog_manager_ref
	validation_module = validation_module_ref

# Show training dialog directly
func show_training_dialog(unit, game_state: Dictionary):
	print("[TRAINING_DIALOG] show_training_dialog called for unit: ", unit.name)
	
	# Get available trainings
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player:
		print("[TRAINING_DIALOG] No current player found")
		return
	
	var available_trainings = validation_module.get_available_trainings(unit, current_player, game_state)
	print("[TRAINING_DIALOG] Available trainings: ", available_trainings)
	
	if available_trainings.is_empty():
		print("[TRAINING_DIALOG] No trainings available")
		return
	
	# Show training selection dialog
	_show_training_selection_dialog(unit, available_trainings, current_player, game_state)

# Show training selection dialog
func _show_training_selection_dialog(unit, available_trainings: Array, player, game_state: Dictionary):
	# Create dialog using centralized strings
	var dialog = GameDialogStrings.create_training_selection_dialog(unit.name)
	
	# Hide default OK button
	dialog.get_ok_button().visible = false
	
	# Get the main container from the dialog (created by create_styled_dialog)
	var main_container = null
	for child in dialog.get_children():
		if child is VBoxContainer:
			main_container = child
			break
	
	# Create button container
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", GameDialogStrings.BUTTON_SPACING)
	
	# Create training buttons
	for training in available_trainings:
		# Create training button
		var training_button = Button.new()
		training_button.text = GameDialogStrings.TRAINING_BUTTON_FORMAT % [training.name, training.cost]
		training_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Apply black text styling
		GameDialogStrings.apply_button_style(training_button)
		training_button.pressed.connect(_on_training_selected.bind(dialog, unit, training, player, game_state))
		button_container.add_child(training_button)
	
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
	
	# Focus first training button
	if button_container.get_child_count() > 0:
		button_container.get_child(0).grab_focus()

# Handle training selection
func _on_training_selected(dialog, unit, training: Dictionary, player, game_state: Dictionary):
	_close_current_dialog(dialog)
	
	# Execute the training
	match training.type:
		"FIGHTER":
			_execute_fighter_training(unit, training.cost, player, game_state)
		"HEALER":
			_execute_healer_training(unit, training.cost, player, game_state)
		"RIDER":
			_execute_rider_training(unit, training.cost, player, game_state)
		"CLIMBER":
			_execute_climber_training(unit, training.cost, player, game_state)
		"SHAMAN":
			_execute_shaman_training(unit, training.cost, player, game_state)
		_:
			print("Unknown training type: ", training.type)

# Execute fighter training
func _execute_fighter_training(unit, cost: int, player, game_state: Dictionary):
	# Deduct power from player's domains
	_deduct_power_from_player(player, game_state, cost)
	
	# Make unit a fighter
	unit.make_fighter()
	
	# Increase unit level
	unit.level += 1
	
	# Consume one action (training now costs an action)
	unit.consume_action()
	
	print("[TRAINING] ", unit.name, " trained as Fighter! New level: ", unit.level, ". Actions remaining: ", unit.actions_remaining)
	
	# Trigger redraw
	main_node.queue_redraw()

# Execute healer training
func _execute_healer_training(unit, cost: int, player, game_state: Dictionary):
	# Deduct power from player's domains
	_deduct_power_from_player(player, game_state, cost)
	
	# Make unit a healer
	unit.make_healer()
	
	# Increase unit level
	unit.level += 1
	
	# Consume one action (training now costs an action)
	unit.consume_action()
	
	print("[TRAINING] ", unit.name, " trained as Healer! New level: ", unit.level, ". Actions remaining: ", unit.actions_remaining)
	
	# Trigger redraw
	main_node.queue_redraw()

# Execute rider training
func _execute_rider_training(unit, cost: int, player, game_state: Dictionary):
	# Deduct power from player's domains
	_deduct_power_from_player(player, game_state, cost)
	
	# Make unit a rider
	unit.make_rider()
	
	# Increase unit level
	unit.level += 1
	
	# Consume one action (training costs an action)
	unit.consume_action()
	
	# Trigger redraw
	main_node.queue_redraw()

# Execute climber training
func _execute_climber_training(unit, cost: int, player, game_state: Dictionary):
	# Deduct power from player's domains
	_deduct_power_from_player(player, game_state, cost)
	
	# Make unit a climber
	unit.make_climber()
	
	# Increase unit level
	unit.level += 1
	
	# Consume one action (training costs an action)
	unit.consume_action()
	
	# Trigger redraw
	main_node.queue_redraw()

# Execute shaman training (added)
func _execute_shaman_training(unit, cost: int, player, game_state: Dictionary):
	# Deduct power from player's domains
	_deduct_power_from_player(player, game_state, cost)
	
	# Apply shaman role/abilities
	if unit.has_method("make_shaman"):
		unit.make_shaman()
	else:
		unit.is_shaman = true
	
	# Increase unit level
	unit.level += 1
	
	# Consume one action (training costs an action)
	unit.consume_action()
	
	print("[TRAINING] ", unit.name, " trained as Shaman! New level: ", unit.level, ". Actions remaining: ", unit.actions_remaining)
	
	# Trigger redraw
	main_node.queue_redraw()

# Deduct power from player's domains (considers market sharing)
func _deduct_power_from_player(player, game_state: Dictionary, cost: int):
	var remaining_cost = cost
	
	# Check if player has market access
	var player_has_market = false
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == player.id and domain.get("has_market_upgrade", false):
			player_has_market = true
			break
	
	if player_has_market and "market_domains" in game_state:
		# Player has market access - can deduct from ALL market domains
		for domain_id in game_state.market_domains:
			if domain_id in game_state.domains and remaining_cost > 0:
				var domain = game_state.domains[domain_id]
				var deduction = min(domain.power, remaining_cost)
				domain.power -= deduction
				remaining_cost -= deduction
	else:
		# Player has no market access - only own domains
		for domain_id in player.domain_ids:
			if domain_id in game_state.domains and remaining_cost > 0:
				var domain = game_state.domains[domain_id]
				var deduction = min(domain.power, remaining_cost)
				domain.power -= deduction
				remaining_cost -= deduction

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
	validation_module = null
	current_dialog = null