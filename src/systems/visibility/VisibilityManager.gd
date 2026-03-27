# res://src/systems/visibility/VisibilityManager.gd
extends RefCounted

# Estrutura: { player_id: { "revealed_edges": {} } }
var player_memories: Dictionary = {}

## Inicializa a memória para um novo jogador se não existir
func _ensure_player_data(player_id: int) -> void:
	if not player_memories.has(player_id):
		player_memories[player_id] = {
			"revealed_edges": {}
		}

## Processa a neblina específica para o jogador atual
func update_fog(active_units: Array, grid_data: Object, painter: Node2D, current_player_id: int) -> void:
	if not grid_data or not painter: return
	
	_ensure_player_data(current_player_id)
	var memory = player_memories[current_player_id]
	var lit_nodes: Array = []
	
	# 1. Apenas unidades do jogador atual geram luz (Visibilidade em Tempo Real)
	for unit in active_units:
		if not is_instance_valid(unit) or unit.owner_id != current_player_id: 
			continue
		
		if not unit.grid_pos in lit_nodes:
			lit_nodes.append(unit.grid_pos)
		
		var neighbors = grid_data.get_neighbors(unit.grid_pos)
		for n in neighbors:
			if not n in lit_nodes:
				lit_nodes.append(n)
	
	# 2. Processar arestas reveladas (Memória Permanente por Jogador)
	for edge_key in grid_data.edges.keys():
		if memory.revealed_edges.has(edge_key): continue
		
		var points = _parse_edge_key(edge_key)
		if points.size() < 2: continue
			
		# Regra: Revela se ambos os pontos estão na luz do jogador ATUAL
		if points[0] in lit_nodes and points[1] in lit_nodes:
			memory.revealed_edges[edge_key] = true
	
	# 3. Injetar no Painter apenas o que este jogador conhece
	painter.lit_nodes = lit_nodes
	painter.revealed_edges = memory.revealed_edges.keys()
	
	if painter.has_method("refresh_fog_layers"):
		painter.refresh_fog_layers()

func _parse_edge_key(key: String) -> Array[Vector2]:
	var parts = key.replace("(", "").replace(")", "").split("_")
	if parts.size() == 2:
		var p1_raw = parts[0].split(",")
		var p2_raw = parts[1].split(",")
		return [Vector2(float(p1_raw[0]), float(p1_raw[1])), Vector2(float(p2_raw[0]), float(p2_raw[1]))]
	return []