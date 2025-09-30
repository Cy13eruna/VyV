extends RefCounted

# GridManager - Responsável por geração e manipulação do grid hexagonal
# Migrado do main_game.gd para melhor organização

class_name GridManager

# Configurações do grid
var hex_size: float = 40.0
var hex_center: Vector2 = Vector2(400, 300)

# Dados do grid (gerados)
var points: Array = []
var hex_coords: Array = []
var paths: Array = []

func generate_hex_grid(radius: int = 3) -> Dictionary:
	"""Gera um grid hexagonal completo"""
	points.clear()
	hex_coords.clear()
	paths.clear()
	
	var point_id = 0
	
	# Generate points in axial coordinates
	for grid_radius in range(radius + 1):
		if grid_radius == 0:
			# Center
			hex_coords.append(Vector2(0, 0))
			points.append(hex_to_pixel(0, 0))
			point_id += 1
		else:
			# Points around center
			for i in range(6):
				for j in range(grid_radius):
					var q = hex_direction(i).x * (grid_radius - j) + hex_direction((i + 1) % 6).x * j
					var r = hex_direction(i).y * (grid_radius - j) + hex_direction((i + 1) % 6).y * j
					hex_coords.append(Vector2(q, r))
					points.append(hex_to_pixel(q, r))
					point_id += 1
	
	# Generate paths
	generate_paths()
	
	print("🌍 GridManager: Grid created - %d points, %d paths" % [points.size(), paths.size()])
	
	return {
		"points": points,
		"hex_coords": hex_coords,
		"paths": paths
	}

func hex_to_pixel(q: float, r: float) -> Vector2:
	"""Converte coordenadas hexagonais para pixels"""
	var x = hex_size * (3.0/2.0 * q)
	var y = hex_size * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r)
	
	# Apply 60° rotation
	var angle = PI / 3.0
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	
	var rotated_x = x * cos_angle - y * sin_angle
	var rotated_y = x * sin_angle + y * cos_angle
	
	return hex_center + Vector2(rotated_x, rotated_y)

func hex_direction(direction: int) -> Vector2:
	"""Retorna vetor de direção hexagonal (0-5)"""
	var directions = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	return directions[direction % 6]

func generate_paths():
	"""Gera caminhos conectando pontos adjacentes"""
	var path_set = {}
	
	for i in range(hex_coords.size()):
		var coord = hex_coords[i]
		for dir in range(6):
			var neighbor_coord = coord + hex_direction(dir)
			var neighbor_index = find_hex_coord_index(neighbor_coord)
			
			if neighbor_index != -1:
				var path_id = "%d_%d" % [min(i, neighbor_index), max(i, neighbor_index)]
				if not path_set.has(path_id):
					paths.append({"points": [i, neighbor_index], "type": 0})  # FIELD
					path_set[path_id] = true

func find_hex_coord_index(coord: Vector2) -> int:
	"""Encontra o índice de uma coordenada hexagonal"""
	for i in range(hex_coords.size()):
		if hex_coords[i].is_equal_approx(coord):
			return i
	return -1

# Getters para acesso aos dados
func get_points() -> Array:
	return points

func get_hex_coords() -> Array:
	return hex_coords

func get_paths() -> Array:
	return paths

func get_point_count() -> int:
	return points.size()

func get_path_count() -> int:
	return paths.size()

# Configuração
func set_hex_size(size: float):
	hex_size = size

func set_hex_center(center: Vector2):
	hex_center = center

# Limpeza de memória
func cleanup():
	points.clear()
	hex_coords.clear()
	paths.clear()
	print("🧹 GridManager: Memory cleaned up")