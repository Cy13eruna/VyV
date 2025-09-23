## V&V Game - Versão Ultra-Simples
## Console limpo + Sistema básico funcionando

extends Node2D

@onready var hex_grid = $HexGrid

# Sistema básico
var units = []
var domains = []
var map_initialized: bool = false

# Cores para domínios
var colors = [
	Color(0, 0, 1),      # Azul
	Color(1, 0.5, 0),    # Laranja
	Color(1, 0, 0),      # Vermelho
	Color(0.5, 0, 1),    # Roxo
	Color(1, 1, 0),      # Amarelo
	Color(0, 1, 1)       # Ciano
]

# Sistema de movimento
var selected_unit = null
var movement_mode_active: bool = false
var highlighted_stars = []
var valid_movement_stars = []

# Sistema de zoom
const ZOOM_FACTOR: float = 1.3
const MIN_ZOOM: float = 0.3
const MAX_ZOOM: float = 5.0

func _ready():
	print("V&V: Inicializando...")
	
	# Aguardar grid estar pronto
	if hex_grid.is_initialized:
		_initialize_game()
	else:
		hex_grid.grid_initialized.connect(_initialize_game, CONNECT_ONE_SHOT)

func _initialize_game():
	# Obter configuração
	var domain_count = _get_domain_count_from_console()
	
	# Configurar mapa
	_setup_map(domain_count)
	
	# Aguardar rebuild
	await get_tree().create_timer(0.3).timeout
	
	# Spawnar elementos
	_spawn_simple_elements(domain_count)
	
	map_initialized = true
	print("V&V: Sistema pronto!")

func _setup_map(player_count: int):
	var map_sizes = {6: 13, 5: 11, 4: 9, 3: 7, 2: 5}
	var map_width = map_sizes.get(player_count, 7)
	var hex_radius = (map_width + 1) / 2
	
	hex_grid.config.set_grid_width(hex_radius)
	hex_grid.config.set_grid_height(hex_radius)
	hex_grid.rebuild_grid()

func _spawn_simple_elements(count: int):
	# Limpar arrays
	units.clear()
	domains.clear()
	
	# Obter posições das estrelas
	var dot_positions = hex_grid.get_dot_positions()
	if dot_positions.size() == 0:
		return
	
	# Encontrar centro
	var center = Vector2.ZERO
	for pos in dot_positions:
		center += pos
	center /= dot_positions.size()
	
	# Encontrar posições mais distantes
	var distances = []
	for i in range(dot_positions.size()):
		var distance = center.distance_to(dot_positions[i])
		distances.append({"id": i, "distance": distance, "pos": dot_positions[i]})
	
	distances.sort_custom(func(a, b): return a.distance > b.distance)
	
	# Criar elementos simples
	for i in range(min(count, distances.size())):
		var star_id = distances[i].id
		var color = colors[i % colors.size()]
		var pos = distances[i].pos
		
		# Criar domínio visual simples
		var domain_visual = _create_simple_domain(pos, color)
		domains.append({"visual": domain_visual, "star_id": star_id, "color": color})
		
		# Criar unidade visual simples
		var unit_visual = _create_simple_unit(pos, color)
		units.append({"visual": unit_visual, "star_id": star_id, "color": color, "pos": pos})

func _create_simple_domain(position: Vector2, color: Color) -> Node2D:
	var domain_node = Node2D.new()
	domain_node.position = position
	domain_node.z_index = 10
	domain_node.draw.connect(_draw_simple_domain.bind(domain_node, color))
	hex_grid.add_child(domain_node)
	domain_node.queue_redraw()
	return domain_node

func _draw_simple_domain(canvas_item: CanvasItem, color: Color):
	# Desenhar hexágono simples
	var points = PackedVector2Array()
	for i in range(6):
		var angle = deg_to_rad(60.0 * i)
		var point = Vector2(cos(angle), sin(angle)) * 25.0
		points.append(point)
	
	canvas_item.draw_colored_polygon(points, Color(color.r, color.g, color.b, 0.3))
	canvas_item.draw_polyline(points + [points[0]], color, 2.0)

func _create_simple_unit(position: Vector2, color: Color) -> Node2D:
	var unit_node = Node2D.new()
	unit_node.position = position
	unit_node.z_index = 50
	unit_node.draw.connect(_draw_simple_unit.bind(unit_node, color))
	hex_grid.add_child(unit_node)
	unit_node.queue_redraw()
	return unit_node

func _draw_simple_unit(canvas_item: CanvasItem, color: Color):
	# Desenhar círculo simples para unidade
	canvas_item.draw_circle(Vector2.ZERO, 8.0, color)
	canvas_item.draw_circle(Vector2.ZERO, 8.0, Color.BLACK, false, 2.0)

func _get_domain_count_from_console() -> int:
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--domain-count="):
			return clamp(int(arg.split("=")[1]), 2, 6)
	return 3

## Input handling
func _unhandled_input(event: InputEvent):
	if not map_initialized:
		return
	
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_handle_left_click(event.global_position)
			MOUSE_BUTTON_WHEEL_UP:
				_handle_zoom_in()
			MOUSE_BUTTON_WHEEL_DOWN:
				_handle_zoom_out()

func _handle_left_click(global_pos: Vector2):
	var hex_pos = _convert_screen_to_hex_position(global_pos)
	
	# Se em modo movimento, tentar mover
	if movement_mode_active and selected_unit:
		_try_move_unit(hex_pos)
		return
	
	# Tentar selecionar unidade
	var clicked_unit = _get_unit_at_position(hex_pos)
	if clicked_unit:
		_handle_unit_selection(clicked_unit)
		return
	
	# Desativar movimento
	if movement_mode_active:
		_deactivate_movement_mode()

func _convert_screen_to_hex_position(screen_pos: Vector2) -> Vector2:
	var camera = get_viewport().get_camera_2d()
	var zoom_factor = camera.zoom.x if camera else 1.0
	var camera_pos = camera.global_position if camera else Vector2.ZERO
	
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2.0
	var mouse_offset = screen_pos - screen_center
	var world_offset = mouse_offset / zoom_factor
	var world_pos = camera_pos + world_offset
	
	return hex_grid.to_local(world_pos)

func _try_move_unit(hex_pos: Vector2):
	var star_id = _get_star_at_position(hex_pos)
	
	if star_id >= 0 and star_id in valid_movement_stars:
		# Mover unidade
		var dot_positions = hex_grid.get_dot_positions()
		if star_id < dot_positions.size():
			selected_unit.visual.position = dot_positions[star_id]
			selected_unit.star_id = star_id
			selected_unit.pos = dot_positions[star_id]
			_update_movement_options()
	else:
		_deactivate_movement_mode()

func _handle_unit_selection(unit):
	if selected_unit == unit:
		_deactivate_movement_mode()
	else:
		_activate_movement_mode(unit)

func _activate_movement_mode(unit):
	selected_unit = unit
	movement_mode_active = true
	_update_movement_options()

func _update_movement_options():
	if not selected_unit:
		return
	
	var current_star = selected_unit.star_id
	var dot_positions = hex_grid.get_dot_positions()
	
	if current_star >= dot_positions.size():
		return
	
	var current_pos = dot_positions[current_star]
	valid_movement_stars = []
	
	# Encontrar estrelas adjacentes
	for i in range(dot_positions.size()):
		if i == current_star:
			continue
		
		var distance = current_pos.distance_to(dot_positions[i])
		if distance <= 38.0:
			valid_movement_stars.append(i)
	
	_highlight_movement_stars()

func _highlight_movement_stars():
	_clear_highlights()
	
	var dot_positions = hex_grid.get_dot_positions()
	for star_id in valid_movement_stars:
		if star_id < dot_positions.size():
			_create_star_highlight(dot_positions[star_id], selected_unit.color)

func _create_star_highlight(position: Vector2, color: Color):
	var highlight = Node2D.new()
	highlight.position = position
	highlight.z_index = 60
	highlight.draw.connect(_draw_star_highlight.bind(highlight, color))
	
	hex_grid.add_child(highlight)
	highlighted_stars.append(highlight)
	highlight.queue_redraw()

func _draw_star_highlight(canvas_item: CanvasItem, color: Color):
	var points = PackedVector2Array()
	for i in range(12):
		var angle = deg_to_rad(30.0 * i)
		var radius = 6.0 if i % 2 == 0 else 3.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	canvas_item.draw_colored_polygon(points, color)

func _clear_highlights():
	for highlight in highlighted_stars:
		if is_instance_valid(highlight):
			highlight.queue_free()
	highlighted_stars.clear()

func _deactivate_movement_mode():
	selected_unit = null
	movement_mode_active = false
	valid_movement_stars.clear()
	_clear_highlights()

func _get_unit_at_position(hex_pos: Vector2):
	for unit in units:
		var distance = hex_pos.distance_to(unit.pos)
		if distance <= 20.0:
			return unit
	return null

func _get_star_at_position(hex_pos: Vector2) -> int:
	var dot_positions = hex_grid.get_dot_positions()
	var closest_star = -1
	var closest_distance = 999999.0
	
	for i in range(dot_positions.size()):
		var distance = hex_pos.distance_to(dot_positions[i])
		if distance <= 30.0 and distance < closest_distance:
			closest_distance = distance
			closest_star = i
	
	return closest_star

func _handle_zoom_in():
	_apply_zoom(true)

func _handle_zoom_out():
	_apply_zoom(false)

func _apply_zoom(zoom_in: bool):
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var factor = ZOOM_FACTOR if zoom_in else (1.0 / ZOOM_FACTOR)
	var new_zoom = camera.zoom * factor
	new_zoom = new_zoom.clamp(Vector2(MIN_ZOOM, MIN_ZOOM), Vector2(MAX_ZOOM, MAX_ZOOM))
	
	camera.zoom = new_zoom

func _exit_tree():
	_clear_highlights()
	
	# Limpar unidades
	for unit in units:
		if is_instance_valid(unit.visual):
			unit.visual.queue_free()
	units.clear()
	
	# Limpar domínios
	for domain in domains:
		if is_instance_valid(domain.visual):
			domain.visual.queue_free()
	domains.clear()