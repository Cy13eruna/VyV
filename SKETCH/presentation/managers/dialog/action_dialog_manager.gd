# 🎯 ACTION DIALOG MANAGER (REFATORADO)
# Purpose: Coordenador principal para seleção e execução de ações de unidades
# Layer: Presentation Manager
# 
# REGRA PÉTRA: TODA AÇÃO CUSTA 1 PODER DO DOMÍNIO NATAL
# - MOVE: 1 poder + 1 ação
# - ATTACK: 1 poder + 1 ação  
# - HEAL: 1 poder + 1 ação
# - SETTLE: 1 poder + 1 ação
# - TRAIN: 1 poder (sem custo de ação)

extends RefCounted
class_name ActionDialogManager

# Import modular components
const ActionDialogValidation = preload("res://presentation/managers/dialog/action_dialog_validation.gd")
const ActionDialogCore = preload("res://presentation/managers/dialog/action_dialog_core.gd")
const ActionDialogTraining = preload("res://presentation/managers/dialog/action_dialog_training.gd")
const ActionDialogSettlement = preload("res://presentation/managers/dialog/action_dialog_settlement.gd")

# References
var main_node: Node2D
var dialog_manager
var unit_manager
var technology_manager

# Modular components
var validation_module: ActionDialogValidation
var core_module: ActionDialogCore
var training_module: ActionDialogTraining
var settlement_module: ActionDialogSettlement

# Current state
var current_unit = null
var selected_action = ""

# Initialize with required references
func initialize(main_node_ref: Node2D, dialog_manager_ref, unit_manager_ref, technology_manager_ref):
	main_node = main_node_ref
	dialog_manager = dialog_manager_ref
	unit_manager = unit_manager_ref
	technology_manager = technology_manager_ref
	
	# Initialize modular components
	validation_module = ActionDialogValidation.new()
	validation_module.initialize(technology_manager)
	
	training_module = ActionDialogTraining.new()
	training_module.initialize(main_node, dialog_manager, validation_module)
	
	settlement_module = ActionDialogSettlement.new()
	settlement_module.initialize(main_node, dialog_manager, unit_manager)
	
	core_module = ActionDialogCore.new()
	core_module.initialize(main_node, dialog_manager, unit_manager, validation_module, training_module, settlement_module)

# Main entry point: show action UI for a unit
func show_unit_action_ui(unit, game_state: Dictionary):
	print("[ACTION_UI] show_unit_action_ui called for unit: ", unit.name)
	
	# Enhanced dialog prevention with forced cleanup
	if dialog_manager.has_open_dialog():
		print("[ACTION_UI] Dialog manager has open dialog, clearing")
		dialog_manager.clear_current_dialog()
		# Wait a frame for cleanup to complete
		await main_node.get_tree().process_frame
	
	# Ensure clean state before starting new action
	clear_action_state()
	unit_manager.clear_selection()
	
	current_unit = unit
	var available_actions = validation_module.get_available_actions(unit, game_state)
	print("[ACTION_UI] Available actions: ", available_actions)
	
	# If no actions available, silently return
	if available_actions.is_empty():
		print("[ACTION_UI] No actions available for unit ", unit.name, ", returning")
		return
	
	# If only one action available, skip selection and go directly to action UI
	if available_actions.size() == 1:
		print("[ACTION_UI] Only one action available: ", available_actions[0])
		selected_action = available_actions[0]
		# Special handling for TRAIN action
		if selected_action == "TRAIN":
			print("[ACTION_UI] Showing training dialog directly")
			training_module.show_training_dialog(unit, game_state)
		elif selected_action == "SETTLE":
			settlement_module.show_settle_ui(unit, game_state)
		else:
			core_module.show_action_specific_ui(selected_action, unit, game_state)
		return
	
	# Multiple actions available - show selection dialog
	print("[ACTION_UI] Multiple actions available, showing selection dialog")
	core_module.show_action_selection_dialog(unit, available_actions, game_state)

# Show training dialog directly (called from unit selection manager)
func show_training_dialog(unit, game_state: Dictionary):
	training_module.show_training_dialog(unit, game_state)

# Handle attack target click (called from input manager)
func handle_attack_target_click(clicked_position, game_state: Dictionary):
	return core_module.handle_attack_target_click(clicked_position, game_state)

# Handle heal target click (called from input manager)
func handle_heal_target_click(clicked_position, game_state: Dictionary):
	return core_module.handle_heal_target_click(clicked_position, game_state)

# Clear action state
func clear_action_state():
	current_unit = null
	selected_action = ""
	
	# Clear state in all modules
	if core_module:
		core_module.clear_action_state()

# Get current unit (for external access)
func get_current_unit():
	if core_module:
		return core_module.get_current_unit()
	return current_unit

# Get selected action (for external access)
func get_selected_action() -> String:
	if core_module:
		return core_module.get_selected_action()
	return selected_action

# Cleanup method to prevent memory leaks
func cleanup():
	# Cleanup all modules
	if validation_module:
		validation_module = null
	
	if core_module:
		core_module.cleanup()
		core_module = null
	
	if training_module:
		training_module.cleanup()
		training_module = null
	
	if settlement_module:
		settlement_module.cleanup()
		settlement_module = null
	
	# Clear all references
	main_node = null
	dialog_manager = null
	unit_manager = null
	technology_manager = null
	current_unit = null
	selected_action = ""