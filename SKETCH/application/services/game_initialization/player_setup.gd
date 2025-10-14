# 👥 PLAYER SETUP
# Purpose: Configure initial players, units and domains
# Layer: Application Services - Game Initialization

extends RefCounted
class_name PlayerSetup

# Preload clean classes
const Unit = preload("res://core/entities/unit_clean.gd")
const Player = preload("res://core/entities/player_clean.gd")
const TurnService = preload("res://application/services/turn_service_clean.gd")

# Import the new Iberian syllable generator for name generation
const IberianSyllableGenerator = preload("res://core/value_objects/iberian_syllable_generator.gd")

# Create players with random colors
static func create_players(player_count: int) -> Dictionary:
	var players = {}
	var used_colors = []
	
	for i in range(player_count):
		var player_id = i + 1
		var player_name = "Player %d" % player_id
		var player_color = Player.get_random_color(used_colors)
		used_colors.append(player_color)
		var player = Player.new(player_id, player_name, player_color)
		players[player_id] = player
	
	return players

# Create units and domains for all players
static func create_units_and_domains(players: Dictionary, spawn_positions: Array) -> Dictionary:
	var result = {
		"units": {},
		"domains": {},
		"success": true,
		"message": ""
	}
	
	var unit_id_counter = 1
	var domain_id_counter = 1
	
	for player_id in players.keys():
		var player = players[player_id]
		
		if spawn_positions.size() >= player_id:
			var spawn_pos = spawn_positions[player_id - 1]
			
			# Create temporary game state for name generation
			var temp_game_state = {
				"units": result.units,
				"domains": result.domains
			}
			
			# Get next available initial using the new system
			var chosen_initial = IberianSyllableGenerator.get_next_available_initial(temp_game_state)
			
			# Generate domain name using the new system
			var domain_name = IberianSyllableGenerator.generate_domain_name(chosen_initial, temp_game_state)
			
			# Create domain first (needed for unit name generation)
			var domain_data = {
				"id": domain_id_counter,
				"owner_id": player_id,
				"name": domain_name,
				"initial": chosen_initial,
				"center_position": spawn_pos,
				"power": 2,  # All domains start with 2 power
				"level": 1,  # Start at level I
				"is_occupied": false,
				"occupied_by_player": -1
			}
			result.domains[domain_id_counter] = domain_data
			
			# Update temp game state with new domain
			temp_game_state.domains[domain_id_counter] = domain_data
			
			# Generate unit name using the new system (based on domain)
			var unit_name = IberianSyllableGenerator.generate_unit_name_for_domain(domain_data, temp_game_state)
			
			var unit = Unit.new(unit_id_counter, player_id, unit_name, spawn_pos)
			result.units[unit_id_counter] = unit
			player.add_unit(unit_id_counter)
			unit_id_counter += 1
			
			# Add domain to player (domain was already created above)
			player.add_domain(domain_id_counter)
			domain_id_counter += 1
	
	return result

# Initialize turn system and apply initial bonuses
static func initialize_turn_system(players: Dictionary, domains: Dictionary) -> Dictionary:
	# Initialize turn system using TurnService
	var turn_data = TurnService.initialize_turn_system(players)
	
	# Apply initial production bonus only to first player for consistency
	var first_player = players[turn_data.current_player_id]
	TurnService._restore_player_power(first_player, domains)
	
	return turn_data



# Helper function to convert color to name for logging
static func color_to_name(color: Color) -> String:
	if color == Color(0.5, 0.0, 1.0):
		return "Roxo"
	elif color == Color.RED:
		return "Vermelho"
	elif color == Color.MAGENTA:
		return "Magenta"
	elif color == Color.YELLOW:
		return "Amarelo"
	elif color == Color.CYAN:
		return "Ciano"
	elif color == Color.GREEN:
		return "Verde"
	else:
		return "Desconhecido"

# Validate player setup after creation
static func validate_player_setup(players: Dictionary, units: Dictionary, domains: Dictionary) -> bool:
	# Check players exist
	if players.size() == 0:
		return false
	
	# Check units exist
	if units.size() == 0:
		return false
	
	# Check domains exist
	if domains.size() == 0:
		return false
	
	# Check each player has at least one unit and one domain
	for player_id in players.keys():
		var player = players[player_id]
		if player.unit_ids.size() == 0:
			return false
		if player.domain_ids.size() == 0:
			return false
	
	return true