# res://src/systems/movement/Pathfinder.gd
extends RefCounted

static func get_reachable_cells(
	start_pos: Vector2, 
	max_ap: int, 
	grid_resource: Object, 
	terrain_mgr: Object, 
	occupied_nodes: Array = []
) -> Array:
	
	var reachable: Array = []
	
	if not grid_resource or not "nodes" in grid_resource:
		return reachable
		
	var nodes_dict = grid_resource.nodes
	
	# REGRA DE OURO: Snapping na posição inicial
	var clean_start = start_pos.snapped(Vector2(0.1, 0.1))
	
	# visited armazena { posicao: custo_acumulado }
	var visited: Dictionary = {clean_start: 0}
	var stack: Array = [{"pos": clean_start, "cost": 0}]
	
	# Snapping na lista de ocupação para comparação segura
	var clean_occupied = []
	for pos in occupied_nodes:
		clean_occupied.append(pos.snapped(Vector2(0.1, 0.1)))
	
	while stack.size() > 0:
		var current = stack.pop_front()
		var curr_pos = current.pos.snapped(Vector2(0.1, 0.1))
		
		if not curr_pos in reachable:
			if not curr_pos in clean_occupied:
				reachable.append(curr_pos)
		
		if current.cost >= max_ap:
			continue
			
		if not nodes_dict.has(curr_pos):
			continue
			
		var neighbors = nodes_dict[curr_pos].neighbors
		
		for n_pos in neighbors:
			var sn_n = n_pos.snapped(Vector2(0.1, 0.1))
			
			var terrain_blocked = false
			if terrain_mgr and terrain_mgr.has_method("blocks_movement"):
				terrain_blocked = terrain_mgr.blocks_movement(curr_pos, sn_n)
			
			if not terrain_blocked:
				var new_cost = current.cost + 1
				
				if not visited.has(sn_n) or visited[sn_n] > new_cost:
					visited[sn_n] = new_cost
					stack.append({"pos": sn_n, "cost": new_cost})
	
	return reachable