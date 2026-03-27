# res://src/systems/visibility/VisibilityManager.gd
extends RefCounted

# Estrutura: { player_id: { "revealed_edges": {} } }
var player_memories: Dictionary = {}

func _ensure_player_data(player_id: int) -> void:
	if not player_memories.has(player_id):
		player_memories[player_id] = { "revealed_edges": {} }

## Processa a neblina garantindo o acesso correto ao Resource GridData
func update_fog(active_units: Array, grid_mgr: Node2D, painter: Node2D, current_player_id: int, terrain_mgr = null) -> void:
	if not grid_mgr or not grid_mgr.data or not painter: return
	
	var grid_resource = grid_mgr.data
	if not "nodes" in grid_resource:
		push_error("VisibilityManager: Resource de grid não possui dicionário 'nodes'")
		return
	
	var nodes_dict = grid_resource.nodes
	_ensure_player_data(current_player_id)
	var memory = player_memories[current_player_id]
	var lit_nodes: Array = []
	
	# 1. Visibilidade em tempo real e Revelação por Proximidade
	for unit in active_units:
		if not is_instance_valid(unit) or unit.owner_id != current_player_id: 
			continue
		
		var origin = unit.grid_pos
		if not origin in lit_nodes: 
			lit_nodes.append(origin)
		
		if nodes_dict.has(origin):
			var neighbors = nodes_dict[origin].neighbors
			for n in neighbors:
				# --- REGRA: Revelação Adjacente ---
				# Revela as 6 arestas tocando o Vagabond na memória, independente de bloqueio
				if terrain_mgr:
					var adj_edge_id = _get_edge_id(origin, n)
					if not memory.revealed_edges.has(adj_edge_id):
						memory.revealed_edges[adj_edge_id] = true
				
				# --- Lógica de Iluminação ---
				var blocked = false
				if terrain_mgr and terrain_mgr.has_method("blocks_vision"):
					blocked = terrain_mgr.blocks_vision(origin, n)
				
				# Se não houver bloqueio, o nó vizinho fica "aceso" (lit)
				if not blocked:
					if not n in lit_nodes: 
						lit_nodes.append(n)
	
	# 2. Processamento de arestas distantes (Memória Permanente)
	if terrain_mgr and terrain_mgr.get("edges"):
		for edge_key in terrain_mgr.edges.keys():
			if memory.revealed_edges.has(edge_key): continue
			
			var points = _parse_edge_key(edge_key)
			if points.size() < 2: continue
			
			# Revela arestas distantes se o jogador puder ver os dois nós que ela conecta
			if points[0] in lit_nodes and points[1] in lit_nodes:
				memory.revealed_edges[edge_key] = true
	
	# 3. Sincronização com o Pintor
	painter.lit_nodes = lit_nodes
	painter.revealed_edges = memory.revealed_edges.keys()
	
	if painter.has_method("refresh_fog_layers"):
		painter.refresh_fog_layers()

# Utilitário para gerar a chave da aresta no mesmo formato do Terrain.gd
func _get_edge_id(a: Vector2, b: Vector2) -> String:
	if a.x < b.x or (a.x == b.x and a.y < b.y):
		return str(a) + "_" + str(b)
	return str(b) + "_" + str(a)

func _parse_edge_key(key: String) -> Array:
	var separator = "_" if "_" in key else "|"
	var parts = key.replace("(", "").replace(")", "").split(separator)
	if parts.size() == 2:
		var p1_raw = parts[0].split(",")
		var p2_raw = parts[1].split(",")
		if p1_raw.size() >= 2 and p2_raw.size() >= 2:
			return [
				Vector2(float(p1_raw[0]), float(p1_raw[1])), 
				Vector2(float(p2_raw[0]), float(p2_raw[1]))
			]
	return []