# res://src/systems/grid/GridManager.gd
extends Node2D

# Módulos estáticos
const Interaction = preload("res://src/systems/grid/GridInteractions.gd")
const Mover = preload("res://src/systems/movement/UnitMover.gd")
const PathfinderScript = preload("res://src/systems/movement/Pathfinder.gd") 

const VagabondScript = preload("res://src/systems/entities/Vagabond.gd")

# Componentes
const GridDataScript = preload("res://src/systems/grid/GridData.gd")
const GridPainterScript = preload("res://src/systems/grid/GridPainter.gd")

var map_radius: int = 5 
var tile_size: float = 64.0

var data: GridDataScript = GridDataScript.new()
var painter: Node2D = null

# Memória de nós tipada
var reachable_nodes: Array[Vector2] = []

func _ready() -> void:
	add_to_group("grid_manager")
	
	painter = get_node_or_null("GridPainter")
	if not painter:
		painter = GridPainterScript.new()
		painter.name = "GridPainter"
		add_child(painter)
	
	if is_instance_valid(Signals):
		# Esta era a linha causando o erro: a função _on_unit_selected precisa existir abaixo
		Signals.unit_selected.connect(_on_unit_selected)
		Signals.unit_deselected.connect(clear_highlights)
		Signals.turn_started.connect(func(_id, _col): clear_highlights())

# --- REAÇÃO A EVENTOS ---

func _on_unit_selected(unit: Node2D) -> void:
	var vagabond = unit as VagabondScript
	if not vagabond: return
	
	var vagabond_mgr = get_tree().get_first_node_in_group("vagabond_manager")
	var all_units = vagabond_mgr.active_vagabonds if vagabond_mgr else []
	
	show_reachable_for.call_deferred(vagabond, all_units)

# --- SERVIÇOS DE GEOMETRIA ---

func world_to_grid(p_world_pos: Vector2) -> Vector2:
	var local_pos = to_local(p_world_pos)
	var closest = data.get_closest_node(local_pos, tile_size * 2.0)
	return closest.snapped(Vector2(0.1, 0.1))

# --- GESTÃO DE ALCANCE ---

func is_node_reachable(p_grid_pos: Vector2) -> bool:
	var target = p_grid_pos.snapped(Vector2(0.1, 0.1))
	for node in reachable_nodes:
		if node.distance_to(target) < 0.05:
			return true
	return false

func show_reachable_for(unit: Node2D, all_units: Array) -> void:
	clear_highlights()
	
	var v = unit as VagabondScript
	if not is_instance_valid(v) or v.ap <= 0: 
		return

	var u_pos = v.grid_pos.snapped(Vector2(0.1, 0.1))
	var terrain_mgr = painter.get("terrain_ref") if painter else null
	
	var allied_domains = _get_allied_domain_positions(v.owner_id)
	
	var occupied: Array[Vector2] = []
	for u in all_units:
		if is_instance_valid(u) and u != v:
			occupied.append(u.grid_pos.snapped(Vector2(0.1, 0.1)))
	
	var raw_nodes = PathfinderScript.get_reachable_cells(
		u_pos, 
		v.ap, 
		data, 
		terrain_mgr,
		occupied,
		allied_domains
	)
	
	for node in raw_nodes:
		var sn_node = node.snapped(Vector2(0.1, 0.1))
		if sn_node.distance_to(u_pos) > 0.1:
			reachable_nodes.append(sn_node)
	
	if painter:
		painter.update_reachable(reachable_nodes, v.entity_color)

func clear_highlights() -> void:
	reachable_nodes.clear()
	if painter:
		painter.update_reachable([], Color.WHITE)

# --- EXECUÇÃO DE MOVIMENTO ---

func request_move(unit: Node2D, target_grid_pos: Vector2) -> void:
	var v = unit as VagabondScript
	if not is_instance_valid(v): return
	
	var target = target_grid_pos.snapped(Vector2(0.1, 0.1))
	var old_pos = v.grid_pos.snapped(Vector2(0.1, 0.1))
	
	var allied_list = _get_allied_domain_positions(v.owner_id)
	var is_free_move = false
	
	for allied_pos in allied_list:
		if target.distance_to(allied_pos) < 0.05:
			is_free_move = true
			break
	
	if not is_free_move:
		v.use_ap()
	
	Mover.move_unit(v, target, self)
	
	if is_instance_valid(Signals):
		Signals.unit_moved.emit(v, old_pos, target)
	
	clear_highlights()

# --- AUXILIARES ---

func _get_allied_domain_positions(p_owner_id: int) -> Array:
	var domain_mgr = get_tree().get_first_node_in_group("domain_manager")
	if domain_mgr and domain_mgr.has_method("get_domain_positions_for_player"):
		var raw_pos = domain_mgr.get_domain_positions_for_player(p_owner_id)
		var clean_pos = []
		for p in raw_pos:
			clean_pos.append(p.snapped(Vector2(0.1, 0.1)))
		return clean_pos
	return []

func setup_map(p_radius: int) -> void:
	map_radius = p_radius
	data.generate_hex_grid(map_radius, tile_size)
	if painter:
		painter.setup(data, tile_size)