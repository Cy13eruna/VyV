# res://src/systems/input/InputHandler.gd
extends RefCounted

enum State { IDLE, SELECTED, BUSY }

var main_ref: Node
var current_state: int = State.IDLE
var selected_unit: Node2D = null 

func _init(p_main: Node) -> void:
	main_ref = p_main
	main_ref.ready.connect(_reconnect_signals)

func _reconnect_signals() -> void:
	if is_instance_valid(Signals):
		if Signals.unit_moved.is_connected(_on_unit_move_completed):
			Signals.unit_moved.disconnect(_on_unit_move_completed)
		Signals.unit_moved.connect(_on_unit_move_completed)

func handle_input(event: InputEvent) -> void:
	if current_state == State.BUSY:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if _is_mouse_over_ui():
			return

		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_process_left_click()
			MOUSE_BUTTON_RIGHT:
				_deselect_all()

func _process_left_click() -> void:
	var world_pos = main_ref.get_global_mouse_position()
	var grid_pos = main_ref.grid_manager.world_to_grid(world_pos)
	
	var v_clicked = main_ref.vagabond_manager.get_vagabond_at(grid_pos)
	if not v_clicked:
		v_clicked = _find_unit_by_proximity(world_pos)

	match current_state:
		State.IDLE:
			if v_clicked:
				_handle_selection(v_clicked)
		
		State.SELECTED:
			# Se clicar em outra unidade do mesmo jogador, troca a seleção
			if is_instance_valid(v_clicked) and v_clicked != selected_unit:
				var owner_id = v_clicked.get("owner_id")
				if owner_id == main_ref.turn_manager.current_player_index:
					_handle_selection(v_clicked)
					return
			
			# Tenta processar ação no grid (só funcionará se o GridManager estiver com nós ativos)
			_handle_action(grid_pos)

func _handle_selection(unit: Node2D) -> void:
	if not is_instance_valid(unit): return
	
	var current_player = main_ref.turn_manager.current_player_index
	var unit_owner = unit.get("owner_id")
	
	if unit_owner != current_player:
		return
		
	if unit.has_method("has_ap") and not unit.has_ap():
		return

	_deselect_all()
	
	selected_unit = unit
	current_state = State.SELECTED
	
	if selected_unit.has_method("set_highlight"):
		selected_unit.set_highlight(true)
	
	# --- MUDANÇA CRÍTICA AQUI ---
	# Removemos o main_ref.grid_manager.show_reachable_for(...)
	# Agora o ActionController abrirá o menu assim que receber este sinal:
	Signals.unit_selected.emit(selected_unit)

func _handle_action(grid_pos: Vector2) -> void:
	if not is_instance_valid(selected_unit): 
		_deselect_all()
		return
	
	# Verifica se o clique foi na própria unidade (para desselecionar)
	var unit_grid_pos = selected_unit.get("grid_pos")
	if grid_pos.distance_to(unit_grid_pos) < 0.1:
		_deselect_all()
		return

	# Só executa movimento se o GridManager tiver calculado caminhos 
	# (o que só acontece após clicar em "Mover" no popup)
	if main_ref.grid_manager.is_node_reachable(grid_pos):
		_execute_movement(grid_pos)
	else:
		# Se clicou em lugar inválido enquanto uma unidade estava selecionada
		_deselect_all()

func _execute_movement(target_pos: Vector2) -> void:
	current_state = State.BUSY
	if main_ref.grid_manager.has_method("clear_highlights"):
		main_ref.grid_manager.clear_highlights()
	main_ref.grid_manager.request_move(selected_unit, target_pos)

func _on_unit_move_completed(_unit: Node2D, _from: Vector2, _to: Vector2) -> void:
	_deselect_all()

func _deselect_all() -> void:
	if is_instance_valid(selected_unit) and selected_unit.has_method("set_highlight"):
		selected_unit.set_highlight(false)
	
	if main_ref.grid_manager.has_method("clear_highlights"):
		main_ref.grid_manager.clear_highlights()
		
	selected_unit = null
	current_state = State.IDLE
	
	if is_instance_valid(Signals):
		Signals.unit_deselected.emit()

func _is_mouse_over_ui() -> bool:
	return main_ref.get_viewport().gui_get_hovered_control() != null

func _find_unit_by_proximity(click_pos: Vector2) -> Node2D:
	if not "active_vagabonds" in main_ref.vagabond_manager:
		return null
	for v in main_ref.vagabond_manager.active_vagabonds:
		if is_instance_valid(v) and v.global_position.distance_to(click_pos) < 45.0:
			return v
	return null