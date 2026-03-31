# res://src/systems/visibility/VisibilityManager.gd
extends RefCounted

var player_memories: Dictionary = {}

func update_visibility(
	active_units: Array, 
	grid_mgr: Node2D, 
	current_player_id: int, 
	terrain_mgr: Object,
	all_domains: Variant = [], 
	force_instant: bool = false
) -> void:
	
	if not grid_mgr or not grid_mgr.data: return
	
	var domains_to_process: Array = all_domains.values() if all_domains is Dictionary else all_domains
	var nodes_dict = grid_mgr.data.nodes
	_ensure_player_data(current_player_id)
	var memory = player_memories[current_player_id]
	var lit_map: Dictionary = {}

	# --- 1. GERAR MAPA DE LUZ ---
	for domain in domains_to_process:
		if domain.get("owner_id") == current_player_id:
			var d_pos = domain.pos.snapped(Vector2(0.1, 0.1))
			lit_map[d_pos] = true
			if nodes_dict.has(d_pos):
				for n in nodes_dict[d_pos].neighbors:
					lit_map[n.snapped(Vector2(0.1, 0.1))] = true

	for unit in active_units:
		if not is_instance_valid(unit) or unit.get("owner_id") != current_player_id: 
			continue
		var u_pos = unit.get("grid_pos").snapped(Vector2(0.1, 0.1))
		lit_map[u_pos] = true
		if nodes_dict.has(u_pos):
			for n in nodes_dict[u_pos].neighbors:
				var sn_n = n.snapped(Vector2(0.1, 0.1))
				if terrain_mgr and terrain_mgr.has_method("blocks_vision"):
					if not terrain_mgr.blocks_vision(u_pos, sn_n):
						lit_map[sn_n] = true
				else:
					lit_map[sn_n] = true

	# --- 2. REVELAR ARESTAS ---
	
	# REGRA PADRÃO ORIGINAL: O diamante. Ambos os nós precisam estar acesos.
	for p1 in lit_map.keys():
		if not nodes_dict.has(p1): continue
		for neighbor in nodes_dict[p1].neighbors:
			var p2 = neighbor.snapped(Vector2(0.1, 0.1))
			if lit_map.has(p2):
				var edge_id = _get_edge_id(p1, p2)
				if not memory.revealed_edges.has(edge_id):
					memory.revealed_edges[edge_id] = [p1, p2]

	# NOVA REGRA ESTREITA (O HALO DO VAGABOND):
	# Garante que as 6 arestas tocando as unidades ativas sejam REVELADAS
	# mesmo que a ponta final da aresta esteja no escuro (escondida pelo terreno).
	for unit in active_units:
		if not is_instance_valid(unit) or unit.get("owner_id") != current_player_id: 
			continue
		var u_pos = unit.get("grid_pos").snapped(Vector2(0.1, 0.1))
		if nodes_dict.has(u_pos):
			for neighbor in nodes_dict[u_pos].neighbors:
				var sn_n = neighbor.snapped(Vector2(0.1, 0.1))
				var edge_id = _get_edge_id(u_pos, sn_n)
				if not memory.revealed_edges.has(edge_id):
					memory.revealed_edges[edge_id] = [u_pos, sn_n]

	# Opcional (se você quiser que os domínios também mostrem seu halo incondicionalmente, 
	# mantenha este bloco, se não, pode apagar):
	for domain in domains_to_process:
		if domain.get("owner_id") == current_player_id:
			var d_pos = domain.pos.snapped(Vector2(0.1, 0.1))
			if nodes_dict.has(d_pos):
				for neighbor in nodes_dict[d_pos].neighbors:
					var sn_n = neighbor.snapped(Vector2(0.1, 0.1))
					var edge_id = _get_edge_id(d_pos, sn_n)
					if not memory.revealed_edges.has(edge_id):
						memory.revealed_edges[edge_id] = [d_pos, sn_n]

	# --- 3. EMISSÃO ---
	Signals.visibility_changed.emit(current_player_id, lit_map.keys(), memory.revealed_edges.values())
	
	var visible_domains: Array = []
	for domain in domains_to_process:
		var d_pos = domain.pos.snapped(Vector2(0.1, 0.1))
		if lit_map.has(d_pos) or domain.get("owner_id") == current_player_id or _is_discovered(memory, d_pos):
			visible_domains.append(domain)
			if lit_map.has(d_pos): _record_discovery(memory, d_pos)

	Signals.domains_visibility_updated.emit(visible_domains)
	_process_unit_hiding(active_units, lit_map, current_player_id, force_instant)

func _process_unit_hiding(units: Array, lit_map: Dictionary, current_id: int, instant: bool) -> void:
	for v in units:
		if not is_instance_valid(v): continue
		var v_pos = v.get("grid_pos").snapped(Vector2(0.1, 0.1))
		var is_mine = v.get("owner_id") == current_id
		var should_be_visible = is_mine or lit_map.has(v_pos)
		v.visible = should_be_visible
		_toggle_unit_interaction(v, should_be_visible)
		if v.has_method("update_fow_visibility"):
			v.update_fow_visibility(lit_map.keys(), instant)

func _toggle_unit_interaction(unit: Node2D, enabled: bool) -> void:
	unit.set_process(enabled)
	unit.set_process_input(enabled)
	for child in unit.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", !enabled)
		elif child is Area2D:
			child.set_deferred("monitorable", enabled)
			child.set_deferred("monitoring", enabled)

func _get_edge_id(a: Vector2, b: Vector2) -> String:
	var p1 = a.snapped(Vector2(0.1, 0.1))
	var p2 = b.snapped(Vector2(0.1, 0.1))
	var first = p1 if (p1.x < p2.x or (p1.x == p2.x and p1.y < p2.y)) else p2
	var second = p2 if first == p1 else p1
	return "%.1f,%.1f_%.1f,%.1f" % [first.x, first.y, second.x, second.y]

func _ensure_player_data(player_id: int) -> void:
	if not player_memories.has(player_id):
		player_memories[player_id] = { "revealed_edges": {}, "discovered_domains": [] }

func _is_discovered(memory: Dictionary, pos: Vector2) -> bool:
	var p = pos.snapped(Vector2(0.1, 0.1))
	for d_pos in memory.discovered_domains:
		if d_pos.distance_to(p) < 0.1: return true
	return false

func _record_discovery(memory: Dictionary, pos: Vector2) -> void:
	var p = pos.snapped(Vector2(0.1, 0.1))
	if not _is_discovered(memory, p): memory.discovered_domains.append(p)