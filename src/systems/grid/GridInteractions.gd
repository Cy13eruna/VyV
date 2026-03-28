# res://src/systems/grid/GridInteractions.gd
extends RefCounted

# Retorna a unidade sob o clique, se houver
static func get_unit_at_pos(click_pos: Vector2, vagabonds: Array) -> Node2D:
	for v in vagabonds:
		# Nota: v.global_position se o clique for global, 
		# mas se o input_handler já converteu, use v.position
		if is_instance_valid(v) and v.global_position.distance_to(click_pos) < 45.0:
			return v
	return null

# Retorna o nó de destino se o clique for válido dentro dos alcançáveis
static func get_target_move(local_click: Vector2, reachable: Array, tolerance: float = 60.0) -> Vector2:
	# CORREÇÃO: Usamos INF para que (0,0) seja uma posição válida e não o valor de "falha"
	var closest = Vector2(INF, INF)
	var min_d = tolerance
	
	for node_pos in reachable:
		var d = node_pos.distance_to(local_click)
		if d < min_d:
			min_d = d
			closest = node_pos
			
	return closest