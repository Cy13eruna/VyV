# res://src/Main.gd
extends Node

# --- CONTAINERS ---
var world: Node2D
var ui: CanvasLayer
var ui_screen_container: Control 

# --- GERENTES (NÓS) ---
var ui_manager: Node
var grid_manager: Node2D
var domain_manager: Node2D 
var vagabond_manager: Node2D
var turn_manager: Node
var action_controller: Node

# --- UI ESPECÍFICA ---
var action_popup: CanvasLayer
var game_hud: Control = null

# --- OBJETOS DE LÓGICA (REFCOUNTED) ---
var terrain_manager: Object 
var visibility_manager: Object 
var match_manager: Object 
var input_handler: Object 
var camera_controller: Camera2D

func _ready() -> void:
	randomize()
	RenderingServer.set_default_clear_color(Color.BLACK) 
	
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
	# 1. Base UI e Turnos
	ui_manager = Node.new()
	ui_manager.set_script(load("res://src/ui/UIManager.gd"))
	ui_manager.name = "UIManager"
	add_child(ui_manager)
	ui_manager.setup(ui_screen_container)
	
	turn_manager = Node.new()
	turn_manager.set_script(load("res://src/systems/turn/TurnManager.gd"))
	turn_manager.name = "TurnManager"
	add_child(turn_manager)
	
	# 2. SISTEMA DE AÇÕES (Crítico: Inicializar antes de criar unidades ou inputs)
	_setup_action_system()
	
	# 3. Grid e Terreno
	grid_manager = load("res://src/systems/grid/GridManager.gd").new()
	grid_manager.name = "GridManager"
	grid_manager.add_to_group("grid_manager")
	world.add_child(grid_manager)
	terrain_manager = load("res://src/systems/terrain/Terrain.gd").new()
	
	# 4. Entidades
	domain_manager = Node2D.new()
	domain_manager.set_script(load("res://src/systems/entities/DomainManager.gd"))
	domain_manager.name = "DomainManager"
	domain_manager.add_to_group("domain_manager")
	world.add_child(domain_manager)
	
	vagabond_manager = Node2D.new()
	vagabond_manager.set_script(load("res://src/systems/entities/VagabondManager.gd"))
	vagabond_manager.name = "VagabondManager"
	vagabond_manager.add_to_group("vagabond_manager")
	world.add_child(vagabond_manager)
	
	# 5. Lógica e Input (Últimos a serem criados)
	match_manager = load("res://src/systems/turn/MatchManager.gd").new(self)
	input_handler = load("res://src/systems/input/InputHandler.gd").new(self)
	visibility_manager = load("res://src/systems/visibility/VisibilityManager.gd").new()

	# 6. Câmera
	camera_controller = Camera2D.new()
	camera_controller.set_script(load("res://src/systems/camera/CameraController.gd"))
	camera_controller.name = "RTSCamera"
	world.add_child(camera_controller)
	camera_controller.make_current()

	if is_instance_valid(Signals):
		_reconnect_signal(Signals.turn_started, _on_global_turn_started)
		_reconnect_signal(Signals.unit_moved, _on_unit_moved)

func _setup_action_system() -> void:
	# Instancia o PopUp
	var popup_script = load("res://src/ui/ActionPopUp.gd")
	if popup_script:
		action_popup = popup_script.new()
		action_popup.name = "ActionPopUp"
		ui.add_child(action_popup)
		action_popup.cancelled.connect(_on_action_popup_closed)
		if action_popup.has_signal("option_selected"):
			action_popup.option_selected.connect(func(_id): _on_action_popup_closed())

	# Instancia o Controller
	var controller_script = load("res://src/systems/actions/ActionController.gd")
	if controller_script:
		action_controller = Node.new()
		action_controller.set_script(controller_script)
		action_controller.name = "ActionController"
		add_child(action_controller)
		
		# Inicialização FORÇADA: Conecta sinais imediatamente antes do primeiro frame
		if action_controller.has_method("initialize"):
			action_controller.initialize(action_popup)

func _reconnect_signal(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)
	sig.connect(callable)

# --- FLUXO DE JOGO ---

func _show_initial_menu() -> void:
	var menu = ui_manager.change_screen("res://src/ui/MatchMakingMenu.gd", {})
	if menu and menu.has_signal("match_requested"):
		menu.match_requested.connect(_on_match_requested)

func _on_match_requested(player_count: int) -> void:
	if is_instance_valid(match_manager):
		match_manager.setup_game(player_count)

func _setup_hud() -> void:
	if is_instance_valid(game_hud):
		if game_hud.is_inside_tree(): return 
		game_hud.queue_free()
	
	var hud_script = load("res://src/ui/GameHUD.gd")
	if hud_script:
		game_hud = hud_script.new()
		game_hud.name = "GameHUD"
		ui_screen_container.add_child(game_hud)
		if game_hud.has_signal("end_turn_requested"):
			_reconnect_signal(game_hud.end_turn_requested, _on_end_turn_requested)

func _on_global_turn_started(player_id: int, p_color: Color, _round_num: int) -> void:
	_update_game_visibility(true)
	
	if is_instance_valid(camera_controller) and is_instance_valid(turn_manager):
		var target_pos = turn_manager.get_current_start_pos()
		camera_controller.global_position = target_pos

	var p_name = turn_manager.get_player_name_by_id(player_id) if is_instance_valid(turn_manager) else "PLAYER " + str(player_id + 1)
	var data = { "id": player_id, "name": p_name, "color": p_color }
	ui_manager.change_screen("res://src/ui/PlayerTurnScreen.gd", data)
	
	_setup_hud()
	
	if is_instance_valid(game_hud) and game_hud.get_parent() == ui_screen_container:
		ui_screen_container.move_child(game_hud, 0) 
		if game_hud.has_method("_on_turn_started"):
			game_hud._on_turn_started(player_id, p_color, _round_num)

func _on_unit_moved(_unit: Node2D, _from: Vector2, _to: Vector2) -> void:
	_update_game_visibility.call_deferred(false)

func _on_end_turn_requested() -> void:
	if is_instance_valid(turn_manager):
		if input_handler and input_handler.has_method("_deselect_all"):
			input_handler._deselect_all()
		if is_instance_valid(action_popup):
			action_popup.close()
		turn_manager.next_turn()

func _on_action_popup_closed() -> void:
	if input_handler and "is_disabled" in input_handler:
		input_handler.set("is_disabled", false)

# --- VISIBILIDADE ---

func _update_game_visibility(force_instant: bool = false) -> void:
	if not (visibility_manager and turn_manager and vagabond_manager): return
	
	var domains = []
	if is_instance_valid(domain_manager):
		domains = domain_manager.get("active_domains") if "active_domains" in domain_manager else []
	
	visibility_manager.update_visibility(
		vagabond_manager.active_vagabonds,
		grid_manager,
		turn_manager.get_current_id(),
		terrain_manager,
		domains,
		force_instant
	)

# --- ENTRADA ---

func _input(event: InputEvent) -> void:
	# CORREÇÃO: Só bloqueamos o input se o popup já estiver visível.
	# No primeiro clique, o popup ainda está INVISÍVEL, então deixamos o evento passar
	# para que o InputHandler selecione a unidade e dispare o sinal de abertura.
	if is_instance_valid(action_popup) and action_popup.visible:
		# Se for um clique de mouse para fechar, podemos tratar aqui, 
		# mas não enviamos para o mapa.
		return

	if input_handler:
		input_handler.handle_input(event)

func _on_focus_changed(control: Control) -> void:
	if control: control.release_focus()