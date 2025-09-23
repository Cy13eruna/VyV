## V&V Game - Versão Final Ultra-Limpa
## Console realmente limpo + Domínios e Unidades funcionando

extends Node2D

const StarMapper = preload("res://scripts/star_mapper_clean.gd")
const Unit = preload("res://scripts/unit_clean.gd")
const Domain = preload("res://scripts/domain_clean.gd")

@onready var hex_grid = $HexGrid
var star_mapper = null
var units = []
var domains = []

# Sistema de mapa dinâmico
var domain_count_to_map_width = {
	6: 13, 5: 11, 4: 9, 3: 7, 2: 5
}
var current_domain_count: int = 6
var map_initialized: bool = false

# Cores disponíveis para domínios
var domain_colors = [
	Color(0, 0, 1),      # Azul
	Color(1, 0.5, 0),    # Laranja
	Color(1, 0, 0),      # Vermelho
	Color(0.5, 0, 1),    # Roxo
	Color(1, 1, 0),      # Amarelo
	Color(0, 1, 1)       # Ciano
]

# Sistema de movimentação
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
	# Obter configuração via console
	var domain_count = _get_domain_count_from_console()
	current_domain_count = domain_count
	
	# Configurar mapa
	_setup_map(domain_count)
	
	# Aguardar rebuild
	await get_tree().create_timer(0.2).timeout
	
	# Configurar sistema
	_setup_system()
	
	# Spawnar domínios
	_spawn_domains()
	
	map_initialized = true
	print("V&V: Sistema pronto!")

func _setup_map(player_count: int):
	var map_width = domain_count_to_map_width[player_count]
	var hex_radius = (map_width + 1) / 2
	
	hex_grid.config.set_grid_width(hex_radius)
	hex_grid.config.set_grid_height(hex_radius)
	hex_grid.rebuild_grid()

func _setup_system():
	# Criar star mapper
	star_mapper = StarMapper.new()
	star_mapper.map_stars(hex_grid.get_dot_positions())
	
	# Ajustar zoom
	_adjust_zoom()

func _spawn_domains():
	# Limpar arrays
	units.clear()
	domains.clear()
	
	# Encontrar posições de spawn
	var spawn_positions = _find_spawn_positions()
	
	# Spawnar domínios com unidades
	for i in range(min(current_domain_count, spawn_positions.size())):
		var star_id = spawn_positions[i]
		var color = domain_colors[i % domain_colors.size()]
		
		# Criar domínio
		var domain = Domain.new()
		domain.setup_references(hex_grid, star_mapper)
		domain.set_color(color)
		if domain.create_at_star(star_id, hex_grid):
			domains.append(domain)
			
			# Criar unidade no centro
			var unit = Unit.new()
			unit.setup_references(hex_grid, star_mapper)
			unit.set_color(color)
			unit.position_at_star(star_id)
			unit.create_visual(self)
			units.append(unit)

func _find_spawn_positions() -> Array:
	if not star_mapper:
		return []
	
	var dot_positions = hex_grid.get_dot_positions()
	if dot_positions.size() == 0:
		return []
	
	# Encontrar centro
	var center = Vector2.ZERO
	for pos in dot_positions:
		center += pos
	center /= dot_positions.size()
	
	# Encontrar estrelas mais distantes
	var star_distances = []
	for i in range(dot_positions.size()):
		var distance = center.distance_to(dot_positions[i])
		star_distances.append({"id": i, "distance": distance})
	
	star_distances.sort_custom(func(a, b): return a.distance > b.distance)
	
	# Selecionar posições distribuídas
	var positions = []
	var step = max(1, star_distances.size() / current_domain_count)
	for i in range(current_domain_count):
		var index = i * step
		if index < star_distances.size():
			positions.append(star_distances[index].id)
	
	return positions

func _adjust_zoom():
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
	else:
		base_zoom = 1.0
	
	camera.zoom = Vector2(base_zoom, base_zoom)

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
	
	# Desativar movimento se clicou em lugar vazio
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
		# Verificar se estrela está ocupada
		var occupied = false
		for unit in units:
			if unit.get_current_star_id() == star_id and unit != selected_unit:
				occupied = true
				break
		
		if not occupied:
			selected_unit.position_at_star(star_id)
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
	
	var current_star = selected_unit.get_current_star_id()
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
		if distance <= 38.0:  # Distância máxima de movimento
			valid_movement_stars.append(i)
	
	_highlight_movement_stars()

func _highlight_movement_stars():
	_clear_highlights()
	
	var dot_positions = hex_grid.get_dot_positions()
	for star_id in valid_movement_stars:
		if star_id < dot_positions.size():
			_create_star_highlight(dot_positions[star_id], selected_unit.team_color)

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
		if unit.is_positioned():
			var unit_pos = hex_grid.to_local(unit.get_world_position())
			var distance = hex_pos.distance_to(unit_pos)
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
		if is_instance_valid(unit):
			unit.cleanup()
	units.clear()
	
	# Limpar domínios
	for domain in domains:
		if is_instance_valid(domain):
			domain.cleanup()
	domains.clear()
	
	star_mapper = null