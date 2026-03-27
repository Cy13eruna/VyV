# res://src/systems/movement/Pathfinder.gd
extends RefCounted

## Calcula os nós alcançáveis a partir de uma posição, respeitando o custo de AP e bloqueios de terreno.
## O modificador 'static' permite chamar Pathfinder.get_reachable_cells() sem dar .new()
static func get_reachable_cells(start_pos: Vector2, max_ap: int, grid_resource: Object, terrain_mgr: Object) -> Array:
	var reachable: Array = []
	
	# Early exit: se não houver dados de grid, retorna vazio
	if not grid_resource or not "nodes" in grid_resource:
		return reachable
		
	var nodes_dict = grid_resource.nodes
	
	# Controle de busca (Dijkstra/BFS simplificado)
	# visited armazena { posicao: custo_acumulado }
	var visited: Dictionary = {start_pos: 0}
	var stack: Array = [{"pos": start_pos, "cost": 0}]
	
	while stack.size() > 0:
		var current = stack.pop_front() # Usar pop_front para BFS (expansão uniforme)
		
		# Registra como alcançável se ainda não estiver na lista
		if not current.pos in reachable:
			reachable.append(current.pos)
		
		# Se já atingiu o limite de movimento, não expande para os vizinhos
		if current.cost >= max_ap:
			continue
			
		# Verifica se a posição atual existe no dicionário do grid
		if not nodes_dict.has(current.pos):
			continue
			
		var neighbors = nodes_dict[current.pos].neighbors
		
		for n_pos in neighbors:
			# REGRA DE OURO: Pergunta ao TerrainManager se a passagem entre as células está bloqueada
			var blocked = false
			if terrain_mgr and terrain_mgr.has_method("blocks_movement"):
				# O terreno checa se a 'edge' (aresta) entre current e neighbor é Hills ou Water
				blocked = terrain_mgr.blocks_movement(current.pos, n_pos)
			
			if not blocked:
				var new_cost = current.cost + 1
				
				# Se ainda não visitamos ou encontramos um caminho mais barato
				if not visited.has(n_pos) or visited[n_pos] > new_cost:
					visited[n_pos] = new_cost
					stack.append({"pos": n_pos, "cost": new_cost})
	
	return reachable