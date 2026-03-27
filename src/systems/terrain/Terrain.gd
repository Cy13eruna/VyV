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
		push_error("TerrainManager: GridResource inválido.")
		return
		
	var nodes_dict = grid_resource.nodes
	var types = Type.values() # [0, 1, 2, 3]
	
	for pos in nodes_dict.keys():
		var neighbors = nodes_dict[pos].neighbors
		for n_pos in neighbors:
			var id = get_edge_id(pos, n_pos)
			
			if not edges.has(id):
				# 100% ALEATÓRIO: 
				# Escolhe qualquer um dos tipos (0 a 3) com chances iguais.
				var random_type = types[randi() % types.size()]
				edges[id] = random_type

func get_edge_id(a: Vector2, b: Vector2) -> String:
	if a.x < b.x or (a.x == b.x and a.y < b.y):
		return str(a) + "_" + str(b)
	return str(b) + "_" + str(a)

func get_edge_color(a: Vector2, b: Vector2) -> Color:
	var id = get_edge_id(a, b)
	var type = edges.get(id, Type.PLAINS)
	return DATA[type].color

func blocks_vision(a: Vector2, b: Vector2) -> bool:
	var id = get_edge_id(a, b)
	var type = edges.get(id, Type.PLAINS)
	return not DATA[type].vis

func blocks_movement(a: Vector2, b: Vector2) -> bool:
	var id = get_edge_id(a, b)
	var type = edges.get(id, Type.PLAINS)
	return not DATA[type].move