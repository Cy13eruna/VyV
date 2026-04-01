# res://src/systems/grid/GridPainter.gd
extends Node2D

const HexMath = preload("res://src/core/math/HexMath.gd")
const SkyScript = preload("res://src/systems/grid/Sky.gd")

var sky_layer: Node2D
var edges_layer: Node2D
var indicators_layer: Node2D
var nodes_layer: Node2D

var tile_size: float = 64.0
var grid_data = null
var terrain_ref: Object 

var reachable_nodes: Array = []
var reachable_color: Color = Color.WHITE 

const ROTATION_30_DEG = 0.523599 
const NODE_RADIUS = 14.0
const COLOR_OFF = Color.BLACK
const COLOR_ON = Color.WHITE

const INDICATOR_RADIUS_PCT = 0.5
const GRADIENT_STEPS = 12

func _ready() -> void:
	_setup_layers()
	_connect_signals()

func _setup_layers() -> void:
	for child in get_children(): child.queue_free()
	
	# 1. SKY LAYER (Fundo absoluto)
	var sky_canvas = CanvasLayer.new()
	sky_canvas.layer = -100 
	add_child(sky_canvas)
	
	sky_layer = Node2D.new()
	sky_layer.set_script(SkyScript)
	sky_layer.name = "SkyLayer"
	sky_canvas.add_child(sky_layer)
	
	# 2. EDGES LAYER
	edges_layer = Node2D.new()
	edges_layer.name = "EdgesLayer"
	edges_layer.z_index = -5
	add_child(edges_layer)
	edges_layer.draw.connect(_draw_edges)
	
	# 3. INDICATORS LAYER
	indicators_layer = Node2D.new()
	indicators_layer.name = "IndicatorsLayer"
	indicators_layer.z_index = -2
	add_child(indicators_layer)
	indicators_layer.draw.connect(_draw_indicators)
	
	# 4. NODES LAYER
	nodes_layer = Node2D.new()
	nodes_layer.name = "NodesLayer"
	nodes_layer.z_index = -1
	add_child(nodes_layer)
	nodes_layer.draw.connect(_draw_nodes)

var lit_nodes: Array = []:
	set(v):
		lit_nodes = v
		if is_instance_valid(nodes_layer): nodes_layer.queue_redraw()

var revealed_edges: Array = []:
	set(v):
		revealed_edges = v
		if is_instance_valid(edges_layer): edges_layer.queue_redraw()

func _connect_signals() -> void:
	if Signals.has_signal("visibility_changed"):
		Signals.visibility_changed.connect(_on_visibility_changed)

func setup(p_data, p_size: float) -> void:
	grid_data = p_data
	tile_size = p_size
	_refresh_all()

func _on_visibility_changed(_player_id: int, p_lit_nodes: Array, p_revealed_edges: Array) -> void:
	lit_nodes = p_lit_nodes
	revealed_edges = p_revealed_edges

func update_reachable(new_nodes: Array, player_color: Color = Color.WHITE) -> void:
	reachable_nodes = new_nodes
	reachable_color = player_color 
	if is_instance_valid(indicators_layer): indicators_layer.queue_redraw()

func _refresh_all() -> void:
	if is_instance_valid(edges_layer): edges_layer.queue_redraw()
	if is_instance_valid(indicators_layer): indicators_layer.queue_redraw()
	if is_instance_valid(nodes_layer): nodes_layer.queue_redraw()

# --- AUXILIAR DE TRADUÇÃO DE ID ---

func _parse_edge_id(id) -> Array:
	if id is String and "_" in id:
		var parts = id.split("_")
		if parts.size() == 2:
			var p1_s = parts[0].split(",")
			var p2_s = parts[1].split(",")
			return [
				Vector2(float(p1_s[0]), float(p1_s[1])),
				Vector2(float(p2_s[0]), float(p2_s[1]))
			]
	elif id is Array and id.size() >= 2:
		return [Vector2(id[0]), Vector2(id[1])]
	return []

# --- DESENHO ---

func _draw_indicators() -> void:
	var base_radius = tile_size * INDICATOR_RADIUS_PCT
	for pos in reachable_nodes:
		_draw_soft_circle(pos, base_radius, reachable_color)

func _draw_soft_circle(pos: Vector2, max_radius: float, color: Color) -> void:
	for i in range(GRADIENT_STEPS):
		var t = float(i) / float(GRADIENT_STEPS)
		var current_radius = lerp(max_radius, max_radius * 0.1, t)
		var alpha = lerp(0.0, 0.6, t * t) 
		var step_color = color
		step_color.a = alpha
		indicators_layer.draw_circle(pos, current_radius, step_color)

func _draw_edges() -> void:
	if not grid_data or not terrain_ref: return
	
	# PASSO 1: Fundo preto para TODAS as arestas (bloqueia o céu)
	for edge_key in grid_data.edges.keys():
		var pts = _parse_edge_id(edge_key)
		if pts.size() == 2:
			var poly = HexMath.get_edge_polygon(pts[0], pts[1], tile_size)
			edges_layer.draw_colored_polygon(poly, Color.WHITE)

	# PASSO 2: Arestas reveladas (Cores do terreno)
	for edge_id in revealed_edges:
		var pts = _parse_edge_id(edge_id)
		if pts.size() == 2:
			var edge_color = terrain_ref.get_edge_color(pts[0], pts[1])
			var poly = HexMath.get_edge_polygon(pts[0], pts[1], tile_size)
			edges_layer.draw_colored_polygon(poly, edge_color)

func _draw_nodes() -> void:
	if not grid_data: return
	var lit_set = {}
	for lp in lit_nodes:
		lit_set["%.1f,%.1f" % [lp.x, lp.y]] = true

	for node_pos in grid_data.nodes.keys():
		var is_lit = lit_set.has("%.1f,%.1f" % [node_pos.x, node_pos.y])
		var color = COLOR_ON if is_lit else COLOR_OFF
		var tris = HexMath.get_hexagram_triangles(node_pos, NODE_RADIUS, ROTATION_30_DEG)
		nodes_layer.draw_colored_polygon(tris[0], color)
		nodes_layer.draw_colored_polygon(tris[1], color)