# 🎮 GAME STATE MANAGER
# Purpose: Game state management, initialization, and coordination
# Layer: Presentation Manager

extends RefCounted
class_name GameStateManager

# Import dependencies
const GameInitializer = preload("res://application/services/game_initializer.gd")
const SkipTurnUseCase = preload("res://application/use_cases/skip_turn_clean.gd")
const FogOfWarService = preload("res://application/services/fog_of_war_service.gd")
const TurnService = preload("res://application/services/turn_service_clean.gd")
const GameState = preload("res://infrastructure/persistence/game_state_clean.gd")

# References
var main_node: Node2D

# Game state
var game_state: Dictionary = {}
var game_over: bool = false
var winner_player = null

# Power tracking for sprite updates
var previous_domain_powers: Dictionary = {}

# Signals
signal game_over_occurred(winner)
signal turn_advanced()

# Setup game
func setup_game():
	var UnitMovementTracker = load("res://core/value_objects/unit_movement_tracker.gd")
	if UnitMovementTracker:
		UnitMovementTracker.clear_all_directions()

# Initialize game with player count
func initialize_game_with_count(player_count: int):
	var init_result = GameInitializer.execute(player_count)
	
	if init_result.success:
		game_state = init_result.game_state
		var validation = GameState.validate_game_state(game_state)
		var summary = GameState.get_game_state_summary(game_state)
		enhance_terrain_variety()
		check_power_changes()
	else:
		game_state = GameState.create_empty_game_state()

# Enhance terrain variety
func enhance_terrain_variety():
	if "edges" in game_state.grid:
		var terrain_distribution = [6.0/12.0, 2.0/12.0, 2.0/12.0, 2.0/12.0]
		
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

# Handle fog toggle
func on_fog_toggle():
	var fog_result = FogOfWarService.execute(game_state)
	main_node.queue_redraw()

# Handle skip turn
func on_skip_turn():
	var skip_result = SkipTurnUseCase.execute(game_state)
	if skip_result.success:
		if skip_result.game_over:
			game_over = true
			winner_player = skip_result.winner
			game_over_occurred.emit(winner_player)
		else:
			turn_advanced.emit()
		check_power_changes()
	main_node.queue_redraw()

# Reset game
func reset_game():
	game_state = {}
	game_over = false
	winner_player = null
	previous_domain_powers.clear()
	
	var UnitMovementTracker = load("res://core/value_objects/unit_movement_tracker.gd")
	if UnitMovementTracker:
		UnitMovementTracker.clear_all_directions()

# Check for power changes
func check_power_changes():
	if not ("domains" in game_state):
		return
	
	var power_changed = false
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		var current_power = domain.get("power", 0)
		var previous_power = previous_domain_powers.get(domain_id, -999)
		
		if previous_power != current_power:
			power_changed = true
			previous_domain_powers[domain_id] = current_power
	
	if power_changed:
		main_node.queue_redraw()

# Get current player
func get_current_player():
	return TurnService.get_current_player(game_state.turn_data, game_state.players)

# Get fog settings
func get_fog_settings():
	var current_player = get_current_player()
	return FogOfWarService.get_visibility_settings(game_state, current_player.id if current_player else 1)

# Getters for external access
func get_game_state() -> Dictionary:
	return game_state

func is_game_over() -> bool:
	return game_over

func get_winner_player():
	return winner_player