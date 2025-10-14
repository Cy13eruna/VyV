# 🎮 V&V GAMEPLAY MANAGER (REFATORADO)
# Purpose: Coordenador principal para lógica de jogo
# Layer: Presentation Manager

extends Node
class_name GameplayManager

# Import modular components (loaded dynamically to avoid parse errors)
var GameplayManagerCore: GDScript
var GameplayInputHandler: GDScript

# Modular components
var core_manager
var input_handler

# References
var main_node: Node2D

# Signals (delegated from core)
signal game_over_occurred(winner)
signal turn_advanced()
signal unit_selected(unit_id: int)
signal unit_moved(unit_id: int, new_position)

func _ready():
	# Defer initialization to avoid class resolution issues
	call_deferred("initialize_components")

# Initialize modular components
func initialize_components():
	# Load classes dynamically
	GameplayManagerCore = load("res://presentation/managers/gameplay/gameplay_manager_core.gd")
	GameplayInputHandler = load("res://presentation/managers/gameplay/gameplay_input_handler.gd")
	
	# Create components
	core_manager = GameplayManagerCore.new()
	input_handler = GameplayInputHandler.new()
	
	# Initialize components if main_node is available
	if main_node:
		setup_components()

# Setup components with references
func setup_components():
	if core_manager and core_manager.has_method("initialize"):
		core_manager.initialize(main_node)
	
	if input_handler and input_handler.has_method("initialize"):
		input_handler.initialize(main_node, core_manager)
	
	# Connect signals from core
	if core_manager:
		if core_manager.has_signal("game_over_occurred"):
			core_manager.game_over_occurred.connect(_on_game_over_occurred)
		if core_manager.has_signal("turn_advanced"):
			core_manager.turn_advanced.connect(_on_turn_advanced)
		if core_manager.has_signal("unit_selected"):
			core_manager.unit_selected.connect(_on_unit_selected)
		if core_manager.has_signal("unit_moved"):
			core_manager.unit_moved.connect(_on_unit_moved)

# Set main node reference
func set_main_node(node: Node2D):
	main_node = node
	if core_manager and input_handler:
		setup_components()
	elif core_manager and core_manager.has_method("set_main_node"):
		core_manager.set_main_node(node)

# Game initialization and setup (delegated to core)
func setup_game():
	if core_manager and core_manager.has_method("setup_game"):
		core_manager.setup_game()

func initialize_game_with_count(player_count: int):
	if core_manager and core_manager.has_method("initialize_game_with_count"):
		core_manager.initialize_game_with_count(player_count)

# Input event handlers (delegated to input handler)
func on_point_clicked(point_id: int):
	if input_handler and input_handler.has_method("on_point_clicked"):
		input_handler.on_point_clicked(point_id)

# Game control actions (delegated to core)
func on_fog_toggle():
	if core_manager and core_manager.has_method("on_fog_toggle"):
		core_manager.on_fog_toggle()

func on_skip_turn():
	if core_manager and core_manager.has_method("on_skip_turn"):
		core_manager.on_skip_turn()

func reset_game():
	if core_manager and core_manager.has_method("reset_game"):
		core_manager.reset_game()

# Getters for external access (delegated to core)
func get_current_player():
	if core_manager and core_manager.has_method("get_current_player"):
		return core_manager.get_current_player()
	return null

func get_fog_settings():
	if core_manager and core_manager.has_method("get_fog_settings"):
		return core_manager.get_fog_settings()
	return {}

func get_game_state() -> Dictionary:
	if core_manager and core_manager.has_method("get_game_state"):
		return core_manager.get_game_state()
	return {}

func get_selected_unit_id() -> int:
	if core_manager and core_manager.has_method("get_selected_unit_id"):
		return core_manager.get_selected_unit_id()
	return -1

func get_valid_movement_targets() -> Array:
	if core_manager and core_manager.has_method("get_valid_movement_targets"):
		return core_manager.get_valid_movement_targets()
	return []

func is_game_over() -> bool:
	if core_manager and core_manager.has_method("is_game_over"):
		return core_manager.is_game_over()
	return false

func get_winner_player():
	if core_manager and core_manager.has_method("get_winner_player"):
		return core_manager.get_winner_player()
	return null

# Technology system access (delegated to core)
func get_player_technologies(player_id: int) -> Array:
	if core_manager and core_manager.has_method("get_player_technologies"):
		return core_manager.get_player_technologies(player_id)
	return []

func has_technology(player_id: int, tech_name: String) -> bool:
	if core_manager and core_manager.has_method("has_technology"):
		return core_manager.has_technology(player_id, tech_name)
	return false

# Get technology manager
func get_technology_manager():
	if core_manager and core_manager.has_method("get_technology_manager"):
		return core_manager.get_technology_manager()
	return null

# Clear all selections (called from empty area clicks)
func clear_selections():
	print("[GAMEPLAY_MANAGER] Clearing all selections")
	if core_manager and core_manager.has_method("clear_selections"):
		core_manager.clear_selections()

# Get unit manager (for external access)
func get_unit_manager():
	if core_manager and core_manager.has_method("get_unit_manager"):
		return core_manager.get_unit_manager()
	return null

# Legacy property access for compatibility
var unit_manager:
	get:
		return get_unit_manager()

# Additional input handling methods (delegated to input handler)
func handle_unit_selection(unit_id: int, game_state: Dictionary):
	if input_handler and input_handler.has_method("handle_unit_selection"):
		input_handler.handle_unit_selection(unit_id, game_state)

func handle_unit_movement(target_position, game_state: Dictionary):
	if input_handler and input_handler.has_method("handle_unit_movement"):
		input_handler.handle_unit_movement(target_position, game_state)

# Input validation methods (delegated to input handler)
func has_unit_at_position(position, game_state: Dictionary) -> bool:
	if input_handler and input_handler.has_method("has_unit_at_position"):
		return input_handler.has_unit_at_position(position, game_state)
	return false

func is_valid_movement_target(position, game_state: Dictionary) -> bool:
	if input_handler and input_handler.has_method("is_valid_movement_target"):
		return input_handler.is_valid_movement_target(position, game_state)
	return false

func is_clickable_domain_center(position, game_state: Dictionary) -> bool:
	if input_handler and input_handler.has_method("is_clickable_domain_center"):
		return input_handler.is_clickable_domain_center(position, game_state)
	return false

# Signal handlers
func _on_game_over_occurred(winner):
	game_over_occurred.emit(winner)

func _on_turn_advanced():
	turn_advanced.emit()

func _on_unit_selected(unit_id: int):
	unit_selected.emit(unit_id)

func _on_unit_moved(unit_id: int, new_position):
	unit_moved.emit(unit_id, new_position)

# Cleanup method to prevent memory leaks
func _exit_tree():
	if core_manager and core_manager.has_method("cleanup"):
		core_manager.cleanup()
	
	if input_handler and input_handler.has_method("cleanup"):
		input_handler.cleanup()
	
	core_manager = null
	input_handler = null
	main_node = null