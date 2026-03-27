# res://src/ui/GameHUD.gd
extends Control

signal end_turn_requested

func _ready() -> void:
	# Ocupa a tela inteira mas ignora o mouse para não bloquear o clique no mundo
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_create_end_turn_button()

func _create_end_turn_button() -> void:
	var turn_button = Button.new()
	turn_button.text = "END TURN"
	turn_button.custom_minimum_size = Vector2(150, 50)
	
	# Posicionamento no canto superior direito
	turn_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	
	# Configurações de input solicitadas
	turn_button.focus_mode = Control.FOCUS_NONE # Bloqueia foco de teclado/espaço
	turn_button.mouse_filter = Control.MOUSE_FILTER_STOP # Captura apenas o clique sobre o botão
	
	turn_button.pressed.connect(_on_btn_pressed)
	add_child(turn_button)

func _on_btn_pressed() -> void:
	end_turn_requested.emit()

# Mantemos o setup vazio para compatibilidade com o UIManager
func setup(_player_data: Dictionary) -> void:
	pass