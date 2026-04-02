# res://src/systems/entities/VagabondManager.gd
extends Node2D

const VAGABOND_SCRIPT_PATH = "res://src/systems/entities/Vagabond.gd"
const VAGABOND_SCENE_PATH = "res://src/systems/entities/Vagabond.tscn"
const Pathfinder = preload("res://src/systems/movement/Pathfinder.gd")
const VagabondResource = preload(VAGABOND_SCRIPT_PATH)

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
	
	# 💡 NOVO: Escuta quando o poder de um domínio acaba
	if Signals.has_signal("domain_power_depleted"):
		if Signals.domain_power_depleted.is_connected(_on_domain_power_depleted):
			Signals.domain_power_depleted.disconnect(_on_domain_power_depleted)
		Signals.domain_power_depleted.connect(_on_domain_power_depleted)

# --- CONSULTAS DE OCUPAÇÃO ---

func get_occupied_nodes(exclude_unit: Node2D = null) -> Array:
	var nodes = []
	for v in active_vagabonds:
		if is_instance_valid(v) and v != exclude_unit:
			var p = v.get("grid_pos")
			if p is Vector2:
				nodes.append(p.snapped(Vector2(0.1, 0.1)))
	return nodes

# --- REAÇÃO A EVENTOS ---

func _on_turn_started(player_id: int, _p_color: Color, _round_num: int) -> void:
	if is_instance_valid(_painter) and _painter.has_method("update_reachable"):
		_painter.update_reachable([], Color.WHITE)
	
	reset_aps_for_player(player_id)

# 💡 NOVO: Quando o domínio atinge 0, exaurimos todas as unidades daquele jogador
func _on_domain_power_depleted(p_owner_id: int) -> void:
	print("[VagabondManager] Poder do domínio P%d esgotado. Exaurindo unidades..." % p_owner_id)
	
	for v in active_vagabonds:
		if is_instance_valid(v) and v.get("owner_id") == p_owner_id:
			# Forçamos o AP para 0 e chamamos a exaustão visual se existir
			v.set("ap", 0)
			if v.has_method("set_exhausted"):
				v.set_exhausted()
			
			# Notifica a UI de que o AP mudou (para atualizar as bolinhas/barra de AP)
			if Signals.has_signal("unit_ap_changed"):
				Signals.unit_ap_changed.emit(v, 0, v.get("max_ap") if v.get("max_ap") else 1)
	
	# Limpamos os destaques de movimento no mapa
	if is_instance_valid(_painter) and _painter.has_method("update_reachable"):
		_painter.update_reachable([], Color.WHITE)
	
	# Opcional: Deselecionar a unidade atual se ela pertencer ao jogador esgotado
	if is_instance_valid(Signals):
		Signals.unit_deselected.emit()

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

	# 💡 SEGURANÇA: Se a unidade já está sem AP, não mostra alcance
	if v.get("ap") <= 0:
		_painter.update_reachable([], Color.WHITE)
		return

	var pos = v.get("grid_pos")
	var m_range = v.get("move_range") if v.get("move_range") != null else 3
	var v_color = v.get("entity_color")
	if v_color == null: v_color = Color.WHITE
	
	var occupied = get_occupied_nodes(v)
	
	var allied_nodes = []
	if domain_mgr and domain_mgr.has_method("get_player_domain_nodes"):
		allied_nodes = domain_mgr.get_player_domain_nodes(v.get("owner_id"))

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
		
		if grid_manager.data.nodes[clean_pos].neighbors.size() == 6:
			var color_name = turn_manager.player_colors[spawned]
			var color_value = turn_manager.COLOR_OPTIONS[color_name]
			
			if domain_manager and domain_manager.has_method("create_domain"):
				domain_manager.create_domain(clean_pos, color_value, spawned, grid_manager.tile_size)
				print("[VagabondManager] Domínio inicial criado para P%d em %s" % [spawned, clean_pos])
				spawned += 1

func _create_vagabond(grid_pos: Vector2, color: Color, player_id: int, grid: Node2D, v_name: String = "") -> void:
	var vagabond: Node2D 
	if ResourceLoader.exists(VAGABOND_SCENE_PATH):
		var scene = load(VAGABOND_SCENE_PATH)
		if scene: vagabond = scene.instantiate()
	
	if not vagabond:
		vagabond = Node2D.new()
		vagabond.set_script(VagabondResource)
	
	var display_name = v_name if not v_name.is_empty() else "UNK"
	vagabond.name = "Vagabond_%s_P%d" % [display_name, player_id]
	
	add_child(vagabond)
	
	if vagabond.has_method("setup"):
		var world_pos = grid.grid_to_world(grid_pos) if grid.has_method("grid_to_world") else grid_pos
		vagabond.setup(world_pos, grid_pos, color, player_id, v_name)
	
	active_vagabonds.append(vagabond)
	print("[VagabondManager] Spawned: %s na posição %s" % [vagabond.name, grid_pos])

func spawn_vagabond(grid_pos: Vector2, color: Color, player_id: int, custom_name: String = "") -> void:
	var grid_mgr = get_tree().get_first_node_in_group("grid_manager")
	if grid_mgr:
		_create_vagabond(grid_pos, color, player_id, grid_mgr, custom_name)

# --- UTILITÁRIOS ---

func get_vagabond_at(grid_pos: Vector2) -> Node2D:
	var target = grid_pos.snapped(Vector2(0.1, 0.1))
	for v in active_vagabonds:
		if is_instance_valid(v):
			var v_grid_pos = v.get("grid_pos")
			if v_grid_pos is Vector2 and v_grid_pos.distance_to(target) < 0.1:
				return v
	return null

func _clear_all() -> void:
	var v_script: Object = VagabondResource
	if v_script and v_script.has_method(&"reset_vagabond_registry"):
		v_script.call(&"reset_vagabond_registry")
		
	for v in active_vagabonds:
		if is_instance_valid(v): 
			v.queue_free()
	active_vagabonds.clear()