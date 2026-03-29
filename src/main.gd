# res://src/Main.gd
extends Node

# Containers básicos
var world: Node2D
var ui: CanvasLayer
var ui_screen_container: Control 

# Gerentes
var ui_manager: Node
var grid_manager: Node2D
var domain_manager: Node2D 
var vagabond_manager: Node2D
var turn_manager: Node
var terrain_manager: RefCounted 
var visibility_manager: RefCounted 
var match_manager: RefCounted
var input_handler: RefCounted
var camera_controller: Camera2D

# UI Específica
var game_hud: Control = null

func _ready() -> void:
	randomize()
	# Fundo mantido como solicitado
	RenderingServer.set_default_clear_color(Color.WHITE) 
	
	_create_hierarchy()
	_setup_managers()
	
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	_show_initial_menu()

# --- INICIALIZAÇÃO ---

func _create_hierarchy() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	
	ui = CanvasLayer.new()
	ui.name = "UI"
	ui.layer = 1
	add_child(ui)
	
	ui_screen_container = Control.new()
	ui_screen_container.name = "UIScreenContainer"
	ui_screen_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_screen_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ui_screen_container)

func _setup_managers() -> void:
	# UI
	ui_manager = Node.new()
	ui_manager.set_script(load("res://src/ui/UIManager.gd"))
	ui_manager.name = "UIManager"
	add_child(ui_manager)
	ui_manager.setup(ui_screen_container)
	
	# Turnos e Coordenação
	turn_manager = Node.new()
	turn_manager.set_script(load("res://src/systems/turn/TurnManager.gd"))
	turn_manager.name = "TurnManager"
	add_child(turn_manager)
	turn_manager.turn_started.connect(_on_turn_started)
	
	match_manager = load("res://src/systems/turn/MatchManager.gd").new(self)
	input_handler = load("res://src/systems/input/InputHandler.gd").new(self)
	
	# Grid e Terreno
	grid_manager = load("res://src/systems/grid/GridManager.gd").new()
	grid_manager.name = "GridManager"
	world.add_child(grid_manager)
	
	terrain_manager = load("res://src/systems/terrain/Terrain.gd").new()
	
	# Domain Manager
	domain_manager = Node2D.new()
	domain_manager.set_script(load("res://src/systems/entities/DomainManager.gd"))
	domain_manager.name = "DomainManager"
	world.add_child(domain_manager)
	
	# Entidades e Visibilidade
	vagabond_manager = Node2D.new()
	vagabond_manager.set_script(load("res://src/systems/entities/VagabondManager.gd"))
	vagabond_manager.name = "VagabondManager"
	world.add_child(vagabond_manager)
	
	visibility_manager = load("res://src/systems/visibility/VisibilityManager.gd").new()

	# Câmera
	camera_controller = Camera2D.new()
	camera_controller.set_script(load("res://src/systems/camera/CameraController.gd"))
	camera_controller.name = "RTSCamera"
	world.add_child(camera_controller)
	camera_controller.make_current()

# --- FLUXO DE JOGO ---

func _show_initial_menu() -> void:
	var menu = ui_manager.change_screen("res://src/ui/MatchMakingMenu.gd", {})
	if menu and menu.has_signal("match_requested"):
		menu.match_requested.connect(_on_match_requested)

func _on_match_requested(player_count: int) -> void:
	match_manager.setup_game(player_count)
	_setup_hud()

func _setup_hud() -> void:
	if not game_hud:
		var hud_scene = load("res://src/ui/GameHUD.gd")
		if hud_scene:
			game_hud = hud_scene.new()
			ui.add_child(game_hud)
			if game_hud.has_signal("end_turn_requested"):
				game_hud.end_turn_requested.connect(_on_end_turn_requested)

func _on_turn_started(player_data: Dictionary) -> void:
	grid_manager._deselect_all()
	vagabond_manager.restore_all_units_ap()
	
	await get_tree().process_frame
	
	_update_game_visibility(true)
	
	ui_manager.change_screen("res://src/ui/PlayerTurnScreen.gd", player_data)

func _on_end_turn_requested() -> void:
	turn_manager.next_turn()

# --- INPUT E VISIBILIDADE ---

func _input(event: InputEvent) -> void:
	if input_handler:
		input_handler.handle_input(event)

func _update_game_visibility(force_instant: bool = false) -> void:
	if visibility_manager and turn_manager:
		var domains = []
		
		# Verificação segura da lista de domínios
		if is_instance_valid(domain_manager):
			var d_list = domain_manager.get("active_domains")
			if d_list is Array:
				domains = d_list
			
		visibility_manager.update_visibility(
			vagabond_manager.active_vagabonds,
			grid_manager,
			turn_manager.current_player_index,
			terrain_manager,
			domains,         # 5º argumento: Array esperado
			force_instant    # 6º argumento: Booleano de força
		)

func _on_focus_changed(control: Control) -> void:
	if control: 
		control.release_focus()