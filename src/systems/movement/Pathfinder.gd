# res://src/systems/movement/Pathfinder.gd
extends RefCounted

## Calcula os nós alcançáveis, respeitando custo de AP, bloqueios de terreno e ocupação de unidades.
static func get_reachable_cells(
	start_pos: Vector2, 
	max_ap: int, 
	grid_resource: Object, 
	terrain_mgr: Object, 
	occupied_nodes: Array = [] # Novo parâmetro: lista de Vector2 com posições de outros Vagabonds
) -> Array:
	
	var reachable: Array = []
	
	if not grid_resource or not "nodes" in grid_resource:
		return reachable
		
	var nodes_dict = grid_resource.nodes
	
	# visited armazena { posicao: custo_acumulado }
	var visited: Dictionary = {start_pos: 0}
	var stack: Array = [{"pos": start_pos, "cost": 0}]
	
	while stack.size() > 0:
		var current = stack.pop_front()
		
		# REGRA DE OCUPAÇÃO: 
		# Só adicionamos aos alcançáveis (destinos válidos) se o nó NÃO estiver ocupado.
		# A origem (start_pos) é ignorada aqui pois já a removemos no GridManager.
		if not current.pos in reachable:
			if not current.pos in occupied_nodes:
				reachable.append(current.pos)
		
		# Se já atingiu o limite de movimento, não expande para os vizinhos
		if current.cost >= max_ap:
			continue
			
		if not nodes_dict.has(current.pos):
			continue
			
		var neighbors = nodes_dict[current.pos].neighbors
		
		for n_pos in neighbors:
			# 1. Checagem de Terreno (Montanhas/Rios)
			var terrain_blocked = false
			if terrain_mgr and terrain_mgr.has_method("blocks_movement"):
				terrain_blocked = terrain_mgr.blocks_movement(current.pos, n_pos)
			
			# 2. Checagem de Unidade (Opcional: Bloqueio de PASSAGEM)
			# Se você quiser que unidades INIMIGAS bloqueiem o caminho, adicione aqui.
			# Por enquanto, unidades apenas bloqueiam o DESTINO (checado acima).
			
			if not terrain_blocked:
				var new_cost = current.cost + 1
				
				if not visited.has(n_pos) or visited[n_pos] > new_cost:
					visited[n_pos] = new_cost
					stack.append({"pos": n_pos, "cost": new_cost})
	
	return reachable