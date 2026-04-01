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
	
	# 1. Garantir que o Painter exista
	painter = get_node_or_null("GridPainter")
	if not painter:
		painter = GridPainterScript.new()
		painter.name = "GridPainter"
		add_child(painter)
	
	# 2. Conectar Sinais
	if is_instance_valid(Signals):
		if not Signals.unit_selected.is_connected(_on_unit_selected):
			Signals.unit_selected.connect(_on_unit_selected)
		if not Signals.unit_deselected.is_connected(clear_highlights):
			Signals.unit_deselected.connect(clear_highlights)
		if not Signals.turn_started.is_connected(_on_turn_started):
			Signals.turn_started.connect(_on_turn_started)

func _on_turn_started(player_id: int, p_color: Color, _round_num: int) -> void:	clear_highlights()

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
	
	# Tenta pegar a referência de terreno do painter ou do manager global
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

# --- INICIALIZAÇÃO CRÍTICA ---

func setup_map(p_radius: int) -> void:
	map_radius = p_radius
	
	# 1. Gera a estrutura geométrica básica
	data.generate_hex_grid(map_radius, tile_size)
	
	# 2. Busca o TerrainManager (Ele deve estar na árvore ou em um grupo)
	var terrain_mgr = get_tree().get_first_node_in_group("terrain_manager")
	
	# 3. MANDA O TERRENO GERAR AS ARESTAS NO DATA (Essencial para não ficar transparente)
	if terrain_mgr and terrain_mgr.has_method("generate_random_terrain"):
		terrain_mgr.generate_random_terrain(data)
	
	# 4. Só agora faz o setup do Painter (Com os dados de arestas já preenchidos)
	if painter:
		painter.set("terrain_ref", terrain_mgr)
		painter.setup(data, tile_size)

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