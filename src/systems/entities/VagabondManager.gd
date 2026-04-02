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
		_reconnect(Signals.turn_started, _on_turn_started)
	
	if Signals.has_signal("turn_ended"):
		_reconnect(Signals.turn_ended, _on_turn_ended)
	
	if Signals.has_signal("domain_power_depleted"):
		_reconnect(Signals.domain_power_depleted, _on_domain_power_depleted)

func _reconnect(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)
	sig.connect(callable)

# --- CONSULTAS DE OCUPAÇÃO ---

func get_occupied_nodes(exclude_unit: Node2D = null) -> Array:
	var nodes = []
	for v in active_vagabonds:
		if is_instance_valid(v) and v != exclude_unit:
			var p = v.get("grid_pos")
			if p is Vector2:
				nodes.append(p.snapped(Vector2(0.1, 0.1)))
	return nodes

func get_vagabond_at(grid_pos: Vector2) -> Node2D:
	var target = grid_pos.snapped(Vector2(0.1, 0.1))
	for v in active_vagabonds:
		if is_instance_valid(v):
			var v_grid_pos = v.get("grid_pos")
			if v_grid_pos is Vector2 and v_grid_pos.distance_to(target) < 0.1:
				return v
	return null

# --- REAÇÃO A EVENTOS ---

func _on_turn_started(_player_id: int, _p_color: Color, _round_num: int) -> void:
	if is_instance_valid(_painter) and _painter.has_method("update_reachable"):
		_painter.update_reachable([], Color.WHITE)

func _on_turn_ended(player_id: int) -> void:
	reset_aps_for_player(player_id)

func _on_domain_power_depleted(p_owner_id: int) -> void:
	print("[VagabondManager] Poder do domínio P%d esgotado. Exaurindo unidades..." % p_owner_id)
	for v in active_vagabonds:
		if is_instance_valid(v) and v.get("owner_id") == p_owner_id:
			v.set("ap", 0)
			if v.has_method("set_exhausted"):
				v.set_exhausted()
			
			if Signals.has_signal("unit_ap_changed"):
				Signals.unit_ap_changed.emit(v, 0, v.get("max_ap") if v.get("max_ap") else 1)
	
	if is_instance_valid(_painter) and _painter.has_method("update_reachable"):
		_painter.update_reachable([], Color.WHITE)
	
	if is_instance_valid(Signals):
		Signals.unit_deselected.emit()

func reset_aps_for_player(player_id: int) -> void:
	var count = 0
	for v in active_vagabonds:
		if is_instance_valid(v) and v.get("owner_id") == player_id:
			if v.has_method("restore_ap"):
				v.restore_ap()
				count += 1
	print("[VagabondManager] Turno encerrado para P%d: %d unidades recarregadas." % [player_id, count])

# --- LÓGICA DE INTERAÇÃO ---

func select_vagabond(v: Node2D) -> void:
	if not is_instance_valid(v) or not _painter: return
	
	var grid_mgr = get_tree().get_first_node_in_group("grid_manager")
	var terrain_mgr = get_tree().get_first_node_in_group("terrain_manager")
	var domain_mgr = get_tree().get_first_node_in_group("domain_manager")
	
	if not grid_mgr or v.get("ap") <= 0:
		_painter.update_reachable([], Color.WHITE)
		return

	var pos = v.get("grid_pos")
	var m_range = v.get("move_range") if v.get("move_range") != null else 3
	var v_color = v.get("entity_color") if v.get("entity_color") != null else Color.WHITE
	
	var occupied = get_occupied_nodes(v)
	var allied_nodes = []
	if domain_mgr and domain_mgr.has_method("get_player_domain_nodes"):
		allied_nodes = domain_mgr.get_player_domain_nodes(v.get("owner_id"))

	var reachable = Pathfinder.get_reachable_cells(
		pos, m_range, grid_mgr.data, terrain_mgr, occupied, allied_nodes
	)
	
	_painter.update_reachable(reachable, v_color)

# --- CRIAÇÃO E SPAWN ---

func spawn_vagabond(grid_pos: Vector2, color: Color, player_id: int, custom_name: String = "") -> void:
	var grid_mgr = get_tree().get_first_node_in_group("grid_manager")
	if not grid_mgr: return

	var vagabond: Node2D 
	if ResourceLoader.exists(VAGABOND_SCENE_PATH):
		var scene = load(VAGABOND_SCENE_PATH)
		if scene: vagabond = scene.instantiate()
	
	if not vagabond:
		vagabond = Node2D.new()
		vagabond.set_script(VagabondResource)
	
	var display_name = custom_name if not custom_name.is_empty() else "UNK"
	vagabond.name = "Vagabond_%s_P%d" % [display_name, player_id]
	add_child(vagabond)
	
	if vagabond.has_method("setup"):
		var world_pos = grid_mgr.grid_to_world(grid_pos) if grid_mgr.has_method("grid_to_world") else grid_pos
		vagabond.setup(world_pos, grid_pos, color, player_id, custom_name)
	
	active_vagabonds.append(vagabond)
	print("[VagabondManager] Spawned: %s na posição %s" % [vagabond.name, grid_pos])

func clear_all() -> void:
	var v_script: Object = VagabondResource
	if v_script and v_script.has_method(&"reset_vagabond_registry"):
		v_script.call(&"reset_vagabond_registry")
		
	for v in active_vagabonds:
		if is_instance_valid(v): 
			v.queue_free()
	active_vagabonds.clear()