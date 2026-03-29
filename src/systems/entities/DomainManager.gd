# res://src/systems/entities/DomainManager.gd
extends Node2D

# Renomeado para coincidir com a busca do Main.gd: domain_manager.get("active_domains")
var active_domains: Array = []
var _painter_ref: Node2D = null

func _ready() -> void:
	add_to_group("domain_manager")

# Função para definir o painter explicitamente
func set_painter(painter: Node2D) -> void:
	_painter_ref = painter
	if _painter_ref:
		_painter_ref.update_domains(active_domains)

func _get_painter() -> Node2D:
	if _painter_ref and is_instance_valid(_painter_ref):
		return _painter_ref
	
	# Fallback: Busca pelo grupo ou pelo Main se necessário
	var grid_mgr = get_tree().get_first_node_in_group("grid_manager")
	if grid_mgr and "painter" in grid_mgr:
		_painter_ref = grid_mgr.painter
		return _painter_ref
	return null

func clear_domains() -> void:
	active_domains.clear()
	var p = _get_painter()
	if p: p.update_domains([])

func create_domain(world_pos: Vector2, color: Color, owner_id: int = -1) -> void:
	# Evita duplicatas por posição
	for d in active_domains:
		if d.pos.distance_to(world_pos) < 1.0: return
		
	# CRÍTICO: O dicionário deve conter "owner_id" para o VisibilityManager 
	# saber se deve ou não iluminar os 7 nódulos permanentemente.
	active_domains.append({
		"pos": world_pos,
		"color": color,
		"owner_id": owner_id
	})
	
	var p = _get_painter()
	if p: 
		p.update_domains(active_domains)

func spawn_domains(player_count: int, grid_mgr: Node2D, v_mgr: Node2D, turn_mgr: Node):
	clear_domains()
	
	if grid_mgr and grid_mgr.painter:
		_painter_ref = grid_mgr.painter

	var nodes = grid_mgr.data.nodes.keys()
	nodes.shuffle()
	
	var spawned = 0
	for pos in nodes:
		if spawned >= player_count: break
		
		# Critério: Apenas locais com 6 vizinhos (espaço aberto)
		if grid_mgr.data.nodes[pos].neighbors.size() == 6:
			if _is_space_free(pos):
				_create_capital(spawned, pos, grid_mgr, v_mgr, turn_mgr)
				spawned += 1
	
	# Sincronização final
	var p = _get_painter()
	if p:
		p.update_domains(active_domains)

func _is_space_free(grid_pos: Vector2) -> bool:
	for domain in active_domains:
		if domain.pos.distance_to(grid_pos) < 200.0: return false
	return true

func _create_capital(id: int, grid_pos: Vector2, grid: Node2D, v_mgr: Node2D, turn: Node):
	# Obtém cor baseada no ID do jogador
	var color_name = turn.player_colors[id]
	var p_color = turn.COLOR_OPTIONS[color_name]
	
	# Passamos o ID do dono para o dicionário de dados
	create_domain(grid_pos, p_color, id)
	
	# Spawna a unidade inicial na mesma posição
	if v_mgr and v_mgr.has_method("spawn_vagabond"):
		v_mgr.spawn_vagabond(grid_pos, id, p_color)