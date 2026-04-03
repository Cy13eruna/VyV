# res://src/ui/GameHUD.gd
extends Control

signal end_turn_requested

# Preload dos upgrades disponíveis
const NewVagabondUpgrade = preload("res://src/systems/upgrades/NewVagabond.gd")

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

# --- LÓGICA DE UPGRADE (GENÉRICA) ---

func _on_open_upgrade_popup(domain: Node2D, click_position: Vector2) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("focus_on_position"):
		camera.focus_on_position(click_position)
	
	var available_upgrades = [NewVagabondUpgrade.new()]
	
	var options = []
	for upgrade in available_upgrades:
		options.append({
			"emoji": upgrade.icon,
			"callback": func(): _open_confirmation_popup(domain, upgrade)
		})
	
	var d_level = domain.domain_level if "domain_level" in domain else 1
	open_popup("UPGRADE DOMAIN", "~ Current Domain Level: %d ~" % d_level, options)

func _open_confirmation_popup(domain: Node2D, upgrade: RefCounted) -> void:
	var confirm_options = [
		{
			"emoji": "DO IT",
			"callback": func(): 
				upgrade.execute(domain)
				_close_popup(),
			"is_text_button": true
		}
	]
	
	open_popup(upgrade.title, upgrade.get_description(domain), confirm_options)

# --- SISTEMA DE POP-UP (MOTOR DE UI) ---

func open_popup(title: String, subtitle: String, options: Array) -> void:
	if not is_inside_tree(): return
	
	_clear_popup_options()
	
	title_label.text = title
	subtitle_label.text = subtitle
	
	for opt in options:
		var btn = _create_button_from_option(opt)
		popup_options_hbox.add_child(btn)
	
	popup_layer.visible = true
	
	# Layout Refresh
	popup_vbox.reset_size()
	popup_balloon.reset_size()
	
	await get_tree().process_frame
	_reposition_popup()

func _create_button_from_option(opt: Dictionary) -> Button:
	var emoji_text = opt.get("emoji", "?")
	var callback = opt.get("callback", func(): pass)
	
	if opt.get("is_text_button", false):
		return _create_rect_button(emoji_text, callback)
	return _create_circle_button(emoji_text, callback)

func _reposition_popup() -> void:
	var center = get_viewport_rect().size / 2.0
	popup_balloon.global_position = center - Vector2(popup_balloon.size.x / 2.0, popup_balloon.size.y + 10)
	triangle_pointer.global_position = center - Vector2(0, 10)

func _clear_popup_options() -> void:
	if popup_options_hbox:
		for child in popup_options_hbox.get_children():
			child.queue_free()

func _close_popup() -> void:
	popup_layer.visible = false

# --- CONSTRUÇÃO DE ELEMENTOS ---

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
	style.shadow_size = 8
	style.shadow_offset = Vector2(4, 4)
	# CORREÇÃO: StyleBoxFlat não tem content_margin_all em código
	style.content_margin_left = 20
	style.content_margin_top = 20
	style.content_margin_right = 20
	style.content_margin_bottom = 20
	
	popup_balloon.add_theme_stylebox_override("panel", style)
	popup_layer.add_child(popup_balloon)
	
	popup_vbox = VBoxContainer.new()
	popup_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_vbox.add_theme_constant_override("separation", 12)
	popup_balloon.add_child(popup_vbox)
	
	title_label = _create_label(20, Color.BLACK)
	subtitle_label = _create_label(14, Color.DIM_GRAY)
	popup_vbox.add_child(title_label)
	popup_vbox.add_child(subtitle_label)
	
	popup_options_hbox = HBoxContainer.new()
	popup_options_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	popup_options_hbox.add_theme_constant_override("separation", 20)
	popup_vbox.add_child(popup_options_hbox)
	
	triangle_pointer = Polygon2D.new()
	triangle_pointer.polygon = PackedVector2Array([Vector2(-15, 0), Vector2(15, 0), Vector2(0, 20)])
	triangle_pointer.color = Color.WHITE
	popup_layer.add_child(triangle_pointer)
	
	popup_layer.visible = false

func _create_label(size: int, color: Color) -> Label:
	var l = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(200, 0)
	return l

func _create_circle_button(emoji: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = emoji
	btn.custom_minimum_size = Vector2(64, 64)
	btn.focus_mode = Control.FOCUS_NONE
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(32)
	style.set_border_width_all(2)
	style.border_color = Color.GHOST_WHITE
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.add_theme_font_size_override("font_size", 30)
	btn.pressed.connect(callback)
	return btn

func _create_rect_button(text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(140, 45)
	btn.focus_mode = Control.FOCUS_NONE
	var style = StyleBoxFlat.new()
	style.bg_color = Color.BLACK
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.pressed.connect(callback)
	return btn

func _create_ui_elements() -> void:
	turn_button = Button.new()
	turn_button.text = "END TURN"
	turn_button.custom_minimum_size = Vector2(150, 50)
	turn_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	turn_button.offset_left = -170
	turn_button.offset_top = 20
	turn_button.pressed.connect(func(): end_turn_requested.emit())
	add_child(turn_button)
	
	status_label = Label.new()
	status_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status_label.offset_left = -300
	status_label.offset_top = 80
	add_child(status_label)

func _on_popup_mask_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_popup()

func _on_turn_started(player_id: int, player_color: Color, _round_num: int = 1) -> void:
	if not _is_initialized: await get_tree().process_frame
	if turn_button:
		turn_button.disabled = false
	if status_label:
		status_label.add_theme_color_override("font_color", player_color)