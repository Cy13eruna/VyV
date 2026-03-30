# res://src/ui/GameHUD.gd
extends Control

signal end_turn_requested

var turn_button: Button
var status_label: Label
var _is_initialized: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_create_ui_elements()
	_is_initialized = true
	_connect_signals.call_deferred()

func _connect_signals() -> void:
	if is_instance_valid(Signals):
		if Signals.turn_started.is_connected(_on_turn_started):
			Signals.turn_started.disconnect(_on_turn_started)
		Signals.turn_started.connect(_on_turn_started)

func _create_ui_elements() -> void:
	# 1. Botão de End Turn
	turn_button = Button.new()
	turn_button.text = "END TURN"
	turn_button.custom_minimum_size = Vector2(150, 50)
	turn_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	turn_button.offset_left = -170
	turn_button.offset_top = 20
	turn_button.focus_mode = Control.FOCUS_NONE
	turn_button.mouse_filter = Control.MOUSE_FILTER_STOP
	turn_button.pressed.connect(_on_btn_pressed)
	add_child(turn_button)
	
	# 2. Label de Status (Agora apenas para a cor/ID)
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "" # Começa vazio
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status_label.offset_left = -300
	status_label.offset_top = 80
	add_child(status_label)

func _on_btn_pressed() -> void:
	if not is_instance_valid(turn_button) or turn_button.disabled: return
	
	turn_button.disabled = true
	turn_button.text = "PROCESSING..."
	end_turn_requested.emit()

func _on_turn_started(player_id: int, player_color: Color) -> void:
	if not _is_initialized:
		await get_tree().process_frame
	_update_ui(player_id, player_color)

func _update_ui(player_id: int, player_color: Color) -> void:
	if not is_instance_valid(turn_button) or not is_instance_valid(status_label):
		return

	turn_button.disabled = false
	turn_button.text = "END TURN"
	
	# REMOVIDO: "Turno do Jogador %d"
	# Se quiseres o ID puro: status_label.text = str(player_id + 1)
	# Se quiseres deixar totalmente vazio conforme pedido:
	status_label.text = "" 
	
	# Mantemos a cor de override apenas se decidires colocar um ícone ou 
	# número futuramente, caso contrário, o label fica invisível.
	status_label.add_theme_color_override("font_color", player_color)
	
	move_to_front()