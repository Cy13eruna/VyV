# 🚶 UNIT MOVEMENT MANAGER
# Purpose: Handle unit movement and related actions
# Layer: Presentation Manager

extends RefCounted
class_name UnitMovementManager

# Import dependencies
const UnitMovementHandler = preload("res://application/use_cases/unit_movement_handler.gd")

# References
var main_node: Node2D
var selection_manager

# Signals
signal unit_moved(unit_id: int, new_position)

# Initialize with references
func initialize(main_node_ref: Node2D, selection_manager_ref):
	main_node = main_node_ref
	selection_manager = selection_manager_ref

# Attempt unit movement
func attempt_unit_movement(target_position, game_state: Dictionary):
	var selected_unit_id = selection_manager.get_selected_unit_id()
	if selected_unit_id == -1:
		return
	
	var move_result = UnitMovementHandler.execute(selected_unit_id, target_position, game_state)
	
	if move_result.success:
		if move_result.power_consumed:
			# Power was consumed, might need to update display
			pass
		unit_moved.emit(selected_unit_id, target_position)
		selection_manager.clear_selection()
	
	if move_result.get("unit_exhausted", false):
		selection_manager.clear_selection()
	
	main_node.queue_redraw()

# Cleanup method
func cleanup():
	main_node = null
	selection_manager = null