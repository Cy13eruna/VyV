# res://src/systems/entities/DomainManager.gd
extends Node2D

var domain_script: GDScript = null
var active_domains: Dictionary = {}
var domain_instances: Array = []

func _ready() -> void:
	add_to_group("domain_manager")
	_load_resources.call_deferred()
	
	# Conecta ao sinal de virada de turno no EventBus
	# ATUALIZADO: O sinal agora envia (id, color, round_number)
	if is_instance_valid(Signals) and Signals.has_signal("turn_started"):
		Signals.turn_started.connect(_on_turn_started)

func _load_resources() -> void:
	domain_script = load("res://src/systems/entities/Domain.gd")

## --- API DE CONSULTA ---

func get_domain_positions_for_player(player_id: int) -> Array:
	var positions: Array = []
	for pos_key in active_domains:
		var domain = active_domains[pos_key]
		if domain.owner_id == player_id:
			positions.append(domain.pos)
	return positions

func get_domain_at(world_pos: Vector2) -> Node2D:
	var clean_pos = world_pos.snapped(Vector2(0.1, 0.1))
	for inst in domain_instances:
		if is_instance_valid(inst) and inst.get("grid_pos").distance_to(clean_pos) < 1.0:
			return inst
	return null

## --- GESTÃO DE DOMÍNIOS ---

func clear_domains() -> void:
	active_domains.clear()
	for inst in domain_instances:
		if is_instance_valid(inst):
			inst.queue_free()
	domain_instances.clear()

func create_domain(world_pos: Vector2, color: Color, owner_id: int = -1, tile_size: float = 64.0) -> Node2D:
	var clean_pos = world_pos.snapped(Vector2(0.1, 0.1))
	var pos_key = str(clean_pos)
	
	if active_domains.has(pos_key):
		return get_domain_at(clean_pos)
			
	active_domains[pos_key] = {
		"pos": clean_pos,
		"color": color,
		"owner_id": owner_id
	}
	
	if not domain_script:
		domain_script = load("res://src/systems/entities/Domain.gd")

	var new_domain = Node2D.new()
	new_domain.set_script(domain_script)
	add_child(new_domain)
	
	if new_domain.has_method("setup_domain"):
		new_domain.setup_domain(clean_pos, clean_pos, color, owner_id, tile_size)
	
	new_domain.name = "Domain_" + pos_key.replace(".", "_")
	domain_instances.append(new_domain)
	
	return new_domain

## --- LÓGICA DE SPAWN ---

func spawn_domains(player_count: int, grid_mgr: Node2D, v_mgr: Node2D, turn_mgr: Node):
	clear_domains()
	if not grid_mgr or not grid_mgr.data: return
	
	var t_size = grid_mgr.get("tile_size") if "tile_size" in grid_mgr else 64.0
	var nodes = grid_mgr.data.nodes.keys()
	
	var valid_nodes = []
	for pos in nodes:
		if grid_mgr.data.nodes[pos].neighbors.size() == 6:
			valid_nodes.append(pos)
	
	if valid_nodes.is_empty(): return

	var directions = [
		Vector2(1, 0),          # 0: Direita
		Vector2(0.5, 0.866),    # 1: Sudeste
		Vector2(-0.5, 0.866),   # 2: Sudoeste
		Vector2(-1, 0),         # 3: Esquerda
		Vector2(-0.5, -0.866),  # 4: Noroeste
		Vector2(0.5, -0.866)    # 5: Nordeste
	]
	
	var edge_positions = []
	for dir in directions:
		var best_node = Vector2.ZERO
		var max_proj = -INF
		for pos in valid_nodes:
			var proj = pos.dot(dir) 
			if proj > max_proj:
				max_proj = proj
				best_node = pos
		edge_positions.append(best_node)

	if edge_positions.size() < 6:
		edge_positions.shuffle()
		var spawned = 0
		for i in range(min(player_count, edge_positions.size())):
			_create_capital(spawned, edge_positions[i], grid_mgr, v_mgr, turn_mgr, t_size)
			spawned += 1
		return

	var selected_indices = []
	match player_count:
		2:
			selected_indices = [0, 1, 2, 3, 4, 5]
			selected_indices.shuffle()
			selected_indices = selected_indices.slice(0, 2)
		3:
			var offset = randi() % 2
			selected_indices = [offset, offset + 2, offset + 4]
		4:
			var offset = randi() % 3
			selected_indices = [offset, (offset + 1) % 6, (offset + 3) % 6, (offset + 4) % 6]
		6:
			selected_indices = [0, 1, 2, 3, 4, 5]
		_:
			selected_indices = [0, 1, 2, 3, 4, 5]
			selected_indices.shuffle()
			selected_indices = selected_indices.slice(0, player_count)

	selected_indices.shuffle()

	var spawned = 0
	for idx in selected_indices:
		_create_capital(spawned, edge_positions[idx], grid_mgr, v_mgr, turn_mgr, t_size)
		spawned += 1

func _create_capital(id: int, grid_pos: Vector2, grid: Node2D, v_mgr: Node2D, turn: Node, t_size: float):
	if not turn: return
	var color_options = turn.get("COLOR_OPTIONS")
	var player_colors = turn.get("player_colors")
	
	if color_options == null or player_colors == null or id >= player_colors.size():
		return
	
	var color_name = player_colors[id]
	var p_color = color_options[color_name]
	
	var domain_inst = create_domain(grid_pos, p_color, id, t_size)
	
	var v_name = ""
	if is_instance_valid(domain_inst) and domain_inst.has_method("generate_vagabond_name"):
		v_name = domain_inst.generate_vagabond_name()
	
	if v_mgr and v_mgr.has_method("_create_vagabond"):
		v_mgr._create_vagabond(grid_pos, p_color, id, grid, v_name)

## ATUALIZADO: Agora recebe o round_number para evitar o bug do 2º jogador
func _on_turn_started(player_id: int, _player_color: Color, round_number: int) -> void:
	# Na primeira rodada, os domínios já nascem com 1 de poder.
	# Ignoramos a produção para que o 2º jogador (e seguintes) não ganhem poder extra no setup.
	if round_number == 1:
		return
		
	for inst in domain_instances:
		if is_instance_valid(inst) and inst.get("owner_id") == player_id:
			if inst.has_method("add_power"):
				inst.add_power(1)