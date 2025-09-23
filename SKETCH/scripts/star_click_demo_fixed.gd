## V&V Game - Versão Corrigida
## Console limpo + Domínios e Unidades funcionando

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

# Sistema de zoom
var zoom_mode_active: bool = false
var current_centered_star_id: int = -1
const ZOOM_FACTOR: float = 1.3
const MIN_ZOOM: float = 0.3
const MAX_ZOOM: float = 5.0
const INVALID_STAR_ID: int = -1

func _ready():
	print("V&V: Inicializando...")
	
	# Inicializar componentes
	if not star_mapper:
		star_mapper = StarMapper.new()
	if not game_manager:
		game_manager = GameManager.new()
	
	# Executar sistema de mapa
	_execute_map_creation_steps()

func _execute_map_creation_steps():
	# Obter quantidade de domínios via console
	var domain_count = _get_domain_count_from_console()
	current_domain_count = domain_count
	var map_width = domain_count_to_map_width[domain_count]
	
	# Passo 1: Renderizar tabuleiro
	_step_1_render_board(map_width)
	
	# Aguardar grid estar pronto
	if hex_grid.is_initialized:
		_continue_remaining_steps()
	else:
		hex_grid.grid_initialized.connect(_continue_remaining_steps, CONNECT_ONE_SHOT)

func _step_1_render_board(width: int):
	var hex_radius = (width + 1) / 2
	hex_grid.config.set_grid_width(hex_radius)
	hex_grid.config.set_grid_height(hex_radius)
	hex_grid.rebuild_grid()

func _continue_remaining_steps():
	if not hex_grid.is_grid_ready():
		await get_tree().create_timer(0.1).timeout
		_continue_remaining_steps()
		return
	
	# Passo 2: Mapear estrelas
	_step_2_map_stars()
	
	# Passo 3: Posicionar domínios
	_step_3_position_domains()
	
	# Passo 4: Ajustar zoom
	_step_4_adjust_zoom()
	
	# Sistema pronto
	map_initialized = true
	print("V&V: Sistema pronto!")

func _step_2_map_stars():
	var dot_positions = hex_grid.get_dot_positions()
	star_mapper.map_stars(dot_positions)
	
	# Configurar GameManager
	game_manager.setup_references(hex_grid, star_mapper, self)
	
	# Conectar sinais
	if not game_manager.unit_created.is_connected(_on_unit_created):
		game_manager.unit_created.connect(_on_unit_created)
	if not game_manager.domain_created.is_connected(_on_domain_created):
		game_manager.domain_created.connect(_on_domain_created)

func _step_3_position_domains():
	# Limpar entidades existentes
	game_manager.clear_all_units()
	game_manager.clear_all_domains()
	
	# Encontrar posições de spawn
	var available_vertices = _find_spawn_vertices()
	if available_vertices.size() == 0:
		return
	
	# Selecionar posições e cores
	var selected_vertices = _select_random_vertices(available_vertices, current_domain_count)
	_prepare_random_colors(current_domain_count)
	
	# Spawnar domínios
	_spawn_colored_domains(selected_vertices)

func _step_4_adjust_zoom():
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var map_width = domain_count_to_map_width[current_domain_count]
	var base_zoom = 1.0
	
	if map_width <= 5:
		base_zoom = 2.0
	elif map_width <= 7:
		base_zoom = 1.6
	elif map_width <= 9:
		base_zoom = 1.3
	elif map_width <= 11:
		base_zoom = 1.1
	else:
		base_zoom = 0.9
	
	camera.zoom = Vector2(base_zoom, base_zoom)
	
	# Centralizar câmera
	var dot_positions = hex_grid.get_dot_positions()
	if dot_positions.size() > 0:
		var center = Vector2.ZERO
		for pos in dot_positions:
			center += pos
		center /= dot_positions.size()
		camera.global_position = hex_grid.to_global(center)

func _find_spawn_vertices() -> Array:
	if not hex_grid or not star_mapper:
		return []
	
	var dot_positions = hex_grid.get_dot_positions()
	var total_stars = star_mapper.get_star_count()
	var domain_centers = []
	
	# Encontrar centro do tabuleiro
	var center = Vector2.ZERO
	for pos in dot_positions:
		center += pos
	center /= dot_positions.size()
	
	# Encontrar as 12 estrelas mais distantes
	var star_distances = []
	for i in range(dot_positions.size()):
		var pos = dot_positions[i]
		var distance = center.distance_to(pos)
		star_distances.append({"id": i, "distance": distance, "pos": pos})
	
	star_distances.sort_custom(func(a, b): return a.distance > b.distance)
	var twelve_farthest = star_distances.slice(0, min(12, star_distances.size()))
	
	# Agrupar em duplas por proximidade
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
	
	# Encontrar centros das duplas
	for pair in pairs:
		var center_star = _find_common_adjacent_star(pair[0].id, pair[1].id, dot_positions)
		if center_star >= 0 and center_star < total_stars:
			domain_centers.append(center_star)
	
	return domain_centers

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

func _prepare_random_colors(count: int):
	available_colors.clear()
	var colors_copy = domain_colors.duplicate()
	
	for i in range(min(count, colors_copy.size())):
		var random_index = randi() % colors_copy.size()
		available_colors.append(colors_copy[random_index])
		colors_copy.remove_at(random_index)

func _spawn_colored_domains(selected_vertices: Array):
	var spawned_count = 0
	for i in range(selected_vertices.size()):
		var vertex_star_id = selected_vertices[i]
		var domain_color = available_colors[i] if i < available_colors.size() else Color.WHITE
		
		var spawn_result = game_manager.spawn_domain_with_unit_colored(vertex_star_id, domain_color)
		
		if spawn_result:
			spawned_count += 1

func _get_domain_count_from_console() -> int:
	var args = OS.get_cmdline_args()
	var domain_count = 6  # Padrão
	
	for arg in args:
		if arg.begins_with("--domain-count="):
			domain_count = int(arg.split("=")[1])
			break
	
	domain_count = clamp(domain_count, 2, 6)
	return domain_count

## Input handling
func _unhandled_input(event: InputEvent):
	if not map_initialized:
		return
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(mouse_event.global_position)
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_handle_zoom_in()
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_handle_zoom_out()

func _handle_left_click(global_pos: Vector2):
	# Converter posição do mouse
	var camera = get_viewport().get_camera_2d()
	var zoom_factor = camera.zoom.x if camera else 1.0
	var camera_pos = camera.global_position if camera else Vector2.ZERO
	
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2.0
	var mouse_offset = global_pos - screen_center
	var world_offset = mouse_offset / zoom_factor
	var world_pos = camera_pos + world_offset
	var hex_grid_pos = hex_grid.to_local(world_pos)
	
	# Verificar se clicou em uma unidade
	var clicked_unit = _get_unit_at_position(hex_grid_pos)
	if clicked_unit:
		_handle_unit_click(clicked_unit)
		return
	
	# Se em modo movimento, tentar mover
	if movement_mode_active and selected_unit:
		var clicked_star_id = _get_star_at_position(hex_grid_pos)
		if clicked_star_id >= 0 and clicked_star_id in valid_movement_stars:
			_move_selected_unit_to_star(clicked_star_id)
			return
		else:
			_deactivate_movement_mode()
			return
	
	# Desativar movimento se clicou em lugar vazio
	if movement_mode_active:
		_deactivate_movement_mode()

func _handle_unit_click(unit):
	if selected_unit == unit:
		_deactivate_movement_mode()
	else:
		_activate_movement_mode(unit)

func _activate_movement_mode(unit):
	if movement_mode_active:
		_deactivate_movement_mode()
	
	selected_unit = unit
	movement_mode_active = true
	
	# Obter estrelas adjacentes válidas
	var adjacent_stars = game_manager.get_valid_adjacent_stars(unit)
	
	# Filtrar estrelas ocupadas
	valid_movement_stars = []
	for star_id in adjacent_stars:
		var occupying_unit = game_manager.get_unit_at_star(star_id)
		if not occupying_unit or occupying_unit == unit:
			valid_movement_stars.append(star_id)
	
	# Destacar estrelas de movimento
	_highlight_movement_stars(unit.visual_node.modulate)

func _deactivate_movement_mode():
	selected_unit = null
	movement_mode_active = false
	valid_movement_stars.clear()
	_clear_star_highlights()

func _highlight_movement_stars(unit_color: Color):
	_clear_star_highlights()
	
	var dot_positions = hex_grid.get_dot_positions()
	
	for star_id in valid_movement_stars:
		if star_id < dot_positions.size():
			var star_pos = dot_positions[star_id]
			_create_colored_star_highlight(star_pos, unit_color)

func _create_colored_star_highlight(position: Vector2, color: Color):
	var highlight_node = Node2D.new()
	highlight_node.position = position
	highlight_node.z_index = 60
	highlight_node.visible = true
	
	highlight_node.draw.connect(_draw_colored_star.bind(highlight_node, color))
	
	hex_grid.add_child(highlight_node)
	highlighted_stars.append(highlight_node)
	
	highlight_node.queue_redraw()

func _draw_colored_star(canvas_item: CanvasItem, color: Color):
	var outer_radius = 6.0
	var inner_radius = 3.0
	var points = PackedVector2Array()
	
	for i in range(12):
		var angle_deg = 30.0 * i
		var angle_rad = deg_to_rad(angle_deg)
		var radius = outer_radius if i % 2 == 0 else inner_radius
		var point = Vector2(cos(angle_rad), sin(angle_rad)) * radius
		points.append(point)
	
	canvas_item.draw_colored_polygon(points, color)

func _clear_star_highlights():
	for highlight in highlighted_stars:
		if is_instance_valid(highlight):
			if highlight.get_parent():
				highlight.get_parent().remove_child(highlight)
			highlight.queue_free()
	highlighted_stars.clear()

func _move_selected_unit_to_star(target_star_id: int):
	if not selected_unit:
		return
	
	# Reset de ações para permitir movimento
	selected_unit.reset_actions()
	
	# Tentar movimento
	if game_manager.move_unit_to_star(selected_unit, target_star_id):
		# Atualizar opções de movimento para nova posição
		var adjacent_stars = game_manager.get_valid_adjacent_stars(selected_unit)
		
		valid_movement_stars = []
		for star_id in adjacent_stars:
			var occupying_unit = game_manager.get_unit_at_star(star_id)
			if not occupying_unit or occupying_unit == selected_unit:
				valid_movement_stars.append(star_id)
		
		_highlight_movement_stars(selected_unit.visual_node.modulate)

func _get_unit_at_position(position: Vector2):
	var click_width = 24.0
	var click_height = 54.0
	
	for unit in game_manager.get_all_units():
		if unit.is_positioned():
			var unit_world_pos = unit.get_world_position()
			var unit_local_pos = hex_grid.to_local(unit_world_pos)
			
			var dx = abs(position.x - unit_local_pos.x)
			var dy = abs(position.y - unit_local_pos.y)
			
			var within_bounds = (dx <= click_width / 2.0) and (dy <= click_height / 2.0)
			
			if within_bounds:
				return unit
	
	return null

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

func _handle_zoom_in():
	_handle_zoom(true)

func _handle_zoom_out():
	_handle_zoom(false)

func _handle_zoom(zoom_in: bool):
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var factor = ZOOM_FACTOR if zoom_in else (1.0 / ZOOM_FACTOR)
	var new_zoom = camera.zoom * factor
	new_zoom = new_zoom.clamp(Vector2(MIN_ZOOM, MIN_ZOOM), Vector2(MAX_ZOOM, MAX_ZOOM))
	
	camera.zoom = new_zoom

## Callbacks (SEM LOGS)
func _on_unit_created(unit_id: int):
	pass

func _on_domain_created(domain_id: int):
	pass

## Limpeza
func _exit_tree():
	_clear_star_highlights()
	
	if game_manager:
		game_manager.cleanup()
		game_manager = null
	
	if star_mapper:
		star_mapper = null
	
	hex_grid = null