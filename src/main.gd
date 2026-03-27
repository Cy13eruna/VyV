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

# Referência ao HUD persistente
var game_hud: Control = null

func _ready() -> void:
	_create_hierarchy()
	_setup_managers()
	
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	var menu_path = "res://src/ui/MatchMakingMenu.gd"
	var menu = ui_manager.change_screen(menu_path, {})
	
	if menu and menu.has_signal("match_requested"):
		menu.match_requested.connect(_on_match_requested)

func _create_hierarchy() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	
	ui = CanvasLayer.new()
	ui.name = "UI"
	ui.layer = 1
	add_child(ui)

func _setup_managers() -> void:
	var ui_script = load("res://src/ui/UIManager.gd")
	if ui_script:
		ui_manager = Node.new()
		ui_manager.set_script(ui_script)
		ui_manager.name = "UIManager"
		add_child(ui_manager)
		ui_manager.setup(ui)
	
	var turn_script = load("res://src/systems/turn/TurnManager.gd")
	if turn_script:
		turn_manager = Node.new()
		turn_manager.set_script(turn_script)
		turn_manager.name = "TurnManager"
		add_child(turn_manager)
		turn_manager.turn_started.connect(_on_turn_started)
	
	var grid_script = load("res://src/systems/grid/GridManager.gd")
	if grid_script:
		grid_manager = grid_script.new()
		grid_manager.name = "GridManager"
		world.add_child(grid_manager)
	
	var vagabond_mgr_script = load("res://src/systems/entities/VagabondManager.gd")
	if vagabond_mgr_script:
		vagabond_manager = Node2D.new()
		vagabond_manager.set_script(vagabond_mgr_script)
		vagabond_manager.name = "VagabondManager"
		world.add_child(vagabond_manager)
	
	var cam_script = load("res://src/systems/camera/CameraController.gd")
	if cam_script:
		camera_controller = Camera2D.new()
		camera_controller.set_script(cam_script)
		camera_controller.name = "RTSCamera"
		world.add_child(camera_controller)
		camera_controller.make_current()

func _on_match_requested(player_count: int) -> void:
	var options_map = {2: 8, 3: 10, 4: 12, 6: 14}
	var radius = options_map.get(player_count, 10)
	
	if grid_manager: grid_manager.setup_map(radius)
	if turn_manager: turn_manager.setup(player_count)
	
	await get_tree().process_frame
	
	if vagabond_manager: 
		vagabond_manager.spawn_players(player_count, turn_manager, radius)
	
	# --- SOLUÇÃO: Instanciar o HUD de forma persistente ---
	# Criamos o HUD manualmente e adicionamos à UI fora do UIManager
	var hud_script = load("res://src/ui/GameHUD.gd")
	if hud_script:
		game_hud = hud_script.new()
		ui.add_child(game_hud)
		if game_hud.has_signal("end_turn_requested"):
			game_hud.end_turn_requested.connect(_on_end_turn_requested)

func _on_turn_started(player_data: Dictionary) -> void:
	if grid_manager: 
		grid_manager._clear_selection()
		
	# Agora o UIManager fica livre para gerenciar apenas o anúncio de turno
	# Sem remover o game_hud que adicionamos via add_child() direto
	ui_manager.change_screen("res://src/ui/PlayerTurnScreen.gd", player_data)

func _on_end_turn_requested() -> void:
	if turn_manager:
		print("Main: Fim de turno solicitado pela UI.")
		turn_manager.next_turn()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var global_click = world.get_global_mouse_position()
			
			if grid_manager and vagabond_manager and turn_manager:
				grid_manager.handle_click(
					global_click, 
					vagabond_manager.active_vagabonds, 
					turn_manager.current_player_index
				)
	
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()

func _on_focus_changed(control: Control) -> void:
	if control:
		control.release_focus()