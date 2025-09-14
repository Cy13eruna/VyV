## HexGridGameManager
## 
## Gerenciador principal do jogo que integra grid hexagonal com sistemas de gameplay
## Coordena seleção de domínios, interação, unidades e mecânicas de jogo
##
## @author: V&V Game Studio
## @version: 1.1 - UNIT SYSTEM INTEGRATED

extends Node2D
class_name HexGridGameManager

## Game events
signal game_initialized()
signal domain_interaction(domain_index: int, interaction_type: String)
signal unit_spawned(unit: Vagabond, position: Vector2)
signal unit_moved(unit: Vagabond, from_pos: Vector2, to_pos: Vector2)

## Core components
@export var hex_grid: HexGridV2Enhanced
var selection_system: DomainSelectionSystem
var visual_system: DomainVisualSystem
var unit_manager: UnitManager

## Game state
var is_game_active: bool = false
var current_player: int = 1
var game_turn: int = 1

## Input handling
var mouse_position: Vector2
var is_mouse_over_grid: bool = false

## Camera reference
@onready var camera: Camera2D = get_viewport().get_camera_2d()

## Initialize game manager
func _ready() -> void:
	_initialize_game_systems()
	_connect_signals()
	_start_game()

## Initialize all game systems
func _initialize_game_systems() -> void:
	# Find hex grid if not assigned
	if not hex_grid:
		hex_grid = $HexGridV2Enhanced
	
	if not hex_grid:
		push_error("HexGridGameManager: No hex grid found!")
		return
	
	# Wait for hex grid to be ready
	if not hex_grid.is_initialized:
		await hex_grid.grid_initialized
	
	# Initialize selection system
	selection_system = DomainSelectionSystem.new(hex_grid)
	
	# Initialize visual system
	visual_system = DomainVisualSystem.new(hex_grid, selection_system)
	
	# Initialize unit manager
	unit_manager = UnitManager.new()
	unit_manager.set_hex_grid_reference(hex_grid)
	unit_manager.set_domain_selection_reference(selection_system)
	add_child(unit_manager)
	
	print("HexGridGameManager: All systems initialized with unit management")

## Connect system signals
func _connect_signals() -> void:
	if selection_system:
		selection_system.domain_selected.connect(_on_domain_selected)
		selection_system.domain_deselected.connect(_on_domain_deselected)
		selection_system.domain_hovered.connect(_on_domain_hovered)
	
	if unit_manager:
		unit_manager.unit_spawned.connect(_on_unit_spawned)
		unit_manager.unit_moved.connect(_on_unit_moved)
		unit_manager.unit_destroyed.connect(_on_unit_destroyed)

## Start the game
func _start_game() -> void:
	is_game_active = true
	current_player = 1
	game_turn = 1
	
	print("HexGridGameManager: Game started - Player %d, Turn %d" % [current_player, game_turn])
	game_initialized.emit()

## Main game update
func _process(delta: float) -> void:
	if not is_game_active:
		return
	
	_update_mouse_position()
	_update_visual_systems(delta)

## Update mouse position relative to grid
func _update_mouse_position() -> void:
	mouse_position = get_global_mouse_position()
	
	# Check if mouse is over the grid area (basic bounds check)
	if hex_grid and hex_grid.cache:
		var hex_positions = hex_grid.cache.get_hex_positions()
		if not hex_positions.is_empty():
			var grid_bounds = hex_grid.geometry.calculate_bounding_rect(hex_positions)
			is_mouse_over_grid = grid_bounds.has_point(mouse_position)

## Update visual systems
func _update_visual_systems(delta: float) -> void:
	if visual_system:
		visual_system.update_visuals(delta)

## Handle input events
func _input(event: InputEvent) -> void:
	if not is_game_active:
		return
	
	if event is InputEventMouseButton and event.pressed:
		_handle_mouse_click(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventKey and event.pressed:
		_handle_keyboard_input(event)

## Handle mouse clicks
func _handle_mouse_click(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if selection_system:
				var clicked = selection_system.handle_mouse_click(mouse_position)
				if clicked:
					print("Domain clicked at %s" % mouse_position)
		
		MOUSE_BUTTON_RIGHT:
			# Right click to deselect
			if selection_system:
				selection_system.deselect_domain()

## Handle mouse motion
func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if selection_system and is_mouse_over_grid:
		selection_system.handle_mouse_hover(mouse_position)

## Handle keyboard input
func _handle_keyboard_input(event: InputEventKey) -> void:
	match event.keycode:
		KEY_SPACE:
			_next_turn()
		KEY_R:
			_restart_game()
		KEY_I:
			_print_game_info()
		KEY_S:
			_print_selection_stats()
		KEY_U:
			_spawn_test_unit()
		KEY_T:
			_test_unit_movement()
		KEY_C:
			_clear_all_units()

## Advance to next turn
func _next_turn() -> void:
	# Advance turn in unit manager
	if unit_manager:
		unit_manager.start_new_turn()
	
	# Update game state
	current_player = unit_manager.current_player if unit_manager else (current_player % 2) + 1
	game_turn = unit_manager.turn_number if unit_manager else game_turn + 1
	
	print("Turn advanced: Player %d, Turn %d" % [current_player, game_turn])

## Restart the game
func _restart_game() -> void:
	print("Game restarted")
	_start_game()

## Print game information
func _print_game_info() -> void:
	print("=== GAME INFO ===")
	print("Active: %s" % is_game_active)
	print("Player: %d" % current_player)
	print("Turn: %d" % game_turn)
	print("Mouse over grid: %s" % is_mouse_over_grid)
	
	if selection_system:
		var stats = selection_system.get_selection_stats()
		print("Domains: %d total, %d visible" % [stats.total_domains, stats.visible_domains])
		print("Selected: %d" % stats.selected_domain)
	
	if unit_manager:
		var unit_stats = unit_manager.get_unit_stats()
		print("Units: %d total" % unit_stats.total_units)
		print("Units by player: %s" % unit_stats.units_by_player)
		print("Units by state: %s" % unit_stats.units_by_state)

## Print selection statistics
func _print_selection_stats() -> void:
	if not selection_system or not visual_system:
		return
	
	print("=== SELECTION STATS ===")
	var selection_stats = selection_system.get_selection_stats()
	var visual_stats = visual_system.get_visual_stats()
	
	print("Selection: %s" % selection_stats)
	print("Visual states: %s" % visual_stats)

## Custom drawing for visual effects
func _draw() -> void:
	if not is_game_active or not visual_system:
		return
	
	# Render domain visual effects
	visual_system.render_domain_visuals(self)

## Force redraw when needed
func _force_redraw() -> void:
	queue_redraw()

## Domain selection event handlers
func _on_domain_selected(domain_index: int, hex_position: Vector2) -> void:
	print("Domain selected: #%d at %s" % [domain_index, hex_position])
	domain_interaction.emit(domain_index, "selected")
	
	# Try to spawn unit at selected domain (for testing)
	if unit_manager and Input.is_action_pressed("ui_accept"):
		_spawn_unit_at_domain(domain_index)
	
	_force_redraw()

func _on_domain_deselected(domain_index: int) -> void:
	print("Domain deselected: #%d" % domain_index)
	domain_interaction.emit(domain_index, "deselected")
	_force_redraw()

func _on_domain_hovered(domain_index: int, hex_position: Vector2) -> void:
	# Only print hover for debugging if needed
	# print("Domain hovered: #%d" % domain_index)
	_force_redraw()

## Get current game state
func get_game_state() -> Dictionary:
	return {
		"active": is_game_active,
		"player": current_player,
		"turn": game_turn,
		"mouse_over_grid": is_mouse_over_grid,
		"selected_domain": selection_system.get_selected_domain() if selection_system else -1
	}

## Enable/disable game
func set_game_active(active: bool) -> void:
	is_game_active = active
	if selection_system:
		selection_system.set_selection_enabled(active)

## Get domain information
func get_domain_info(domain_index: int) -> Dictionary:
	if selection_system:
		return selection_system.get_domain_info(domain_index)
	return {}

## Spawn unit at domain center
func _spawn_unit_at_domain(domain_index: int) -> void:
	if not unit_manager:
		return
	
	var unit = unit_manager.spawn_vagabond_at_domain(domain_index, current_player)
	if unit:
		print("Spawned Vagabond at domain %d for player %d" % [domain_index, current_player])
	else:
		print("Failed to spawn unit at domain %d" % domain_index)

## Test functions for unit system
func _spawn_test_unit() -> void:
	if not unit_manager or not hex_grid:
		return
	
	var star_positions = hex_grid.cache.get_dot_positions()
	if star_positions.is_empty():
		return
	
	# Spawn at random star position
	var random_index = randi() % star_positions.size()
	var unit = unit_manager.spawn_vagabond_at_position(star_positions[random_index], current_player)
	if unit:
		print("Test unit spawned at %s" % star_positions[random_index])

func _test_unit_movement() -> void:
	if not unit_manager:
		return
	
	var player_units = unit_manager.get_units_for_player(current_player)
	if player_units.is_empty():
		print("No units to move for player %d" % current_player)
		return
	
	# Move first unit to random nearby position
	var unit = player_units[0]
	var nearby_pos = unit_manager.get_nearest_star_position(unit.current_star_position + Vector2(100, 0))
	if unit_manager.move_unit(unit, nearby_pos):
		print("Test unit moved to %s" % nearby_pos)
	else:
		print("Failed to move test unit")

func _clear_all_units() -> void:
	if unit_manager:
		unit_manager.clear_all_units()
		print("All units cleared")

## Unit event handlers
func _on_unit_spawned(unit: Vagabond, position: Vector2) -> void:
	unit_spawned.emit(unit, position)
	print("GameManager: Unit spawned at %s" % position)

func _on_unit_moved(unit: Vagabond, from_pos: Vector2, to_pos: Vector2) -> void:
	unit_moved.emit(unit, from_pos, to_pos)
	print("GameManager: Unit moved from %s to %s" % [from_pos, to_pos])

func _on_unit_destroyed(unit: Vagabond, position: Vector2) -> void:
	print("GameManager: Unit destroyed at %s" % position)

## Clean up on exit
func _exit_tree() -> void:
	if selection_system:
		selection_system.domain_selected.disconnect(_on_domain_selected)
		selection_system.domain_deselected.disconnect(_on_domain_deselected)
		selection_system.domain_hovered.disconnect(_on_domain_hovered)
	
	if unit_manager:
		unit_manager.unit_spawned.disconnect(_on_unit_spawned)
		unit_manager.unit_moved.disconnect(_on_unit_moved)
		unit_manager.unit_destroyed.disconnect(_on_unit_destroyed)
	
	print("HexGridGameManager: Cleaned up with unit system")