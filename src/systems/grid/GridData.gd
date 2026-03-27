# res://src/systems/grid/GridData.gd
extends Resource

# Dicionário de Nodes: { Vector2_pos: { "neighbors": [Vector2], "entity": null } }
var nodes: Dictionary = {}
# Dicionário de Edges: { "pos1_pos2": { "bioma": "grama", "level": 1 } }
var edges: Dictionary = {}

func clear() -> void:
	nodes.clear()
	edges.clear()

func add_node(pos: Vector2) -> void:
	# Usamos um snapping consistente para evitar erros de precisão float
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
		# Registra a vizinhança bidirecional
		if not b in nodes[a].neighbors: nodes[a].neighbors.append(b)
		if not a in nodes[b].neighbors: nodes[b].neighbors.append(a)

func get_neighbors(p_node: Vector2) -> Array:
	var p = p_node.snapped(Vector2(0.1, 0.1))
	if nodes.has(p):
		return nodes[p].neighbors
	return []

func _get_edge_key(p1: Vector2, p2: Vector2) -> String:
	var p1_s = str(p1.snapped(Vector2(0.1, 0.1)))
	var p2_s = str(p2.snapped(Vector2(0.1, 0.1)))
	var list = [p1_s, p2_s]
	list.sort() 
	return list[0] + "_" + list[1]

## FUNÇÃO ATUALIZADA: Agora retorna Vector2 e garante segurança contra Nil
func get_closest_node(world_pos: Vector2, max_dist: float) -> Vector2:
	# Iniciamos com Vector2.ZERO para nunca retornar Nil
	var closest: Vector2 = Vector2.ZERO
	var min_dist: float = max_dist
	
	# Se não houver nós, nem tentamos o loop
	if nodes.is_empty():
		return Vector2.ZERO

	for p in nodes.keys():
		var d = world_pos.distance_to(p)
		if d < min_dist:
			min_dist = d
			closest = p
			
	# Retorna o ponto encontrado ou Vector2.ZERO (0,0) caso nada esteja perto o suficiente
	return closest