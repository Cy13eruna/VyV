## V&V Game - Sistema de Instâncias por Jogador
## Nova arquitetura preparada para multiplayer online
## Logs limpos e organizados

extends Node2D

# Preloads das novas classes
const PlayerInstance = preload("res://scripts/systems/player_instance.gd")
const GameServer = preload("res://scripts/systems/game_server.gd")
const SharedGameState = preload("res://scripts/systems/shared_game_state.gd")
const StarMapper = preload("res://scripts/star_mapper.gd")

@onready var hex_grid = $HexGrid

## Sistema principal
var game_server: GameServer
var current_player: PlayerInstance

## Estado do jogo
var map_initialized: bool = false
var game_started: bool = false

## Interface
var next_turn_button: Button
var button_canvas_layer: CanvasLayer

## Sistema de movimento
var selected_unit = null
var movement_mode_active: bool = false
var highlighted_stars = []
var valid_movement_stars = []

## Sistema de zoom
var zoom_mode_active: bool = false
var current_centered_star_id: int = -1
const ZOOM_FACTOR: float = 1.3
const MIN_ZOOM: float = 0.3
const MAX_ZOOM: float = 5.0
const INVALID_STAR_ID: int = -1

func _ready():
	print("V&V: Inicializando sistema com arquitetura por instâncias...")
	
	# Inicializar servidor do jogo
	game_server = GameServer.new()
	
	# Conectar sinais do servidor
	game_server.player_added.connect(_on_player_added)
	game_server.turn_changed.connect(_on_turn_changed)
	game_server.game_state_changed.connect(_on_game_state_changed)
	
	# Inicializar sistema
	_initialize_game()

## Inicializar jogo
func _initialize_game():
	# Obter configuração via console
	var domain_count = _get_domain_count_from_console()
	print("V&V: Configurando jogo para %d jogadores" % domain_count)
	
	# Configurar mapa
	_setup_map(domain_count)
	
	# Aguardar mapa estar pronto
	if hex_grid.is_initialized:
		_continue_setup(domain_count)
	else:
		hex_grid.grid_initialized.connect(_continue_setup.bind(domain_count), CONNECT_ONE_SHOT)

## Configurar mapa baseado na quantidade de jogadores
func _setup_map(player_count: int):
	var map_width = game_server.shared_state.get_map_width_for_domains(player_count)
	var hex_radius = (map_width + 1) / 2
	
	print("V&V: Configurando mapa %dx%d para %d jogadores" % [hex_radius, hex_radius, player_count])
	
	hex_grid.config.set_grid_width(hex_radius)
	hex_grid.config.set_grid_height(hex_radius)
	hex_grid.rebuild_grid()

## Continuar configuração após mapa estar pronto
func _continue_setup(player_count: int):
	if not hex_grid.is_grid_ready():
		await get_tree().create_timer(0.1).timeout
		_continue_setup(player_count)
		return
	
	# Configurar estado compartilhado
	var star_mapper = StarMapper.new()
	star_mapper.map_stars(hex_grid.get_dot_positions())
	game_server.setup_shared_state(hex_grid, star_mapper, self)
	
	# Adicionar jogadores
	_add_players(player_count)
	
	# Posicionar domínios iniciais
	_spawn_initial_domains()
	
	# Configurar interface
	_setup_interface()
	
	# Iniciar jogo
	game_server.start_game()
	map_initialized = true
	game_started = true
	
	print("V&V: Sistema inicializado com sucesso!")

## Adicionar jogadores ao servidor
func _add_players(count: int):
	var player_names = ["Azul", "Laranja", "Vermelho", "Roxo", "Amarelo", "Ciano"]
	
	for i in range(count):
		var name = player_names[i] if i < player_names.size() else "Jogador " + str(i + 1)
		game_server.add_player(name)

## Spawnar domínios iniciais para todos os jogadores
func _spawn_initial_domains():
	var spawn_positions = _find_spawn_positions()
	
	for i in range(game_server.players.size()):
		if i < spawn_positions.size():
			var player = game_server.players[i]
			var star_id = spawn_positions[i]
			
			# Criar domínio
			var domain = player.create_domain(star_id)
			if domain:
				# Criar unidade no centro do domínio
				var unit = player.create_unit(star_id)
				if unit:
					unit.create_visual(self)
					print("V&V: Jogador %s posicionado na estrela %d" % [player.player_name, star_id])

## Encontrar posições de spawn estratégicas
func _find_spawn_positions() -> Array:
	var farthest_stars = game_server.shared_state.find_farthest_stars(12)
	var positions = []
	
	# Selecionar posições bem distribuídas
	var step = max(1, farthest_stars.size() / game_server.players.size())
	for i in range(game_server.players.size()):
		var index = i * step
		if index < farthest_stars.size():
			positions.append(farthest_stars[index].id)
	
	return positions

## Configurar interface do usuário
func _setup_interface():
	# Criar botão de próximo turno
	button_canvas_layer = CanvasLayer.new()
	button_canvas_layer.layer = 100
	add_child(button_canvas_layer)
	
	next_turn_button = Button.new()
	next_turn_button.text = "PRÓXIMO TURNO"
	next_turn_button.size = Vector2(140, 40)
	next_turn_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	next_turn_button.position = Vector2(-150, 10)
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	
	button_canvas_layer.add_child(next_turn_button)
	_update_button_appearance()

## Atualizar aparência do botão baseado no jogador atual
func _update_button_appearance():
	if not next_turn_button or not game_server:
		return
	
	current_player = game_server.get_current_player()
	if not current_player:
		return
	
	next_turn_button.modulate = current_player.team_color
	next_turn_button.text = "TURNO: " + current_player.player_name

## Input handling
func _unhandled_input(event: InputEvent):
	if not map_initialized or not game_started:
		return
	
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_handle_left_click(event.global_position)
			MOUSE_BUTTON_WHEEL_UP:
				_handle_zoom_in()
			MOUSE_BUTTON_WHEEL_DOWN:
				_handle_zoom_out()

## Manipular clique esquerdo
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

## Converter posição da tela para coordenadas hex
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

## Tentar mover unidade selecionada
func _try_move_unit(hex_pos: Vector2):
	var star_id = _get_star_at_position(hex_pos)
	
	if star_id >= 0 and star_id in valid_movement_stars:
		if game_server.move_unit(selected_unit, star_id):
			print("V&V: Unidade movida para estrela %d" % star_id)
			_update_movement_options()
		else:
			print("V&V: Movimento inválido")
	else:
		_deactivate_movement_mode()

## Manipular seleção de unidade
func _handle_unit_selection(unit):
	# Verificar se é unidade do jogador atual
	if not current_player or not unit in current_player.units:
		print("V&V: Não é sua unidade!")
		return
	
	if selected_unit == unit:
		_deactivate_movement_mode()
	else:
		_activate_movement_mode(unit)

## Ativar modo de movimento
func _activate_movement_mode(unit):
	selected_unit = unit
	movement_mode_active = true
	
	_update_movement_options()
	print("V&V: Unidade selecionada - modo movimento ativo")

## Atualizar opções de movimento
func _update_movement_options():
	if not selected_unit:
		return
	
	var current_star = selected_unit.get_current_star_id()
	var adjacent_stars = game_server.shared_state.get_adjacent_stars(current_star)
	var all_units = game_server.get_all_units()
	
	# Filtrar estrelas ocupadas
	valid_movement_stars = []
	for star_id in adjacent_stars:
		if not game_server.shared_state.is_star_occupied(star_id, all_units):
			if game_server.shared_state.is_movement_valid(current_star, star_id):
				valid_movement_stars.append(star_id)
	
	_highlight_movement_stars()

## Destacar estrelas de movimento
func _highlight_movement_stars():
	_clear_highlights()
	
	var dot_positions = hex_grid.get_dot_positions()
	for star_id in valid_movement_stars:
		if star_id < dot_positions.size():
			_create_star_highlight(dot_positions[star_id], current_player.team_color)

## Criar destaque de estrela
func _create_star_highlight(position: Vector2, color: Color):
	var highlight = Node2D.new()
	highlight.position = position
	highlight.z_index = 60
	highlight.draw.connect(_draw_star_highlight.bind(highlight, color))
	
	hex_grid.add_child(highlight)
	highlighted_stars.append(highlight)
	highlight.queue_redraw()

## Desenhar destaque de estrela
func _draw_star_highlight(canvas_item: CanvasItem, color: Color):
	var points = PackedVector2Array()
	for i in range(12):
		var angle = deg_to_rad(30.0 * i)
		var radius = 6.0 if i % 2 == 0 else 3.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	canvas_item.draw_colored_polygon(points, color)

## Limpar destaques
func _clear_highlights():
	for highlight in highlighted_stars:
		if is_instance_valid(highlight):
			highlight.queue_free()
	highlighted_stars.clear()

## Desativar modo de movimento
func _deactivate_movement_mode():
	selected_unit = null
	movement_mode_active = false
	valid_movement_stars.clear()
	_clear_highlights()

## Obter unidade na posição
func _get_unit_at_position(hex_pos: Vector2):
	var visible_units = game_server.get_visible_units_for_current_player()
	
	for unit in visible_units:
		if unit.is_positioned():
			var unit_pos = hex_grid.to_local(unit.get_world_position())
			var distance = hex_pos.distance_to(unit_pos)
			if distance <= 20.0:  # Tolerância de clique
				return unit
	
	return null

## Obter estrela na posição
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

## Sistema de zoom simplificado
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

## Obter quantidade de domínios via console
func _get_domain_count_from_console() -> int:
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--domain-count="):
			return clamp(int(arg.split("=")[1]), 2, 6)
	return 3  # Padrão

## Callbacks do servidor
func _on_player_added(player_id: int):
	print("V&V: Jogador %d adicionado" % player_id)

func _on_turn_changed(player_id: int):
	current_player = game_server.get_player(player_id)
	_update_button_appearance()
	_deactivate_movement_mode()
	print("V&V: Turno do jogador %s" % current_player.player_name)

func _on_game_state_changed(new_state: String):
	print("V&V: Estado do jogo: %s" % new_state)

## Callback do botão de próximo turno
func _on_next_turn_pressed():
	game_server.next_turn()

## Limpeza
func _exit_tree():
	if game_server:
		game_server.cleanup()
	
	_clear_highlights()
	
	if button_canvas_layer and is_instance_valid(button_canvas_layer):
		button_canvas_layer.queue_free()