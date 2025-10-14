# 👥 UNIT MANAGER (REFACTORED)
# Purpose: Main coordinator for unit management
# Layer: Presentation Manager

extends RefCounted
class_name UnitManager

# Import dependencies
const ActionDialogManager = preload("res://presentation/managers/dialog/action_dialog_manager.gd")

# Import sub-managers
const UnitSelectionManager = preload("res://presentation/managers/unit/unit_selection_manager.gd")
const UnitMovementManager = preload("res://presentation/managers/unit/unit_movement_manager.gd")
const UnitSpawningManager = preload("res://presentation/managers/unit/unit_spawning_manager.gd")
const UnitSettlerManager = preload("res://presentation/managers/unit/unit_settler_manager.gd")
const UnitGridUtils = preload("res://presentation/managers/unit/unit_grid_utils.gd")
const UnitNameGenerator = preload("res://presentation/managers/unit/unit_name_generator.gd")
const UnitPowerManager = preload("res://presentation/managers/unit/unit_power_manager.gd")

# References
var main_node: Node2D
var dialog_manager
var domain_manager  # Forward reference, will be set later
var technology_manager  # Forward reference, will be set later
var action_dialog_manager: ActionDialogManager

# Sub-managers
var selection_manager: UnitSelectionManager
var movement_manager: UnitMovementManager
var spawning_manager: UnitSpawningManager
var settler_manager: UnitSettlerManager

# Signals (delegated from sub-managers)
signal unit_selected(unit_id: int)
signal unit_moved(unit_id: int, new_position)

# Constructor - auto-initialize sub-managers
func _init():
	# Create sub-managers
	selection_manager = UnitSelectionManager.new()
	movement_manager = UnitMovementManager.new()
	spawning_manager = UnitSpawningManager.new()
	settler_manager = UnitSettlerManager.new()

# Initialize with main node and dialog manager (called from gameplay_manager)
func initialize_with_references(main_node_ref: Node2D, dialog_manager_ref):
	main_node = main_node_ref
	dialog_manager = dialog_manager_ref
	
	# Initialize sub-managers
	selection_manager.initialize(main_node, null)  # action_dialog_manager set later
	movement_manager.initialize(main_node, selection_manager)
	
	# Connect signals
	selection_manager.unit_selected.connect(_on_unit_selected)
	movement_manager.unit_moved.connect(_on_unit_moved)

# Set domain manager reference (to avoid circular dependency)
func set_domain_manager(domain_manager_ref):
	domain_manager = domain_manager_ref

# Set technology manager reference
func set_technology_manager(tech_manager):
	technology_manager = tech_manager
	if selection_manager:
		selection_manager.set_technology_manager(tech_manager)
	
	# Initialize action dialog manager when all dependencies are set
	if not action_dialog_manager and main_node and dialog_manager and technology_manager:
		print("[UNIT_MANAGER] Initializing action_dialog_manager")
		action_dialog_manager = ActionDialogManager.new()
		action_dialog_manager.initialize(main_node, dialog_manager, self, technology_manager)
		# Update selection manager with action dialog manager
		# Note: In refactored version, action_dialog_manager is handled internally
		if selection_manager.has_method("_set_action_dialog_manager"):
			selection_manager._set_action_dialog_manager(action_dialog_manager)
		else:
			# Fallback: try to access selection_core directly
			if selection_manager.selection_core:
				selection_manager.selection_core.action_dialog_manager = action_dialog_manager
		print("[UNIT_MANAGER] action_dialog_manager initialized successfully")

# Set game state reference for managers that need it
func set_game_state_reference(game_state: Dictionary):
	spawning_manager.set_game_state_reference(game_state)
	settler_manager.set_game_state_reference(game_state)

# Delegate to UnitGridUtils
func find_unit_at_position(position, game_state: Dictionary) -> int:
	return UnitGridUtils.find_unit_at_position(position, game_state)

# Delegate to selection manager
func attempt_unit_selection(unit_id: int, game_state: Dictionary) -> void:
	selection_manager.attempt_unit_selection(unit_id, game_state, domain_manager)

# Delegate to movement manager
func attempt_unit_movement(target_position, game_state: Dictionary):
	movement_manager.attempt_unit_movement(target_position, game_state)

# Delegate to selection manager
func clear_selection():
	selection_manager.clear_selection()

# Delegate to spawning manager
func spawn_unit_at_domain_center(domain):
	spawning_manager.spawn_unit_at_domain_center(domain)

# Delegate to selection manager
func get_selected_unit_id() -> int:
	return selection_manager.get_selected_unit_id()

func get_valid_movement_targets() -> Array:
	return selection_manager.get_valid_movement_targets()

# Delegate to UnitPowerManager
func _unit_has_power_to_move(unit, game_state: Dictionary) -> bool:
	return UnitPowerManager.unit_has_power_to_move(unit, game_state, domain_manager)

# Set unit selection for movement (API for ActionDialogManager)
func _set_unit_selection_for_movement(unit, game_state: Dictionary):
	if selection_manager:
		# Use the public API instead of direct access
		selection_manager.attempt_unit_selection(unit.id, game_state, domain_manager)
		# The selection manager will handle movement targets and signals internally

# Delegate to settler manager
func _can_unit_use_settler(unit, game_state: Dictionary) -> bool:
	return settler_manager.can_unit_use_settler(unit, game_state)

# Execute settler action (API for ActionDialogManager)
func execute_settler_action(unit):
	if settler_manager:
		settler_manager.execute_settler_action(unit)

# Signal handlers
func _on_unit_selected(unit_id: int):
	unit_selected.emit(unit_id)

func _on_unit_moved(unit_id: int, new_position):
	unit_moved.emit(unit_id, new_position)

# Check if player has specific technology (API for sub-managers)
func has_player_technology(player_id: int, tech_name: String) -> bool:
	if technology_manager:
		return technology_manager.has_technology(player_id, tech_name)
	return false

# Cleanup method to prevent memory leaks
func cleanup():
	# Clear action dialog manager
	if action_dialog_manager:
		action_dialog_manager.cleanup()
		action_dialog_manager = null
	
	# Clear sub-managers
	if selection_manager:
		selection_manager.cleanup()
		selection_manager = null
	
	if movement_manager:
		movement_manager.cleanup()
		movement_manager = null
	
	if spawning_manager:
		spawning_manager.cleanup()
		spawning_manager = null
	
	if settler_manager:
		settler_manager.cleanup()
		settler_manager = null
	
	# Clear all references
	main_node = null
	dialog_manager = null
	domain_manager = null
	technology_manager = null