## GameController - Controlador Principal Refatorado do Jogo V&V
## Coordena sistemas e gerencia o fluxo principal do jogo

extends Node2D

const StarMapper = preload("res://scripts/star_mapper.gd")
const GameManagerRefactored = preload("res://scripts/game_manager_refactored.gd")

@onready var hex_grid = $HexGrid

## Sistemas principais
var star_mapper: StarMapper
var game_manager: GameManagerRefactored
var config: GameConfig

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

func _ready() -> void:
	EventBus.emit_info("V&V: Initializing game controller...")
	
	# Inicializar configuração
	config = GameConfig.get_instance()
	
	# Inicializar componentes
	star_mapper = StarMapper.new()
	game_manager = GameManagerRefactored.new(config)
	
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
	
	var camera = get_viewport().get_camera_2d()
	game_manager.setup_references(hex_grid, star_mapper, self, camera)
	
	# Conectar aos eventos do EventBus
	_connect_to_events()
	
	# Inicializar sistema de spawn
	_initialize_spawn_system()
	
	EventBus.emit_info("V&V: Game controller ready!")

## Conectar aos eventos do EventBus
func _connect_to_events() -> void:
	if not EventBus.instance:
		return
	
	# Eventos de input
	EventBus.instance.star_clicked.connect(_on_star_clicked)
	
	# Eventos de entidades
	EventBus.instance.unit_created.connect(_on_unit_created)
	EventBus.instance.domain_created.connect(_on_domain_created)

## Handle input events
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(mouse_event.global_position)

## Handle left click through game manager
func _handle_left_click(global_pos: Vector2) -> void:
	var input_result = game_manager.process_mouse_input(global_pos, MOUSE_BUTTON_LEFT)
	
	if not input_result.valid:
		if movement_mode_active:
			EventBus.emit_info("Click outside valid area - deactivating movement")
			_deactivate_movement_mode()
		return
	
	var star_id = input_result.star_id
	
	# If in movement mode, prioritize checking for valid movement stars
	if movement_mode_active and selected_unit:
		if star_id in valid_movement_stars:
			# Check if target star is already occupied by another unit
			var occupying_unit = game_manager.get_unit_at_star(star_id)
			if occupying_unit and occupying_unit != selected_unit:
				EventBus.emit_warning("Movement blocked: star %d already occupied by unit %d" % [star_id, occupying_unit.get_entity_id()])
				return
			
			EventBus.emit_info("Valid movement: moving unit to star %d" % star_id)
			_move_selected_unit_to_star(star_id)
			return
		else:
			# Click outside valid stars - deactivate movement
			EventBus.emit_info("Click outside valid stars - deactivating movement")
			_deactivate_movement_mode()
			return
	
	# Check if clicked on a unit
	var clicked_unit = _get_unit_at_position(input_result.hex_grid_pos)
	if clicked_unit:
		EventBus.emit_info("Unit clicked: %d" % clicked_unit.get_entity_id())
		_handle_unit_click(clicked_unit)
		return
	
	# If movement mode is active and clicked elsewhere, deactivate
	if movement_mode_active:
		EventBus.emit_info("Click elsewhere - deactivating movement")
		_deactivate_movement_mode()

## Sistema principal de spawn
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

## Handle unit click (selection/deselection)
func _handle_unit_click(unit) -> void:
	if selected_unit == unit:
		# Clicking same unit - deactivate movement mode
		_deactivate_movement_mode()
		EventBus.emit_info("Same unit clicked - deactivating movement")
	else:
		# Clicking different unit - activate movement mode
		_activate_movement_mode(unit)
		EventBus.emit_info("New unit selected - activating movement")

## Activate movement mode for unit
func _activate_movement_mode(unit) -> void:
	# Deactivate previous mode if active
	if movement_mode_active:
		_deactivate_movement_mode()
	
	selected_unit = unit
	movement_mode_active = true
	
	EventBus.emit_info("Activating movement for unit %d at star %d" % [unit.get_entity_id(), unit.get_current_star_id()])
	
	# Get valid adjacent stars
	var adjacent_stars = game_manager.get_valid_adjacent_stars(unit)
	
	# Filter out occupied stars
	valid_movement_stars = []
	for star_id in adjacent_stars:
		var occupying_unit = game_manager.get_unit_at_star(star_id)
		if not occupying_unit or occupying_unit == unit:
			valid_movement_stars.append(star_id)
	
	EventBus.emit_info("Valid adjacent stars: %s (filtered: %d occupied)" % [str(valid_movement_stars), adjacent_stars.size() - valid_movement_stars.size()])
	
	# Highlight valid movement stars with unit color
	_highlight_movement_stars(unit.visual_component.current_color)
	
	EventBus.emit_info("%d stars highlighted for movement" % valid_movement_stars.size())

## Deactivate movement mode
func _deactivate_movement_mode() -> void:
	selected_unit = null
	movement_mode_active = false
	valid_movement_stars.clear()
	
	# Clear star highlights
	_clear_star_highlights()
	EventBus.emit_info("Movement mode deactivated")

## Move selected unit to star
func _move_selected_unit_to_star(target_star_id: int) -> void:
	if not selected_unit:
		return
	
	# Reset actions to allow movement
	selected_unit.reset_actions()
	
	# Attempt movement
	if game_manager.move_unit_to_star(selected_unit, target_star_id):
		EventBus.emit_info("Unit moved to star %d" % target_star_id)
		
		# Update movement options for new position
		var adjacent_stars = game_manager.get_valid_adjacent_stars(selected_unit)
		
		# Filter out occupied stars
		valid_movement_stars = []
		for star_id in adjacent_stars:
			var occupying_unit = game_manager.get_unit_at_star(star_id)
			if not occupying_unit or occupying_unit == selected_unit:
				valid_movement_stars.append(star_id)
		
		_highlight_movement_stars(selected_unit.visual_component.current_color)
		
		EventBus.emit_info("New movement options: %d stars" % valid_movement_stars.size())
	else:
		EventBus.emit_error("Movement failed")

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
	var outer_radius = config.star_highlight_size  # dot_radius das estrelas fixas
	var inner_radius = config.star_inner_radius   # dot_star_size das estrelas fixas
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
	# Encontrar adjacentes de A
	var adjacent_to_a = []
	var star_a_pos = dot_positions[star_a_id]
	for i in range(dot_positions.size()):
		if i != star_a_id and star_a_pos.distance_to(dot_positions[i]) <= config.max_adjacent_distance:
			adjacent_to_a.append(i)
	
	# Encontrar adjacentes de B
	var adjacent_to_b = []
	var star_b_pos = dot_positions[star_b_id]
	for i in range(dot_positions.size()):
		if i != star_b_id and star_b_pos.distance_to(dot_positions[i]) <= config.max_adjacent_distance:
			adjacent_to_b.append(i)
	
	# Encontrar comum
	for star_id in adjacent_to_a:
		if star_id in adjacent_to_b:
			return star_id
	
	return -1

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
		
		if spawn_result.success:
			EventBus.emit_info("Domain %d created at star %d" % [i + 1, vertex_star_id])
		else:
			EventBus.emit_error("Spawn %d failed: %s" % [i + 1, spawn_result.get("reason", "unknown")])

## Event callbacks
func _on_star_clicked(star_id: int, button: int) -> void:
	# Handled in _handle_left_click
	pass

func _on_unit_created(unit_data: Dictionary) -> void:
	EventBus.emit_info("Unit created: %d" % unit_data.entity_id)

func _on_domain_created(domain_data: Dictionary) -> void:
	EventBus.emit_info("Domain created: %d" % domain_data.entity_id)