# res://src/systems/grid/GridData.gd
extends Resource

const HexMath = preload("res://src/core/math/HexMath.gd")

# Dicionário de Nodes: { Vector2_pos: { "neighbors": [Vector2], "entity": null } }
var nodes: Dictionary = {}
# Dicionário de Edges: { "pos1_pos2": { "bioma": "grama", "level": 1 } }
var edges: Dictionary = {}

func clear() -> void:
	nodes.clear()
	edges.clear()

# --- GERAÇÃO DE MALHA (Nova Responsabilidade) ---

func generate_hex_grid(radius: int, tile_size: float) -> void:
	clear()
	var r_pixel = (radius * tile_size * 0.5)
	var search_range = radius * 2
	
	# Passar 1: Gerar e Validar Pontos (Nodes)
	for y in range(-search_range, search_range + 1):
		for x in range(-search_range * 2, search_range * 2 + 1):
			var coords = Vector2i(x, y)
			var points = HexMath.get_triangle_points(coords, tile_size)
			for p in points:
				if _is_point_in_hexagon(p, r_pixel):
					add_node(p)
	
	# Passar 2: Criar Conexões (Edges)
	for y in range(-search_range, search_range + 1):
		for x in range(-search_range * 2, search_range * 2 + 1):
			var coords = Vector2i(x, y)
			var points = HexMath.get_triangle_points(coords, tile_size)
			# Conecta os 3 pontos de cada triângulo da malha básica
			add_edge(points[0], points[1])
			add_edge(points[1], points[2])
			add_edge(points[2], points[0])

func _is_point_in_hexagon(p: Vector2, radius: float) -> bool:
	var h_limit = radius * 0.866025
	var d_v = abs(p.y)
	var d_d1 = abs(p.x * 0.866025 + p.y * 0.5)
	var d_d2 = abs(p.x * 0.866025 - p.y * 0.5)
	return d_v <= h_limit + 1.0 and d_d1 <= h_limit + 1.0 and d_d2 <= h_limit + 1.0

# --- MANIPULAÇÃO DE DADOS ---

func add_node(pos: Vector2) -> void:
	var p = pos.snapped(Vector2(0.1, 0.1))
	if not nodes.has(p):
		nodes[p] = { "neighbors": [], "entity": null }

func add_edge(p1: Vector2, p2: Vector2, bioma_data: Dictionary = {}) -> void:
	var a = p1.snapped(Vector2(0.1, 0.1))
	var b = p2.snapped(Vector2(0.1, 0.1))
	
	if not nodes.has(a) or not nodes.has(b):
		return

	var edge_key = _get_edge_key(a, b)
	
	if not edges.has(edge_key):
		edges[edge_key] = bioma_data
		# Registro bidirecional
		if not b in nodes[a].neighbors: nodes[a].neighbors.append(b)
		if not a in nodes[b].neighbors: nodes[b].neighbors.append(a)

func get_neighbors(p_node: Vector2) -> Array:
	var p = p_node.snapped(Vector2(0.1, 0.1))
	if nodes.has(p):
		return nodes[p].neighbors
	return []

func _get_edge_key(p1: Vector2, p2: Vector2) -> String:
	# Garantimos que a chave seja sempre a mesma independente da ordem dos pontos
	var p1_s = str(p1.snapped(Vector2(0.1, 0.1)))
	var p2_s = str(p2.snapped(Vector2(0.1, 0.1)))
	var list = [p1_s, p2_s]
	list.sort() 
	return list[0] + "_" + list[1]

func get_closest_node(world_pos: Vector2, max_dist: float) -> Vector2:
	var closest: Vector2 = Vector2.ZERO
	var min_dist: float = max_dist
	
	if nodes.is_empty():
		return Vector2.ZERO

	for p in nodes.keys():
		var d = world_pos.distance_to(p)
		if d < min_dist:
			min_dist = d
			closest = p
			
	return closest