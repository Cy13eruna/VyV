# res://src/ui/PlayerTurnScreen.gd
extends Control

var _player_name: String = "UNKNOWN"
var _player_color: Color = Color.WHITE
var _callback: Callable

func setup(data: Dictionary) -> void:
	# Tenta buscar o nome em diferentes chaves
	if data.has("name"):
		_player_name = str(data["name"])
	elif data.has("color_name"):
		_player_name = str(data["color_name"])
	elif data.has("display_id"):
		_player_name = "PLAYER " + str(data["display_id"])
	
	_player_color = data.get("color", Color.WHITE)
	_callback = data.get("callback", func(): pass)
	
	# 1. PRESET_FULL_RECT garante que o Control ocupe toda a área da janela
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 2. MOUSE_FILTER_STOP é CRUCIAL: ele impede que cliques "vazem" para o botão atrás
	mouse_filter = Control.MOUSE_FILTER_STOP 
	
	# 3. Z_INDEX garante que esta tela seja desenhada NA FRENTE do GameHUD
	# Se o HUD estiver no nível padrão, 10 já é suficiente para cobri-lo.
	z_index = 10 
	
	_build_ui()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	# 4. Fundo Preto Totalmente Opaco
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# O fundo também deve bloquear o mouse por segurança
	bg.mouse_filter = Control.MOUSE_FILTER_STOP 
	add_child(bg)
	
	# 2. Container Central
	var vbox = VBoxContainer.new()
	vbox.name = "CenterContainer"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 30) 
	add_child(vbox)
	
	# 3. Label do Jogador
	var label = Label.new()
	label.text = _player_name.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", _player_color)
	vbox.add_child(label)
	
	# 4. Botão START
	var btn = Button.new()
	btn.text = "START TURN"
	btn.custom_minimum_size = Vector2(250, 70)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 24)
	
	btn.pressed.connect(_on_start_pressed)
	vbox.add_child(btn)
	
	btn.grab_focus.call_deferred()

func _on_start_pressed() -> void:
	print("[PlayerTurnScreen] Turno iniciado para: ", _player_name)
	
	if _callback and _callback.is_valid():
		_callback.call()
	
	# Ao liberar este nó, o HUD que estava atrás volta a ser visível e interativo
	queue_free()