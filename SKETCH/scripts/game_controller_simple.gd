## GameController - Controlador Principal Simplificado do Jogo V&V
## Versão funcional básica com scroll navigation

extends Node2D

const StarMapper = preload("res://scripts/star_mapper.gd")

@onready var hex_grid = $HexGrid
@onready var camera = $Camera2D
@onready var ui_layer = $UILayer

## Sistemas principais
var star_mapper: StarMapper
var game_manager

## Sistema de scroll navigation
var scroll_navigation: Control
var h_scroll: HScrollBar
var v_scroll: VScrollBar

## Sistema de movimentação de unidades
var selected_unit = null
var movement_mode_active: bool = false
var highlighted_stars = []
var valid_movement_stars = []

## Cores disponíveis para domínios
var domain_colors = [
	Color(0, 0, 1),      # Azul RGB
	Color(1, 0.5, 0),    # Laranja
	Color(1, 0, 0),      # Vermelho RGB
	Color(0.5, 0, 1),    # Roxo
	Color(1, 1, 0),      # Amarelo
	Color(0, 1, 1)       # Ciano
]
var available_colors = []

## Configurações de scroll
var scroll_enabled: bool = false
var grid_bounds: Rect2
var viewport_size: Vector2

func _ready() -> void:
	EventBus.emit_info("V&V: Initializing simple game controller...")
	
	# Inicializar componentes básicos
	star_mapper = StarMapper.new()
	
	# Usar o GameManager original por enquanto
	const GameManager = preload("res://scripts/game_manager.gd")
	game_manager = GameManager.new()
	
	# Inicializar sistema de scroll
	_setup_scroll_navigation()
	
	if hex_grid.is_initialized:
		_setup_system()
	else:
		hex_grid.grid_initialized.connect(_setup_system)

func _setup_system() -> void:
	if not hex_grid or not hex_grid.is_grid_ready():
		return
	
	# Configurar componentes
	var dot_positions = hex_grid.get_dot_positions()
	star_mapper.map_stars(dot_positions)
	game_manager.setup_references(hex_grid, star_mapper, self)
	
	# Configurar scroll navigation
	_setup_scroll_bounds()
	
	# Conectar aos eventos do EventBus
	_connect_to_events()
	
	# Inicializar sistema de spawn
	_initialize_spawn_system()
	
	EventBus.emit_info("V&V: Simple game controller ready!")

## Configurar sistema de navegação por scroll
func _setup_scroll_navigation() -> void:
	# Criar container principal
	scroll_navigation = Control.new()
	scroll_navigation.name = "ScrollNavigation"
	scroll_navigation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_navigation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Criar barra horizontal - SIMPLES E VISÍVEL
	h_scroll = HScrollBar.new()
	h_scroll.name = "HorizontalScroll"
	h_scroll.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	h_scroll.position.y = -25
	h_scroll.size.y = 20
	h_scroll.min_value = 0
	h_scroll.max_value = 1000
	h_scroll.step = 10
	h_scroll.page = 100
	h_scroll.visible = false
	h_scroll.modulate = Color.WHITE
	scroll_navigation.add_child(h_scroll)
	
	# Criar barra vertical - SIMPLES E VISÍVEL
	v_scroll = VScrollBar.new()
	v_scroll.name = "VerticalScroll"
	v_scroll.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	v_scroll.position.x = -25
	v_scroll.size.x = 20
	v_scroll.min_value = 0
	v_scroll.max_value = 1000
	v_scroll.step = 10
	v_scroll.page = 100
	v_scroll.visible = false
	v_scroll.modulate = Color.WHITE
	scroll_navigation.add_child(v_scroll)
	
	# Adicionar diretamente ao nó principal
	add_child(scroll_navigation)
	
	# Conectar sinais
	h_scroll.value_changed.connect(_on_h_scroll_changed)
	v_scroll.value_changed.connect(_on_v_scroll_changed)
	
	EventBus.emit_info("Scroll navigation system initialized - H:%s V:%s" % [h_scroll != null, v_scroll != null])

## Configurar estilo das barras de scroll
func _setup_scroll_style() -> void:
	# Criar StyleBox para as barras
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Cinza escuro semi-transparente
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.5, 0.5, 0.5, 1.0)  # Borda cinza
	style_box.corner_radius_top_left = 3
	style_box.corner_radius_top_right = 3
	style_box.corner_radius_bottom_left = 3
	style_box.corner_radius_bottom_right = 3
	
	# Aplicar estilo às barras
	if h_scroll:
		h_scroll.add_theme_stylebox_override("scroll", style_box)
		h_scroll.add_theme_stylebox_override("scroll_focus", style_box)
	
	if v_scroll:
		v_scroll.add_theme_stylebox_override("scroll", style_box)
		v_scroll.add_theme_stylebox_override("scroll_focus", style_box)

## Configurar limites do scroll baseado no grid
func _setup_scroll_bounds() -> void:
	if not hex_grid:
		return
	
	var dot_positions = hex_grid.get_dot_positions()
	if dot_positions.is_empty():
		return
	
	var min_pos = dot_positions[0]
	var max_pos = dot_positions[0]
	
	for pos in dot_positions:
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)
	
	# Adicionar margem
	var margin = 100.0
	grid_bounds = Rect2(
		min_pos - Vector2(margin, margin),
		(max_pos - min_pos) + Vector2(margin * 2, margin * 2)
	)
	
	EventBus.emit_info("Grid bounds calculated: %s" % grid_bounds)

## Atualizar ranges das barras de scroll
func _update_scroll_ranges() -> void:
	if not camera or not h_scroll or not v_scroll:
		return
	
	# Usar valores simples para teste
	h_scroll.min_value = -500
	h_scroll.max_value = 500
	h_scroll.page = 100
	h_scroll.value = camera.global_position.x
	
	v_scroll.min_value = -500
	v_scroll.max_value = 500
	v_scroll.page = 100
	v_scroll.value = camera.global_position.y
	
	EventBus.emit_info("Scroll ranges updated - H:[%.0f-%.0f] V:[%.0f-%.0f] Cam:(%.0f,%.0f)" % [h_scroll.min_value, h_scroll.max_value, v_scroll.min_value, v_scroll.max_value, camera.global_position.x, camera.global_position.y])

## Atualizar valores das barras baseado na posição da câmera
func _update_scroll_values() -> void:
	if not camera or not h_scroll or not v_scroll:
		return
	
	var camera_pos = camera.global_position
	var zoom = camera.zoom.x
	var visible_area = viewport_size / zoom
	
	# Calcular posição do canto superior esquerdo da área visível
	var top_left = camera_pos - visible_area * 0.5
	
	# Atualizar valores sem triggerar sinais
	h_scroll.set_value_no_signal(top_left.x)
	v_scroll.set_value_no_signal(top_left.y)

## Habilitar/desabilitar sistema de scroll
func _set_scroll_enabled(enabled: bool) -> void:
	scroll_enabled = enabled
	
	if h_scroll and v_scroll:
		h_scroll.visible = enabled
		v_scroll.visible = enabled
		
		if enabled:
			# Forçar visibilidade máxima
			h_scroll.z_index = 1000
			v_scroll.z_index = 1000
			h_scroll.modulate = Color.RED  # Vermelho para debug
			v_scroll.modulate = Color.BLUE  # Azul para debug
			_update_scroll_ranges()
	
	EventBus.emit_info("Scroll %s - H:%s V:%s Zoom:%.1f" % ["ON" if enabled else "OFF", h_scroll.visible if h_scroll else "null", v_scroll.visible if v_scroll else "null", camera.zoom.x if camera else 0])

## Verificar se deve mostrar barras de scroll baseado no zoom
func _update_scroll_visibility() -> void:
	if not camera:
		return
	
	var zoom = camera.zoom.x
	var should_show = zoom >= 1.0  # Mostrar quando zoom >= 1.0x
	
	if should_show != scroll_enabled:
		_set_scroll_enabled(should_show)
		
	# Atualizar ranges se já habilitado
	if scroll_enabled:
		_update_scroll_ranges()

## Conectar aos eventos do EventBus
func _connect_to_events() -> void:
	if not EventBus.instance:
		return
	
	# Eventos de entidades
	EventBus.instance.unit_created.connect(_on_unit_created)
	EventBus.instance.domain_created.connect(_on_domain_created)

## Handle input events
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(mouse_event.global_position)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_handle_zoom_in()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_handle_zoom_out()

## Handle zoom in
func _handle_zoom_in() -> void:
	if camera:
		# Obter posição do mouse em coordenadas de tela
		var mouse_screen_pos = get_viewport().get_mouse_position()
		var viewport_size = get_viewport().get_visible_rect().size
		
		# Converter para posição mundial antes do zoom
		var world_pos_before = camera.global_position + (mouse_screen_pos - viewport_size * 0.5) / camera.zoom.x
		
		# Aplicar zoom
		var old_zoom = camera.zoom.x
		camera.zoom *= 1.1
		camera.zoom = camera.zoom.clamp(Vector2(0.5, 0.5), Vector2(3.0, 3.0))
		
		# Converter para posição mundial após o zoom
		var world_pos_after = camera.global_position + (mouse_screen_pos - viewport_size * 0.5) / camera.zoom.x
		
		# Ajustar câmera para manter o ponto do mouse fixo
		camera.global_position += world_pos_before - world_pos_after
		
		_update_scroll_visibility()
		EventBus.emit_info("Zoom in to %.1fx" % camera.zoom.x)

## Handle zoom out
func _handle_zoom_out() -> void:
	if camera:
		# Obter posição do mouse em coordenadas de tela
		var mouse_screen_pos = get_viewport().get_mouse_position()
		var viewport_size = get_viewport().get_visible_rect().size
		
		# Converter para posição mundial antes do zoom
		var world_pos_before = camera.global_position + (mouse_screen_pos - viewport_size * 0.5) / camera.zoom.x
		
		# Aplicar zoom
		var old_zoom = camera.zoom.x
		camera.zoom /= 1.1
		camera.zoom = camera.zoom.clamp(Vector2(0.5, 0.5), Vector2(3.0, 3.0))
		
		# Converter para posição mundial após o zoom
		var world_pos_after = camera.global_position + (mouse_screen_pos - viewport_size * 0.5) / camera.zoom.x
		
		# Ajustar câmera para manter o ponto do mouse fixo
		camera.global_position += world_pos_before - world_pos_after
		
		_update_scroll_visibility()
		EventBus.emit_info("Zoom out to %.1fx" % camera.zoom.x)

## Callback: mudança na barra horizontal
func _on_h_scroll_changed(value: float) -> void:
	if not camera or not scroll_enabled:
		return
	
	camera.global_position.x = value
	EventBus.emit_info("H-Scroll: %.1f -> Camera X: %.1f" % [value, camera.global_position.x])

## Callback: mudança na barra vertical
func _on_v_scroll_changed(value: float) -> void:
	if not camera or not scroll_enabled:
		return
	
	camera.global_position.y = value
	EventBus.emit_info("V-Scroll: %.1f -> Camera Y: %.1f" % [value, camera.global_position.y])

## Handle left click (versão simplificada)
func _handle_left_click(global_pos: Vector2) -> void:
	EventBus.emit_info("Left click at: %s" % global_pos)
	# Por enquanto, apenas log - funcionalidade completa será adicionada depois

## Sistema de spawn (usando o sistema original)
func _initialize_spawn_system() -> void:
	EventBus.emit_info("Starting spawn system...")
	
	if not game_manager:
		EventBus.emit_error("GameManager not configured!")
		return
	
	# Obter quantidade de domínios
	var num_domains = _get_domain_count_from_args()
	EventBus.emit_info("Domains requested: %d" % num_domains)
	
	# Encontrar vértices disponíveis
	var available_vertices = _find_spawn_vertices()
	if available_vertices.size() == 0:
		EventBus.emit_error("No vertices found!")
		return
	
	# Selecionar vértices e cores aleatórias
	var selected_vertices = _select_random_vertices(available_vertices, num_domains)
	_prepare_random_colors(num_domains)
	
	# Spawnar domínios coloridos
	_spawn_colored_domains(selected_vertices)
	
	EventBus.emit_info("Spawn system completed!")

## Obter quantidade de domínios dos argumentos
func _get_domain_count_from_args() -> int:
	var args = OS.get_cmdline_args()
	var domain_count = 6  # Padrão
	
	for arg in args:
		if arg.begins_with("--domain-count="):
			domain_count = int(arg.split("=")[1])
			break
	
	# Validar
	domain_count = clamp(domain_count, 1, 6)
	
	EventBus.emit_info("=== SPAWN CONFIGURATION ===")
	EventBus.emit_info("Selected quantity: %d" % domain_count)
	
	return domain_count

## Algoritmo de detecção de vértices: 12 estrelas -> 6 duplas -> 6 centros
func _find_spawn_vertices() -> Array:
	if not hex_grid or not star_mapper:
		return []
	
	var dot_positions = hex_grid.get_dot_positions()
	var domain_centers = []
	
	# 1. Encontrar centro do tabuleiro
	var center = Vector2.ZERO
	for pos in dot_positions:
		center += pos
	center /= dot_positions.size()
	
	# 2. Encontrar as 12 estrelas mais distantes
	var star_distances = []
	for i in range(dot_positions.size()):
		var pos = dot_positions[i]
		var distance = center.distance_to(pos)
		star_distances.append({"id": i, "distance": distance, "pos": pos})
	
	star_distances.sort_custom(func(a, b): return a.distance > b.distance)
	var twelve_farthest = star_distances.slice(0, 12)
	
	# 3. Agrupar em duplas por proximidade
	var pairs = []
	var used_stars = []
	
	for star_a in twelve_farthest:
		if star_a.id in used_stars or pairs.size() >= 6:
			continue
		
		var closest_star = null
		var closest_distance = 999999.0
		
		for star_b in twelve_farthest:
			if star_b.id == star_a.id or star_b.id in used_stars:
				continue
			
			var distance = star_a.pos.distance_to(star_b.pos)
			if distance < closest_distance:
				closest_distance = distance
				closest_star = star_b
		
		if closest_star:
			pairs.append([star_a, closest_star])
			used_stars.append_array([star_a.id, closest_star.id])
	
	# 4. Encontrar centros das duplas
	for pair in pairs:
		var center_star = _find_common_adjacent_star(pair[0].id, pair[1].id, dot_positions)
		if center_star >= 0:
			domain_centers.append(center_star)
	
	return domain_centers

## Encontrar estrela adjacente comum a duas estrelas
func _find_common_adjacent_star(star_a_id: int, star_b_id: int, dot_positions: Array) -> int:
	var max_adjacent_distance = 38.0
	
	# Encontrar adjacentes de A
	var adjacent_to_a = []
	var star_a_pos = dot_positions[star_a_id]
	for i in range(dot_positions.size()):
		if i != star_a_id and star_a_pos.distance_to(dot_positions[i]) <= max_adjacent_distance:
			adjacent_to_a.append(i)
	
	# Encontrar adjacentes de B
	var adjacent_to_b = []
	var star_b_pos = dot_positions[star_b_id]
	for i in range(dot_positions.size()):
		if i != star_b_id and star_b_pos.distance_to(dot_positions[i]) <= max_adjacent_distance:
			adjacent_to_b.append(i)
	
	# Encontrar comum
	for star_id in adjacent_to_a:
		if star_id in adjacent_to_b:
			return star_id
	
	return -1

## Selecionar vértices aleatórios
func _select_random_vertices(available_vertices: Array, count: int) -> Array:
	if available_vertices.size() == 0:
		return []
	
	var max_count = min(count, available_vertices.size())
	var vertices_copy = available_vertices.duplicate()
	var selected = []
	
	for i in range(max_count):
		var random_index = randi() % vertices_copy.size()
		selected.append(vertices_copy[random_index])
		vertices_copy.remove_at(random_index)
	
	return selected

## Preparar cores aleatórias
func _prepare_random_colors(count: int) -> void:
	available_colors.clear()
	var colors_copy = domain_colors.duplicate()
	
	for i in range(min(count, colors_copy.size())):
		var random_index = randi() % colors_copy.size()
		available_colors.append(colors_copy[random_index])
		colors_copy.remove_at(random_index)

## Spawnar domínios com cores
func _spawn_colored_domains(selected_vertices: Array) -> void:
	EventBus.emit_info("Spawning colored domains...")
	
	for i in range(selected_vertices.size()):
		var vertex_star_id = selected_vertices[i]
		var domain_color = available_colors[i] if i < available_colors.size() else Color.WHITE
		
		var spawn_result = game_manager.spawn_domain_with_unit_colored(vertex_star_id, domain_color)
		
		if spawn_result:
			EventBus.emit_info("Domain %d created at star %d" % [i + 1, vertex_star_id])
		else:
			EventBus.emit_error("Spawn %d failed" % [i + 1])

## Event callbacks
func _on_unit_created(unit_data: Dictionary) -> void:
	EventBus.emit_info("Unit created: %s" % unit_data)

func _on_domain_created(domain_data: Dictionary) -> void:
	EventBus.emit_info("Domain created: %s" % domain_data)