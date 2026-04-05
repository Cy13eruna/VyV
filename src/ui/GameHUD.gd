# res://src/ui/GameHUD.gd
extends Control

signal end_turn_requested

const NewVagabondUpgrade = preload("res://src/systems/upgrades/NewVagabond.gd")
const NewTechUpgrade = preload("res://src/systems/upgrades/NewTech.gd")

# --- UI ELEMENTS ---
var turn_button: Button
var status_label: Label
var popup_layer: CanvasLayer
var popup_mask: Control
var popup_balloon: PanelContainer
var popup_vbox: VBoxContainer
var popup_options_hbox: HBoxContainer
var triangle_pointer: Polygon2D
var title_label: Label
var subtitle_label: Label

var _is_initialized: bool = false

# --- INITIALIZATION ---

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_create_ui_elements()
	_create_popup_system()
	
	_is_initialized = true
	_connect_signals.call_deferred()

func _connect_signals() -> void:
	if not is_instance_valid(Signals): return
	
	Signals.turn_started.connect(_on_turn_started)
	Signals.request_upgrade_menu.connect(_on_open_upgrade_popup)

# --- UPGRADE LOGIC ---

func _on_open_upgrade_popup(domain: Node2D, click_position: Vector2) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("focus_on_position"):
		camera.focus_on_position(click_position)
	
	var upgrades = [NewVagabondUpgrade.new(), NewTechUpgrade.new()]
	var options = []
	
	for upgrade in upgrades:
		var callback: Callable
		
		# Tech abre direto, outros pedem confirmação
		if upgrade.id == "new_tech":
			callback = func(): 
				upgrade.execute(domain)
				_close_popup()
		else:
			callback = func(): _open_confirmation_popup(domain, upgrade)
			
		options.append({"emoji": upgrade.icon, "callback": callback})
	
	var d_level = domain.get("domain_level") if domain.get("domain_level") != null else 1
	open_popup("UPGRADE DOMAIN", "~ Current Domain Level: %d ~" % d_level, options)

func _open_confirmation_popup(domain: Node2D, upgrade: RefCounted) -> void:
	var confirm_options = [{
		"emoji": "DO IT",
		"is_text_button": true,
		"callback": func(): 
			popup_options_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			upgrade.execute(domain)
			_close_popup()
	}]
	open_popup(upgrade.title, upgrade.get_description(domain), confirm_options)

# --- POP-UP ENGINE ---

func open_popup(title: String, subtitle: String, options: Array) -> void:
	if not is_inside_tree(): return
	
	_clear_popup_options()
	popup_options_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	
	title_label.text = title
	subtitle_label.text = subtitle
	
	for opt in options:
		var btn = _create_button(opt)
		popup_options_hbox.add_child(btn)
	
	popup_layer.show()
	
	# Aguarda um frame para o layout atualizar e reposiciona
	await get_tree().process_frame
	_reposition_popup()

func _create_button(opt: Dictionary) -> Button:
	var btn = Button.new()
	btn.text = opt.get("emoji", "?")
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(opt.get("callback", func(): pass))
	
	var style = StyleBoxFlat.new()
	if opt.get("is_text_button", false):
		btn.custom_minimum_size = Vector2(140, 45)
		style.bg_color = Color.BLACK
		style.set_corner_radius_all(4)
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		btn.custom_minimum_size = Vector2(64, 64)
		style.bg_color = Color.WHITE
		style.set_corner_radius_all(32)
		style.set_border_width_all(2)
		style.border_color = Color.GHOST_WHITE
		btn.add_theme_color_override("font_color", Color.BLACK)
		btn.add_theme_font_size_override("font_size", 30)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	return btn

func _reposition_popup() -> void:
	var center = get_viewport_rect().size / 2.0
	popup_balloon.global_position = center - Vector2(popup_balloon.size.x / 2.0, popup_balloon.size.y + 10)
	triangle_pointer.global_position = center - Vector2(0, 10)

func _clear_popup_options() -> void:
	for child in popup_options_hbox.get_children():
		child.queue_free()

func _close_popup() -> void:
	popup_layer.hide()

# --- CONSTRUCTION ---

func _create_popup_system() -> void:
	popup_layer = CanvasLayer.new()
	popup_layer.layer = 100
	add_child(popup_layer)
	
	popup_mask = Control.new()
	popup_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_mask.gui_input.connect(func(event): if event is InputEventMouseButton and event.pressed: _close_popup())
	popup_layer.add_child(popup_mask)
	
	popup_balloon = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.shadow_size = 8
	style.content_margin_left = 20; style.content_margin_right = 20
	style.content_margin_top = 20; style.content_margin_bottom = 20
	popup_balloon.add_theme_stylebox_override("panel", style)
	popup_layer.add_child(popup_balloon)
	
	popup_vbox = VBoxContainer.new()
	popup_vbox.add_theme_constant_override("separation", 12)
	popup_balloon.add_child(popup_vbox)
	
	title_label = _setup_label(20, Color.BLACK)
	subtitle_label = _setup_label(14, Color.DIM_GRAY)
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
	
	popup_layer.hide()

func _setup_label(size: int, color: Color) -> Label:
	var l = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(200, 0)
	return l

func _create_ui_elements() -> void:
	turn_button = Button.new()
	turn_button.text = "END TURN"
	turn_button.custom_minimum_size = Vector2(150, 50)
	turn_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	turn_button.offset_left = -170; turn_button.offset_top = 20
	turn_button.pressed.connect(func(): end_turn_requested.emit())
	add_child(turn_button)
	
	status_label = Label.new()
	status_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status_label.offset_left = -300; status_label.offset_top = 80
	add_child(status_label)

func _on_turn_started(player_id: int, player_color: Color, _round: int = 1) -> void:
	if not _is_initialized: await get_tree().process_frame
	turn_button.disabled = false
	status_label.add_theme_color_override("font_color", player_color)