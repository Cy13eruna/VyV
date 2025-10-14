# 🎯 UNIT SELECTION MANAGER (REFATORADO)
# Purpose: Coordenador principal para seleção de unidades
# Layer: Presentation Manager

extends RefCounted
class_name UnitSelectionManager

# Import modular components (loaded dynamically to avoid parse errors)
var UnitActionValidator: GDScript
var UnitSelectionCore: GDScript

# Modular components
var action_validator
var selection_core

# Signals (delegated from core)
signal unit_selected(unit_id: int)

func _init():
	setup_components()

# Setup modular components
func setup_components():
	# Load classes dynamically
	UnitActionValidator = load("res://presentation/managers/unit/selection/unit_action_validator.gd")
	UnitSelectionCore = load("res://presentation/managers/unit/selection/unit_selection_core.gd")
	
	# Create components
	selection_core = UnitSelectionCore.new()
	
	# Connect signals
	if selection_core and selection_core.has_signal("unit_selected"):
		selection_core.unit_selected.connect(_on_unit_selected)

# Initialize with references (delegated to core)
func initialize(main_node_ref: Node2D, action_dialog_manager_ref):
	if selection_core and selection_core.has_method("initialize"):
		selection_core.initialize(main_node_ref, action_dialog_manager_ref)

# Set technology manager reference (delegated to core)
func set_technology_manager(tech_manager):
	if selection_core and selection_core.has_method("set_technology_manager"):
		selection_core.set_technology_manager(tech_manager)

# Set action dialog manager reference (for compatibility)
func _set_action_dialog_manager(action_dialog_manager_ref):
	if selection_core:
		selection_core.action_dialog_manager = action_dialog_manager_ref

# Set attack targets (for compatibility)
func _set_attack_targets(unit_id: int, targets: Array):
	if selection_core:
		selection_core.selected_unit_id = unit_id
		selection_core.valid_attack_targets = targets

# Set heal targets (for compatibility)
func _set_heal_targets(unit_id: int, targets: Array):
	if selection_core:
		selection_core.selected_unit_id = unit_id
		selection_core.valid_heal_targets = targets

# Clear attack targets (for compatibility)
func _clear_attack_targets():
	if selection_core:
		selection_core.valid_attack_targets.clear()

# Clear heal targets (for compatibility)
func _clear_heal_targets():
	if selection_core:
		selection_core.valid_heal_targets.clear()

# Set movement targets only without triggering selection (for compatibility)
func _set_movement_targets_only(unit_id: int, game_state: Dictionary):
	if selection_core:
		selection_core.selected_unit_id = unit_id
		var unit = game_state.units.get(unit_id)
		if unit:
			var MovementService = load("res://application/services/movement_service.gd")
			selection_core.valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units, game_state)

# Attempt to select a unit (delegated to core)
func attempt_unit_selection(unit_id: int, game_state: Dictionary, domain_manager) -> void:
	if selection_core and selection_core.has_method("attempt_unit_selection"):
		selection_core.attempt_unit_selection(unit_id, game_state, domain_manager)

# Clear unit selection (delegated to core)
func clear_selection():
	if selection_core and selection_core.has_method("clear_selection"):
		selection_core.clear_selection()

# Getters for external access (delegated to core)
func get_selected_unit_id() -> int:
	if selection_core and selection_core.has_method("get_selected_unit_id"):
		return selection_core.get_selected_unit_id()
	return -1

func get_valid_movement_targets() -> Array:
	if selection_core and selection_core.has_method("get_valid_movement_targets"):
		return selection_core.get_valid_movement_targets()
	return []

func get_valid_attack_targets() -> Array:
	if selection_core and selection_core.has_method("get_valid_attack_targets"):
		return selection_core.get_valid_attack_targets()
	return []

func get_valid_heal_targets() -> Array:
	if selection_core and selection_core.has_method("get_valid_heal_targets"):
		return selection_core.get_valid_heal_targets()
	return []

# Fallback unit selection (delegated to core)
func _fallback_unit_selection(unit_id: int, unit, game_state: Dictionary, domain_manager = null):
	if selection_core and selection_core.has_method("fallback_unit_selection"):
		selection_core.fallback_unit_selection(unit_id, unit, game_state, domain_manager)

# Action validation methods (delegated to validator)
func _can_unit_use_settler(unit, game_state: Dictionary, domain_manager = null) -> bool:
	if UnitActionValidator:
		return UnitActionValidator.can_unit_use_settler(unit, game_state, domain_manager)
	return false

func _is_unit_on_domain_nucleus(unit, game_state: Dictionary) -> bool:
	if UnitActionValidator:
		return UnitActionValidator.is_unit_on_domain_nucleus(unit, game_state)
	return false

func _get_unit_natal_power(unit, game_state: Dictionary) -> int:
	if UnitActionValidator:
		return UnitActionValidator.get_unit_natal_power(unit, game_state)
	return 0

func _find_natal_domain(unit, game_state: Dictionary):
	if UnitActionValidator:
		return UnitActionValidator.find_natal_domain(unit, game_state)
	return null

func _calculate_hex_distance(pos1, pos2) -> int:
	if UnitActionValidator:
		return UnitActionValidator.calculate_hex_distance(pos1, pos2)
	return 0

func _count_available_actions(unit, game_state: Dictionary) -> int:
	if UnitActionValidator:
		return UnitActionValidator.count_available_actions(unit, game_state)
	return 0

func _can_unit_train(unit, game_state: Dictionary) -> bool:
	if UnitActionValidator:
		return UnitActionValidator.can_unit_train(unit, game_state)
	return false

func _is_unit_at_domain_center(unit, game_state: Dictionary) -> bool:
	if UnitActionValidator:
		return UnitActionValidator.is_unit_at_domain_center(unit, game_state)
	return false

func _has_adjacent_enemies(unit, game_state: Dictionary) -> bool:
	if UnitActionValidator:
		return UnitActionValidator.has_adjacent_enemies(unit, game_state)
	return false

func _can_establish_domain(unit, game_state: Dictionary) -> bool:
	if UnitActionValidator:
		return UnitActionValidator.can_establish_domain(unit, game_state)
	return false

func _is_unit_away_from_border(unit, game_state: Dictionary) -> bool:
	if UnitActionValidator:
		return UnitActionValidator.is_unit_away_from_border(unit, game_state)
	return false

func _get_player_total_power(player, game_state: Dictionary) -> int:
	if UnitActionValidator:
		return UnitActionValidator.get_player_total_power(player, game_state)
	return 0

func _deduct_power_from_player(player, game_state: Dictionary, cost: int):
	if UnitActionValidator:
		UnitActionValidator.deduct_power_from_player(player, game_state, cost)

# Legacy methods (delegated to core)
func _show_settler_confirmation_dialog(unit):
	if selection_core and selection_core.has_method("show_settler_confirmation_dialog"):
		selection_core.show_settler_confirmation_dialog(unit)

# Additional utility methods
func update_movement_targets(game_state: Dictionary):
	if selection_core and selection_core.has_method("update_movement_targets"):
		selection_core.update_movement_targets(game_state)

func is_unit_selected(unit_id: int) -> bool:
	if selection_core and selection_core.has_method("is_unit_selected"):
		return selection_core.is_unit_selected(unit_id)
	return false

func get_selection_state() -> Dictionary:
	if selection_core and selection_core.has_method("get_selection_state"):
		return selection_core.get_selection_state()
	return {}

# Signal handler
func _on_unit_selected(unit_id: int):
	unit_selected.emit(unit_id)

# Cleanup method
func cleanup():
	if selection_core and selection_core.has_method("cleanup"):
		selection_core.cleanup()
	
	selection_core = null
	action_validator = null