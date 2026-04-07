# res://src/systems/actions/ActionController.gd
extends Node

## Gerencia a lógica de intenção. 
## Escuta sinais de seleção e coordena a abertura do PopUp.

var action_popup: CanvasLayer = null
var _is_initialized: bool = false

## Inicialização manual chamada pelo Main.gd
func initialize(p_popup: CanvasLayer) -> void:
	action_popup = p_popup
	_connect_signals()
	_is_initialized = true
	print("[ActionController] Inicializado e monitorando seleções.")

func _connect_signals() -> void:
	if not is_instance_valid(Signals): return

	# Conexão unit_selected: Prioridade máxima para o fluxo de UI
	if Signals.has_signal("unit_selected"):
		if Signals.unit_selected.is_connected(_on_unit_selected):
			Signals.unit_selected.disconnect(_on_unit_selected)
		Signals.unit_selected.connect(_on_unit_selected)
	
	# Fechamento automático ao desselecionar
	if Signals.has_signal("unit_deselected"):
		if Signals.unit_deselected.is_connected(_on_unit_deselected_close):
			Signals.unit_deselected.disconnect(_on_unit_deselected_close)
		Signals.unit_deselected.connect(_on_unit_deselected_close)

func _on_unit_deselected_close() -> void:
	if is_instance_valid(action_popup):
		action_popup.close()

func _on_unit_selected(unit: Node2D) -> void:
	if not _is_initialized: 
		return
		
	if not is_instance_valid(unit) or not unit.has_method("get_available_actions"):
		return
		
	var actions = unit.get_available_actions()
	if actions.is_empty(): return
		
	var unit_name = unit.get("vagabond_name") if "vagabond_name" in unit else "Unit"
	
	if is_instance_valid(action_popup):
		_setup_popup_connections(unit)
		
		# --- CORREÇÃO PARA O PRIMEIRO CLIQUE ---
		# Se o popup acabou de ser instanciado e ainda não está "Ready",
		# usamos call_deferred para garantir que os nós internos (botões) existam.
		if not action_popup.is_node_ready():
			action_popup.open.call_deferred(unit_name, "Escolha uma Ação", actions)
		else:
			action_popup.open(unit_name, "Escolha uma Ação", actions)

func _setup_popup_connections(unit: Node2D) -> void:
	if is_instance_valid(action_popup):
		# Limpa conexões de sinais para garantir que o bind aponte para a unidade correta
		if action_popup.has_signal("option_selected"):
			for connection in action_popup.option_selected.get_connections():
				action_popup.option_selected.disconnect(connection.callable)
		
		action_popup.option_selected.connect(_on_popup_option_selected.bind(unit))

func _on_popup_option_selected(action_id: String, unit: Node2D) -> void:
	if is_instance_valid(action_popup):
		action_popup.close()
	_execute_action(action_id, unit)

func _execute_action(action_id: String, unit: Node2D) -> void:
	if not is_instance_valid(unit): return

	match action_id:
		"move":
			if Signals.has_signal("unit_move_requested"):
				Signals.unit_move_requested.emit(unit)
		"settle":
			_handle_settle_intent(unit)

func _handle_settle_intent(unit: Node2D) -> void:
	var domain_mgr = get_tree().get_first_node_in_group("domain_manager")
	if is_instance_valid(domain_mgr) and domain_mgr.has_method("create_domain"):
		var g_pos = unit.get("grid_pos")
		var e_color = unit.get("entity_color")
		var o_id = unit.get("owner_id")
		
		if domain_mgr.create_domain(g_pos, e_color, o_id):
			unit.queue_free()
			if Signals.has_signal("map_updated"):
				Signals.map_updated.emit()