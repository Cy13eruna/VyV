# res://src/main.gd
extends Node

# Containers básicos
var world: Node2D
var ui: CanvasLayer
var ui_screen_container: Control 

# Gerentes
var ui_manager: Node
var grid_manager: Node2D
var vagabond_manager: Node2D
var turn_manager: Node
var visibility_manager: RefCounted 
var camera_controller: Camera2D

# Referência ao HUD persistente
var game_hud: Control = null

func _ready() -> void:
	randomize()
	RenderingServer.set_default_clear_color(Color.WHITE)
	
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
	
	ui_screen_container = Control.new()
	ui_screen_container.name = "UIScreenContainer"
	ui_screen_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_screen_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ui_screen_container)

func _setup_managers() -> void:
	var ui_script = load("res://src/ui/UIManager.gd")
	if ui_script:
		ui_manager = Node.new()
		ui_manager.set_script(ui_script)
		ui_manager.name = "UIManager"
		add_child(ui_manager)
		ui_manager.setup(ui_screen_container)
	
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
	
	var vis_script = load("res://src/systems/visibility/VisibilityManager.gd")
	if vis_script:
		visibility_manager = vis_script.new()

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
	
	_update_fog(true)
	
	if not game_hud:
		var hud_script = load("res://src/ui/GameHUD.gd")
		if hud_script:
			game_hud = hud_script.new()
			ui.add_child(game_hud)
			if game_hud.has_signal("end_turn_requested"):
				game_hud.end_turn_requested.connect(_on_end_turn_requested)

func _on_turn_started(player_data: Dictionary) -> void:
	if grid_manager: 
		grid_manager._deselect_all()
	
	if vagabond_manager:
		vagabond_manager.restore_all_units_ap()
		
	# Pequeno aguardo para garantir que o motor processou as posições do novo turno
	await get_tree().process_frame
	
	_update_fog(true)
		
	ui_manager.change_screen("res://src/ui/PlayerTurnScreen.gd", player_data)

func _on_end_turn_requested() -> void:
	if turn_manager:
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
				# Durante movimento, a neblina atualiza suavemente
				_update_fog.call_deferred(false)

# --- LÓGICA DE VISIBILIDADE CENTRALIZADA ---

func _update_fog(force_instant: bool = false) -> void:
	if visibility_manager and grid_manager and vagabond_manager and turn_manager:
		var current_player = turn_manager.current_player_index
		
		# 1. Atualiza o terreno (GridPainter)
		visibility_manager.update_fog(
			vagabond_manager.active_vagabonds, 
			grid_manager.data, 
			grid_manager.painter,
			current_player
		)
		
		# 2. Sincroniza unidades
		var current_lit_nodes = grid_manager.painter.lit_nodes
		
		for v in vagabond_manager.active_vagabonds:
			if not is_instance_valid(v): continue
			
			if v.owner_id == current_player:
				# FORÇA visibilidade total para o dono do turno
				v.visible = true
				v.modulate.a = 1.0
				# Reset de escala/visual caso tenha vindo de um estado exausto
				if force_instant and v.has_method("_animate_ap_change"):
					v._animate_ap_change()
			else:
				# Inimigos: usam lógica de Fog suave (gameplay) ou instantânea (troca de turno)
				v.update_fow_visibility(current_lit_nodes, force_instant)

func _on_focus_changed(control: Control) -> void:
	if control:
		control.release_focus()