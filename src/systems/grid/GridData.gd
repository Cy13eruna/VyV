# res://src/systems/grid/GridData.gd
extends Resource

const HexMath = preload("res://src/core/math/HexMath.gd")

# Nodes: { Vector2: { "neighbors": Array[Vector2], "entity": Node } }
var nodes: Dictionary = {}
# Edges: { String: Dictionary }
var edges: Dictionary = {}

func clear() -> void:
	nodes.clear()
	edges.clear()

# --- GERAÇÃO DE MALHA ---

func generate_hex_grid(radius: int, tile_size: float) -> void:
	clear()
	var r_pixel = (radius * tile_size * 0.5)
	var search_range = radius + 1 # Range otimizado
	
	for y in range(-search_range, search_range + 1):
		for x in range(-search_range * 2, search_range * 2 + 1):
			var coords = Vector2i(x, y)
			var points = HexMath.get_triangle_points(coords, tile_size)
			
			# Adiciona nós e cria conexões entre os 3 pontos do triângulo
			for i in range(3):
				var p1 = points[i]
				var p2 = points[(i + 1) % 3]
				
				# Só processamos se o ponto estiver dentro do limite do hexágono
				if _is_point_in_hexagon(p1, r_pixel):
					add_node(p1)
					if _is_point_in_hexagon(p2, r_pixel):
						add_node(p2)
						add_edge(p1, p2)

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
	
	if not nodes.has(a) or not nodes.has(b) or a == b:
		return

	var edge_key = _get_edge_key(a, b)
	if not edges.has(edge_key):
		edges[edge_key] = bioma_data
		# Registro bidirecional seguro
		if not b in nodes[a].neighbors: nodes[a].neighbors.append(b)
		if not a in nodes[b].neighbors: nodes[b].neighbors.append(a)

func get_neighbors(p_node: Vector2) -> Array:
	var p = p_node.snapped(Vector2(0.1, 0.1))
	return nodes.get(p, {}).get("neighbors", [])

func _get_edge_key(p1: Vector2, p2: Vector2) -> String:
	# Ordenação rápida para garantir chave única independente da direção
	if p1.x < p2.x or (p1.x == p2.x and p1.y < p2.y):
		return str(p1) + "_" + str(p2)
	return str(p2) + "_" + str(p1)

func get_closest_node(world_pos: Vector2, max_dist: float) -> Vector2:
	var closest = Vector2.ZERO
	var min_dist = max_dist
	
	for p in nodes.keys():
		var d = world_pos.distance_to(p)
		if d < min_dist:
			min_dist = d
			closest = p
	return closest