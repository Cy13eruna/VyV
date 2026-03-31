# res://src/systems/movement/Pathfinder.gd
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
	
	# 1. PREPARAÇÃO DE DADOS (Normalização para busca O(1))
	var clean_occupied = {}
	for pos in occupied_nodes: 
		clean_occupied[pos.snapped(snap_val)] = true

	var clean_allied = {}
	for pos in allied_domain_nodes: 
		clean_allied[pos.snapped(snap_val)] = true
	
	var start_snapped = start_pos.snapped(snap_val)
	var visited: Dictionary = {start_snapped: 0}
	var stack: Array = [{"pos": start_snapped, "cost": 0}]
	
	# 2. ALGORITMO DE BUSCA (Breadth-First Search)
	while stack.size() > 0:
		var current = stack.pop_front()
		var curr_pos = current.pos
		
		# Registro para visualização (Highlight azul)
		if not curr_pos in reachable:
			# Só pode parar se a célula estiver vazia ou for a posição inicial
			if not clean_occupied.has(curr_pos) or curr_pos == start_snapped:
				reachable.append(curr_pos)
		
		if not nodes_dict.has(curr_pos):
			continue
			
		var neighbors = nodes_dict[curr_pos].neighbors
		
		for n_pos in neighbors:
			var sn_n = n_pos.snapped(snap_val)
			
			var move_cost: int
			var can_pass: bool
			
			# --- O VETO IMPERIAL (CURTO-CIRCUITO) ---
			# Se o destino é aliado, ignoramos a existência do terreno
			if clean_allied.has(sn_n):
				move_cost = 0
				can_pass = true
			else:
				# Se não é aliado, o terreno volta a ter autoridade
				move_cost = 1
				var terrain_blocked = false
				if terrain_mgr and terrain_mgr.has_method("blocks_movement"):
					terrain_blocked = terrain_mgr.blocks_movement(curr_pos, sn_n)
				can_pass = not terrain_blocked
			
			# --- VALIDAÇÃO DE AP E VISITA ---
			if can_pass:
				var new_cost = current.cost + move_cost
				
				if new_cost <= max_ap:
					# Atualizamos se for a primeira visita ou se achamos um caminho mais barato (custo 0)
					if not visited.has(sn_n) or visited[sn_n] > new_cost:
						visited[sn_n] = new_cost
						stack.append({"pos": sn_n, "cost": new_cost})
	
	return reachable