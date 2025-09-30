# 🎮 INITIALIZE GAME USE CASE (CLEAN)
# Purpose: Complete game initialization orchestration
# Layer: Application/UseCases
# Dependencies: Clean services and core entities

extends RefCounted

# Preload clean classes
const HexCoordinate = preload("res://core/value_objects/hex_coordinate_clean.gd")
const Position = preload("res://core/value_objects/position_clean.gd")
const Unit = preload("res://core/entities/unit_clean.gd")
const Player = preload("res://core/entities/player_clean.gd")

# Preload clean services
const GridService = preload("res://application/services/grid_service_clean.gd")
const TurnService = preload("res://application/services/turn_service_clean.gd")

# Execute complete game initialization
static func execute(player_count: int = 2) -> Dictionary:
	print("    InitializeGameUseCase.execute() starting with player_count: ", player_count)
	var result = {
		"success": false,
		"message": "",
		"game_state": {}
	}
	
	print("    Validating player count...")
	# Validate player count
	if player_count < 2 or player_count > 8:
		result.message = "Invalid player count: %d" % player_count
		print("    ERROR: Invalid player count")
		return result
	print("    Player count valid")
	
	print("    Initializing game state...")
	# Initialize game state
	var game_state = {
		"grid": {},
		"players": {},
		"units": {},
		"domains": {},
		"turn_data": {},
		"fog_of_war_enabled": true,
		"game_settings": {
			"player_count": player_count,
			"grid_radius": 3,
			"units_per_player": 1,
			"domains_per_player": 1
		}
	}
	print("    Game state created")
	
	print("    Generating grid...")
	# Generate grid using GridService
	game_state.grid = GridService.generate_hex_grid(3)
	print("    Grid generated successfully")
	
	print("    Creating players...")
	# Create players
	for i in range(player_count):
		var player_id = i + 1
		var player_name = "Player %d" % player_id
		var player_color = Player.get_default_color(player_id)
		var player = Player.new(player_id, player_name, player_color)
		game_state.players[player_id] = player
	print("    Players created")
	
	print("    Getting spawn positions...")
	# Get spawn positions (corner points for now)
	var spawn_positions = _get_spawn_positions(game_state.grid, player_count)
	print("    Spawn positions found: ", spawn_positions.size())
	
	print("    Creating units and domains...")
	# Create units and domains for each player
	var unit_id_counter = 1
	var domain_id_counter = 1
	
	for player_id in range(1, player_count + 1):
		var player = game_state.players[player_id]
		
		if spawn_positions.size() >= player_id:
			var spawn_pos = spawn_positions[player_id - 1]
			
			# Create unit
			var unit_name = "Unit%d" % unit_id_counter
			var unit = Unit.new(unit_id_counter, player_id, unit_name, spawn_pos)
			game_state.units[unit_id_counter] = unit
			player.add_unit(unit_id_counter)
			unit_id_counter += 1
			
			# Create domain (placeholder for now)
			var domain_data = {
				"id": domain_id_counter,
				"owner_id": player_id,
				"name": "Domain%d" % domain_id_counter,
				"center_position": spawn_pos,
				"power": 3,
				"is_occupied": false,
				"occupied_by_player": -1
			}
			game_state.domains[domain_id_counter] = domain_data
			player.add_domain(domain_id_counter)
			domain_id_counter += 1
	print("    Units and domains created")
	
	print("    Initializing turn system...")
	# Initialize turn system using TurnService
	game_state.turn_data = TurnService.initialize_turn_system(game_state.players)
	print("    Turn system initialized")
	
	result.success = true
	result.game_state = game_state
	result.message = "Game initialized with %d players" % player_count
	
	print("    InitializeGameUseCase completed successfully")
	return result

# Get spawn positions for players
static func _get_spawn_positions(grid_data: Dictionary, player_count: int) -> Array:
	var spawn_positions = []
	
	# Get all corner points (they make good spawn positions)
	var corner_points = []
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.is_corner:
			corner_points.append(point.position)
	
	# If we have enough corners, use them
	if corner_points.size() >= player_count:
		for i in range(player_count):
			spawn_positions.append(corner_points[i])
	else:
		# Fallback: use any points with good spacing
		var all_points = []
		for point_id in grid_data.points:
			var point = grid_data.points[point_id]
			all_points.append(point.position)
		
		# Simple spacing algorithm
		var step = max(1, all_points.size() / player_count)
		for i in range(player_count):
			var index = i * step
			if index < all_points.size():
				spawn_positions.append(all_points[index])
	
	return spawn_positions

# Generate terrain variation (future implementation)
static func _generate_terrain(grid_data: Dictionary) -> bool:
	# Future: Add terrain variety to edges
	# For now, all terrain is FIELD (type 0)
	return true

# Validate game state after initialization
static func _validate_game_state(game_state: Dictionary) -> bool:
	# Check required components
	if not ("grid" in game_state and "players" in game_state and "units" in game_state):
		return false
	
	# Check grid has points
	if game_state.grid.points.size() == 0:
		return false
	
	# Check players exist
	if game_state.players.size() == 0:
		return false
	
	# Check units exist
	if game_state.units.size() == 0:
		return false
	
	return true