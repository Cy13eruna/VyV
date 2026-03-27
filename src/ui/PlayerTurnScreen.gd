# res://src/ui/PlayerTurnScreen.gd
extends Control

var _player_name: String
var _player_color: Color
var _callback: Callable

func setup(data: Dictionary) -> void:
	# Agora recebemos o nome da cor (ex: "Green") e o objeto Color do Godot
	_player_name = data.get("name", "Unknown")
	_player_color = data.get("color", Color.WHITE)
	_callback = data.get("callback", func(): pass)
	
	# Bloqueia cliques no mundo enquanto a tela estiver ativa
	self.mouse_filter = Control.MOUSE_FILTER_STOP 
	_build_ui()

func _build_ui() -> void:
	# Fundo totalmente preto para esconder o tabuleiro antes do início
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# Espaçamento entre o texto e o botão
	vbox.add_theme_constant_override("separation", 20) 
	add_child(vbox)
	
	# Rótulo com o nome do jogador
	var label = Label.new()
	label.text = "PLAYER " + _player_name.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Aplica a cor do jogador ao texto
	label.add_theme_color_override("font_color", _player_color)
	
	# Opcional: Criar um estilo para aumentar a fonte se desejar futuramente
	vbox.add_child(label)
	
	# Botão START
	var btn = Button.new()
	btn.text = "START"
	btn.custom_minimum_size = Vector2(200, 60)
	btn.pressed.connect(_on_start_pressed)
	vbox.add_child(btn)

func _on_start_pressed() -> void:
	if _callback:
		_callback.call()
	
	# Libera o foco do botão para não atrapalhar atalhos de teclado (como Espaço)
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner:
		focus_owner.release_focus()
		
	queue_free()