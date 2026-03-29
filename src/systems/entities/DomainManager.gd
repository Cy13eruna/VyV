# res://src/systems/entities/DomainManager.gd
extends Node2D

var active_domains_data: Array = []
var _painter_ref: Node2D = null

# Função para definir o painter explicitamente via código
func set_painter(painter: Node2D) -> void:
	_painter_ref = painter
	if _painter_ref:
		_painter_ref.update_domains(active_domains_data)

func _get_painter() -> Node2D:
	if _painter_ref and is_instance_valid(_painter_ref):
		return _painter_ref
	
	# Fallback: Busca pelo GridManager se a referência direta falhar
	var grid_mgr = get_tree().get_first_node_in_group("grid_manager")
	if grid_mgr and "painter" in grid_mgr:
		_painter_ref = grid_mgr.painter
		return _painter_ref
	return null

func clear_domains() -> void:
	active_domains_data.clear()
	var p = _get_painter()
	if p: p.update_domains([])

func create_domain(world_pos: Vector2, color: Color, _tile_size: float = 0.0) -> void:
	# Verifica se já existe um domínio nessa posição (evita duplicatas no log)
	for d in active_domains_data:
		if d.pos.distance_to(world_pos) < 1.0: return
		
	active_domains_data.append({
		"pos": world_pos,
		"color": color
	})
	
	var p = _get_painter()
	if p: 
		p.update_domains(active_domains_data)
	# Removi o push_warning para não poluir seu console, 
	# pois o spawn_domains fará a atualização final.

func spawn_domains(player_count: int, grid_mgr: Node2D, v_mgr: Node2D, turn_mgr: Node):
	clear_domains()
	# CONFIGURAÇÃO CRÍTICA: Salva o painter antes de começar o spawn
	if grid_mgr and grid_mgr.painter:
		_painter_ref = grid_mgr.painter

	var nodes = grid_mgr.data.nodes.keys()
	nodes.shuffle()
	
	var spawned = 0
	for pos in nodes:
		if spawned >= player_count: break
		if grid_mgr.data.nodes[pos].neighbors.size() == 6:
			if _is_space_free(pos):
				_create_capital(spawned, pos, grid_mgr, v_mgr, turn_mgr)
				spawned += 1
	
	# Sincronização final forçada
	if _painter_ref:
		_painter_ref.update_domains(active_domains_data)

func _is_space_free(grid_pos: Vector2) -> bool:
	for domain in active_domains_data:
		if domain.pos.distance_to(grid_pos) < 200.0: return false
	return true

func _create_capital(id: int, grid_pos: Vector2, grid: Node2D, v_mgr: Node2D, turn: Node):
	var color_name = turn.player_colors[id]
	var p_color = turn.COLOR_OPTIONS[color_name]
	
	# Chamada interna
	create_domain(grid_pos, p_color)
	
	if v_mgr.has_method("spawn_vagabond"):
		v_mgr.spawn_vagabond(grid_pos, id, p_color)