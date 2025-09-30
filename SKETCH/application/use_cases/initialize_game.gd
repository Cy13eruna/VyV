# 🎮 INITIALIZE GAME USE CASE
# Purpose: Orchestrate complete game initialization
# Layer: Application/UseCases
# Dependencies: Services only

class_name InitializeGameUseCase
extends RefCounted

static func execute(player_count: int = 2) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"game_state": {}
	}
	
	# Validate player count
	if player_count < GameConstants.MIN_PLAYERS or player_count > GameConstants.MAX_PLAYERS:
		result.message = "Invalid player count: %d" % player_count
		return result
	
	# Initialize game state
	var game_state = {
		"grid": {},
		"players": {},
		"units": {},
		"domains": {},
		"turn_data": {},
		"fog_of_war_enabled": true
	}
	
	# Generate grid
	game_state.grid = GridService.generate_hex_grid()
	
	# Generate terrain
	var terrain_result = GenerateTerrainUseCase.execute(game_state)
	if not terrain_result.success:
		result.message = "Failed to generate terrain: " + terrain_result.message
		return result
	
	# Create players
	for i in range(player_count):
		var player_id = i + 1
		var player_name = "Player %d" % player_id
		var player_color = Player.get_default_color(player_id)
		var player = Player.new(player_id, player_name, player_color)
		game_state.players[player_id] = player
	
	# Get spawn positions
	var spawn_positions = DomainService.get_spawn_positions(game_state.grid, game_state.domains)
	
	# Create domains and units for each player
	var domain_id_counter = 1
	var unit_id_counter = 1
	
	for player_id in game_state.players:
		if spawn_positions.size() >= player_id:
			var spawn_pos = spawn_positions[player_id - 1]
			
			# Create domain
			var domain = DomainService.create_domain(domain_id_counter, player_id, spawn_pos, game_state.players)
			game_state.domains[domain_id_counter] = domain
			domain_id_counter += 1
			
			# Create unit
			var unit_name = _generate_unit_name(domain.name)
			var unit = Unit.new(unit_id_counter, player_id, unit_name, spawn_pos)
			game_state.units[unit_id_counter] = unit
			game_state.players[player_id].add_unit(unit_id_counter)
			unit_id_counter += 1
	
	# Initialize turn system
	game_state.turn_data = TurnService.initialize_turn_system(game_state.players)
	
	result.success = true
	result.game_state = game_state
	result.message = "Game initialized with %d players" % player_count
	
	return result

static func _generate_unit_name(domain_name: String) -> String:
	var initial = domain_name.substr(0, 1)
	if initial in GameConstants.UNIT_NAMES:
		var names = GameConstants.UNIT_NAMES[initial]
		return names[randi() % names.size()]
	return "Unit"