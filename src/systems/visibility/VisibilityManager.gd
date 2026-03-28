# res://src/systems/visibility/VisibilityManager.gd
extends RefCounted

# Memória persistente do que cada jogador já explorou (FOW permanente)
# Estrutura: { player_id: { "revealed_edges": {} } }
var player_memories: Dictionary = {}

## Função principal que orquestra a neblina e a visibilidade das unidades
func update_visibility(
	active_units: Array, 
	grid_mgr: Node2D, 
	current_player_id: int, 
	terrain_mgr: Object,
	force_instant: bool = false
) -> void:
	
	if not grid_mgr or not grid_mgr.painter: return
	
	var painter = grid_mgr.painter
	var nodes_dict = grid_mgr.data.nodes
	
	_ensure_player_data(current_player_id)
	var memory = player_memories[current_player_id]
	var lit_nodes: Array = []
	
	# --- 1. CÁLCULO DE ILUMINAÇÃO (O QUE ESTÁ VISÍVEL AGORA) ---
	for unit in active_units:
		if not is_instance_valid(unit) or unit.owner_id != current_player_id: 
			continue
		
		var origin = unit.grid_pos
		if not origin in lit_nodes: 
			lit_nodes.append(origin)
		
		if nodes_dict.has(origin):
			var neighbors = nodes_dict[origin].neighbors
			for n in neighbors:
				# Revelação Adjacente (Memória Permanente de arestas próximas)
				var adj_edge_id = _get_edge_id(origin, n)
				memory.revealed_edges[adj_edge_id] = true
				
				# Lógica de Bloqueio de Visão (Tempo Real)
				var blocked = false
				if terrain_mgr and terrain_mgr.has_method("blocks_vision"):
					blocked = terrain_mgr.blocks_vision(origin, n)
				
				if not blocked and not n in lit_nodes: 
					lit_nodes.append(n)
	
	# --- 2. MEMÓRIA DISTANTE (REVELA ARESTAS ENTRE DOIS NÓS ILUMINADOS) ---
	if terrain_mgr and terrain_mgr.get("edges"):
		for edge_key in terrain_mgr.edges.keys():
			if memory.revealed_edges.has(edge_key): continue
			
			var points = _parse_edge_key(edge_key)
			if points.size() >= 2:
				if points[0] in lit_nodes and points[1] in lit_nodes:
					memory.revealed_edges[edge_key] = true
	
	# --- 3. ATUALIZAÇÃO VISUAL DOS VAGABONDS ---
	_process_unit_hiding(active_units, lit_nodes, current_player_id, force_instant)
	
	# --- 4. SINCRONIZAÇÃO COM O PAINTER ---
	painter.lit_nodes = lit_nodes
	painter.revealed_edges = memory.revealed_edges.keys()
	
	if painter.has_method("refresh_fog_layers"):
		painter.refresh_fog_layers()

# --- MÉTODOS PRIVADOS ---

## Gerencia quem deve ou não aparecer na tela
func _process_unit_hiding(units: Array, lit_nodes: Array, current_id: int, instant: bool) -> void:
	for v in units:
		if not is_instance_valid(v): continue
		
		# Se é do próprio jogador, sempre visível
		if v.owner_id == current_id:
			v.visible = true
			
			# CORREÇÃO: Em vez de forçar modulate.a = 1.0, pedimos para a unidade
			# atualizar seu estado visual. O Vagabond.gd usará 0.5 se o AP for 0.
			if v.has_method("_update_visual_state"):
				v._update_visual_state(instant)
			
			# Garante que a UI de AP apareça corretamente
			if instant and v.has_method("_animate_ap_change"):
				v._animate_ap_change()
		else:
			# Se é inimigo, usa a lógica de FOW interna da unidade
			if v.has_method("update_fow_visibility"):
				v.update_fow_visibility(lit_nodes, instant)

func _ensure_player_data(player_id: int) -> void:
	if not player_memories.has(player_id):
		player_memories[player_id] = { "revealed_edges": {} }

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