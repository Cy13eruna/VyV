# res://src/systems/grid/GridInteractions.gd
extends RefCounted

## Retorna a unidade sob o clique
static func get_unit_at_pos(click_pos: Vector2, vagabonds: Array) -> Node2D:
	for v in vagabonds:
		if not is_instance_valid(v): continue
		
		# Usamos global_position para garantir consistência com o evento de Input
		if v.global_position.distance_to(click_pos) < 50.0: # Tolerância levemente aumentada
			return v
	return null

## Retorna o nó de destino se o clique for válido dentro dos alcançáveis.
## ESTA FUNÇÃO É O CORTE FINAL: Ela não consulta o terreno, apenas a lista 'reachable'.
static func get_target_move(local_click: Vector2, reachable: Array, tolerance: float = 80.0) -> Vector2:
	var closest = Vector2(INF, INF)
	var min_d = tolerance
	
	# Se a lista de alcançáveis estiver vazia, nem processamos
	if reachable.is_empty():
		return closest
	
	for node_pos in reachable:
		# Compara a distância entre o clique do mouse e os nós que o Pathfinder já tingiu de azul
		var d = node_pos.distance_to(local_click)
		if d < min_d:
			min_d = d
			closest = node_pos
			
	# Se retornou algo diferente de INF, o movimento é OBRIGATÓRIO, 
	# pois o Pathfinder já validou que este nó é seguro/aliado.
	return closest