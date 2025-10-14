# 🎮 GAMEPLAY INPUT HANDLER
# Purpose: Handle input events and coordinate with game systems
# Layer: Presentation Managers - Gameplay Input

extends RefCounted
class_name GameplayInputHandler

# References
var main_node: Node2D
var core_manager

# Initialize with references
func initialize(main_node_ref: Node2D, core_manager_ref):
	main_node = main_node_ref
	core_manager = core_manager_ref

# Handle point click events
func on_point_clicked(point_id: int):
	print("[GAMEPLAY_INPUT] Point clicked: ", point_id)
	
	# Get managers from core
	var game_state_manager = core_manager.get_game_state_manager()
	var unit_manager = core_manager.get_unit_manager()
	var domain_manager = core_manager.get_domain_manager()
	
	# DEBUG: Check manager integrity
	if not game_state_manager:
		print("ERROR: game_state_manager is null in on_point_clicked")
		return
	
	if not unit_manager:
		print("ERROR: unit_manager is null in on_point_clicked")
		return
	
	if game_state_manager.is_game_over():
		return
	
	var game_state = game_state_manager.get_game_state()
	var point = game_state.grid.points.get(point_id)
	if not point:
		return
	
	var target_position = point.position
	var unit_at_point = -1
	if unit_manager:
		unit_at_point = unit_manager.find_unit_at_position(target_position, game_state)
		print("[GAMEPLAY_INPUT] Unit at point: ", unit_at_point)
	
	if unit_at_point != -1:
		# Unit clicked - try to select it
		print("[GAMEPLAY_INPUT] Attempting to select unit: ", unit_at_point)
		unit_manager.attempt_unit_selection(unit_at_point, game_state)
	else:
		# Empty position clicked
		handle_empty_position_click(target_position, game_state, unit_manager, domain_manager)

# Handle clicks on empty positions
func handle_empty_position_click(target_position, game_state: Dictionary, unit_manager, domain_manager):
	# Check if it's a valid movement target first (priority when unit is selected)
	if unit_manager.get_selected_unit_id() != -1:
		var is_valid_target = false
		for valid_target in unit_manager.get_valid_movement_targets():
			if valid_target.equals(target_position):
				is_valid_target = true
				break
		
		if is_valid_target:
			unit_manager.attempt_unit_movement(target_position, game_state)
			return
		else:
			unit_manager.clear_selection()
			main_node.queue_redraw()
			return
	
	# Check if clicked on nuclear star (domain center with power >= level)
	# Only if no unit is selected
	if domain_manager and domain_manager.is_nuclear_star_clickable(target_position, game_state):
		domain_manager.show_nuclear_star_dialog(game_state)
		return

# Handle unit selection events
func handle_unit_selection(unit_id: int, game_state: Dictionary):
	var unit_manager = core_manager.get_unit_manager()
	if unit_manager:
		unit_manager.attempt_unit_selection(unit_id, game_state)

# Handle unit movement events
func handle_unit_movement(target_position, game_state: Dictionary):
	var unit_manager = core_manager.get_unit_manager()
	if unit_manager:
		unit_manager.attempt_unit_movement(target_position, game_state)

# Handle domain interaction events
func handle_domain_interaction(position, game_state: Dictionary):
	var domain_manager = core_manager.get_domain_manager()
	if domain_manager and domain_manager.is_nuclear_star_clickable(position, game_state):
		domain_manager.show_nuclear_star_dialog(game_state)

# Clear current selections
func clear_selections():
	var unit_manager = core_manager.get_unit_manager()
	if unit_manager:
		unit_manager.clear_selection()
	
	if main_node:
		main_node.queue_redraw()

# Check if position has unit
func has_unit_at_position(position, game_state: Dictionary) -> bool:
	var unit_manager = core_manager.get_unit_manager()
	if unit_manager:
		return unit_manager.find_unit_at_position(position, game_state) != -1
	return false

# Get unit at position
func get_unit_at_position(position, game_state: Dictionary) -> int:
	var unit_manager = core_manager.get_unit_manager()
	if unit_manager:
		return unit_manager.find_unit_at_position(position, game_state)
	return -1

# Check if position is valid movement target
func is_valid_movement_target(position, game_state: Dictionary) -> bool:
	var unit_manager = core_manager.get_unit_manager()
	if not unit_manager or unit_manager.get_selected_unit_id() == -1:
		return false
	
	for valid_target in unit_manager.get_valid_movement_targets():
		if valid_target.equals(position):
			return true
	return false

# Check if position is clickable domain center
func is_clickable_domain_center(position, game_state: Dictionary) -> bool:
	var domain_manager = core_manager.get_domain_manager()
	if domain_manager:
		return domain_manager.is_nuclear_star_clickable(position, game_state)
	return false

# Get current game state
func get_current_game_state() -> Dictionary:
	var game_state_manager = core_manager.get_game_state_manager()
	if game_state_manager:
		return game_state_manager.get_game_state()
	return {}

# Check if game is over
func is_game_over() -> bool:
	var game_state_manager = core_manager.get_game_state_manager()
	if game_state_manager:
		return game_state_manager.is_game_over()
	return false

# Get selected unit information
func get_selection_info() -> Dictionary:
	var unit_manager = core_manager.get_unit_manager()
	if unit_manager:
		return {
			"selected_unit_id": unit_manager.get_selected_unit_id(),
			"valid_movement_targets": unit_manager.get_valid_movement_targets()
		}
	return {"selected_unit_id": -1, "valid_movement_targets": []}

# Cleanup method
func cleanup():
	main_node = null
	core_manager = null