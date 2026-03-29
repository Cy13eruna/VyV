# res://src/systems/visibility/VisibilityManager.gd
extends RefCounted

# Memória persistente: { player_id: { "revealed_edges": {}, "discovered_domains": [] } }
var player_memories: Dictionary = {}

func update_visibility(
	active_units: Array, 
	grid_mgr: Node2D, 
	current_player_id: int, 
	terrain_mgr: Object,
	all_domains: Array = [], 
	force_instant: bool = false
) -> void:
	
	if not grid_mgr or not grid_mgr.painter: return
	
	var painter = grid_mgr.painter
	var nodes_dict = grid_mgr.data.nodes
	
	_ensure_player_data(current_player_id)
	var memory = player_memories[current_player_id]
	
	var lit_map: Dictionary = {}

	# --- 1. LUZ DOS DOMÍNIOS (CAPITAIS ALIADAS) ---
	for domain in all_domains:
		var is_mine = (domain.has("owner_id") and domain.owner_id == current_player_id)
		if is_mine:
			var center = domain.pos
			lit_map[center] = true
			if nodes_dict.has(center):
				for n in nodes_dict[center].neighbors:
					lit_map[n] = true
					memory.revealed_edges[_get_edge_id(center, n)] = true

	# --- 2. LUZ DAS UNIDADES (DINÂMICA) ---
	for unit in active_units:
		if not is_instance_valid(unit) or unit.owner_id != current_player_id: 
			continue
		
		var origin = unit.grid_pos
		lit_map[origin] = true
		
		if nodes_dict.has(origin):
			for n in nodes_dict[origin].neighbors:
				memory.revealed_edges[_get_edge_id(origin, n)] = true
				
				var blocked = false
				if terrain_mgr and terrain_mgr.has_method("blocks_vision"):
					blocked = terrain_mgr.blocks_vision(origin, n)
				
				if not blocked:
					lit_map[n] = true

	var lit_nodes = lit_map.keys()

	# --- 3. REGRA DO LOSANGO (ENTRE NÓS ILUMINADOS) ---
	if terrain_mgr and terrain_mgr.get("edges"):
		for edge_key in terrain_mgr.edges.keys():
			if memory.revealed_edges.has(edge_key): continue
			var points = _parse_edge_key(edge_key)
			if points.size() >= 2:
				if lit_map.has(points[0]) and lit_map.has(points[1]):
					memory.revealed_edges[edge_key] = true

	# --- 4. FILTRAGEM DE DOMÍNIOS VISÍVEIS (ROBUSTA) ---
	var visible_domains: Array = []
	for domain in all_domains:
		var is_mine = (domain.has("owner_id") and domain.owner_id == current_player_id)
		
		# Checagem de luz com tolerância para Vector2
		var is_lit = false
		for l_pos in lit_nodes:
			if l_pos.distance_to(domain.pos) < 1.0: # Tolerância de 1 pixel
				is_lit = true
				break
		
		if is_mine or is_lit or _is_discovered(memory, domain.pos):
			visible_domains.append(domain)
			if is_lit and not is_mine:
				_record_discovery(memory, domain.pos)

	# --- 5. SINCRONIZAÇÃO ---
	painter.lit_nodes = lit_nodes
	painter.revealed_edges = memory.revealed_edges.keys()
	
	if painter.has_method("update_domains"):
		painter.update_domains(visible_domains)
	
	_process_unit_hiding(active_units, lit_nodes, current_player_id, force_instant)
	
	if painter.has_method("refresh_fog_layers"):
		painter.refresh_fog_layers()

# --- MÉTODOS PRIVADOS ---

func _is_discovered(memory: Dictionary, pos: Vector2) -> bool:
	for d_pos in memory.discovered_domains:
		if d_pos.distance_to(pos) < 1.0: return true
	return false

func _record_discovery(memory: Dictionary, pos: Vector2) -> void:
	if not _is_discovered(memory, pos):
		memory.discovered_domains.append(pos)

func _ensure_player_data(player_id: int) -> void:
	if not player_memories.has(player_id):
		player_memories[player_id] = { 
			"revealed_edges": {},
			"discovered_domains": [] 
		}

func _process_unit_hiding(units: Array, lit_nodes: Array, current_id: int, instant: bool) -> void:
	for v in units:
		if not is_instance_valid(v): continue
		if v.owner_id == current_id:
			v.visible = true
			if v.has_method("_update_visual_state"): v._update_visual_state(instant)
		else:
			if v.has_method("update_fow_visibility"):
				v.update_fow_visibility(lit_nodes, instant)

func _get_edge_id(a: Vector2, b: Vector2) -> String:
	if a.x < b.x or (a.x == b.x and a.y < b.y):
		return str(a) + "_" + str(b)
	return str(b) + "_" + str(a)

func _parse_edge_key(key: String) -> Array:
	var separator = "_" if "_" in key else "|"
	var parts = key.replace("(", "").replace(")", "").split(separator)
	if parts.size() == 2:
		var p1_raw = parts[0].split(","); var p2_raw = parts[1].split(",")
		if p1_raw.size() >= 2 and p2_raw.size() >= 2:
			return [Vector2(float(p1_raw[0]), float(p1_raw[1])), Vector2(float(p2_raw[0]), float(p2_raw[1]))]
	return []