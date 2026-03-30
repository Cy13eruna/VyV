# res://src/systems/input/InputHandler.gd
extends RefCounted

# O estado do InputHandler
enum State { IDLE, SELECTED, BUSY }

# --- SOLUÇÃO PARA O ERRO DE PARSE ---
# Carregamos o script explicitamente. Isso garante que o tipo seja reconhecido 
# mesmo que o class_name global ainda não tenha sido registrado pelo motor.
const VagabondScript = preload("res://src/systems/entities/Vagabond.gd")

var main_ref: Node
var current_state: int = State.IDLE

## Usamos Node2D para a definição da variável para evitar o Parse Error,
## e fazemos o tratamento tipado internamente.
var selected_unit: Node2D = null 

func _init(p_main: Node) -> void:
	main_ref = p_main
	if is_instance_valid(Signals):
		_reconnect_signals()

func _reconnect_signals() -> void:
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

# --- LÓGICA DE CLIQUE ---

func _process_left_click() -> void:
	var world_pos = main_ref.get_global_mouse_position()
	var grid_pos = main_ref.grid_manager.world_to_grid(world_pos)
	
	# Usamos o VagabondScript carregado para fazer o cast seguro
	var clicked_unit = main_ref.vagabond_manager.get_vagabond_at(grid_pos)
	var v_clicked = clicked_unit as VagabondScript

	if not v_clicked:
		v_clicked = _find_unit_by_proximity(world_pos) as VagabondScript

	match current_state:
		State.IDLE:
			if v_clicked:
				_handle_selection(v_clicked)
		
		State.SELECTED:
			if v_clicked and v_clicked != selected_unit:
				if v_clicked.owner_id == main_ref.turn_manager.current_player_index:
					_handle_selection(v_clicked)
					return
			
			_handle_action(grid_pos)

# --- PROCESSAMENTO DE ESTADOS ---

## Aceitamos Node2D na assinatura para evitar erro de escopo no cabeçalho
func _handle_selection(unit: Node2D) -> void:
	var v = unit as VagabondScript
	if not v: return
	
	var current_player = main_ref.turn_manager.current_player_index
	
	# Acesso direto e seguro via VagabondScript
	if v.owner_id != current_player:
		print("[Input] Unidade do jogador %d. Turno atual: %d" % [v.owner_id, current_player])
		return
		
	if not v.has_ap():
		print("[Input] Unidade exausta.")
		return

	_deselect_all()
	selected_unit = v
	current_state = State.SELECTED
	
	# Feedback Visual
	if v.has_method("set_highlight"):
		v.set_highlight(true)
	
	# O GridManager já foi atualizado para aceitar Node2D e fazer o cast interno
	main_ref.grid_manager.show_reachable_for(selected_unit, [])
	
	Signals.unit_selected.emit(selected_unit)

func _handle_action(grid_pos: Vector2) -> void:
	# Cast interno para acessar grid_pos da MapEntity
	var v_selected = selected_unit as VagabondScript
	if not is_instance_valid(v_selected): 
		_deselect_all()
		return
	
	if grid_pos.distance_to(v_selected.grid_pos) < 0.1:
		_deselect_all()
		return

	if main_ref.grid_manager.is_node_reachable(grid_pos):
		_execute_movement(grid_pos)
	else:
		_deselect_all()

func _execute_movement(target_pos: Vector2) -> void:
	current_state = State.BUSY
	
	if main_ref.grid_manager.has_method("clear_highlights"):
		main_ref.grid_manager.clear_highlights()
		
	main_ref.grid_manager.request_move(selected_unit, target_pos)

func _on_unit_move_completed(_unit: Node2D, _from: Vector2, _to: Vector2) -> void:
	_deselect_all()
	current_state = State.IDLE

func _deselect_all() -> void:
	if is_instance_valid(selected_unit) and selected_unit.has_method("set_highlight"):
		selected_unit.set_highlight(false)
	
	if main_ref.grid_manager.has_method("clear_highlights"):
		main_ref.grid_manager.clear_highlights()
		
	selected_unit = null
	if current_state != State.BUSY:
		current_state = State.IDLE
	
	Signals.unit_deselected.emit()

# --- AUXILIARES ---

func _is_mouse_over_ui() -> bool:
	return main_ref.get_viewport().gui_get_hovered_control() != null

func _find_unit_by_proximity(click_pos: Vector2) -> Node2D:
	for v in main_ref.vagabond_manager.active_vagabonds:
		if is_instance_valid(v) and v.global_position.distance_to(click_pos) < 45.0:
			return v
	return null