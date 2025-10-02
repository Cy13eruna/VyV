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
	var used_initials = []  # Track used domain initials
	
	# Domain name pools by initial
	var domain_names = {
		"A": ["Avalon", "Arcadia", "Astoria", "Aurora", "Atlantis"],
		"B": ["Babylon", "Britannia", "Byzantium", "Bohemia", "Bavaria"],
		"C": ["Camelot", "Carthage", "Castile", "Crimea", "Cyprus"],
		"D": ["Damascus", "Delphi", "Dresden", "Dublin", "Dalmatia"],
		"E": ["Eldorado", "Ephesus", "Estonia", "Ethiopia", "Elysium"],
		"F": ["Florence", "Flanders", "Francia", "Frisia", "Phoenicia"],
		"G": ["Galicia", "Geneva", "Georgia", "Granada", "Gaul"],
		"H": ["Helvetia", "Hibernia", "Holstein", "Hungary", "Hispania"],
		"I": ["Iberia", "Iceland", "Illyria", "India", "Ionia"],
		"J": ["Jerusalem", "Judea", "Jamaica", "Japan", "Java"],
		"K": ["Kiev", "Kashmir", "Korea", "Kurdistan", "Kenya"],
		"L": ["Lombardy", "Lusitania", "Lithuania", "Latvia", "Libya"],
		"M": ["Macedonia", "Mesopotamia", "Morocco", "Malta", "Moldavia"],
		"N": ["Normandy", "Nubia", "Naples", "Norway", "Navarre"],
		"O": ["Olympia", "Orleans", "Ostrogoth", "Occitania", "Oman"],
		"P": ["Persia", "Prussia", "Portugal", "Poland", "Phoenicia"],
		"Q": ["Quebec", "Qin", "Qatar", "Quito", "Queensland"],
		"R": ["Rome", "Rus", "Rhodesia", "Romania", "Rajasthan"],
		"S": ["Sparta", "Saxony", "Sicily", "Serbia", "Siam"],
		"T": ["Troy", "Tuscany", "Thrace", "Tibet", "Tunisia"],
		"U": ["Ukraine", "Umbria", "Ulster", "Uruk", "Uzbekistan"],
		"V": ["Venice", "Valencia", "Visigoths", "Vietnam", "Vallachia"],
		"W": ["Wales", "Westphalia", "Wurttemberg", "Wallachia", "Wessex"],
		"X": ["Xanadu", "Xinjiang", "Xian", "Xerxes", "Xhosa"],
		"Y": ["York", "Yemen", "Yukon", "Yugoslavia", "Yucatan"],
		"Z": ["Zion", "Zanzibar", "Zimbabwe", "Zulu", "Zurich"]
	}
	
	# Unit name pools by initial (matching domain initials)
	var unit_names = {
		"A": ["Arthur", "Alexander", "Adrian", "Albert", "Antonio"],
		"B": ["Baldwin", "Bernard", "Boris", "Bruno", "Bartholomew"],
		"C": ["Constantine", "Charles", "Christopher", "Casimir", "Cyrus"],
		"D": ["Dimitri", "David", "Daniel", "Diego", "Dominic"],
		"E": ["Edmund", "Edward", "Eugene", "Emilio", "Erasmus"],
		"F": ["Frederick", "Ferdinand", "Francis", "Felix", "Fabio"],
		"G": ["Gregory", "Gabriel", "George", "Gustavo", "Godfrey"],
		"H": ["Henry", "Harold", "Hugo", "Hector", "Humphrey"],
		"I": ["Ivan", "Isaac", "Ignatius", "Ibrahim", "Isidore"],
		"J": ["James", "John", "Joseph", "Julian", "Joachim"],
		"K": ["Kenneth", "Kevin", "Klaus", "Konstantin", "Khalil"],
		"L": ["Louis", "Leopold", "Lorenzo", "Lucian", "Lancelot"],
		"M": ["Marcus", "Michael", "Manuel", "Maximilian", "Matthias"],
		"N": ["Nicholas", "Nathan", "Neville", "Nestor", "Napoleon"],
		"O": ["Oliver", "Oscar", "Octavius", "Orlando", "Oswald"],
		"P": ["Peter", "Paul", "Philip", "Patrick", "Perseus"],
		"Q": ["Quentin", "Quincy", "Quintus", "Qasim", "Quirin"],
		"R": ["Richard", "Robert", "Roland", "Rodrigo", "Raphael"],
		"S": ["Stephen", "Sebastian", "Samuel", "Sergio", "Solomon"],
		"T": ["Thomas", "Theodore", "Timothy", "Tristan", "Thaddeus"],
		"U": ["Ulrich", "Umberto", "Ugo", "Uriel", "Ulysses"],
		"V": ["Victor", "Vincent", "Vladimir", "Valentino", "Virgil"],
		"W": ["William", "Walter", "Winston", "Wolfgang", "Wilfred"],
		"X": ["Xavier", "Xerxes", "Ximeno", "Xander", "Xenophon"],
		"Y": ["Yves", "Yorick", "Yusuf", "Yaroslav", "Yolanda"],
		"Z": ["Zachary", "Zeno", "Zoltan", "Zephyr", "Zander"]
	}
	
	for player_id in range(1, player_count + 1):
		var player = game_state.players[player_id]
		
		if spawn_positions.size() >= player_id:
			var spawn_pos = spawn_positions[player_id - 1]
			
			# Find an unused initial for domain
			var domain_name = ""
			var chosen_initial = ""
			
			for initial in domain_names.keys():
				if initial not in used_initials:
					chosen_initial = initial
					var names_for_initial = domain_names[initial]
					domain_name = names_for_initial[randi() % names_for_initial.size()]
					used_initials.append(initial)
					break
			
			if domain_name == "":
				# Fallback if we run out of initials
				domain_name = "Domain %d" % domain_id_counter
				chosen_initial = "?"
			
			# Create unit with matching initial
			var unit_name = ""
			if chosen_initial in unit_names:
				var unit_names_for_initial = unit_names[chosen_initial]
				unit_name = unit_names_for_initial[randi() % unit_names_for_initial.size()]
			else:
				unit_name = "Unit%d" % unit_id_counter
			
			var unit = Unit.new(unit_id_counter, player_id, unit_name, spawn_pos)
			game_state.units[unit_id_counter] = unit
			player.add_unit(unit_id_counter)
			unit_id_counter += 1
			
			# Create domain with initial power
			var domain_data = {
				"id": domain_id_counter,
				"owner_id": player_id,
				"name": domain_name,
				"initial": chosen_initial,
				"center_position": spawn_pos,
				"power": 1,  # Start with 1 power
				"is_occupied": false,
				"occupied_by_player": -1
			}
			game_state.domains[domain_id_counter] = domain_data
			player.add_domain(domain_id_counter)
			domain_id_counter += 1
			
			print("    Player %d: Domain '%s' (%s) with unit '%s'" % [player_id, domain_name, chosen_initial, unit_name])
	
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

# Get spawn positions using hexagon corner algorithm
static func _get_spawn_positions(grid_data: Dictionary, player_count: int) -> Array:
	var spawn_positions = []
	
	# Initialize random seed for different spawns each game
	randomize()
	
	# Step 1: Get all corner points (hexagon tips)
	var corner_points = []
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.is_corner:
			corner_points.append(point)
	
	print("    Found %d corner points" % corner_points.size())
	
	# Get all points with exactly 6 connections (perfect hex centers)
	var six_connection_points = []
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.connected_edges.size() == 6:
			six_connection_points.append(point)
	
	# Shuffle 6-connection points for additional randomness
	six_connection_points.shuffle()
	
	print("    Found %d points with 6 connections" % six_connection_points.size())
	
	# Randomize corner selection for each game
	var available_corners = corner_points.duplicate()
	available_corners.shuffle()  # Randomize the order
	
	# For each player, find spawn position using the algorithm
	for player_index in range(player_count):
		# Step 1: Select random corner from shuffled list
		var corner_index = player_index % available_corners.size()
		var selected_corner = available_corners[corner_index]
		
		print("    Player %d: Selected corner at %s" % [player_index + 1, selected_corner.position.hex_coord.get_string()])
		
		# Step 2: Find closest point with 6 connections to this corner
		var closest_six_point = null
		var min_distance = 999999.0
		
		for six_point in six_connection_points:
			var distance = selected_corner.position.hex_coord.distance_to(six_point.position.hex_coord)
			if distance < min_distance:
				min_distance = distance
				closest_six_point = six_point
		
		if closest_six_point != null:
			print("    Player %d: Found closest 6-connection point at distance %.1f" % [player_index + 1, min_distance])
			# Step 3: Spawn at this point
			spawn_positions.append(closest_six_point.position)
		else:
			print("    Player %d: No 6-connection point found, using corner" % [player_index + 1])
			# Fallback: use the corner itself
			spawn_positions.append(selected_corner.position)
	
	print("    Generated %d spawn positions" % spawn_positions.size())
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