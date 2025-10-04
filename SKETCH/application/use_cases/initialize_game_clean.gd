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
	# Validate player count (only 2, 3, 4, 6 allowed)
	var valid_counts = [2, 3, 4, 6]
	if player_count not in valid_counts:
		result.message = "Invalid player count: %d. Valid counts: %s" % [player_count, str(valid_counts)]
		print("    ERROR: Invalid player count")
		return result
	print("    Player count valid")
	
	print("    Initializing game state...")
	# Calculate grid radius based on player count (NOVOS VALORES ATUALIZADOS)
	# Players -> Diameter -> Radius (diameter = 2*radius + 1)
	# 2 -> 9 -> 4
	# 3 -> 11 -> 5  
	# 4 -> 13 -> 6
	# 6 -> 15 -> 7
	var grid_radius: int
	match player_count:
		2:
			grid_radius = 4  # Diameter 9
		3:
			grid_radius = 5  # Diameter 11
		4:
			grid_radius = 6  # Diameter 13
		6:
			grid_radius = 7  # Diameter 15
		_:
			grid_radius = 4  # Default fallback
	
	print("    Using grid radius: %d (diameter: %d stars)" % [grid_radius, 2 * grid_radius + 1])
	
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
			"grid_radius": grid_radius,
			"units_per_player": 1,
			"domains_per_player": 1
		}
	}
	print("    Game state created")
	
	print("    Generating grid...")
	# Generate grid using GridService with calculated radius
	game_state.grid = GridService.generate_hex_grid(grid_radius)
	print("    Grid generated successfully")
	
	print("    Creating players...")
	# Create players with random colors
	var used_colors = []
	for i in range(player_count):
		var player_id = i + 1
		var player_name = "Player %d" % player_id
		var player_color = Player.get_random_color(used_colors)
		used_colors.append(player_color)
		var player = Player.new(player_id, player_name, player_color)
		game_state.players[player_id] = player
		print("    Player %d: %s with color %s" % [player_id, player_name, _color_to_name(player_color)])
	print("    Players created")
	
	print("    Getting spawn positions...")
	# Get spawn positions (corner points for now)
	var spawn_positions = _get_spawn_positions(game_state.grid, player_count)
	print("    Spawn positions found: ", spawn_positions.size())
	
	print("    Creating units and domains...")
	# Create units and domains for each player
	# Create units for each domain
	var unit_id_counter = 1
	var existing_unit_names = []  # Track existing names to prevent duplicates
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
			
			# NOVO: Get all available initials (not used yet)
			var available_initials = []
			for initial in domain_names.keys():
				if initial not in used_initials:
					available_initials.append(initial)
			
			# Randomly select from available initials
			if available_initials.size() > 0:
				chosen_initial = available_initials[randi() % available_initials.size()]
				var names_for_initial = domain_names[chosen_initial]
				domain_name = names_for_initial[randi() % names_for_initial.size()]
				used_initials.append(chosen_initial)
			
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
			
			# Validate and fix unit name
			unit_name = _validate_unit_name(unit_name, existing_unit_names)
			existing_unit_names.append(unit_name)
			
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
	
	return {"success": true, "game_state": game_state}

# Helper function to convert color to name for logging
static func _color_to_name(color: Color) -> String:
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

# Validate unit name: limit to 5 characters and ensure uniqueness
static func _validate_unit_name(original_name: String, existing_names: Array) -> String:
	# Limit to 5 characters
	var name = original_name.substr(0, 5)
	
	# Ensure uniqueness
	var base_name = name
	var counter = 1
	while name in existing_names:
		# If name exists, try with number suffix
		if base_name.length() >= 4:
			# If base name is 4+ chars, truncate to fit number
			name = base_name.substr(0, 4) + str(counter)
		else:
			# If base name is short, just add number
			name = base_name + str(counter)
		
		# Ensure result is still max 5 characters
		name = name.substr(0, 5)
		counter += 1
		
		# Safety check to prevent infinite loop
		if counter > 99:
			name = "U" + str(randi() % 9999).pad_zeros(4)
			name = name.substr(0, 5)
			break
	
	return name

# Get spawn positions using corner + 6-connection algorithm with spawn rules
static func _get_spawn_positions(grid_data: Dictionary, player_count: int) -> Array:
	var spawn_positions = []
	
	# Initialize random seed for different spawns each game
	randomize()
	
	# Get all corner points (hexagon tips)
	var corner_points = []
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.is_corner:
			corner_points.append(point)
	
	print("    Found %d corner points" % corner_points.size())
	
	# CRITICAL: Sort corner points by angle to ensure proper hexagon order
	corner_points.sort_custom(_compare_corners_by_angle)
	
	# DEBUG: Log corner positions after sorting
	for i in range(corner_points.size()):
		var corner = corner_points[i]
		var angle = atan2(corner.position.pixel_pos.y - 384, corner.position.pixel_pos.x - 512) * 180.0 / PI
		print("    Corner %d: q=%d, r=%d, pixel=(%.1f,%.1f), angle=%.1f°" % [i, corner.coordinate.q, corner.coordinate.r, corner.position.pixel_pos.x, corner.position.pixel_pos.y, angle])
	
	# Get all points with exactly 6 connections (perfect hex centers)
	var six_connection_points = []
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.connected_edges.size() == 6:
			six_connection_points.append(point)
	
	print("    Found %d points with 6 connections" % six_connection_points.size())
	
	# Apply spawn rules based on player count to select corners
	var selected_corners = []
	match player_count:
		2:
			# 2 players: não podem estar em pontas adjacentes, mínimo uma ponta do hexágono de distância
			selected_corners = _select_corners_2_players(corner_points)
		3:
			# 3 players: não podem estar em pontas adjacentes, mínimo uma ponta do hexágono de distância
			selected_corners = _select_corners_3_players(corner_points)
		4:
			# 4 players: todo jogador deve estar adjacente a uma ponta vazia do hexágono
			selected_corners = _select_corners_4_players(corner_points)
		6:
			# 6 players: um por ponta
			selected_corners = _select_corners_6_players(corner_points)
		_:
			# Fallback para configurações não suportadas
			print("    WARNING: Unsupported player count %d, using fallback" % player_count)
			selected_corners = _select_corners_fallback(corner_points, player_count)
	
	# For each selected corner, find closest 6-connection point
	for i in range(selected_corners.size()):
		var corner = selected_corners[i]
		var closest_six_point = _find_closest_six_connection_point(corner, six_connection_points)
		
		if closest_six_point != null:
			spawn_positions.append(closest_six_point.position)
			print("    Player %d: Corner %d -> 6-connection point" % [i + 1, corner_points.find(corner)])
		else:
			# Fallback: use corner itself
			spawn_positions.append(corner.position)
			print("    Player %d: Corner %d (no 6-connection found)" % [i + 1, corner_points.find(corner)])
	
	print("    Generated %d spawn positions" % spawn_positions.size())
	return spawn_positions

# Find closest 6-connection point to a corner
static func _find_closest_six_connection_point(corner, six_connection_points: Array):
	var closest_point = null
	var min_distance = 999999.0
	
	for six_point in six_connection_points:
		var distance = corner.position.hex_coord.distance_to(six_point.position.hex_coord)
		if distance < min_distance:
			min_distance = distance
			closest_point = six_point
	
	return closest_point

# Corner selection rules for 2 players: não adjacentes, mínimo uma ponta de distância
static func _select_corners_2_players(corner_points: Array) -> Array:
	var selected_corners = []
	
	# Hexágono tem 6 pontas (0,1,2,3,4,5)
	# Para não serem adjacentes com mínimo uma ponta de distância:
	# Opções válidas: (0,2), (0,3), (0,4), (1,3), (1,4), (1,5), (2,4), (2,5), (3,5)
	var valid_pairs = [[0,2], [0,3], [0,4], [1,3], [1,4], [1,5], [2,4], [2,5], [3,5]]
	
	# Escolher par aleatório
	var chosen_pair = valid_pairs[randi() % valid_pairs.size()]
	
	for i in chosen_pair:
		if i < corner_points.size():
			selected_corners.append(corner_points[i])
	
	return selected_corners

# Corner selection rules for 3 players: não adjacentes, mínimo uma ponta de distância
static func _select_corners_3_players(corner_points: Array) -> Array:
	var selected_corners = []
	
	# Algoritmo robusto: selecionar 3 corners não adjacentes
	# Primeiro, ordenar corners por posição para garantir ordem consistente
	var sorted_corners = corner_points.duplicate()
	sorted_corners.sort_custom(_compare_corners_by_angle)
	
	# Para 6 corners em um hexágono, selecionar alternados (0,2,4) garante não adjacência
	if sorted_corners.size() >= 6:
		# Selecionar corners alternados para garantir distância mínima
		selected_corners.append(sorted_corners[0])  # Corner 0
		selected_corners.append(sorted_corners[2])  # Corner 2 (pula 1)
		selected_corners.append(sorted_corners[4])  # Corner 4 (pula 3)
		print("    3 players: Selected corners 0, 2, 4 (alternated)")
	else:
		# Fallback para casos com menos corners
		for i in range(min(3, sorted_corners.size())):
			selected_corners.append(sorted_corners[i])
		print("    3 players: Fallback selection (insufficient corners)")
	
	return selected_corners

# Função auxiliar para ordenar corners por ângulo (usando coordenadas de pixel)
static func _compare_corners_by_angle(a, b) -> bool:
	# Calcular ângulo de cada corner em relação ao centro da tela (512, 384)
	var center = Vector2(512, 384)
	var pos_a = a.position.pixel_pos - center
	var pos_b = b.position.pixel_pos - center
	var angle_a = atan2(pos_a.y, pos_a.x)
	var angle_b = atan2(pos_b.y, pos_b.x)
	return angle_a < angle_b

# Corner selection rules for 4 players: duas duplas em extremidades opostas
static func _select_corners_4_players(corner_points: Array) -> Array:
	var selected_corners = []
	
	# Algoritmo conforme especificado no i.txt:
	# 0. selecione aleatoriamente uma ponta do tabuleiro
	# 1. posicione um jogador nessa ponta
	# 2. aleatoriamente selecione uma ponta adjacente
	# 3. posicione outro jogador nessa ponta
	# 4. encontre as duas pontas opostas a essas duas pontas ocupadas por jogadores
	# 5. posicione um jogador em cada uma dessas duas pontas opostas
	# 6. pronto! temos duas duplas de jogadores cada um numa extremidade do tabuleiro
	
	if corner_points.size() < 6:
		print("    ERROR: Insufficient corner points for 4 players")
		return selected_corners
	
	# Passo 0 e 1: Selecionar ponta aleatória para jogador 1
	var first_corner_index = randi() % 6
	selected_corners.append(corner_points[first_corner_index])
	var first_corner = corner_points[first_corner_index]
	print("    Player 1: Corner %d (randomly selected) at q=%d,r=%d pixel=(%.1f,%.1f)" % [first_corner_index, first_corner.coordinate.q, first_corner.coordinate.r, first_corner.position.pixel_pos.x, first_corner.position.pixel_pos.y])
	
	# Passo 2 e 3: Selecionar ponta adjacente para jogador 2
	# Pontas adjacentes são (index-1) e (index+1) com wrap-around
	var adjacent_indices = [
		(first_corner_index - 1 + 6) % 6,  # Ponta anterior (com wrap)
		(first_corner_index + 1) % 6       # Ponta seguinte (com wrap)
	]
	var second_corner_index = adjacent_indices[randi() % 2]
	selected_corners.append(corner_points[second_corner_index])
	var second_corner = corner_points[second_corner_index]
	print("    Player 2: Corner %d (adjacent to %d) at q=%d,r=%d pixel=(%.1f,%.1f)" % [second_corner_index, first_corner_index, second_corner.coordinate.q, second_corner.coordinate.r, second_corner.position.pixel_pos.x, second_corner.position.pixel_pos.y])
	
	# Passo 4 e 5: Encontrar as duas pontas opostas
	# Em um hexágono, a ponta oposta está a 3 posições de distância
	var third_corner_index = (first_corner_index + 3) % 6
	var fourth_corner_index = (second_corner_index + 3) % 6
	
	selected_corners.append(corner_points[third_corner_index])
	selected_corners.append(corner_points[fourth_corner_index])
	
	var third_corner = corner_points[third_corner_index]
	var fourth_corner = corner_points[fourth_corner_index]
	
	print("    Player 3: Corner %d (opposite to %d) at q=%d,r=%d pixel=(%.1f,%.1f)" % [third_corner_index, first_corner_index, third_corner.coordinate.q, third_corner.coordinate.r, third_corner.position.pixel_pos.x, third_corner.position.pixel_pos.y])
	print("    Player 4: Corner %d (opposite to %d) at q=%d,r=%d pixel=(%.1f,%.1f)" % [fourth_corner_index, second_corner_index, fourth_corner.coordinate.q, fourth_corner.coordinate.r, fourth_corner.position.pixel_pos.x, fourth_corner.position.pixel_pos.y])
	
	# DEBUG: Verificar distâncias entre os pares
	var distance_pair1 = first_corner.position.pixel_pos.distance_to(second_corner.position.pixel_pos)
	var distance_pair2 = third_corner.position.pixel_pos.distance_to(fourth_corner.position.pixel_pos)
	var distance_opposite1 = first_corner.position.pixel_pos.distance_to(third_corner.position.pixel_pos)
	var distance_opposite2 = second_corner.position.pixel_pos.distance_to(fourth_corner.position.pixel_pos)
	
	print("    Distance between pair 1 (players 1-2): %.1f" % distance_pair1)
	print("    Distance between pair 2 (players 3-4): %.1f" % distance_pair2)
	print("    Distance between opposites (1-3): %.1f" % distance_opposite1)
	print("    Distance between opposites (2-4): %.1f" % distance_opposite2)
	print("    Result: Two pairs at opposite ends of the board")
	
	return selected_corners

# Corner selection rules for 6 players: um por ponta
static func _select_corners_6_players(corner_points: Array) -> Array:
	var selected_corners = []
	
	# Simples: um jogador em cada ponta do hexágono
	for i in range(min(6, corner_points.size())):
		selected_corners.append(corner_points[i])
	
	return selected_corners

# Fallback para configurações não suportadas
static func _select_corners_fallback(corner_points: Array, player_count: int) -> Array:
	var selected_corners = []
	
	# Usar algoritmo antigo como fallback
	for i in range(min(player_count, corner_points.size())):
		selected_corners.append(corner_points[i])
	
	return selected_corners

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