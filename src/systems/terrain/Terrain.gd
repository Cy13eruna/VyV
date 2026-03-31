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

## Modificado: Agora aceita a Array original de nós aliados para evitar 100% falhas de precisão float.
func blocks_movement(a: Vector2, b: Vector2, allied_nodes: Array = []) -> bool:
	# 1. SE PASSAMOS A LISTA DE ALIADOS, FAZEMOS A CHECAGEM DE IMUNIDADE
	if not allied_nodes.is_empty():
		var a_allied = false
		var b_allied = false
		
		# Usar uma tolerância de distância (< 0.1) é a única forma de 
		# vencer os arredondamentos flutuantes chatos do Godot
		for pos in allied_nodes:
			if a.distance_to(pos) < 0.1:
				a_allied = true
			if b.distance_to(pos) < 0.1:
				b_allied = true
			
			# Se AMBAS as pontas da aresta estão no domínio, o terreno é ignorado
			if a_allied and b_allied:
				return false 
				
	# 2. REGRA PADRÃO
	# Se as duas pontas não forem aliadas, o terreno volta a mandar no jogo.
	var id = get_edge_id(a, b)
	var type = edges.get(id, Type.PLAINS)
	return not DATA[type].move