## V&V Game - Sistema Refatorado com Arquitetura Modular
## Arquivo principal drasticamente simplificado usando GameController
##
## ✅ REFATORAÇÃO COMPLETA REALIZADA!
## 🎯 Responsabilidade única: Inicialização e orquestração de alto nível
## 📋 Sistemas extraídos: TurnManager, InputHandler, UIManager, GameController
## 🚀 Arquitetura modular seguindo princípios SOLID

extends Node2D

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")
const ObjectFactories = preload("res://scripts/core/object_factories.gd")
const ResourceCleanup = preload("res://scripts/core/resource_cleanup.gd")

# Importar sistemas principais
const StarMapper = preload("res://scripts/entities/star_mapper.gd")
const GameManager = preload("res://scripts/game/game_manager.gd")
const GameController = preload("res://scripts/game/managers/game_controller.gd")

## Referências dos sistemas principais
@onready var hex_grid = $HexGrid
var star_mapper: StarMapper
var game_manager: GameManager
var game_controller: GameController

## Sistema de mapa dinâmico
var domain_count_to_map_width = {
	6: 13,
	5: 11,
	4: 9,
	3: 7,
	2: 5
}
var current_domain_count: int = 6
var map_initialized: bool = false

## Cores disponíveis para domínios/teams
var team_colors = [
	Color(0, 0, 1),      # Azul RGB
	Color(1, 0.5, 0),    # Laranja
	Color(1, 0, 0),      # Vermelho RGB
	Color(0.5, 0, 1),    # Roxo
	Color(1, 1, 0),      # Amarelo
	Color(0, 1, 1)       # Ciano
]

func _ready() -> void:
	Logger.info("Inicializando sistema refatorado com GameController...", "MainGame")
	
	# Inicializar sistema de cleanup
	ResourceCleanup.initialize()
	
	# Inicializar ObjectPool primeiro
	ObjectFactories.setup_object_pools()
	
	# Inicializar componentes
	_initialize_core_systems()
	
	# Configurar mapa baseado em argumentos de console
	_step_0_console_input()
	
	# Configurar cleanup automático no exit
	get_tree().auto_accept_quit = false
	get_tree().quit_request.connect(_on_quit_request)

## Inicializar sistemas principais
func _initialize_core_systems() -> void:
	if not star_mapper:
		star_mapper = StarMapper.new()
	if not game_manager:
		game_manager = GameManager.new()
	if not game_controller:
		game_controller = GameController.new()
	
	Logger.debug("Sistemas principais inicializados", "MainGame")

## Configurar sistema completo após inicialização do mapa
func _setup_complete_system() -> void:
	# Aguardar um frame para garantir que tudo está pronto
	await get_tree().process_frame
	
	# Inicializar GameController com todas as referências
	game_controller.initialize(self, hex_grid, star_mapper, game_manager)
	
	# Configurar sistema de turnos
	var all_domains = game_manager.get_all_domains()
	var all_units = game_manager.get_all_units()
	game_controller.setup_turn_system(all_units, all_domains)
	
	# Aguardar outro frame para interface estar pronta
	await get_tree().process_frame
	
	# Iniciar jogo
	game_controller.start_game()
	map_initialized = true
	
	Logger.info("Sistema completo configurado e jogo iniciado!", "MainGame")

## Processar input através do GameController
func _unhandled_input(event: InputEvent) -> void:
	if not map_initialized or not game_controller:
		return
	
	if game_controller.process_input(event):
		get_viewport().set_input_as_handled()

## === SISTEMA DE CRIAÇÃO DE MAPA (MANTIDO) ===

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
	
	_setup_complete_system()

func _step_2_map_stars() -> void:
	if not hex_grid or not hex_grid.is_grid_ready():
		return
	
	var dot_positions = hex_grid.get_dot_positions()
	star_mapper.map_stars(dot_positions)
	
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

## === FUNÇÕES DE SPAWN (MANTIDAS) ===

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

func _spawn_colored_domains(selected_vertices: Array) -> void:
	var spawned_count = 0
	for i in range(selected_vertices.size()):
		var vertex_star_id = selected_vertices[i]
		var domain_color = team_colors[i % team_colors.size()]
		
		var spawn_result = game_manager.spawn_domain_with_unit_colored(vertex_star_id, domain_color)
		
		if spawn_result:
			spawned_count += 1

## Callbacks dos sistemas (simplificados)
func _on_unit_created(unit) -> void:
	Logger.debug("Unidade criada via callback", "MainGame")

func _on_domain_created(domain) -> void:
	Logger.debug("Domínio criado via callback", "MainGame")

## Callback para quit request
func _on_quit_request() -> void:
	Logger.info("Quit request recebido, executando cleanup...", "MainGame")
	
	# Cleanup completo de recursos
	ResourceCleanup.cleanup_all_resources()
	
	# Aguardar frames para processamento
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Aceitar quit após cleanup
	get_tree().quit()

## Limpeza
func _exit_tree():
	Logger.info("MainGame _exit_tree chamado", "MainGame")
	
	if game_controller:
		game_controller.cleanup()
	
	# Cleanup de emergência
	ResourceCleanup.emergency_cleanup()
	
	Logger.info("MainGame limpo", "MainGame")