# 🎮 V&V GAME CONTROLLER
# Purpose: Handle game logic, state management, and coordination
# Layer: Presentation Controller

class_name GameController
extends RefCounted

# Preload complete ONION architecture
const GameInitializer = preload("res://application/services/game_initializer.gd")
const UnitMovementHandler = preload("res://application/use_cases/unit_movement_handler.gd")
const SkipTurnUseCase = preload("res://application/use_cases/skip_turn_clean.gd")
const FogOfWarService = preload("res://application/services/fog_of_war_service.gd")

const TurnService = preload("res://application/services/turn_service_clean.gd")
const MovementService = preload("res://application/services/movement_service.gd")
const GridService = preload("res://application/services/grid_service_clean.gd")

const GameState = preload("res://infrastructure/persistence/game_state_clean.gd")

# References
var main_node: Node2D
var ui_manager: UIManager
var camera_controller: CameraController

# Game state and systems
var game_state: Dictionary = {}
var selected_unit_id: int = -1
var valid_movement_targets: Array = []
var game_over: bool = false
var winner_player = null

# Power tracking for sprite updates
var previous_domain_powers: Dictionary = {}

# Debug system (simple)
var debug_enabled: bool = true

func set_references(main_node_ref: Node2D, ui_ref: UIManager, camera_ref: CameraController):
	main_node = main_node_ref
	ui_manager = ui_ref
	camera_controller = camera_ref

func setup_game():
	# Initialize unit movement tracker
	var UnitMovementTracker = load("res://core/value_objects/unit_movement_tracker.gd")
	if UnitMovementTracker:
		UnitMovementTracker.clear_all_directions()
	else:
		pass

func setup_final_game_with_count(player_count: int):
	# Initialize game with selected player count
	var init_result = GameInitializer.execute(player_count)
	
	if init_result.success:
		game_state = init_result.game_state
		
		# Validate game state
		var validation = GameState.validate_game_state(game_state)
		
		# Display comprehensive game summary
		var summary = GameState.get_game_state_summary(game_state)
		
		# Add terrain variety to edges
		enhance_terrain_variety()
		
		# Initialize power tracking
		check_power_changes()
		
		# Update skip button color after game initialization
		ui_manager.update_skip_button_color(game_state)
	else:
		game_state = GameState.create_empty_game_state()

func enhance_terrain_variety():
	# Add some terrain variety to make the game more interesting
	if "edges" in game_state.grid:
		var terrain_distribution = [6.0/12.0, 2.0/12.0, 2.0/12.0, 2.0/12.0]  # FIELD, FOREST, MOUNTAIN, WATER
		
		for edge_id in game_state.grid.edges:
			var edge = game_state.grid.edges[edge_id]
			var rand_val = randf()
			
			if rand_val < terrain_distribution[0]:
				edge.terrain_type = 0  # FIELD
			elif rand_val < terrain_distribution[0] + terrain_distribution[1]:
				edge.terrain_type = 1  # FOREST
			elif rand_val < terrain_distribution[0] + terrain_distribution[1] + terrain_distribution[2]:
				edge.terrain_type = 2  # MOUNTAIN
			else:
				edge.terrain_type = 3  # WATER

# Input event handlers
func on_point_clicked(point_id: int):
	if game_over:
		return
	
	# Get point position
	var point = game_state.grid.points.get(point_id)
	if not point:
		return
	
	var target_position = point.position
	
	# Check if there's a unit at this point
	var unit_at_point = find_unit_at_position(target_position)
	
	if unit_at_point != -1:
		# There's a unit at this point - check if it's own or enemy
		var unit = game_state.units[unit_at_point]
		var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
		
		if current_player and unit.owner_id == current_player.id:
			# Own unit - select it
			attempt_unit_selection(unit_at_point)
		else:
			# Enemy unit - try to move to this position (may trigger forest blocking)
			if selected_unit_id != -1:
				attempt_unit_movement(target_position)
	else:
		# No unit at point - try to move selected unit here
		if selected_unit_id != -1:
			# Check if target position is a valid movement target
			var is_valid_target = false
			for valid_target in valid_movement_targets:
				if valid_target.equals(target_position):
					is_valid_target = true
					break
			
			if is_valid_target:
				attempt_unit_movement(target_position)
			else:
				# Clicked outside valid targets - deselect unit
				clear_selection()
				main_node.queue_redraw()

func on_fog_toggle():
	var fog_result = ToggleFogUseCase.execute(game_state)
	if fog_result.success:
		pass
	
	# Clear selection when SPACE is pressed
	clear_selection()
	main_node.queue_redraw()

func on_skip_turn():
	var skip_result = SkipTurnUseCase.execute(game_state)
	if skip_result.success:
		if skip_result.game_over:
			game_over = true
			winner_player = skip_result.winner
			# Hide skip button when game is over
			if ui_manager.skip_turn_button:
				ui_manager.skip_turn_button.visible = false
		else:
			# Game continues - show turn transition
			ui_manager.show_turn_transition(game_state)
		# Check for power changes after turn advance (domains may generate power)
		check_power_changes()
	clear_selection()
	main_node.queue_redraw()

func on_quit_game():
	main_node.get_tree().quit()

# Handle new game button click
func on_new_game():
	# Reset game state
	game_state = {}
	selected_unit_id = -1
	valid_movement_targets.clear()
	game_over = false
	winner_player = null
	
	# Reset tracking variables
	previous_domain_powers.clear()
	
	# Reset unit movement tracking
	var UnitMovementTracker = load("res://core/value_objects/unit_movement_tracker.gd")
	if UnitMovementTracker:
		UnitMovementTracker.clear_all_directions()
	
	ui_manager.reset_to_menu()
	main_node.queue_redraw()

# Game logic
func select_unit(unit_id: int):
	selected_unit_id = unit_id
	var unit = game_state.units[unit_id]
	
	valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units, game_state)
	
	main_node.queue_redraw()

func attempt_unit_movement(target_position):
	if selected_unit_id == -1:
		return
	
	var move_result = UnitMovementHandler.execute(selected_unit_id, target_position, game_state)
	
	if move_result.success:
		if move_result.power_consumed:
			check_power_changes()  # Update sprites immediately after power consumption
		clear_selection()
	
	# Clear selection if unit is exhausted (regardless of success/failure)
	if move_result.get("unit_exhausted", false):
		clear_selection()
	
	main_node.queue_redraw()

func clear_selection():
	selected_unit_id = -1
	valid_movement_targets.clear()

# Find unit at specific position
func find_unit_at_position(position) -> int:
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.position.equals(position):
			return unit_id
	return -1

# Attempt to select a unit (only own units)
func attempt_unit_selection(unit_id: int) -> void:
	var unit = game_state.units.get(unit_id)
	if not unit:
		return
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player:
		return
	
	# Only allow selecting own units
	if unit.owner_id != current_player.id:
		return
	
	# Only allow selecting units with actions
	if not unit.can_move():
		return
	
	# Select the unit
	selected_unit_id = unit_id
	valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units, game_state)
	
	main_node.queue_redraw()

# Save/Load functionality
func save_game_state():
	var serialized = GameState.serialize_game_state(game_state)

func load_game_state():
	pass

# Check for power changes and update sprites accordingly
func check_power_changes():
	if not ("domains" in game_state):
		return
	
	var power_changed = false
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		var current_power = domain.get("power", 0)
		var previous_power = previous_domain_powers.get(domain_id, -999)  # Use -999 to force initial update
		
		if previous_power != current_power:
			power_changed = true
			previous_domain_powers[domain_id] = current_power
	
	if power_changed:
		main_node.queue_redraw()  # Force sprite update

func get_current_player():
	return TurnService.get_current_player(game_state.turn_data, game_state.players)

func get_fog_settings():
	var current_player = get_current_player()
	return ToggleFogUseCase.get_visibility_settings(game_state, current_player.id if current_player else 1)