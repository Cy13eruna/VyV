# 🎯 UNIT SELECTION CORE
# Purpose: Core logic for unit selection and state management
# Layer: Presentation Managers - Unit Selection

extends RefCounted
class_name UnitSelectionCore

# Import dependencies
const TurnService = preload("res://application/services/turn_service_clean.gd")
const MovementService = preload("res://application/services/movement_service.gd")
const UnitPowerManager = preload("res://presentation/managers/unit/unit_power_manager.gd")

# Unit selection state
var selected_unit_id: int = -1
var valid_movement_targets: Array = []
var valid_attack_targets: Array = []
var valid_heal_targets: Array = []

# Recursion protection
var _is_selecting: bool = false
var _selection_timeout: float = 0.0

# References
var main_node: Node2D
var action_dialog_manager
var domain_manager
var technology_manager

# Signals
signal unit_selected(unit_id: int)

# Initialize with references
func initialize(main_node_ref: Node2D, action_dialog_manager_ref):
	main_node = main_node_ref
	action_dialog_manager = action_dialog_manager_ref
	print("[SELECTION_CORE] Initialized with action_dialog_manager: ", action_dialog_manager != null)

# Set technology manager reference
func set_technology_manager(tech_manager):
	technology_manager = tech_manager

# Attempt to select a unit
func attempt_unit_selection(unit_id: int, game_state: Dictionary, domain_manager_ref) -> void:
	print("[SELECTION_CORE] Attempting to select unit: ", unit_id, ", _is_selecting: ", _is_selecting)
	
	# Prevent recursion with timeout
	var current_time = Time.get_time_dict_from_system()["second"]
	if _is_selecting:
		# Check if timeout has passed (2 seconds)
		if current_time - _selection_timeout > 2.0:
			print("[SELECTION_CORE] WARNING: Selection timeout reached, resetting protection")
			_is_selecting = false
		else:
			print("[SELECTION_CORE] CRITICAL: Recursion detected, aborting selection for unit: ", unit_id)
			return
	
	_is_selecting = true
	_selection_timeout = current_time
	print("[SELECTION_CORE] Setting _is_selecting = true for unit: ", unit_id)
	domain_manager = domain_manager_ref
	var unit = game_state.units.get(unit_id)
	if not unit:
		_is_selecting = false
		return
	
	# Import action validator for validation
	var UnitActionValidator = load("res://presentation/managers/unit/selection/unit_action_validator.gd")
	
	# Check if this is the current player's unit
	if not UnitActionValidator.validate_unit_ownership(unit, game_state):
		_is_selecting = false
		return
	
	# Note: Double-click functionality removed
	
	# If same unit is already selected, show action dialog
	if selected_unit_id == unit_id:
		print("[SELECTION_CORE] Same unit selected, action_dialog_manager available: ", action_dialog_manager != null)
		if action_dialog_manager:
			action_dialog_manager.show_unit_action_ui(unit, game_state)
		else:
			print("[SELECTION_CORE] action_dialog_manager is null!")
		_is_selecting = false
		return
	
	# Select the unit
	selected_unit_id = unit_id
	
	# Calculate valid movement targets
	valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units, game_state)
	
	# Check if unit is on domain nucleus (always show action menu)
	if UnitActionValidator.is_unit_on_domain_nucleus(unit, game_state):
		# Units on domain nucleus always show action menu (upgrade + other actions)
		print("[NUCLEUS] Unit ", unit.name, " is on domain nucleus, showing action menu")
		print("[NUCLEUS] action_dialog_manager available: ", action_dialog_manager != null)
		if action_dialog_manager:
			action_dialog_manager.show_unit_action_ui(unit, game_state)
		else:
			print("[NUCLEUS] No action_dialog_manager available - trying to get from unit_manager")
			# Try to get action_dialog_manager from a parent reference if available
			if domain_manager and domain_manager.has_method("get_unit_manager"):
				var unit_manager = domain_manager.get_unit_manager()
				if unit_manager and unit_manager.action_dialog_manager:
					print("[NUCLEUS] Found action_dialog_manager from unit_manager")
					unit_manager.action_dialog_manager.show_unit_action_ui(unit, game_state)
		_is_selecting = false
		return
	
	# Check if unit has multiple actions available
	var action_count = UnitActionValidator.count_available_actions(unit, game_state)
	print("[ACTIONS] Unit ", unit.name, " has ", action_count, " available actions")
	if action_count > 1:
		# Show action selection dialog for multiple actions
		print("[ACTIONS] Showing action menu for multiple actions")
		print("[ACTIONS] action_dialog_manager available: ", action_dialog_manager != null)
		if action_dialog_manager:
			action_dialog_manager.show_unit_action_ui(unit, game_state)
		else:
			print("[ACTIONS] No action_dialog_manager available - trying to get from unit_manager")
			# Try to get action_dialog_manager from a parent reference if available
			if domain_manager and domain_manager.has_method("get_unit_manager"):
				var unit_manager = domain_manager.get_unit_manager()
				if unit_manager and unit_manager.action_dialog_manager:
					print("[ACTIONS] Found action_dialog_manager from unit_manager")
					unit_manager.action_dialog_manager.show_unit_action_ui(unit, game_state)
		_is_selecting = false
		return
	
	# Emit selection signal
	unit_selected.emit(unit_id)
	
	# Trigger redraw
	main_node.queue_redraw()
	
	# Clear recursion protection
	_is_selecting = false
	print("[SELECTION_CORE] Clearing _is_selecting for unit: ", unit_id)

# Clear unit selection
func clear_selection():
	selected_unit_id = -1
	valid_movement_targets.clear()
	valid_attack_targets.clear()
	valid_heal_targets.clear()
	main_node.queue_redraw()

# Fallback unit selection (old system for compatibility)
func fallback_unit_selection(unit_id: int, unit, game_state: Dictionary, domain_manager_ref = null):
	domain_manager = domain_manager_ref
	
	# Import action validator for validation
	var UnitActionValidator = load("res://presentation/managers/unit/selection/unit_action_validator.gd")
	
	# Check if clicking on already selected unit with Settler capability
	if unit_id == selected_unit_id and UnitActionValidator.can_unit_use_settler(unit, game_state, domain_manager):
		show_settler_confirmation_dialog(unit)
		return
	
	# If unit has Settler capability but is not selected yet, select it first
	if UnitActionValidator.can_unit_use_settler(unit, game_state, domain_manager):
		# Select the unit - it can both move and use Settler
		selected_unit_id = unit_id
		# Calculate movement targets even for Settler units (they can choose to move or use Settler)
		if unit.can_move() and UnitPowerManager.unit_has_power_to_move(unit, game_state, domain_manager):
			valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units, game_state)
		else:
			valid_movement_targets = []  # No movement if can't move
		unit_selected.emit(unit_id)
		main_node.queue_redraw()
		return
	
	# For regular unit selection, check if unit can move
	if not unit.can_move():
		# Just return without showing dialog - silent restriction
		return
	
	# Check if unit has enough power to move
	if not UnitPowerManager.unit_has_power_to_move(unit, game_state, domain_manager):
		# Just return without showing dialog - silent restriction
		return
	
	selected_unit_id = unit_id
	valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units, game_state)
	
	unit_selected.emit(unit_id)
	main_node.queue_redraw()

# Show Settler confirmation dialog (legacy - kept for compatibility)
func show_settler_confirmation_dialog(unit):
	# Placeholder - this should be handled by UnitSettlerManager
	pass

# Getters for external access
func get_selected_unit_id() -> int:
	return selected_unit_id

func get_valid_movement_targets() -> Array:
	return valid_movement_targets

func get_valid_attack_targets() -> Array:
	return valid_attack_targets

func get_valid_heal_targets() -> Array:
	return valid_heal_targets

# Update movement targets for selected unit
func update_movement_targets(game_state: Dictionary):
	if selected_unit_id == -1:
		return
	
	var unit = game_state.units.get(selected_unit_id)
	if not unit:
		return
	
	valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units, game_state)

# Check if unit is currently selected
func is_unit_selected(unit_id: int) -> bool:
	return selected_unit_id == unit_id

# Get selection state summary
func get_selection_state() -> Dictionary:
	return {
		"selected_unit_id": selected_unit_id,
		"has_movement_targets": valid_movement_targets.size() > 0,
		"has_attack_targets": valid_attack_targets.size() > 0,
		"has_heal_targets": valid_heal_targets.size() > 0
	}

# Cleanup method
func cleanup():
	main_node = null
	action_dialog_manager = null
	domain_manager = null
	technology_manager = null
	selected_unit_id = -1
	valid_movement_targets.clear()
	valid_attack_targets.clear()
	valid_heal_targets.clear()