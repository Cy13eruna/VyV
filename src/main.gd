# res://src/main.gd
extends Node

# Containers básicos
var world: Node2D
var ui: CanvasLayer

# Gerentes
var ui_manager: Node
var grid_manager: Node2D
var vagabond_manager: Node2D
var turn_manager: Node
var camera_controller: Camera2D

func _ready() -> void:
	_create_hierarchy()
	_setup_managers()
	
	var menu_path = "res://src/ui/MatchMakingMenu.gd"
	# Mudamos para o menu inicial
	var menu = ui_manager.change_screen(menu_path, {})
	
	if menu and menu.has_signal("match_requested"):
		menu.match_requested.connect(_on_match_requested)

func _create_hierarchy() -> void:
	# World centraliza as coordenadas. 
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	
	ui = CanvasLayer.new()
	ui.name = "UI"
	# IMPORTANTE: Garantimos que a UI não bloqueie o mouse no mundo por padrão
	ui.layer = 1
	add_child(ui)

func _setup_managers() -> void:
	# --- UI Manager ---
	var ui_script = load("res://src/ui/UIManager.gd")
	if ui_script:
		ui_manager = Node.new()
		ui_manager.set_script(ui_script)
		ui_manager.name = "UIManager"
		add_child(ui_manager)
		ui_manager.setup(ui)
	
	# --- Turn Manager ---
	var turn_script = load("res://src/systems/turn/TurnManager.gd")
	if turn_script:
		turn_manager = Node.new()
		turn_manager.set_script(turn_script)
		turn_manager.name = "TurnManager"
		add_child(turn_manager)
		turn_manager.turn_started.connect(_on_turn_started)
	
	# --- Grid Manager ---
	var grid_script = load("res://src/systems/grid/GridManager.gd")
	if grid_script:
		grid_manager = grid_script.new()
		grid_manager.name = "GridManager"
		world.add_child(grid_manager)
	
	# --- Vagabond Manager ---
	var vagabond_mgr_script = load("res://src/systems/entities/VagabondManager.gd")
	if vagabond_mgr_script:
		vagabond_manager = Node2D.new()
		vagabond_manager.set_script(vagabond_mgr_script)
		vagabond_manager.name = "VagabondManager"
		world.add_child(vagabond_manager)
		vagabond_manager.position = Vector2.ZERO 
	
	# --- RTS Camera ---
	var cam_script = load("res://src/systems/camera/CameraController.gd")
	if cam_script:
		camera_controller = Camera2D.new()
		camera_controller.set_script(cam_script)
		camera_controller.name = "RTSCamera"
		world.add_child(camera_controller)
		camera_controller.make_current()

func _on_match_requested(player_count: int) -> void:
	# Ajuste de raio para garantir que o mapa seja grande o suficiente
	var options_map = {2: 8, 3: 10, 4: 12, 6: 14}
	var radius = options_map.get(player_count, 10)
	
	print("Main: Iniciando partida para ", player_count, " jogadores.")
	
	if grid_manager: 
		grid_manager.setup_map(radius)
	
	if turn_manager: 
		turn_manager.setup(player_count)
	
	# Aguarda o Grid preencher o dicionário de nodes no GridData
	await get_tree().process_frame
	
	if vagabond_manager: 
		vagabond_manager.spawn_players(player_count, turn_manager, radius)

func _on_turn_started(player_data: Dictionary) -> void:
	if grid_manager: 
		grid_manager._deselect_all()
	# Atualiza a UI para o turno atual
	ui_manager.change_screen("res://src/ui/PlayerTurnScreen.gd", player_data)

func _unhandled_input(event: InputEvent) -> void:
	# Detecta clique do mouse
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			
			# OBTENÇÃO DA POSIÇÃO GLOBAL REAL:
			# get_global_mouse_position() leva em conta a Camera2D ativa automaticamente
			var global_click = world.get_global_mouse_position()
			
			# Verificamos se o clique não foi consumido por algum botão da UI
			# (Se você clicar num botão de 'Passar Turno', o jogo não deve tentar mover o boneco)
			if grid_manager and vagabond_manager:
				grid_manager.handle_click(global_click, vagabond_manager)
				
	# Atalho para passar o turno (Debug)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if turn_manager: 
				turn_manager.next_turn()