# res://src/systems/entities/VagabondManager.gd
extends Node2D

var vagabond_script: GDScript
var active_vagabonds: Array = []

func _ready() -> void:
	global_position = Vector2.ZERO
	var paths = ["res://src/systems/entities/Vagabond.gd", "res://src/entities/Vagabond.gd"]
	for path in paths:
		if ResourceLoader.exists(path):
			vagabond_script = load(path)
			break

func restore_all_units_ap() -> void:
	for v in active_vagabonds:
		if is_instance_valid(v) and v.has_method("restore_ap"):
			v.restore_ap()

## Função original mantida para estabilidade, mas atualizada com a lógica de Domínio
func spawn_players(player_count: int, turn_manager: Node, map_radius: int) -> void:
	_clear_all()
	
	var grid_manager = get_parent().get_node_or_null("GridManager")
	var domain_manager = get_parent().get_node_or_null("DomainManager")
	if not grid_manager: return

	var all_nodes = grid_manager.data.nodes.keys()
	all_nodes.shuffle()

	var spawned = 0
	for node_pos in all_nodes:
		if spawned >= player_count: break
		
		# Critério: Longe das bordas e espaço livre para o hexagrama (distância de 300px)
		if grid_manager.data.nodes[node_pos].neighbors.size() == 6 and _is_area_clear(node_pos):
			var color_name = turn_manager.player_colors[spawned]
			var color_value = turn_manager.COLOR_OPTIONS[color_name]
			
			# 1. Spawna o Domínio visual (Hexagrama)
			if domain_manager:
				domain_manager.create_domain(node_pos, color_value, grid_manager.tile_size)
			
			# 2. Instancia o Vagabond no centro
			_create_vagabond(node_pos, color_value, spawned, grid_manager)
			spawned += 1

func _is_area_clear(pos: Vector2) -> bool:
	for v in active_vagabonds:
		if v.grid_pos.distance_to(pos) < 3.0: return false
	return true

func _create_vagabond(grid_pos: Vector2, color: Color, id: int, grid: Node2D) -> void:
	var vagabond = Node2D.new()
	vagabond.set_script(vagabond_script)
	vagabond.name = "Vagabond_P" + str(id)
	add_child(vagabond)
	
	var world_pos = grid.to_global(grid_pos)
	if vagabond.has_method("setup"):
		vagabond.setup(world_pos, grid_pos, color, id)
		vagabond.global_position = world_pos
		if "vagabond_color" in vagabond: vagabond.vagabond_color = color
		active_vagabonds.append(vagabond)

func _clear_all() -> void:
	for v in active_vagabonds:
		if is_instance_valid(v): v.queue_free()
	active_vagabonds.clear()

func get_vagabond_at(pos: Vector2, radius: float = 60.0) -> Node2D:
	for v in active_vagabonds:
		if is_instance_valid(v) and v.global_position.distance_to(pos) < radius:
			return v
	return null