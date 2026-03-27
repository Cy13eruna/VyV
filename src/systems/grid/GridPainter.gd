# res://src/systems/grid/GridPainter.gd
extends Node2D

# Referências para as camadas (Layers)
var edges_layer: Node2D
var indicators_layer: Node2D
var nodes_layer: Node2D

var tile_size: float = 64.0
var grid_data = null
var terrain_ref: RefCounted # Injetado pelo Main.gd (res://src/systems/Terrain.gd)

# --- ESTADO DE VISIBILIDADE (Injetado pelo VisibilityManager) ---
var lit_nodes: Array = []        # Nós adjacentes a unidades (acesos)
var revealed_edges: Array = []   # Arestas descobertas (chaves/strings)

# Configurações Visuais
const LINE_WIDTH = 8.0
const NODE_RADIUS = 13.0
const COLOR_OFF = Color.BLACK
const COLOR_ON = Color.WHITE

func _ready() -> void:
	_create_layers()

func _create_layers() -> void:
	# 1. Camada de Arestas
	edges_layer = Node2D.new()
	edges_layer.name = "EdgesLayer"
	add_child(edges_layer)
	edges_layer.draw.connect(_draw_edges)
	
	# 2. Camada de Domínios (Reservado para o futuro)
	var domains_layer = Node2D.new()
	domains_layer.name = "DomainsLayer"
	add_child(domains_layer)
	
	# 3. Camada de Indicadores de Movimento
	indicators_layer = Node2D.new()
	indicators_layer.name = "IndicatorsLayer"
	add_child(indicators_layer)
	indicators_layer.draw.connect(_draw_indicators)
	
	# 4. Camada de Nódulos (Acima de tudo)
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

# --- INTERFACE DE ATUALIZAÇÃO ---

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
	
	# Desenha apenas as arestas que estão na lista de reveladas pela visibilidade
	for edge_key in revealed_edges:
		var points = _parse_edge_key(edge_key)
		if points.size() == 2:
			# Obtém a cor baseada no terreno definido no Terrain.gd
			var edge_color = terrain_ref.get_edge_color(points[0], points[1])
			
			# Desenha a linha da aresta com a cor do terreno
			edges_layer.draw_line(points[0], points[1], edge_color, LINE_WIDTH, true)

func _draw_nodes() -> void:
	if not grid_data: return
	
	for node_pos in grid_data.nodes.keys():
		var is_lit = node_pos in lit_nodes
		
		# Fog of War: Preto se não estiver "aceso", Branco se estiver
		var color = COLOR_ON if is_lit else COLOR_OFF
		nodes_layer.draw_circle(node_pos, NODE_RADIUS, color)
		
		if is_lit:
			# Borda de definição para nós visíveis
			nodes_layer.draw_arc(node_pos, NODE_RADIUS, 0, TAU, 32, Color.BLACK, 2.5, true)

func _draw_indicators() -> void:
	if not indicators_layer.has_meta("reachable"): return
	
	var reachable = indicators_layer.get_meta("reachable")
	var base_color = indicators_layer.get_meta("color")
	var target_radius = tile_size * 0.35
	
	for pos in reachable:
		var steps = 8
		for i in range(steps, 0, -1):
			var r = (target_radius / steps) * i
			var alpha = lerp(0.0, 0.4, float(i) / steps)
			var color = base_color
			color.a = alpha
			indicators_layer.draw_circle(pos, r, color)
		
		var border_color = base_color
		border_color.a = 0.5
		indicators_layer.draw_arc(pos, target_radius, 0, TAU, 32, border_color, 2.0, true)

# --- UTILITÁRIOS ---

func _parse_edge_key(key: String) -> Array:
	# O formato esperado da key é "Vector2_Vector2" conforme gerado no Terrain.gd
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