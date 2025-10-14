# 🎮 GAME INITIALIZER (REFATORADO)
# Purpose: Coordenador principal para inicialização completa do jogo
# Layer: Application Services

extends RefCounted
class_name GameInitializer

# Import modular components
const GridGenerator = preload("res://application/services/game_initialization/grid_generator.gd")
const PlayerSetup = preload("res://application/services/game_initialization/player_setup.gd")

# Execute complete game initialization
static func execute(player_count: int = 2) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"game_state": {}
	}
	
	# Validate player count (only 2, 3, 4, 6 allowed)
	var valid_counts = [2, 3, 4, 6]
	if player_count not in valid_counts:
		result.message = "Invalid player count: %d. Valid counts: %s" % [player_count, str(valid_counts)]
		return result
	
	# Initialize game state structure
	var game_state = {
		"grid": {},
		"players": {},
		"units": {},
		"domains": {},
		"turn_data": {},
		"fog_of_war_enabled": true,
		"game_settings": {
			"player_count": player_count,
			"grid_radius": GridGenerator.calculate_grid_radius(player_count),
			"units_per_player": 1,
			"domains_per_player": 1
		}
	}
	
	# Generate grid using GridGenerator
	game_state.grid = GridGenerator.generate_hex_grid(player_count)
	
	# Validate grid generation
	if not GridGenerator.validate_grid_data(game_state.grid):
		result.message = "Failed to generate valid grid data"
		return result
	
	# Create players using PlayerSetup
	game_state.players = PlayerSetup.create_players(player_count)
	
	# Get spawn positions using GridGenerator
	var spawn_positions = GridGenerator.get_spawn_positions(game_state.grid, player_count)
	
	# Create units and domains using PlayerSetup
	var setup_result = PlayerSetup.create_units_and_domains(game_state.players, spawn_positions)
	
	if not setup_result.success:
		result.message = setup_result.message
		return result
	
	game_state.units = setup_result.units
	game_state.domains = setup_result.domains
	
	# Initialize turn system using PlayerSetup
	game_state.turn_data = PlayerSetup.initialize_turn_system(game_state.players, game_state.domains)
	
	# Validate complete game state
	if not validate_game_state(game_state):
		result.message = "Game state validation failed after initialization"
		return result
	
	result.success = true
	result.game_state = game_state
	return result

# Validate game state after initialization
static func validate_game_state(game_state: Dictionary) -> bool:
	# Check required components
	if not ("grid" in game_state and "players" in game_state and "units" in game_state and "domains" in game_state):
		return false
	
	# Validate grid
	if not GridGenerator.validate_grid_data(game_state.grid):
		return false
	
	# Validate player setup
	if not PlayerSetup.validate_player_setup(game_state.players, game_state.units, game_state.domains):
		return false
	
	# Check turn data exists
	if not ("turn_data" in game_state) or game_state.turn_data.is_empty():
		return false
	
	return true

# Get game settings summary
static func get_game_settings_summary(player_count: int) -> Dictionary:
	return {
		"player_count": player_count,
		"grid_radius": GridGenerator.calculate_grid_radius(player_count),
		"grid_diameter": GridGenerator.calculate_grid_radius(player_count) * 2 + 1,
		"units_per_player": 1,
		"domains_per_player": 1,
		"valid_player_counts": [2, 3, 4, 6]
	}