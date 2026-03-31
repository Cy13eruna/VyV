extends RefCounted

static func get_reachable_cells(
	start_pos: Vector2, 
	max_ap: int, 
	grid_resource: Object, 
	terrain_mgr: Object, 
	occupied_nodes: Array = [],
	allied_domain_nodes: Array = []
) -> Array:
	
	var reachable: Array = []
	if not grid_resource or not "nodes" in grid_resource:
		return reachable
		
	var nodes_dict = grid_resource.nodes
	var snap_val = Vector2(0.1, 0.1)
	
	# 1. NORMALIZAÇÃO TOTAL
	var clean_occupied = {}
	for pos in occupied_nodes: 
		clean_occupied[str(pos.snapped(snap_val))] = true

	var clean_allied = {}
	for pos in allied_domain_nodes: 
		clean_allied[str(pos.snapped(snap_val))] = true
	
	var start_snapped = start_pos.snapped(snap_val)
	var start_str = str(start_snapped)
	
	# visited armazena o menor custo para chegar em cada nó
	var visited: Dictionary = {start_str: 0}
	var stack: Array = [{"pos": start_snapped, "cost": 0}]
	
	# Usaremos um Set temporário para evitar duplicatas na lista final
	var reachable_set = {}

	while stack.size() > 0:
		var current = stack.pop_front()
		var curr_pos = current.pos
		var str_curr = str(curr_pos.snapped(snap_val))
		
		# --- REGRA DE OCUPAÇÃO ---
		# Um nó só é considerado "alcançável" (para clicar e mover) se:
		# 1. Não estiver ocupado OR 2. For o nó de onde a unidade está saindo.
		if not clean_occupied.has(str_curr) or str_curr == start_str:
			reachable_set[str_curr] = curr_pos
		
		if not nodes_dict.has(curr_pos): continue
			
		for n_pos in nodes_dict[curr_pos].neighbors:
			var sn_n = n_pos.snapped(snap_val)
			var str_n = str(sn_n)
			
			# --- LÓGICA DE CUSTO ---
			var move_cost = 0 if clean_allied.has(str_n) else 1
			
			# --- LÓGICA DE PASSAGEM ---
			var can_pass = false
			
			# Bloqueio de Passagem (Corpo a Corpo):
			# Se você quiser que unidades INIMIGAS bloqueiem a passagem, você checaria aqui.
			# Por enquanto, mantemos sua regra de Domínio/Terreno:
			if clean_allied.has(str_curr) or clean_allied.has(str_n):
				can_pass = true
			else:
				if terrain_mgr and terrain_mgr.has_method("blocks_movement"):
					can_pass = not terrain_mgr.blocks_movement(curr_pos, sn_n)
				else:
					can_pass = true
			
			if can_pass:
				var new_cost = current.cost + move_cost
				if new_cost <= max_ap:
					# Se ainda não visitamos ou achamos um caminho mais barato
					if not visited.has(str_n) or visited[str_n] > new_cost:
						visited[str_n] = new_cost
						stack.append({"pos": sn_n, "cost": new_cost})
	
	# Converte o Set de volta para Array para o GridPainter
	return reachable_set.values()