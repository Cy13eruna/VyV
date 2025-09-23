## V&V Game - Versão Simplificada e Funcional
## Console ultra-limpo, sem erros de parsing

extends Node2D

@onready var hex_grid = $HexGrid

## Sistema básico
var players = []
var current_player_index = 0
var current_turn = 1

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
	
	# Configurar mapa
	_setup_map(domain_count)
	
	# Configurar jogadores
	_setup_players(domain_count)
	
	# Configurar interface
	_setup_interface()
	
	map_initialized = true
	game_started = true
	
	print("V&V: Sistema pronto!")

func _setup_map(player_count: int):
	var map_sizes = {6: 13, 5: 11, 4: 9, 3: 7, 2: 5}
	var map_width = map_sizes.get(player_count, 7)
	var hex_radius = (map_width + 1) / 2
	
	hex_grid.config.set_grid_width(hex_radius)
	hex_grid.config.set_grid_height(hex_radius)
	hex_grid.rebuild_grid()

func _setup_players(count: int):
	var colors = [
		Color(0, 0, 1),      # Azul
		Color(1, 0.5, 0),    # Laranja
		Color(1, 0, 0),      # Vermelho
		Color(0.5, 0, 1),    # Roxo
		Color(1, 1, 0),      # Amarelo
		Color(0, 1, 1)       # Ciano
	]
	var names = ["Azul", "Laranja", "Vermelho", "Roxo", "Amarelo", "Ciano"]
	
	for i in range(count):
		var player = {
			"id": i + 1,
			"name": names[i] if i < names.size() else "Jogador " + str(i + 1),
			"color": colors[i] if i < colors.size() else Color.WHITE,
			"units": [],
			"domains": []
		}
		players.append(player)

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

func _update_button_appearance():
	if not next_turn_button or players.size() == 0:
		return
	
	var current_player = players[current_player_index]
	next_turn_button.modulate = current_player.color
	next_turn_button.text = "TURNO: " + current_player.name

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

func _handle_left_click(global_pos: Vector2):
	# Implementação básica de clique
	pass

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

func _get_domain_count_from_console() -> int:
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--domain-count="):
			return clamp(int(arg.split("=")[1]), 2, 6)
	return 3  # Padrão

func _on_next_turn_pressed():
	current_player_index = (current_player_index + 1) % players.size()
	if current_player_index == 0:
		current_turn += 1
	
	_update_button_appearance()

func _exit_tree():
	if button_canvas_layer and is_instance_valid(button_canvas_layer):
		button_canvas_layer.queue_free()