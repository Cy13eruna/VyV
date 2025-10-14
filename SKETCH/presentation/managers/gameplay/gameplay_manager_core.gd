# 🎮 GAMEPLAY MANAGER CORE
# Purpose: Initialize and coordinate specialized managers
# Layer: Presentation Managers - Gameplay Core

extends RefCounted
class_name GameplayManagerCore

# Specialized managers (loaded dynamically to avoid parse errors)
var DialogManager: GDScript
var TechnologyManager: GDScript
var DomainManager: GDScript
var UnitManager: GDScript
var GameStateManager: GDScript

# References
var main_node: Node2D

# Specialized manager instances
var dialog_manager
var technology_manager
var domain_manager
var unit_manager
var game_state_manager

# Signals (forwarded from managers)
signal game_over_occurred(winner)
signal turn_advanced()
signal unit_selected(unit_id: int)
signal unit_moved(unit_id: int, new_position)

# Initialize with main node reference
func initialize(main_node_ref: Node2D):
	main_node = main_node_ref
	initialize_managers()

# Initialize all specialized managers
func initialize_managers():
	# Load manager classes dynamically
	DialogManager = load("res://presentation/managers/dialog/dialog_manager.gd")
	TechnologyManager = load("res://presentation/managers/dialog/technology_manager.gd")
	DomainManager = load("res://presentation/managers/domain/domain_manager.gd")
	UnitManager = load("res://presentation/managers/unit/unit_manager.gd")
	GameStateManager = load("res://presentation/managers/game/game_state_manager.gd")
	
	# Initialize managers in correct order
	dialog_manager = DialogManager.new()
	dialog_manager.main_node = main_node
	
	technology_manager = TechnologyManager.new()
	technology_manager.main_node = main_node
	technology_manager.dialog_manager = dialog_manager
	
	domain_manager = DomainManager.new()
	domain_manager.initialize(main_node, dialog_manager, technology_manager)
	
	unit_manager = UnitManager.new()
	unit_manager.initialize_with_references(main_node, dialog_manager)
	
	game_state_manager = GameStateManager.new()
	game_state_manager.main_node = main_node
	
	# Set cross-references to avoid circular dependencies
	domain_manager.set_unit_manager(unit_manager)
	unit_manager.set_domain_manager(domain_manager)
	unit_manager.set_technology_manager(technology_manager)
	
	# Connect manager signals
	game_state_manager.game_over_occurred.connect(_on_game_over_occurred)
	game_state_manager.turn_advanced.connect(_on_turn_advanced)
	unit_manager.unit_selected.connect(_on_unit_selected)
	unit_manager.unit_moved.connect(_on_unit_moved)

# Set main node reference for all managers
func set_main_node(node: Node2D):
	main_node = node
	if dialog_manager:
		dialog_manager.main_node = node
	if technology_manager:
		technology_manager.main_node = node
	if domain_manager:
		domain_manager.main_node = node
	if unit_manager:
		unit_manager.main_node = node
	if game_state_manager:
		game_state_manager.main_node = node

# Game initialization and setup
func setup_game():
	if not game_state_manager:
		return
	game_state_manager.setup_game()

func initialize_game_with_count(player_count: int):
	if not game_state_manager or not unit_manager:
		return
	game_state_manager.initialize_game_with_count(player_count)
	# Update unit manager with game state reference
	unit_manager.set_game_state_reference(game_state_manager.get_game_state())

# Game control actions
func on_fog_toggle():
	if not game_state_manager or not unit_manager:
		return
	game_state_manager.on_fog_toggle()
	unit_manager.clear_selection()

func on_skip_turn():
	if not game_state_manager or not unit_manager:
		return
	game_state_manager.on_skip_turn()
	unit_manager.clear_selection()

func reset_game():
	if not game_state_manager or not unit_manager or not technology_manager:
		return
	game_state_manager.reset_game()
	unit_manager.clear_selection()
	# Reset technology manager
	technology_manager.player_technologies.clear()

# Signal handlers
func _on_game_over_occurred(winner):
	game_over_occurred.emit(winner)

func _on_turn_advanced():
	turn_advanced.emit()

func _on_unit_selected(unit_id: int):
	unit_selected.emit(unit_id)

func _on_unit_moved(unit_id: int, new_position):
	unit_moved.emit(unit_id, new_position)

# Getters for external access (maintaining compatibility)
func get_current_player():
	if not game_state_manager:
		return null
	return game_state_manager.get_current_player()

func get_fog_settings():
	if not game_state_manager:
		return {}
	return game_state_manager.get_fog_settings()

func get_game_state() -> Dictionary:
	if not game_state_manager:
		return {}
	return game_state_manager.get_game_state()

func get_selected_unit_id() -> int:
	if not unit_manager:
		return -1
	return unit_manager.get_selected_unit_id()

func get_valid_movement_targets() -> Array:
	if not unit_manager:
		return []
	return unit_manager.get_valid_movement_targets()

func is_game_over() -> bool:
	if not game_state_manager:
		return false
	return game_state_manager.is_game_over()

func get_winner_player():
	if not game_state_manager:
		return null
	return game_state_manager.get_winner_player()

# Technology system access
func get_player_technologies(player_id: int) -> Array:
	if not technology_manager:
		return []
	return technology_manager.get_player_technologies(player_id)

func has_technology(player_id: int, tech_name: String) -> bool:
	if not technology_manager:
		return false
	return technology_manager.has_technology(player_id, tech_name)

# Get technology manager
func get_technology_manager():
	return technology_manager

# Clear all selections
func clear_selections():
	print("[GAMEPLAY_CORE] Clearing all selections")
	if unit_manager and unit_manager.has_method("clear_selection"):
		unit_manager.clear_selection()

# Get managers for external access
func get_unit_manager():
	return unit_manager

func get_domain_manager():
	return domain_manager

func get_game_state_manager():
	return game_state_manager

# Cleanup method to prevent memory leaks
func cleanup():
	# Disconnect all signals to prevent reference cycles
	if game_state_manager:
		if game_state_manager.is_connected("game_over_occurred", _on_game_over_occurred):
			game_state_manager.disconnect("game_over_occurred", _on_game_over_occurred)
		if game_state_manager.is_connected("turn_advanced", _on_turn_advanced):
			game_state_manager.disconnect("turn_advanced", _on_turn_advanced)
	
	if unit_manager:
		if unit_manager.is_connected("unit_selected", _on_unit_selected):
			unit_manager.disconnect("unit_selected", _on_unit_selected)
		if unit_manager.is_connected("unit_moved", _on_unit_moved):
			unit_manager.disconnect("unit_moved", _on_unit_moved)
		# Cleanup unit manager
		if unit_manager.has_method("cleanup"):
			unit_manager.cleanup()
	
	# Cleanup other managers if they have cleanup methods
	if technology_manager and technology_manager.has_method("cleanup"):
		technology_manager.cleanup()
	
	if domain_manager and domain_manager.has_method("cleanup"):
		domain_manager.cleanup()
	
	if game_state_manager and game_state_manager.has_method("cleanup"):
		game_state_manager.cleanup()
	
	# Clear manager references
	dialog_manager = null
	technology_manager = null
	domain_manager = null
	unit_manager = null
	game_state_manager = null
	main_node = null