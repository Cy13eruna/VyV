# res://src/ui/PlayerTurnScreen.gd
extends Control

var _player_name: String = "UNKNOWN"
var _player_color: Color = Color.WHITE
var _callback: Callable

func setup(data: Dictionary) -> void:
	# Tenta buscar o nome em diferentes chaves para evitar o "Unknown"
	if data.has("name"):
		_player_name = str(data["name"])
	elif data.has("color_name"):
		_player_name = str(data["color_name"])
	elif data.has("display_id"):
		_player_name = "PLAYER " + str(data["display_id"])
	
	_player_color = data.get("color", Color.WHITE)
	_callback = data.get("callback", func(): pass)
	
	# Garante que a tela cubra tudo e bloqueie o mundo
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP 
	
	_build_ui()

func _build_ui() -> void:
	# Limpa qualquer lixo visual anterior (caso setup seja chamado duas vezes)
	for child in get_children():
		child.queue_free()

	# 1. Fundo Preto (Esconde o tabuleiro para o hot-seat)
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 2. Container Central
	var vbox = VBoxContainer.new()
	vbox.name = "CenterContainer"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 30) 
	add_child(vbox)
	
	# 3. Label do Jogador
	var label = Label.new()
	# Se o nome for apenas a cor, formatamos para ficar elegante
	label.text = _player_name.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Aumentar a fonte via código para dar destaque
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", _player_color)
	vbox.add_child(label)
	
	# 4. Botão START
	var btn = Button.new()
	btn.text = "START TURN"
	btn.custom_minimum_size = Vector2(250, 70)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Estilo básico para o botão não ficar genérico demais
	btn.add_theme_font_size_override("font_size", 24)
	
	btn.pressed.connect(_on_start_pressed)
	vbox.add_child(btn)
	
	# Faz o botão brilhar ou ganhar foco automaticamente para facilitar o teclado/gamepad
	btn.grab_focus.call_deferred()

func _on_start_pressed() -> void:
	print("[PlayerTurnScreen] Turno iniciado para: ", _player_name)
	
	if _callback and _callback.is_valid():
		_callback.call()
	
	# Libera o mouse para o mundo novamente
	queue_free()