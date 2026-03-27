# res://src/systems/grid/GridPainter.gd
extends Node2D

# Referências para as camadas (Layers)
var edges_layer: Node2D
var indicators_layer: Node2D
var nodes_layer: Node2D

var tile_size: float = 64.0
var grid_data = null
var terrain_ref: RefCounted 

# --- ESTADO DE VISIBILIDADE ---
var lit_nodes: Array = []
var revealed_edges: Array = []

# Configurações Visuais
const NODE_RADIUS = 14.0
const COLOR_OFF = Color.BLACK
const COLOR_ON = Color.WHITE

func _ready() -> void:
	_create_layers()

func _create_layers() -> void:
	edges_layer = Node2D.new()
	edges_layer.name = "EdgesLayer"
	add_child(edges_layer)
	edges_layer.draw.connect(_draw_edges)
	
	var domains_layer = Node2D.new()
	domains_layer.name = "DomainsLayer"
	add_child(domains_layer)
	
	indicators_layer = Node2D.new()
	indicators_layer.name = "IndicatorsLayer"
	add_child(indicators_layer)
	indicators_layer.draw.connect(_draw_indicators)
	
	nodes_layer = Node2D.new()
	nodes_layer.name = "NodesLayer"
	add_child(nodes_layer)
	nodes_layer.draw.connect(_draw_nodes)

func setup(p_data, p_size: float) -> void:
	grid_data = p_data
	tile_size = p_size
	lit_nodes.clear()
	revealed_edges.clear()
	_refresh_all()

func refresh_fog_layers() -> void:
	edges_layer.queue_redraw()
	nodes_layer.queue_redraw()

func update_reachable(new_nodes: Array, player_color: Color = Color.BLACK) -> void:
	indicators_layer.set_meta("reachable", new_nodes)
	indicators_layer.set_meta("color", player_color)
	indicators_layer.queue_redraw()

func _refresh_all() -> void:
	edges_layer.queue_redraw()
	indicators_layer.queue_redraw()
	nodes_layer.queue_redraw()

# --- FUNÇÕES DE DESENHO ---

func _draw_edges() -> void:
	if not grid_data or not terrain_ref: return
	
	# Para um encaixe perfeito no grid hexagonal:
	# A largura do losango (distância entre pontas obtusas) deve ser tile_size / sqrt(3)
	var diamond_width = tile_size / 1.73205
	
	for edge_key in revealed_edges:
		var points = _parse_edge_key(edge_key)
		if points.size() == 2:
			var p1 = points[0]
			var p2 = points[1]
			var edge_color = terrain_ref.get_edge_color(p1, p2)
			
			var mid = (p1 + p2) / 2.0
			var dir = (p2 - p1).normalized()
			var perp = Vector2(-dir.y, dir.x) * (diamond_width / 2.0)
			
			var diamond_points = PackedVector2Array([
				p1,           # Ponta aguda 1
				mid + perp,   # Ponta obtusa 1 (Centro do triângulo adjacente)
				p2,           # Ponta aguda 2
				mid - perp    # Ponta obtusa 2 (Centro do triângulo adjacente)
			])
			
			edges_layer.draw_colored_polygon(diamond_points, edge_color)

func _draw_nodes() -> void:
	if not grid_data: return
	
	for node_pos in grid_data.nodes.keys():
		var is_lit = node_pos in lit_nodes
		var color = COLOR_ON if is_lit else COLOR_OFF
		_draw_hexagram(nodes_layer, node_pos, NODE_RADIUS, color)

func _draw_hexagram(canvas: CanvasItem, pos: Vector2, radius: float, color: Color) -> void:
	# Rotação de 30 graus: alteramos o ponto de partida de -90 para -60 graus
	var rotation_offset = deg_to_rad(-60)
	
	# Triângulo 1
	var t1 = PackedVector2Array()
	for i in range(3):
		var angle = rotation_offset + deg_to_rad(i * 120)
		t1.append(pos + Vector2(cos(angle), sin(angle)) * radius)
	
	# Triângulo 2 (Invertido em relação ao T1 rotacionado)
	var t2 = PackedVector2Array()
	for i in range(3):
		var angle = rotation_offset + deg_to_rad(i * 120 + 60)
		t2.append(pos + Vector2(cos(angle), sin(angle)) * radius)
	
	canvas.draw_colored_polygon(t1, color)
	canvas.draw_colored_polygon(t2, color)

func _draw_indicators() -> void:
	if not indicators_layer.has_meta("reachable"): return
	
	var reachable = indicators_layer.get_meta("reachable")
	var base_color = indicators_layer.get_meta("color")
	var target_radius = tile_size * 0.35
	
	for pos in reachable:
		var color = base_color
		color.a = 0.4
		_draw_hexagram(indicators_layer, pos, target_radius, color)

# --- UTILITÁRIOS ---

func _parse_edge_key(key: String) -> Array:
	var parts = key.replace("(", "").replace(")", "").split("_")
	if parts.size() == 2:
		var p1_raw = parts[0].split(",")
		var p2_raw = parts[1].split(",")
		if p1_raw.size() >= 2 and p2_raw.size() >= 2:
			return [
				Vector2(float(p1_raw[0]), float(p1_raw[1])),
				Vector2(float(p2_raw[0]), float(p2_raw[1]))
			]
	return []