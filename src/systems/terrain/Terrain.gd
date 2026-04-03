# res://src/systems/Terrain.gd
extends RefCounted

enum Type { PLAINS, HILLS, WOODS, WATERS }

const DATA = {
	Type.PLAINS: {"color": Color.GREEN, "move": true, "vis": true},
	Type.HILLS:  {"color": Color(0.5, 0.5, 0.5), "move": false, "vis": false},
	Type.WOODS:  {"color": Color(0.0, 0.5, 0.0), "move": true, "vis": false},
	Type.WATERS: {"color": Color.CYAN, "move": false, "vis": true}
}

var edges: Dictionary = {}

func generate_random_terrain(grid_resource: Object) -> void:
	edges.clear()
	if not grid_resource or not "nodes" in grid_resource:
		return
	
	# Garante que o dicionário de arestas no recurso de dados esteja limpo
	if "edges" in grid_resource:
		grid_resource.edges.clear()
	else:
		grid_resource.set("edges", {})

	var nodes_dict = grid_resource.nodes
	
	# Distribuição alvo: 1/2 Plains, 1/6 Woods, 1/6 Hills, 1/6 Waters
	# Limiares acumulados: 0.5 -> 0.666 -> 0.833 -> 1.0
	for pos in nodes_dict.keys():
		for n_pos in nodes_dict[pos].neighbors:
			var id = get_edge_id(pos, n_pos)
			
			if not edges.has(id):
				var roll = randf()
				var random_type: Type
				
				if roll < 0.5:
					random_type = Type.PLAINS   # 50% (1/2)
				elif roll < 0.666:
					random_type = Type.WOODS    # ~16.6% (1/6)
				elif roll < 0.833:
					random_type = Type.HILLS    # ~16.6% (1/6)
				else:
					random_type = Type.WATERS   # Restante (1/6)
				
				edges[id] = random_type
				
				# Registra a existência da aresta para o GridPainter
				grid_resource.edges[id] = true
				
	print("[Terrain] Geração concluída. Distribuição: 1/2 Plains, 1/6 Woods, 1/6 Hills, 1/6 Waters.")

func get_edge_id(a: Vector2, b: Vector2) -> String:
	var p1 = a.snapped(Vector2(0.1, 0.1))
	var p2 = b.snapped(Vector2(0.1, 0.1))
	if p1.x < p2.x or (p1.x == p2.x and p1.y < p2.y):
		return "%.1f,%.1f_%.1f,%.1f" % [p1.x, p1.y, p2.x, p2.y]
	return "%.1f,%.1f_%.1f,%.1f" % [p2.x, p2.y, p1.x, p1.y]

func get_edge_color(a: Vector2, b: Vector2) -> Color:
	var id = get_edge_id(a, b)
	var type = edges.get(id, Type.PLAINS)
	return DATA[type].color

func blocks_vision(a: Vector2, b: Vector2) -> bool:
	var id = get_edge_id(a, b)
	var type = edges.get(id, Type.PLAINS)
	return not DATA[type].vis

func blocks_movement(a: Vector2, b: Vector2, allied_nodes: Array = []) -> bool:
	for pos in allied_nodes:
		if a.distance_to(pos) < 0.1 and b.distance_to(pos) < 0.1:
			return false 
			
	var id = get_edge_id(a, b)
	var type = edges.get(id, Type.PLAINS)
	return not DATA[type].move