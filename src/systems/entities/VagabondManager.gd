# res://src/systems/entities/VagabondManager.gd
extends Node2D

const VAGABOND_SCRIPT_PATH = "res://src/systems/entities/Vagabond.gd"
const VAGABOND_SCENE_PATH = "res://src/systems/entities/Vagabond.tscn"
const Pathfinder = preload("res://src/systems/movement/Pathfinder.gd") # Certifique-se do caminho correto

var active_vagabonds: Array[Node2D] = []
var _painter: Node2D = null

func _ready() -> void:
	add_to_group("vagabond_manager")
	global_position = Vector2.ZERO
	_painter = get_tree().get_first_node_in_group("painter")
	if is_instance_valid(Signals):
		_reconnect_signals()

func _reconnect_signals() -> void:
	if Signals.has_signal("turn_started"):
		if Signals.turn_started.is_connected(_on_turn_started):
			Signals.turn_started.disconnect(_on_turn_started)
		Signals.turn_started.connect(_on_turn_started)

# --- CONSULTAS DE OCUPAÇÃO ---

## Retorna um Array de Vector2 com as posições de todos os vagabonds vivos
func get_occupied_nodes(exclude_unit: Node2D = null) -> Array:
	var nodes = []
	for v in active_vagabonds:
		if is_instance_valid(v) and v != exclude_unit:
			var p = v.get("grid_pos")
			if p is Vector2:
				nodes.append(p.snapped(Vector2(0.1, 0.1)))
	return nodes

# --- REAÇÃO A EVENTOS ---

func _on_turn_started(player_id: int, _player_color: Color) -> void:
	if _painter and _painter.has_method("update_reachable"):
		_painter.update_reachable([], Color.WHITE)
	reset_aps_for_player(player_id)

func reset_aps_for_player(player_id: int) -> void:
	var count = 0
	for v in active_vagabonds:
		if is_instance_valid(v):
			if v.get("owner_id") == player_id and v.has_method("restore_ap"):
				v.restore_ap()
				count += 1
	print("[VagabondManager] Turno do Jogador %d: %d unidades restauradas." % [player_id, count])

# --- LÓGICA DE INTERAÇÃO ---

func select_vagabond(v: Node2D) -> void:
	if not is_instance_valid(v) or not _painter: return
	
	var grid_mgr = get_tree().get_first_node_in_group("grid_manager")
	var terrain_mgr = get_tree().get_first_node_in_group("terrain_manager")
	var domain_mgr = get_tree().get_first_node_in_group("domain_manager")
	
	if not grid_mgr: return

	var pos = v.get("grid_pos")
	var m_range = v.get("move_range") if v.get("move_range") != null else 3
	var v_color = v.get("entity_color")
	if v_color == null: v_color = Color.WHITE
	
	# Obtemos nós ocupados por OUTRAS unidades
	var occupied = get_occupied_nodes(v)
	
	# Obtemos domínios aliados para bônus de movimento (custo 0)
	var allied_nodes = []
	if domain_mgr and domain_mgr.has_method("get_player_domain_nodes"):
		allied_nodes = domain_mgr.get_player_domain_nodes(v.get("owner_id"))

	# Cálculo de alcance via Pathfinder atualizado
	var reachable = Pathfinder.get_reachable_cells(
		pos, 
		m_range, 
		grid_mgr.data, 
		terrain_mgr, 
		occupied, 
		allied_nodes
	)
	
	_painter.update_reachable(reachable, v_color)

# --- CRIAÇÃO E SPAWN ---

func spawn_players(player_count: int, turn_manager: Node, grid_manager: Node2D) -> void:
	_clear_all()
	var domain_manager = get_tree().get_first_node_in_group("domain_manager")
	
	if not grid_manager or not grid_manager.data: return

	var all_nodes = grid_manager.data.nodes.keys()
	all_nodes.shuffle()

	var spawned = 0
	for node_pos in all_nodes:
		if spawned >= player_count: break
		var clean_pos = node_pos.snapped(Vector2(0.1, 0.1))
		
		# Verificação de spawn: 6 vizinhos e área limpa de outras unidades
		if grid_manager.data.nodes[clean_pos].neighbors.size() == 6 and _is_area_clear(clean_pos):
			var color_name = turn_manager.player_colors[spawned]
			var color_value = turn_manager.COLOR_OPTIONS[color_name]
			
			if domain_manager and domain_manager.has_method("create_domain"):
				domain_manager.create_domain(clean_pos, color_value, spawned, grid_manager.tile_size)
			
			_create_vagabond(clean_pos, color_value, spawned, grid_manager)
			spawned += 1

func _create_vagabond(grid_pos: Vector2, color: Color, player_id: int, grid: Node2D) -> void:
	var vagabond: Node2D 
	if ResourceLoader.exists(VAGABOND_SCENE_PATH):
		var scene = load(VAGABOND_SCENE_PATH)
		if scene: vagabond = scene.instantiate()
	
	if not vagabond:
		vagabond = Node2D.new()
		var script = load(VAGABOND_SCRIPT_PATH)
		if script: vagabond.set_script(script)
	
	vagabond.name = "Vagabond_P%d_%d" % [player_id, active_vagabonds.size()]
	add_child(vagabond)
	
	if vagabond.has_method("setup"):
		vagabond.setup(grid_pos, grid_pos, color, player_id)
	
	active_vagabonds.append(vagabond)

func get_vagabond_at(grid_pos: Vector2) -> Node2D:
	var target = grid_pos.snapped(Vector2(0.1, 0.1))
	for v in active_vagabonds:
		if is_instance_valid(v):
			var v_grid_pos = v.get("grid_pos")
			if v_grid_pos is Vector2 and v_grid_pos.distance_to(target) < 0.1:
				return v
	return null

func _is_area_clear(pos: Vector2) -> bool:
	# Verificação baseada em distância de grid (Vector2.distance_to para posições snapped)
	for v in active_vagabonds:
		if is_instance_valid(v):
			var v_grid_pos = v.get("grid_pos")
			if v_grid_pos is Vector2 and v_grid_pos.distance_to(pos) < 100.0: 
				return false
	return true

func _clear_all() -> void:
	for v in active_vagabonds:
		if is_instance_valid(v): v.queue_free()
	active_vagabonds.clear()