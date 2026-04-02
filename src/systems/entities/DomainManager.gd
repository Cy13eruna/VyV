# res://src/systems/entities/DomainManager.gd
extends Node2D

var domain_script: GDScript = null
var active_domains: Dictionary = {}
var domain_instances: Array = []

func _ready() -> void:
	add_to_group("domain_manager")
	_load_resources.call_deferred()
	
	if is_instance_valid(Signals):
		_reconnect_signal(Signals.turn_started, _on_turn_started)

func _reconnect_signal(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)
	sig.connect(callable)

func _load_resources() -> void:
	domain_script = load("res://src/systems/entities/Domain.gd")

## --- API DE CONSULTA ---

func get_domain_positions_for_player(player_id: int) -> Array:
	var positions: Array = []
	for pos_key in active_domains:
		var domain_data = active_domains[pos_key]
		if domain_data.owner_id == player_id:
			positions.append(domain_data.pos)
	return positions

func get_domain_at(world_pos: Vector2) -> Node2D:
	var clean_pos = world_pos.snapped(Vector2(0.1, 0.1))
	for inst in domain_instances:
		if is_instance_valid(inst):
			var inst_pos = inst.get("grid_pos")
			if inst_pos is Vector2 and inst_pos.distance_to(clean_pos) < 1.0:
				return inst
	return null

## --- REGRA: ESTADO DE REVOLTA E OCUPAÇÃO ---

func is_domain_occupied_by_enemy(world_pos: Vector2, owner_id: int) -> bool:
	var v_mgr = get_tree().get_first_node_in_group("vagabond_manager")
	if not is_instance_valid(v_mgr): return false
	
	var vagabond = v_mgr.get_vagabond_at(world_pos)
	if is_instance_valid(vagabond):
		return vagabond.get("owner_id") != owner_id
	return false

func is_in_revolt(home_pos: Vector2, owner_id: int) -> bool:
	return is_domain_occupied_by_enemy(home_pos, owner_id)

## --- API DE PODER ---

func get_domain_power_at(world_pos: Vector2) -> int:
	var domain = get_domain_at(world_pos)
	if is_instance_valid(domain):
		var p = domain.get("power")
		return p if p != null else 0
	return 0

func consume_power_at(world_pos: Vector2, amount: int) -> bool:
	var domain = get_domain_at(world_pos)
	if is_instance_valid(domain):
		var owner_id = domain.get("owner_id")
		
		if is_in_revolt(world_pos, owner_id):
			return true 
			
		var current_power = domain.get("power") if domain.get("power") != null else 0
		if current_power >= amount:
			if domain.has_method("add_power"):
				domain.add_power(-amount)
				
				var new_power = domain.get("power")
				if new_power <= 0 and is_instance_valid(Signals):
					Signals.domain_power_depleted.emit(owner_id)
					
				return true
	return false

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
	
	new_domain.name = "Domain_" + pos_key.replace(".", "_").replace(",", "_")
	domain_instances.append(new_domain)
	
	return new_domain

## --- LOGICA DE SPAWN ---

func spawn_domains(player_count: int, grid_mgr: Node2D, _v_mgr: Node2D, turn_mgr: Node):
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
		Vector2(1, 0), Vector2(0.5, 0.866), Vector2(-0.5, 0.866),
		Vector2(-1, 0), Vector2(-0.5, -0.866), Vector2(0.5, -0.866)
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

	var selected_indices = range(edge_positions.size())
	selected_indices.shuffle()
	selected_indices = selected_indices.slice(0, player_count)

	for i in range(selected_indices.size()):
		var idx = selected_indices[i]
		_create_capital(i, edge_positions[idx], turn_mgr, t_size)

func _create_capital(id: int, grid_pos: Vector2, turn: Node, t_size: float):
	if not is_instance_valid(turn): return
	
	var p_color = turn.get_player_color_by_id(id)
	
	# 1. Cria a entidade
	create_domain(grid_pos, p_color, id, t_size)
	
	# 💡 CORREÇÃO CRÍTICA: Se grid_pos já está na casa dos centenas (ex: 128, -221), 
	# ele já é a posição de mundo. Não multiplique novamente por t_size.
	var final_world_pos = grid_pos 
	
	# Caso o seu sistema use coordenadas axiais (ex: 1, 2), aí sim multiplicamos.
	# Verificação simples: se a distância for maior que 50, assumimos que já é posição de mundo.
	if grid_pos.length() < 50.0:
		final_world_pos = grid_pos * t_size

	if turn.has_method("register_player_start_position"):
		turn.register_player_start_position(id, final_world_pos)
		
	print("[DomainManager] P%d: Grid %s -> Câmera em %s" % [id, grid_pos, final_world_pos])

## Produção
func _on_turn_started(player_id: int, _player_color: Color, _round_number: int) -> void:
	for inst in domain_instances:
		if is_instance_valid(inst) and inst.get("owner_id") == player_id:
			var pos = inst.get("grid_pos")
			if is_domain_occupied_by_enemy(pos, player_id):
				continue
			if inst.has_method("add_power"):
				inst.add_power(1)