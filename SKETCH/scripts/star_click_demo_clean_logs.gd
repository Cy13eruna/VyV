## Demo de Spawn de Domínios - Sistema de Mapa Dinâmico
## Sistema principal do jogo V&V com mapas adaptativos - LOGS LIMPOS

extends Node2D

const StarMapper = preload("res://scripts/star_mapper.gd")
const Unit = preload("res://scripts/unit.gd")
const Domain = preload("res://scripts/domain.gd")
const GameManager = preload("res://scripts/game_manager.gd")

@onready var hex_grid = $HexGrid
var star_mapper = null
var game_manager = null

# Sistema de mapa dinâmico
var domain_count_to_map_width = {
	6: 13,
	5: 11,
	4: 9,
	3: 7,
	2: 5
}
var current_domain_count: int = 6
var map_initialized: bool = false

# Cores disponíveis para domínios
var domain_colors = [
	Color(0, 0, 1),      # Azul RGB
	Color(1, 0.5, 0),    # Laranja
	Color(1, 0, 0),      # Vermelho RGB
	Color(0.5, 0, 1),    # Roxo
	Color(1, 1, 0),      # Amarelo
	Color(0, 1, 1)       # Ciano
]
var available_colors = []

# Sistema de movimentação de unidades
var selected_unit = null
var movement_mode_active: bool = false
var highlighted_stars = []
var valid_movement_stars = []

# Sistema de zoom em duas etapas
var current_centered_star_id: int = -1
var zoom_mode_active: bool = false

# Zoom system constants
const ZOOM_FACTOR: float = 1.3
const MIN_ZOOM: float = 0.3
const MAX_ZOOM: float = 5.0
const INVALID_STAR_ID: int = -1

func _ready() -> void:
	print("V&V: Inicializando...")
	
	# Passo 0: Aguardar input via console para quantidade de domínios
	_step_0_console_input()
	
	# Inicializar componentes apenas se não existirem
	if not star_mapper:
		star_mapper = StarMapper.new()
	if not game_manager:
		game_manager = GameManager.new()

func _setup_system() -> void:
	# Sistema já foi configurado nos 5 passos
	# Apenas inicializar sistema de spawn
	_initialize_spawn_system()
	print("V&V: Sistema pronto!")

## Handle input events
func _unhandled_input(event: InputEvent) -> void:
	# Input de mouse apenas se mapa estiver inicializado
	if not map_initialized:
		return
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(mouse_event.global_position)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_handle_zoom_in()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_handle_zoom_out()

## Passo 0: Aguardar input via console para quantidade de domínios
func _step_0_console_input() -> void:
	# Obter quantidade de domínios dos argumentos da linha de comando
	var domain_count = _get_domain_count_from_console()
	
	# Executar os 4 passos seguintes
	_execute_map_creation_steps(domain_count)

## Obter quantidade de domínios via console (argumentos)
func _get_domain_count_from_console() -> int:
	var args = OS.get_cmdline_args()
	var domain_count = 6  # Padrão
	
	# Procurar argumento --domain-count=X
	for arg in args:
		if arg.begins_with("--domain-count="):
			domain_count = int(arg.split("=")[1])
			break
	
	# Validar range 2-6
	domain_count = clamp(domain_count, 2, 6)
	return domain_count

## Executar os 4 passos de criação do mapa
func _execute_map_creation_steps(domain_count: int) -> void:
	current_domain_count = domain_count
	var map_width = domain_count_to_map_width[domain_count]
	
	# Passo 1: Renderizar tabuleiro
	_step_1_render_board(map_width)
	
	# Aguardar grid estar pronto para continuar
	if hex_grid.is_initialized:
		_continue_remaining_steps()
	else:
		hex_grid.grid_initialized.connect(_continue_remaining_steps, CONNECT_ONE_SHOT)

## Passo 1: Renderizar tabuleiro com a devida largura baseado na quantidade de domínios
func _step_1_render_board(width: int) -> void:
	# Converter largura em estrelas para raio hexagonal
	# Fórmula: raio = (largura + 1) / 2
	var hex_radius = (width + 1) / 2
	
	# Configurar novo tamanho do grid
	hex_grid.config.set_grid_width(hex_radius)
	hex_grid.config.set_grid_height(hex_radius)
	
	# Forçar reconstrução do grid
	hex_grid.rebuild_grid()

## Continuar com os passos restantes após renderização
func _continue_remaining_steps() -> void:
	# Aguardar o grid estar pronto com mais tempo
	if not hex_grid.is_grid_ready():
		# Aguardar mais tempo para grid estar 100% pronto
		get_tree().create_timer(0.5).timeout.connect(_continue_remaining_steps, CONNECT_ONE_SHOT)
		return
	
	# Passo 2: Mapear estrelas
	_step_2_map_stars()
	
	# Passo 3: Posicionar domínios
	_step_3_position_domains()
	
	# Passo 4: Ajustar zoom
	_step_4_adjust_zoom()
	
	# Marcar sistema como inicializado
	map_initialized = true
	
	# Configurar sistema de jogo
	_setup_system()

## Passo 2: Mapear estrelas desse tabuleiro para maior precisão nos próximos passos
func _step_2_map_stars() -> void:
	if not hex_grid or not hex_grid.is_grid_ready():
		return
	
	# Garantir que star_mapper não seja recriado (preservar dados)
	if not star_mapper:
		star_mapper = StarMapper.new()
	
	# Obter posições das estrelas do tabuleiro
	var dot_positions = hex_grid.get_dot_positions()
	
	# Mapear estrelas com StarMapper
	star_mapper.map_stars(dot_positions)
	
	# Configurar GameManager com o mapeamento
	if not game_manager:
		game_manager = GameManager.new()
	
	game_manager.setup_references(hex_grid, star_mapper, self)
	
	# Conectar sinais se necessário
	if not game_manager.unit_created.is_connected(_on_unit_created):
		game_manager.unit_created.connect(_on_unit_created)
	if not game_manager.domain_created.is_connected(_on_domain_created):
		game_manager.domain_created.connect(_on_domain_created)

## Passo 3: Posicionar os domínios utilizando o mapeamento
func _step_3_position_domains() -> void:
	# Verificar se game_manager está disponível
	if not game_manager:
		return
	
	# Reconfigurar referências antes de usar (garantir que não foram perdidas)
	game_manager.setup_references(hex_grid, star_mapper, self)
	
	# Limpar domínios e unidades existentes
	game_manager.clear_all_units()
	game_manager.clear_all_domains()
	
	# Encontrar posições utilizando o mapeamento
	var available_vertices = _find_spawn_vertices()
	if available_vertices.size() == 0:
		return
	
	# Selecionar posições e cores para os domínios
	var selected_vertices = _select_random_vertices(available_vertices, current_domain_count)
	_prepare_random_colors(current_domain_count)
	
	# Posicionar domínios nas posições mapeadas
	_spawn_colored_domains(selected_vertices)

## Passo 4: Ajustar o zoom ao novo mapeamento
func _step_4_adjust_zoom() -> void:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	# Calcular zoom baseado no mapeamento
	var map_width = domain_count_to_map_width[current_domain_count]
	var base_zoom = 1.0
	
	# Ajustar zoom conforme o tamanho do mapeamento
	if map_width <= 5:
		base_zoom = 2.0  # Mapas muito pequenos: zoom maior
	elif map_width <= 7:
		base_zoom = 1.6  # Mapas pequenos: zoom moderado
	elif map_width <= 9:
		base_zoom = 1.3  # Mapas médios: zoom leve
	elif map_width <= 11:
		base_zoom = 1.1  # Mapas grandes: zoom mínimo
	else:
		base_zoom = 0.9  # Mapas muito grandes: zoom reduzido
	
	# Aplicar zoom inicial
	camera.zoom = Vector2(base_zoom, base_zoom)
	
	# Centralizar câmera no centro do mapeamento
	var dot_positions = hex_grid.get_dot_positions()
	if dot_positions.size() > 0:
		var center = Vector2.ZERO
		for pos in dot_positions:
			center += pos
		center /= dot_positions.size()
		camera.global_position = hex_grid.to_global(center)
	
	# Resetar sistema de zoom dinâmico para manter funcionalidade completa
	zoom_mode_active = false
	current_centered_star_id = INVALID_STAR_ID

## Sistema principal de spawn
func _initialize_spawn_system() -> void:
	pass

## Algoritmo de detecção de vértices: 12 estrelas -> 6 duplas -> 6 centros
func _find_spawn_vertices() -> Array:
	if not hex_grid or not star_mapper:
		return []
	
	var dot_positions = hex_grid.get_dot_positions()
	var total_stars = star_mapper.get_star_count()
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
	var twelve_farthest = star_distances.slice(0, min(12, star_distances.size()))
	
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
		if center_star >= 0 and center_star < total_stars:
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
	var spawned_count = 0
	for i in range(selected_vertices.size()):
		var vertex_star_id = selected_vertices[i]
		var domain_color = available_colors[i] if i < available_colors.size() else Color.WHITE
		
		var spawn_result = game_manager.spawn_domain_with_unit_colored(vertex_star_id, domain_color)
		
		if spawn_result:
			spawned_count += 1

## Callbacks (SEM LOGS)
func _on_unit_created(unit) -> void:
	pass

func _on_domain_created(domain) -> void:
	pass

## Reset zoom mode when user clicks (allows centering new star)
func _reset_zoom_mode() -> void:
	if zoom_mode_active:
		zoom_mode_active = false
		current_centered_star_id = INVALID_STAR_ID

## Validate zoom system state
func _validate_zoom_system() -> bool:
	if not star_mapper:
		return false
	if not hex_grid:
		return false
	if not get_viewport().get_camera_2d():
		return false
	return true

## Handle left click for unit selection and movement
func _handle_left_click(global_pos: Vector2) -> void:
	# Reset zoom mode on any click
	_reset_zoom_mode()
	# Convert mouse position to hex grid coordinates with proper camera transformation
	var camera = get_viewport().get_camera_2d()
	var zoom_factor = camera.zoom.x if camera else 1.0
	var camera_pos = camera.global_position if camera else Vector2.ZERO
	
	# Calculate world position from screen coordinates
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2.0
	var mouse_offset = global_pos - screen_center
	var world_offset = mouse_offset / zoom_factor
	var world_pos = camera_pos + world_offset
	
	# Convert to hex grid local coordinates
	var hex_grid_pos = hex_grid.to_local(world_pos)
	
	# If in movement mode, prioritize checking for valid movement stars
	if movement_mode_active and selected_unit:
		var clicked_star_id = _get_star_at_position(hex_grid_pos)
		
		if clicked_star_id >= 0 and clicked_star_id in valid_movement_stars:
			# Check if target star is already occupied by another unit
			var occupying_unit = game_manager.get_unit_at_star(clicked_star_id)
			if occupying_unit and occupying_unit != selected_unit:
				return
			
			_move_selected_unit_to_star(clicked_star_id)
			return
		else:
			# Clique fora das estrelas válidas - desativar movimento
			_deactivate_movement_mode()
			return
	
	# Check if clicked on a unit
	var clicked_unit = _get_unit_at_position(hex_grid_pos)
	if clicked_unit:
		_handle_unit_click(clicked_unit)
		return
	
	# If movement mode is active and clicked elsewhere, deactivate
	if movement_mode_active:
		_deactivate_movement_mode()

## Handle unit click (selection/deselection)
func _handle_unit_click(unit) -> void:
	if selected_unit == unit:
		# Clicking same unit - deactivate movement mode
		_deactivate_movement_mode()
	else:
		# Clicking different unit - activate movement mode
		_activate_movement_mode(unit)

## Activate movement mode for unit
func _activate_movement_mode(unit) -> void:
	# Deactivate previous mode if active
	if movement_mode_active:
		_deactivate_movement_mode()
	
	selected_unit = unit
	movement_mode_active = true
	
	# Get valid adjacent stars
	var adjacent_stars = game_manager.get_valid_adjacent_stars(unit)
	
	# Filter out occupied stars
	valid_movement_stars = []
	for star_id in adjacent_stars:
		var occupying_unit = game_manager.get_unit_at_star(star_id)
		if not occupying_unit or occupying_unit == unit:
			valid_movement_stars.append(star_id)
	
	# Highlight valid movement stars with unit color
	_highlight_movement_stars(unit.visual_node.modulate)

## Deactivate movement mode
func _deactivate_movement_mode() -> void:
	selected_unit = null
	movement_mode_active = false
	valid_movement_stars.clear()
	
	# Clear star highlights
	_clear_star_highlights()

## Highlight valid movement stars with unit color
func _highlight_movement_stars(unit_color: Color) -> void:
	_clear_star_highlights()
	
	var dot_positions = hex_grid.get_dot_positions()
	
	for star_id in valid_movement_stars:
		if star_id < dot_positions.size():
			var star_pos = dot_positions[star_id]
			_create_colored_star_highlight(star_pos, unit_color)

## Create colored star highlight
func _create_colored_star_highlight(position: Vector2, color: Color) -> void:
	var highlight_node = Node2D.new()
	highlight_node.position = position
	highlight_node.z_index = 60
	highlight_node.visible = true
	
	# Connect draw signal
	highlight_node.draw.connect(_draw_colored_star.bind(highlight_node, color))
	
	hex_grid.add_child(highlight_node)
	highlighted_stars.append(highlight_node)
	
	# Force redraw
	highlight_node.queue_redraw()

## Draw colored star highlight
func _draw_colored_star(canvas_item: CanvasItem, color: Color) -> void:
	# Usar EXATAMENTE as mesmas medidas das estrelas fixas
	var outer_radius = 6.0  # dot_radius das estrelas fixas
	var inner_radius = 3.0  # dot_star_size das estrelas fixas
	var points = PackedVector2Array()
	
	# Usar EXATAMENTE o mesmo algoritmo do HexGridGeometry.calculate_star_geometry
	for i in range(12):  # 6 outer + 6 inner points
		var angle_deg = 30.0 * i  # 30 degrees between each point
		var angle_rad = deg_to_rad(angle_deg)
		var radius = outer_radius if i % 2 == 0 else inner_radius
		var point = Vector2(cos(angle_rad), sin(angle_rad)) * radius
		points.append(point)
	
	# Desenhar estrela preenchida com medidas exatas das estrelas fixas
	canvas_item.draw_colored_polygon(points, color)

## Clear all star highlights
func _clear_star_highlights() -> void:
	for highlight in highlighted_stars:
		if is_instance_valid(highlight):
			highlight.queue_free()
	highlighted_stars.clear()

## Move selected unit to star
func _move_selected_unit_to_star(target_star_id: int) -> void:
	if not selected_unit:
		return
	
	# Reset actions to allow movement
	selected_unit.reset_actions()
	
	# Attempt movement
	if game_manager.move_unit_to_star(selected_unit, target_star_id):
		# Update movement options for new position
		var adjacent_stars = game_manager.get_valid_adjacent_stars(selected_unit)
		
		# Filter out occupied stars
		valid_movement_stars = []
		for star_id in adjacent_stars:
			var occupying_unit = game_manager.get_unit_at_star(star_id)
			if not occupying_unit or occupying_unit == selected_unit:
				valid_movement_stars.append(star_id)
		
		_highlight_movement_stars(selected_unit.visual_node.modulate)

## Get unit at position
func _get_unit_at_position(position: Vector2):
	# Rectangular click area for emoji (vertical rectangle like 3 stacked stars)
	var click_width = 24.0   # Width equivalent to ~1.5 stars
	var click_height = 54.0  # Height equivalent to ~3 stacked stars
	
	for unit in game_manager.get_all_units():
		if unit.is_positioned():
			var unit_world_pos = unit.get_world_position()
			var unit_local_pos = hex_grid.to_local(unit_world_pos)
			
			# Check if click is within rectangular bounds
			var dx = abs(position.x - unit_local_pos.x)
			var dy = abs(position.y - unit_local_pos.y)
			
			var within_bounds = (dx <= click_width / 2.0) and (dy <= click_height / 2.0)
			
			if within_bounds:
				return unit
	
	return null

## Get star at position
func _get_star_at_position(position: Vector2) -> int:
	var click_tolerance = 30.0
	var dot_positions = hex_grid.get_dot_positions()
	
	var closest_star = -1
	var closest_distance = 999999.0
	
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = position.distance_to(star_pos)
		
		if distance <= click_tolerance and distance < closest_distance:
			closest_distance = distance
			closest_star = i
	
	return closest_star

## Handle zoom in with two-stage system
func _handle_zoom_in() -> void:
	_handle_zoom(true)

## Handle zoom out with two-stage system
func _handle_zoom_out() -> void:
	_handle_zoom(false)

## Unified zoom handler with two-stage system: center first, then zoom
func _handle_zoom(zoom_in: bool) -> void:
	# Validate system state
	if not _validate_zoom_system():
		return
	
	var camera = get_viewport().get_camera_2d()
	
	# Get nearest star under cursor
	var nearest_star_data = _get_nearest_star_under_cursor(camera)
	if nearest_star_data.star_id == INVALID_STAR_ID:
		return
	
	# Two-stage zoom system
	if _should_center_star(nearest_star_data.star_id):
		_center_star(camera, nearest_star_data)
	else:
		_apply_zoom(camera, nearest_star_data, zoom_in)

## Check if we should center the star (stage 1) or zoom (stage 2)
func _should_center_star(star_id: int) -> bool:
	return not zoom_mode_active or current_centered_star_id != star_id

## Stage 1: Center star without zooming
func _center_star(camera: Camera2D, star_data: Dictionary) -> void:
	current_centered_star_id = star_data.star_id
	zoom_mode_active = true
	
	# Center camera and cursor without zoom
	camera.global_position = star_data.world_pos
	get_viewport().warp_mouse(star_data.screen_center)

## Stage 2: Apply zoom while maintaining centering
func _apply_zoom(camera: Camera2D, star_data: Dictionary, zoom_in: bool) -> void:
	# Check zoom limits
	var current_zoom = camera.zoom.x
	if zoom_in and current_zoom >= MAX_ZOOM:
		return
	elif not zoom_in and current_zoom <= MIN_ZOOM:
		return
	
	# Apply zoom
	var zoom_factor = ZOOM_FACTOR if zoom_in else (1.0 / ZOOM_FACTOR)
	camera.zoom *= zoom_factor
	camera.zoom = camera.zoom.clamp(Vector2(MIN_ZOOM, MIN_ZOOM), Vector2(MAX_ZOOM, MAX_ZOOM))
	
	# Maintain centering
	camera.global_position = star_data.world_pos
	get_viewport().warp_mouse(star_data.screen_center)

## Get nearest star under cursor with all required data
func _get_nearest_star_under_cursor(camera: Camera2D) -> Dictionary:
	# Calculate world position under cursor
	var mouse_screen = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2.0
	var mouse_offset = mouse_screen - screen_center
	var world_point = camera.global_position + mouse_offset / camera.zoom.x
	
	# Find nearest star
	var star_id = INVALID_STAR_ID
	var star_world_pos = Vector2.ZERO
	
	if star_mapper and hex_grid:
		var hex_grid_pos = hex_grid.to_local(world_point)
		star_id = star_mapper.get_nearest_star_id(hex_grid_pos)
		
		if star_id != INVALID_STAR_ID:
			var star_local_pos = star_mapper.get_star_position(star_id)
			star_world_pos = hex_grid.to_global(star_local_pos)
		else:
			# Fallback to cursor position
			star_world_pos = world_point
	else:
		# Fallback when systems not ready
		star_world_pos = world_point
	
	return {
		"star_id": star_id,
		"world_pos": star_world_pos,
		"screen_center": screen_center
	}