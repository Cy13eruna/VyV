# res://src/ui/GameHUD.gd

extends Control

signal end_turn_requested

# --- ELEMENTOS EXISTENTES ---
var turn_button: Button
var status_label: Label
var _is_initialized: bool = false

# --- ELEMENTOS DO POP-UP ---
var popup_layer: CanvasLayer
var popup_mask: Control
var popup_balloon: PanelContainer
var popup_vbox: VBoxContainer
var popup_options_hbox: HBoxContainer
var triangle_pointer: Polygon2D

# Labels para o conteúdo interno
var title_label: Label
var subtitle_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_create_ui_elements()
	_create_popup_system()
	
	_is_initialized = true
	_connect_signals.call_deferred()

func _connect_signals() -> void:
	if is_instance_valid(Signals):
		if Signals.turn_started.is_connected(_on_turn_started):
			Signals.turn_started.disconnect(_on_turn_started)
		Signals.turn_started.connect(_on_turn_started)
		
		if not Signals.request_upgrade_menu.is_connected(_on_open_upgrade_popup):
			Signals.request_upgrade_menu.connect(_on_open_upgrade_popup)

func _create_popup_system() -> void:
	popup_layer = CanvasLayer.new()
	popup_layer.layer = 100
	add_child(popup_layer)
	
	popup_mask = Control.new()
	popup_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_mask.gui_input.connect(_on_popup_mask_input)
	popup_layer.add_child(popup_mask)
	
	popup_balloon = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_border_width_all(0) 
	style.shadow_size = 8
	style.shadow_offset = Vector2(4, 4)
	style.content_margin_left = 20
	style.content_margin_top = 20
	style.content_margin_right = 20
	style.content_margin_bottom = 20
	
	popup_balloon.add_theme_stylebox_override("panel", style)
	popup_layer.add_child(popup_balloon)
	
	popup_vbox = VBoxContainer.new()
	# Importante: Permitir que o container cresça conforme o conteúdo
	popup_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_vbox.add_theme_constant_override("separation", 12)
	popup_balloon.add_child(popup_vbox)
	
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color.BLACK)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Forçar um tamanho mínimo para o título não colapsar
	title_label.custom_minimum_size = Vector2(200, 0)
	popup_vbox.add_child(title_label)
	
	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_color_override("font_color", Color.DIM_GRAY)
	subtitle_label.add_theme_font_size_override("font_size", 14)
	popup_vbox.add_child(subtitle_label)
	
	popup_options_hbox = HBoxContainer.new()
	popup_options_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	popup_options_hbox.add_theme_constant_override("separation", 20)
	popup_vbox.add_child(popup_options_hbox)
	
	triangle_pointer = Polygon2D.new()
	triangle_pointer.polygon = PackedVector2Array([
		Vector2(-15, 0), Vector2(15, 0), Vector2(0, 20)
	])
	triangle_pointer.color = Color.WHITE
	popup_layer.add_child(triangle_pointer)
	
	popup_layer.visible = false

# --- LÓGICA DE UPGRADE ---

func _on_open_upgrade_popup(domain: Node2D) -> void:
	var options = [
		{
			"emoji": "🆙", 
			"callback": func(): _execute_upgrade(domain)
		}
	]
	open_popup("UPGRADE DOMAIN", "~ cost: ⭐%d ~" % domain.domain_level, options)

func _execute_upgrade(domain: Node2D) -> void:
	domain.add_power(-domain.domain_level)
	domain.upgrade_level()

# --- FUNÇÕES CORE DO POP-UP ---

func open_popup(title: String, subtitle: String, options: Array) -> void:
	if not is_inside_tree(): return
	
	# Limpeza imediata
	for child in popup_options_hbox.get_children():
		child.free()
	
	title_label.text = title
	subtitle_label.text = subtitle
	
	for opt in options:
		var btn = _create_circle_button(opt.emoji, opt.callback)
		popup_options_hbox.add_child(btn)
	
	# PASSO CRÍTICO: Tornar visível ANTES de calcular a posição
	popup_layer.visible = true
	
	# Forçar o motor de UI a processar os tamanhos novos
	popup_vbox.reset_size()
	popup_balloon.reset_size()
	
	# Se o reset_size não for suficiente, process_frame garante a atualização
	await get_tree().process_frame
	
	var center = get_viewport_rect().size / 2.0
	
	# Reposicionar após o frame de cálculo
	popup_balloon.global_position = center - Vector2(popup_balloon.size.x / 2.0, popup_balloon.size.y + 10)
	triangle_pointer.global_position = center - Vector2(0, 10)

func _create_circle_button(emoji: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = emoji
	btn.custom_minimum_size = Vector2(64, 64)
	btn.focus_mode = Control.FOCUS_NONE
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color.WHITE
	btn_style.set_corner_radius_all(32) 
	btn_style.set_border_width_all(0) 
	
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_stylebox_override("hover", btn_style)
	btn.add_theme_stylebox_override("pressed", btn_style)
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.add_theme_font_size_override("font_size", 30)
	
	btn.pressed.connect(func():
		callback.call()
		_close_popup()
	)
	return btn

func _on_popup_mask_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_popup()

func _close_popup() -> void:
	popup_layer.visible = false

# --- ELEMENTOS HUD ORIGINAIS ---

func _create_ui_elements() -> void:
	turn_button = Button.new()
	turn_button.text = "END TURN"
	turn_button.custom_minimum_size = Vector2(150, 50)
	turn_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	turn_button.offset_left = -170
	turn_button.offset_top = 20
	turn_button.pressed.connect(_on_btn_pressed)
	add_child(turn_button)
	
	status_label = Label.new()
	status_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status_label.offset_left = -300
	status_label.offset_top = 80
	add_child(status_label)

func _on_btn_pressed() -> void:
	turn_button.disabled = true
	end_turn_requested.emit()

func _on_turn_started(player_id: int, player_color: Color, _round_num: int = 1) -> void:
	if not _is_initialized: await get_tree().process_frame
	_update_ui(player_id, player_color)

func _update_ui(player_id: int, player_color: Color) -> void:
	turn_button.disabled = false
	turn_button.text = "END TURN"
	status_label.add_theme_color_override("font_color", player_color)