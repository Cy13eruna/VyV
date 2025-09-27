## V&V Game - Sistema de Turnos Implementado
## Sistema multi-instâncias com turnos por time/cor
##
## 🚨 ATENÇÃO: ARQUIVO EM REFATORAÇÃO CRÍTICA!
## ⚠️  Este arquivo tem 700+ linhas e viola princípios SOLID
## 📋 Roteiro de refatoração: ../.qodo/CRITICAL_REFACTOR_ROADMAP.md
## 🎯 Meta: Dividir em TurnManager, InputHandler, UIManager, GameController
## ❌ NÃO ADICIONE MAIS CÓDIGO AQUI - Use os sistemas modulares!
##
## TODO CRÍTICO:
## - [ ] Extrair TurnManager (linhas 95-250)
## - [ ] Extrair InputHandler (linhas 290-450)
## - [ ] Extrair UIManager (linhas 155-190)
## - [ ] Manter apenas orquestração aqui
## - [ ] Usar EventBus em vez de acoplamento direto
## - [ ] Substituir new() por ObjectPool
## - [ ] Usar Config em vez de magic numbers

extends Node2D

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

const StarMapper = preload("res://scripts/entities/star_mapper.gd")
const Unit = preload("res://scripts/entities/unit.gd")
const Domain = preload("res://scripts/entities/domain.gd")
const GameManager = preload("res://scripts/game/game_manager.gd")

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

# Sistema de turnos
var teams = []  # Array de teams com suas cores e unidades/domínios
var current_team_index: int = 0
var current_turn: int = 1
var game_started: bool = false

# Interface de turnos
var next_turn_button: Button
var button_canvas_layer: CanvasLayer

# Cores disponíveis para domínios/teams
var team_colors = [
	Color(0, 0, 1),      # Azul RGB
	Color(1, 0.5, 0),    # Laranja
	Color(1, 0, 0),      # Vermelho RGB
	Color(0.5, 0, 1),    # Roxo
	Color(1, 1, 0),      # Amarelo
	Color(0, 1, 1)       # Ciano
]
var team_names = ["Azul", "Laranja", "Vermelho", "Roxo", "Amarelo", "Ciano"]

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
	Logger.info("Inicializando sistema com turnos...", "MainGame")
	
	# Passo 0: Aguardar input via console para quantidade de domínios
	_step_0_console_input()
	
	# Inicializar componentes apenas se não existirem
	if not star_mapper:
		star_mapper = StarMapper.new()
	if not game_manager:
		game_manager = GameManager.new()

func _setup_system() -> void:
	# Aguardar um frame para garantir que tudo está pronto
	await get_tree().process_frame
	
	# Configurar sistema de turnos
	_setup_turn_system()
	
	# Configurar interface de turnos
	_setup_turn_interface()
	
	# Aguardar outro frame para interface estar pronta
	await get_tree().process_frame
	
	# Iniciar jogo
	game_started = true
	_start_first_turn()
	
	Logger.info("Sistema com turnos ativado!", "MainGame")

## Configurar sistema de turnos
func _setup_turn_system() -> void:
	teams.clear()
	
	# Criar teams baseado nas cores dos domínios spawned
	var all_domains = game_manager.get_all_domains()
	var all_units = game_manager.get_all_units()
	
	# Agrupar por cores das unidades (que são mais confiáveis)
	var color_groups = {}
	
	for unit in all_units:
		if not unit.visual_node:
			continue
			
		var unit_color = unit.visual_node.modulate
		# Verificar se a cor não é branca (cor padrão)
		if unit_color == Color.WHITE or unit_color.a < 0.5:
			continue
			
		var color_key = _color_to_key(unit_color)
		
		if not color_groups.has(color_key):
			color_groups[color_key] = {
				"color": unit_color,
				"units": [],
				"domains": []
			}
		
		color_groups[color_key].units.append(unit)
		Logger.debug("Unidade adicionada ao grupo %s" % color_key, "TurnSystem")
	
	# Associar domínios aos grupos de cor
	for domain in all_domains:
		var domain_color = domain.line_color  # Usar line_color em vez de get_color()
		var color_key = _color_to_key(domain_color)
		
		if color_groups.has(color_key):
			color_groups[color_key].domains.append(domain)
	
	# Criar teams baseado nos grupos de cor
	var team_index = 0
	for color_key in color_groups.keys():
		var group = color_groups[color_key]
		var team_name = team_names[team_index] if team_index < team_names.size() else "Team " + str(team_index + 1)
		
		var new_team = {
			"id": team_index,
			"name": team_name,
			"color": group.color,
			"domains": group.domains,
			"units": group.units,
			"is_active": false
		}
		teams.append(new_team)
		team_index += 1
	
	Logger.info("Teams criados: %d" % teams.size(), "TurnSystem")
	for team in teams:
		Logger.debug("Team %s: %d unidades, %d domínios" % [team.name, team.units.size(), team.domains.size()], "TurnSystem")

## Configurar interface de turnos
func _setup_turn_interface() -> void:
	# Criar CanvasLayer para UI
	button_canvas_layer = CanvasLayer.new()
	button_canvas_layer.layer = 100  # Sempre no topo
	add_child(button_canvas_layer)
	
	# Criar botão NEXT TURN
	next_turn_button = Button.new()
	next_turn_button.text = "NEXT TURN"
	next_turn_button.size = Vector2(120, 40)
	
	# Posicionar no canto superior direito
	next_turn_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	next_turn_button.position = Vector2(-130, 10)  # Margem de 10px
	
	# Conectar sinal
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	
	# Adicionar ao CanvasLayer
	button_canvas_layer.add_child(next_turn_button)
	
	# Atualizar aparência inicial
	_update_turn_button()

## Atualizar aparência do botão baseado no team atual
func _update_turn_button() -> void:
	if not next_turn_button or teams.size() == 0:
		return
	
	if current_team_index >= teams.size():
		current_team_index = 0
	
	var current_team = teams[current_team_index]
	
	# Definir cor do botão baseado no team atual
	next_turn_button.modulate = current_team.color
	
	# Atualizar texto do botão
	next_turn_button.text = "TURNO: " + current_team.name
	
	Logger.debug("Botão atualizado: %s (cor: %s)" % [current_team.name, current_team.color], "TurnSystem")

## Iniciar primeiro turno
func _start_first_turn() -> void:
	if teams.size() == 0:
		return
	
	current_team_index = 0
	current_turn = 1
	
	_activate_team_turn(current_team_index)

## Ativar turno de um team específico
func _activate_team_turn(team_index: int) -> void:
	# Desativar todos os teams
	for team in teams:
		team.is_active = false
	
	# Ativar team atual
	if team_index < teams.size():
		var active_team = teams[team_index]
		active_team.is_active = true
		
		# Reset de ações das unidades do team (cada unidade tem 1 ação)
		for unit in active_team.units:
			unit.reset_actions()
		
		Logger.info("Turno %d - Team %s ativo (%d unidades)" % [current_turn, active_team.name, active_team.units.size()], "TurnSystem")
	
	# Atualizar interface
	_update_turn_button()
	
	# Desativar modo de movimento se ativo
	_deactivate_movement_mode()

## Callback do botão NEXT TURN
func _on_next_turn_pressed() -> void:
	_next_turn()

## Avançar para próximo turno
func _next_turn() -> void:
	if not game_started or teams.size() == 0:
		return
	
	# Avançar para próximo team
	current_team_index = (current_team_index + 1) % teams.size()
	
	# Se voltou ao primeiro team, incrementar turno
	if current_team_index == 0:
		current_turn += 1
	
	# Ativar próximo team
	_activate_team_turn(current_team_index)

## Verificar se unidade pertence ao team atual
func _is_unit_from_current_team(unit) -> bool:
	if teams.size() == 0:
		return false
	
	var current_team = teams[current_team_index]
	return unit in current_team.units

## Verificar se unidade pode agir
func _can_unit_act(unit) -> bool:
	if teams.size() == 0:
		return false
	
	var current_team = teams[current_team_index]
	if not current_team.is_active:
		return false
	
	# Verificar se unidade pertence ao team atual e tem ações
	return unit in current_team.units and unit.actions_remaining > 0

## Converter cor para chave string
func _color_to_key(color: Color) -> String:
	return "%.2f_%.2f_%.2f" % [color.r, color.g, color.b]

## Comparar cores (com tolerância para pequenas diferenças)
func _colors_are_equal(color1: Color, color2: Color, tolerance: float = 0.1) -> bool:
	return (
		abs(color1.r - color2.r) < tolerance and
		abs(color1.g - color2.g) < tolerance and
		abs(color1.b - color2.b) < tolerance
	)

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

## Handle left click for unit selection and movement (COM CONTROLE DE TURNOS)
func _handle_left_click(global_pos: Vector2) -> void:
	# Reset zoom mode on any click
	_reset_zoom_mode()
	
	# Convert mouse position to hex grid coordinates
	var camera = get_viewport().get_camera_2d()
	var zoom_factor = camera.zoom.x if camera else 1.0
	var camera_pos = camera.global_position if camera else Vector2.ZERO
	
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2.0
	var mouse_offset = global_pos - screen_center
	var world_offset = mouse_offset / zoom_factor
	var world_pos = camera_pos + world_offset
	var hex_grid_pos = hex_grid.to_local(world_pos)
	
	# If in movement mode, prioritize checking for valid movement stars
	if movement_mode_active and selected_unit:
		var clicked_star_id = _get_star_at_position(hex_grid_pos)
		
		if clicked_star_id >= 0 and clicked_star_id in valid_movement_stars:
			# Verificar se unidade pode agir
			if not _can_unit_act(selected_unit):
				Logger.warning("Unidade já usou sua ação neste turno!", "TurnSystem")
				return
			
			# Check if target star is already occupied by another unit
			var occupying_unit = game_manager.get_unit_at_star(clicked_star_id)
			if occupying_unit and occupying_unit != selected_unit:
				return
			
			# Executar movimento (a unidade consumirá sua própria ação)
			_move_selected_unit_to_star(clicked_star_id)
			return
		else:
			_deactivate_movement_mode()
			return
	
	# Check if clicked on a unit
	var clicked_unit = _get_unit_at_position(hex_grid_pos)
	if clicked_unit:
		# Verificar se unidade pertence ao team atual
		if not _is_unit_from_current_team(clicked_unit):
			Logger.warning("Esta unidade não pertence ao seu team!", "TurnSystem")
			return
		
		_handle_unit_click(clicked_unit)
		return
	
	# If movement mode is active and clicked elsewhere, deactivate
	if movement_mode_active:
		_deactivate_movement_mode()

## Handle unit click (selection/deselection) - COM CONTROLE DE TURNOS
func _handle_unit_click(unit) -> void:
	# Verificar se é turno do team correto
	if not _is_unit_from_current_team(unit):
		return
	
	if selected_unit == unit:
		_deactivate_movement_mode()
	else:
		_activate_movement_mode(unit)

## Activate movement mode for unit - COM CONTROLE DE TURNOS
func _activate_movement_mode(unit) -> void:
	# Verificar se unidade pode agir
	if not _can_unit_act(unit):
		Logger.warning("Unidade já usou sua ação neste turno!", "TurnSystem")
		return
	
	# Verificar se unidade pertence ao team atual
	if not _is_unit_from_current_team(unit):
		return
	
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

## Move selected unit to star - COM CONTROLE DE TURNOS
func _move_selected_unit_to_star(target_star_id: int) -> void:
	if not selected_unit:
		return
	
	# Verificar se unidade pode agir
	if not _can_unit_act(selected_unit):
		return
	
	# Attempt movement (unit will consume its own action)
	if game_manager.move_unit_to_star(selected_unit, target_star_id):
		Logger.debug("Unidade movida! Ações restantes: %d" % selected_unit.actions_remaining, "TurnSystem")
		
		# IMPORTANTE: Remover highlights após usar a ação
		if selected_unit.actions_remaining <= 0:
			Logger.debug("Unidade sem ações - removendo highlights", "TurnSystem")
			_deactivate_movement_mode()
		else:
			# Se ainda tem ações, atualizar highlights
			var adjacent_stars = game_manager.get_valid_adjacent_stars(selected_unit)
			
			# Filter out occupied stars
			valid_movement_stars = []
			for star_id in adjacent_stars:
				var occupying_unit = game_manager.get_unit_at_star(star_id)
				if not occupying_unit or occupying_unit == selected_unit:
					valid_movement_stars.append(star_id)
			
			_highlight_movement_stars(selected_unit.visual_node.modulate)

## RESTO DO CÓDIGO ORIGINAL (sem modificações)

## Passo 0: Aguardar input via console para quantidade de domínios
func _step_0_console_input() -> void:
	var domain_count = _get_domain_count_from_console()
	_execute_map_creation_steps(domain_count)

func _get_domain_count_from_console() -> int:
	var args = OS.get_cmdline_args()
	var domain_count = 6
	
	for arg in args:
		if arg.begins_with("--domain-count="):
			domain_count = int(arg.split("=")[1])
			break
	
	domain_count = clamp(domain_count, 2, 6)
	return domain_count

func _execute_map_creation_steps(domain_count: int) -> void:
	current_domain_count = domain_count
	var map_width = domain_count_to_map_width[domain_count]
	
	_step_1_render_board(map_width)
	
	if hex_grid.is_initialized:
		_continue_remaining_steps()
	else:
		hex_grid.grid_initialized.connect(_continue_remaining_steps, CONNECT_ONE_SHOT)

func _step_1_render_board(width: int) -> void:
	var hex_radius = (width + 1) / 2
	hex_grid.config.set_grid_width(hex_radius)
	hex_grid.config.set_grid_height(hex_radius)
	hex_grid.rebuild_grid()

func _continue_remaining_steps() -> void:
	if not hex_grid.is_grid_ready():
		get_tree().create_timer(0.5).timeout.connect(_continue_remaining_steps, CONNECT_ONE_SHOT)
		return
	
	_step_2_map_stars()
	_step_3_position_domains()
	_step_4_adjust_zoom()
	
	map_initialized = true
	_setup_system()

func _step_2_map_stars() -> void:
	if not hex_grid or not hex_grid.is_grid_ready():
		return
	
	if not star_mapper:
		star_mapper = StarMapper.new()
	
	var dot_positions = hex_grid.get_dot_positions()
	star_mapper.map_stars(dot_positions)
	
	if not game_manager:
		game_manager = GameManager.new()
	
	game_manager.setup_references(hex_grid, star_mapper, self)
	
	if not game_manager.unit_created.is_connected(_on_unit_created):
		game_manager.unit_created.connect(_on_unit_created)
	if not game_manager.domain_created.is_connected(_on_domain_created):
		game_manager.domain_created.connect(_on_domain_created)

func _step_3_position_domains() -> void:
	if not game_manager:
		return
	
	game_manager.setup_references(hex_grid, star_mapper, self)
	game_manager.clear_all_units()
	game_manager.clear_all_domains()
	
	var available_vertices = _find_spawn_vertices()
	if available_vertices.size() == 0:
		return
	
	var selected_vertices = _select_random_vertices(available_vertices, current_domain_count)
	_prepare_random_colors(current_domain_count)
	_spawn_colored_domains(selected_vertices)

func _step_4_adjust_zoom() -> void:
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
	
	var dot_positions = hex_grid.get_dot_positions()
	if dot_positions.size() > 0:
		var center = Vector2.ZERO
		for pos in dot_positions:
			center += pos
		center /= dot_positions.size()
		camera.global_position = hex_grid.to_global(center)
	
	zoom_mode_active = false
	current_centered_star_id = INVALID_STAR_ID

func _find_spawn_vertices() -> Array:
	if not hex_grid or not star_mapper:
		return []
	
	var dot_positions = hex_grid.get_dot_positions()
	var total_stars = star_mapper.get_star_count()
	var domain_centers = []
	
	var center = Vector2.ZERO
	for pos in dot_positions:
		center += pos
	center /= dot_positions.size()
	
	var star_distances = []
	for i in range(dot_positions.size()):
		var pos = dot_positions[i]
		var distance = center.distance_to(pos)
		star_distances.append({"id": i, "distance": distance, "pos": pos})
	
	star_distances.sort_custom(func(a, b): return a.distance > b.distance)
	var twelve_farthest = star_distances.slice(0, min(12, star_distances.size()))
	
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
	
	for pair in pairs:
		var center_star = _find_common_adjacent_star(pair[0].id, pair[1].id, dot_positions)
		if center_star >= 0 and center_star < total_stars:
			domain_centers.append(center_star)
	
	return domain_centers

func _find_common_adjacent_star(star_a_id: int, star_b_id: int, dot_positions: Array) -> int:
	var max_adjacent_distance = 38.0
	
	var adjacent_to_a = []
	var star_a_pos = dot_positions[star_a_id]
	for i in range(dot_positions.size()):
		if i != star_a_id and star_a_pos.distance_to(dot_positions[i]) <= max_adjacent_distance:
			adjacent_to_a.append(i)
	
	var adjacent_to_b = []
	var star_b_pos = dot_positions[star_b_id]
	for i in range(dot_positions.size()):
		if i != star_b_id and star_b_pos.distance_to(dot_positions[i]) <= max_adjacent_distance:
			adjacent_to_b.append(i)
	
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

func _prepare_random_colors(count: int) -> void:
	# Usar cores dos teams em ordem
	pass

func _spawn_colored_domains(selected_vertices: Array) -> void:
	var spawned_count = 0
	for i in range(selected_vertices.size()):
		var vertex_star_id = selected_vertices[i]
		var domain_color = team_colors[i % team_colors.size()]
		
		var spawn_result = game_manager.spawn_domain_with_unit_colored(vertex_star_id, domain_color)
		
		if spawn_result:
			spawned_count += 1

func _on_unit_created(unit) -> void:
	pass

func _on_domain_created(domain) -> void:
	pass

func _reset_zoom_mode() -> void:
	if zoom_mode_active:
		zoom_mode_active = false
		current_centered_star_id = INVALID_STAR_ID

func _validate_zoom_system() -> bool:
	return star_mapper != null and hex_grid != null and get_viewport().get_camera_2d() != null

func _deactivate_movement_mode() -> void:
	selected_unit = null
	movement_mode_active = false
	valid_movement_stars.clear()
	_clear_star_highlights()

func _highlight_movement_stars(unit_color: Color) -> void:
	_clear_star_highlights()
	
	var dot_positions = hex_grid.get_dot_positions()
	
	for star_id in valid_movement_stars:
		if star_id < dot_positions.size():
			var star_pos = dot_positions[star_id]
			_create_colored_star_highlight(star_pos, unit_color)

func _create_colored_star_highlight(position: Vector2, color: Color) -> void:
	var highlight_node = Node2D.new()
	highlight_node.position = position
	highlight_node.z_index = 60
	highlight_node.visible = true
	
	highlight_node.draw.connect(_draw_colored_star.bind(highlight_node, color))
	
	hex_grid.add_child(highlight_node)
	highlighted_stars.append(highlight_node)
	
	highlight_node.queue_redraw()

func _draw_colored_star(canvas_item: CanvasItem, color: Color) -> void:
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

func _clear_star_highlights() -> void:
	for highlight in highlighted_stars:
		if is_instance_valid(highlight):
			highlight.queue_free()
	highlighted_stars.clear()

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

func _handle_zoom_in() -> void:
	_handle_zoom(true)

func _handle_zoom_out() -> void:
	_handle_zoom(false)

func _handle_zoom(zoom_in: bool) -> void:
	if not _validate_zoom_system():
		return
	
	var camera = get_viewport().get_camera_2d()
	var nearest_star_data = _get_nearest_star_under_cursor(camera)
	if nearest_star_data.star_id == INVALID_STAR_ID:
		return
	
	if _should_center_star(nearest_star_data.star_id):
		_center_star(camera, nearest_star_data)
	else:
		_apply_zoom(camera, nearest_star_data, zoom_in)

func _should_center_star(star_id: int) -> bool:
	return not zoom_mode_active or current_centered_star_id != star_id

func _center_star(camera: Camera2D, star_data: Dictionary) -> void:
	current_centered_star_id = star_data.star_id
	zoom_mode_active = true
	
	camera.global_position = star_data.world_pos
	get_viewport().warp_mouse(star_data.screen_center)

func _apply_zoom(camera: Camera2D, star_data: Dictionary, zoom_in: bool) -> void:
	var current_zoom = camera.zoom.x
	if zoom_in and current_zoom >= MAX_ZOOM:
		return
	elif not zoom_in and current_zoom <= MIN_ZOOM:
		return
	
	var zoom_factor = ZOOM_FACTOR if zoom_in else (1.0 / ZOOM_FACTOR)
	camera.zoom *= zoom_factor
	camera.zoom = camera.zoom.clamp(Vector2(MIN_ZOOM, MIN_ZOOM), Vector2(MAX_ZOOM, MAX_ZOOM))
	
	camera.global_position = star_data.world_pos
	get_viewport().warp_mouse(star_data.screen_center)

func _get_nearest_star_under_cursor(camera: Camera2D) -> Dictionary:
	var mouse_screen = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2.0
	var mouse_offset = mouse_screen - screen_center
	var world_point = camera.global_position + mouse_offset / camera.zoom.x
	
	var star_id = INVALID_STAR_ID
	var star_world_pos = Vector2.ZERO
	
	if star_mapper and hex_grid:
		var hex_grid_pos = hex_grid.to_local(world_point)
		star_id = star_mapper.get_nearest_star_id(hex_grid_pos)
		
		if star_id != INVALID_STAR_ID:
			var star_local_pos = star_mapper.get_star_position(star_id)
			star_world_pos = hex_grid.to_global(star_local_pos)
		else:
			star_world_pos = world_point
	else:
		star_world_pos = world_point
	
	return {
		"star_id": star_id,
		"world_pos": star_world_pos,
		"screen_center": screen_center
	}

## Limpeza
func _exit_tree():
	_clear_star_highlights()
	
	if button_canvas_layer and is_instance_valid(button_canvas_layer):
		button_canvas_layer.queue_free()