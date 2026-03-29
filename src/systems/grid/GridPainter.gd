# res://src/systems/grid/GridPainter.gd
extends Node2D

# Camadas
var edges_layer: Node2D
var domains_layer: Node2D 
var indicators_layer: Node2D
var nodes_layer: Node2D

var tile_size: float = 64.0
var grid_data = null
var terrain_ref: RefCounted 

var lit_nodes: Array = []
var revealed_edges: Array = []
var active_domains: Array = [] 

const NODE_RADIUS = 14.0
const COLOR_OFF = Color.BLACK
const COLOR_ON = Color.WHITE

# Fonte para o texto do domínio
var _font: Font = ThemeDB.fallback_font

func _ready() -> void:
	_create_layers()

func _create_layers() -> void:
	for child in get_children(): child.queue_free()

	# Ordem de profundidade (Z-Index):
	# -1: Arestas/Terreno
	#  0: (Fundo/Vazio)
	#  1: Indicadores (Reachable)
	#  2: Nódulos (Círculos/Hexagramas pequenos)
	#  9: Domínios (Estrela + Texto) -> Acima de quase tudo
	
	edges_layer = Node2D.new(); edges_layer.name = "EdgesLayer"; edges_layer.z_index = -1 
	add_child(edges_layer); edges_layer.draw.connect(_draw_edges)
	
	indicators_layer = Node2D.new(); indicators_layer.name = "IndicatorsLayer"; indicators_layer.z_index = 1
	add_child(indicators_layer); indicators_layer.draw.connect(_draw_indicators)
	
	nodes_layer = Node2D.new(); nodes_layer.name = "NodesLayer"; nodes_layer.z_index = 2
	add_child(nodes_layer); nodes_layer.draw.connect(_draw_nodes)

	# Elevando os Domínios para o topo (Z=9). Texto e Estrela desenhados aqui.
	domains_layer = Node2D.new(); domains_layer.name = "DomainsLayer"; domains_layer.z_index = 9
	add_child(domains_layer); domains_layer.draw.connect(_draw_domains)

func setup(p_data, p_size: float) -> void:
	grid_data = p_data
	tile_size = p_size
	_refresh_all()

# --- INTERFACE ---

func update_domains(domain_list: Array) -> void:
	active_domains = domain_list
	domains_layer.queue_redraw()

func update_reachable(new_nodes: Array, player_color: Color = Color.BLACK) -> void:
	indicators_layer.set_meta("reachable", new_nodes)
	indicators_layer.set_meta("color", player_color)
	indicators_layer.queue_redraw()

func refresh_fog_layers() -> void:
	_refresh_all()

func _refresh_all() -> void:
	if edges_layer: edges_layer.queue_redraw()
	if domains_layer: domains_layer.queue_redraw()
	if indicators_layer: indicators_layer.queue_redraw()
	if nodes_layer: nodes_layer.queue_redraw()

# --- FUNÇÕES DE DESENHO ---

func _draw_domains() -> void:
	for domain in active_domains:
		# Desenha a geometria e o texto na mesma camada elevada
		_draw_capital_star(domains_layer, domain.pos, tile_size, domain.color)
		_draw_domain_text(domains_layer, domain.pos, tile_size, domain.color)

func _draw_capital_star(canvas: CanvasItem, pos: Vector2, size: float, color: Color) -> void:
	var outer_r = size * 0.92 
	var inner_r = size * 0.55
	
	var pts = PackedVector2Array()
	for i in range(12):
		var angle = deg_to_rad(i * 30 - 30) 
		var r = outer_r if i % 2 != 0 else inner_r
		pts.append(pos + Vector2(cos(angle), sin(angle)) * r)
	
	pts.append(pts[0])
	
	# Estrela e Círculo central
	canvas.draw_polyline(pts, color, 4.0, true)

func _draw_domain_text(canvas: CanvasItem, pos: Vector2, size: float, color: Color) -> void:
	var outer_r = size * 0.92
	var text = "DOMAIN"
	var font_size = 14
	var text_size = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	
	# Alinhado na base da estrela
	var text_pos = pos + Vector2(-text_size.x / 2.0, outer_r)
	
	# Sombra (Z-index alto exige sombra para não "sumir" no brilho de outros FX)
	canvas.draw_string(_font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)
	canvas.draw_string(_font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)

func _draw_indicators() -> void:
	if not indicators_layer.has_meta("reachable"): return
	var reachable = indicators_layer.get_meta("reachable")
	var base_color = indicators_layer.get_meta("color")
	for pos in reachable:
		var color = base_color
		color.a = 0.4
		_draw_hexagram(indicators_layer, pos, tile_size * 0.35, color)

func _draw_edges() -> void:
	if not grid_data or not terrain_ref: return
	var d_width = tile_size / 1.73205081
	for edge_key in revealed_edges:
		var points = _parse_edge_key(edge_key)
		if points.size() == 2:
			var edge_color = terrain_ref.get_edge_color(points[0], points[1])
			var mid = (points[0] + points[1]) / 2.0
			var dir = (points[1] - points[0]).normalized()
			var perp = Vector2(-dir.y, dir.x) * (d_width / 2.0)
			var d_pts = PackedVector2Array([points[0], mid+perp, points[1], mid-perp])
			edges_layer.draw_colored_polygon(d_pts, edge_color)

func _draw_nodes() -> void:
	if not grid_data: return
	for node_pos in grid_data.nodes.keys():
		var is_lit = node_pos in lit_nodes
		var color = COLOR_ON if is_lit else COLOR_OFF
		_draw_hexagram(nodes_layer, node_pos, NODE_RADIUS, color)

func _draw_hexagram(canvas: CanvasItem, pos: Vector2, radius: float, color: Color) -> void:
	var rot = deg_to_rad(-90)
	var t1 = PackedVector2Array(); var t2 = PackedVector2Array()
	for i in range(3):
		t1.append(pos + Vector2(cos(rot + deg_to_rad(i*120)), sin(rot + deg_to_rad(i*120))) * radius)
		t2.append(pos + Vector2(cos(rot + deg_to_rad(i*120+60)), sin(rot + deg_to_rad(i*120+60))) * radius)
	canvas.draw_colored_polygon(t1, color); canvas.draw_colored_polygon(t2, color)

func _parse_edge_key(key: String) -> Array:
	var parts = key.replace("(", "").replace(")", "").split("_")
	if parts.size() == 2:
		var p1 = parts[0].split(","); var p2 = parts[1].split(",")
		return [Vector2(float(p1[0]), float(p1[1])), Vector2(float(p2[0]), float(p2[1]))]
	return []