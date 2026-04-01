extends Node

# Containers básicos
var world: Node2D
var ui: CanvasLayer
var ui_screen_container: Control 

# Gerentes (Nós)
var ui_manager: Node
var grid_manager: Node2D
var domain_manager: Node2D 
var vagabond_manager: Node2D
var turn_manager: Node

# Objetos de Lógica (RefCounted)
var terrain_manager: Object 
var visibility_manager: Object 
var match_manager: Object 
var input_handler: Object 
var camera_controller: Camera2D

# UI Específica
var game_hud: Control = null

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
	# 1. UI Manager
	ui_manager = Node.new()
	ui_manager.set_script(load("res://src/ui/UIManager.gd"))
	ui_manager.name = "UIManager"
	add_child(ui_manager)
	ui_manager.setup(ui_screen_container)
	
	# 2. Turn Manager
	turn_manager = Node.new()
	turn_manager.set_script(load("res://src/systems/turn/TurnManager.gd"))
	turn_manager.name = "TurnManager"
	add_child(turn_manager)
	
	# 3. Grid e Terreno
	grid_manager = load("res://src/systems/grid/GridManager.gd").new()
	grid_manager.name = "GridManager"
	world.add_child(grid_manager)
	
	terrain_manager = load("res://src/systems/terrain/Terrain.gd").new()
	
	# 4. Domain Manager
	domain_manager = Node2D.new()
	domain_manager.set_script(load("res://src/systems/entities/DomainManager.gd"))
	domain_manager.name = "DomainManager"
	world.add_child(domain_manager)
	
	# 5. Vagabond Manager
	vagabond_manager = Node2D.new()
	vagabond_manager.set_script(load("res://src/systems/entities/VagabondManager.gd"))
	vagabond_manager.name = "VagabondManager"
	world.add_child(vagabond_manager)
	
	# 6. Auxiliares
	match_manager = load("res://src/systems/turn/MatchManager.gd").new(self)
	input_handler = load("res://src/systems/input/InputHandler.gd").new(self)
	visibility_manager = load("res://src/systems/visibility/VisibilityManager.gd").new()

	# 7. Câmera
	camera_controller = Camera2D.new()
	camera_controller.set_script(load("res://src/systems/camera/CameraController.gd"))
	camera_controller.name = "RTSCamera"
	world.add_child(camera_controller)
	camera_controller.make_current()
	
	# 8. Sinais Globais
	if is_instance_valid(Signals):
		_reconnect_signal(Signals.turn_started, _on_global_turn_started)
		_reconnect_signal(Signals.unit_moved, _on_unit_moved)

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
	match_manager.setup_game(player_count)
	_setup_hud()

func _setup_hud() -> void:
	if is_instance_valid(game_hud):
		game_hud.queue_free()
	
	var hud_script = load("res://src/ui/GameHUD.gd")
	if hud_script:
		game_hud = hud_script.new()
		game_hud.name = "GameHUD"
		ui_screen_container.add_child(game_hud)
		
		if game_hud.has_signal("end_turn_requested"):
			game_hud.end_turn_requested.connect(_on_end_turn_requested)

## CORRIGIDO: Parâmetros ajustados para 3 argumentos e erro de indentação resolvido
func _on_global_turn_started(player_id: int, p_color: Color, _round_num: int) -> void:
	await get_tree().process_frame
	_update_game_visibility(true)
	
	# BUSCA DO NOME PARA EVITAR "UNKNOWN"
	var p_name = "PLAYER " + str(player_id + 1)
	if is_instance_valid(turn_manager) and turn_manager.player_colors.size() > player_id:
		p_name = turn_manager.player_colors[player_id]

	# CORREÇÃO: Usando p_color que vem do argumento
	var data = {
		"id": player_id,
		"name": p_name,
		"color": p_color 
	}
	
	ui_manager.change_screen("res://src/ui/PlayerTurnScreen.gd", data)
	
	# Verificação e Reordenamento do HUD
	if not is_instance_valid(game_hud) or game_hud.get_parent() == null:
		_setup_hud()
	
	if game_hud.get_parent() == ui_screen_container:
		ui_screen_container.move_child(game_hud, -1)
	
	# O HUD agora se atualiza via Signals, mas chamamos por segurança se necessário
	if game_hud.has_method("_on_turn_started"):
		game_hud._on_turn_started(player_id, p_color, _round_num)

func _on_unit_moved(_unit: Node2D, _from: Vector2, _to: Vector2) -> void:
	_update_game_visibility.call_deferred(false)

func _on_end_turn_requested() -> void:
	if is_instance_valid(turn_manager):
		print("[Main] Finalizando turno via HUD.")
		if input_handler and input_handler.has_method("_deselect_current"):
			input_handler._deselect_current()
		
		turn_manager.next_turn()

# --- VISIBILIDADE ---

func _update_game_visibility(force_instant: bool = false) -> void:
	if not visibility_manager or not turn_manager or not vagabond_manager: 
		return
		
	var domains = []
	if is_instance_valid(domain_manager):
		# Tenta pegar o dicionário direto ou via método
		if "active_domains" in domain_manager:
			domains = domain_manager.get("active_domains")
		elif domain_manager.has_method("get_all_domains"):
			domains = domain_manager.get_all_domains()
	
	visibility_manager.update_visibility(
		vagabond_manager.active_vagabonds,
		grid_manager,
		turn_manager.current_player_index,
		terrain_manager,
		domains,
		force_instant
	)

# --- ENTRADA ---

func _input(event: InputEvent) -> void:
	if input_handler:
		input_handler.handle_input(event)

func _on_focus_changed(control: Control) -> void:
	if control: 
		control.release_focus()