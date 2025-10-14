# 🗺️ GRID GENERATOR
# Purpose: Generate hexagonal grid and calculate spawn positions
# Layer: Application Services - Game Initialization

extends RefCounted
class_name GridGenerator

# Preload clean services
const GridService = preload("res://application/services/grid_service_clean.gd")

# Calculate grid radius based on player count
static func calculate_grid_radius(player_count: int) -> int:
	# Players -> Diameter -> Radius (diameter = 2*radius + 1)
	# 2 -> 9 -> 4
	# 3 -> 11 -> 5  
	# 4 -> 13 -> 6
	# 6 -> 15 -> 7
	match player_count:
		2:
			return 4  # Diameter 9
		3:
			return 5  # Diameter 11
		4:
			return 6  # Diameter 13
		6:
			return 7  # Diameter 15
		_:
			return 4  # Default fallback

# Generate hexagonal grid with calculated radius
static func generate_hex_grid(player_count: int) -> Dictionary:
	var grid_radius = calculate_grid_radius(player_count)
	return GridService.generate_hex_grid(grid_radius)

# Get spawn positions using corner + 6-connection algorithm with spawn rules
static func get_spawn_positions(grid_data: Dictionary, player_count: int) -> Array:
	var spawn_positions = []
	
	# Initialize random seed for different spawns each game
	randomize()
	
	# Get all corner points (hexagon tips)
	var corner_points = []
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.is_corner:
			corner_points.append(point)
	
	# CRITICAL: Sort corner points by angle to ensure proper hexagon order
	corner_points.sort_custom(_compare_corners_by_angle)
	
	# Get all points with exactly 6 connections (perfect hex centers)
	var six_connection_points = []
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.connected_edges.size() == 6:
			six_connection_points.append(point)
	
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
			selected_corners = _select_corners_fallback(corner_points, player_count)
	
	# For each selected corner, find closest 6-connection point
	for i in range(selected_corners.size()):
		var corner = selected_corners[i]
		var closest_six_point = _find_closest_six_connection_point(corner, six_connection_points)
		
		if closest_six_point != null:
			spawn_positions.append(closest_six_point.position)
		else:
			# Fallback: use corner itself
			spawn_positions.append(corner.position)
	
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
	else:
		# Fallback para casos com menos corners
		for i in range(min(3, sorted_corners.size())):
			selected_corners.append(sorted_corners[i])
	
	return selected_corners

# Corner selection rules for 4 players: duas duplas em extremidades opostas
static func _select_corners_4_players(corner_points: Array) -> Array:
	var selected_corners = []
	
	# Algoritmo conforme especificado:
	# 0. selecione aleatoriamente uma ponta do tabuleiro
	# 1. posicione um jogador nessa ponta
	# 2. aleatoriamente selecione uma ponta adjacente
	# 3. posicione outro jogador nessa ponta
	# 4. encontre as duas pontas opostas a essas duas pontas ocupadas por jogadores
	# 5. posicione um jogador em cada uma dessas duas pontas opostas
	# 6. pronto! temos duas duplas de jogadores cada um numa extremidade do tabuleiro
	
	if corner_points.size() < 6:
		return selected_corners
	
	# Passo 0 e 1: Selecionar ponta aleatória para jogador 1
	var first_corner_index = randi() % 6
	selected_corners.append(corner_points[first_corner_index])
	
	# Passo 2 e 3: Selecionar ponta adjacente para jogador 2
	# Pontas adjacentes são (index-1) e (index+1) com wrap-around
	var adjacent_indices = [
		(first_corner_index - 1 + 6) % 6,  # Ponta anterior (com wrap)
		(first_corner_index + 1) % 6       # Ponta seguinte (com wrap)
	]
	var second_corner_index = adjacent_indices[randi() % 2]
	selected_corners.append(corner_points[second_corner_index])
	
	# Passo 4 e 5: Encontrar as duas pontas opostas
	# Em um hexágono, a ponta oposta está a 3 posições de distância
	var third_corner_index = (first_corner_index + 3) % 6
	var fourth_corner_index = (second_corner_index + 3) % 6
	
	selected_corners.append(corner_points[third_corner_index])
	selected_corners.append(corner_points[fourth_corner_index])
	
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

# Função auxiliar para ordenar corners por ângulo (usando coordenadas de pixel)
static func _compare_corners_by_angle(a, b) -> bool:
	# Calcular ângulo de cada corner em relação ao centro da tela (512, 384)
	var center = Vector2(512, 384)
	var pos_a = a.position.pixel_pos - center
	var pos_b = b.position.pixel_pos - center
	var angle_a = atan2(pos_a.y, pos_a.x)
	var angle_b = atan2(pos_b.y, pos_b.x)
	return angle_a < angle_b

# Generate terrain variation (future implementation)
static func generate_terrain(grid_data: Dictionary) -> bool:
	# Future: Add terrain variety to edges
	# For now, all terrain is FIELD (type 0)
	return true

# Validate grid data after generation
static func validate_grid_data(grid_data: Dictionary) -> bool:
	# Check required components
	if not ("points" in grid_data and "edges" in grid_data):
		return false
	
	# Check grid has points
	if grid_data.points.size() == 0:
		return false
	
	# Check grid has edges
	if grid_data.edges.size() == 0:
		return false
	
	return true