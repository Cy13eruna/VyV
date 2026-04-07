# res://src/ui/ActionPopUp.gd
extends CanvasLayer

signal option_selected(action_id: String)
signal cancelled()

# Referências geradas via código
var mask: Control
var balloon: PanelContainer
var title_label: Label
var subtitle_label: Label
var options_host: HBoxContainer

var is_open: bool = false
var _is_built: bool = false

func _ready() -> void:
	layer = 100 
	visible = false
	if not _is_built:
		_build_ui_structure()

func _build_ui_structure() -> void:
	# 1. Background Mask
	mask = Control.new()
	mask.name = "BackgroundMask"
	mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Garante que a máscara bloqueie cliques no mapa enquanto aberta
	mask.mouse_filter = Control.MOUSE_FILTER_STOP 
	add_child(mask)
	
	var bg_color = ColorRect.new()
	bg_color.name = "Dimmer"
	bg_color.color = Color(0, 0, 0, 0.4) 
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.add_child(bg_color)
	
	mask.gui_input.connect(_on_mask_input)

	# 2. Balloon Content
	balloon = PanelContainer.new()
	balloon.name = "BalloonContent"
	balloon.custom_minimum_size = Vector2(280, 160)
	balloon.mouse_filter = Control.MOUSE_FILTER_STOP # Impede fechar ao clicar no painel
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(20)
	style.shadow_size = 12
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.set_content_margin_all(25.0) 
	
	balloon.add_theme_stylebox_override("panel", style)
	add_child(balloon)
	
	# 3. Layout Vertical
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	balloon.add_child(vbox)
	
	# 4. Labels
	title_label = Label.new()
	title_label.name = "Title"
	title_label.add_theme_color_override("font_color", Color.BLACK)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	subtitle_label = Label.new()
	subtitle_label.name = "Subtitle"
	subtitle_label.add_theme_color_override("font_color", Color.DIM_GRAY)
	subtitle_label.add_theme_font_size_override("font_size", 14)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle_label)
	
	# 5. Container de Opções
	options_host = HBoxContainer.new()
	options_host.name = "OptionsContainer"
	options_host.alignment = BoxContainer.ALIGNMENT_CENTER
	options_host.add_theme_constant_override("separation", 25)
	vbox.add_child(options_host)
	
	_is_built = true

## Abre o menu. Se chamado antes do _ready, ele se auto-inicializa.
func open(p_title: String, p_subtitle: String, options: Array) -> void:
	# SEGURANÇA: Se o Main.gd chamar open() no mesmo frame da criação, 
	# forçamos a construção da UI aqui para evitar referências nulas.
	if not _is_built:
		_build_ui_structure()
	
	title_label.text = p_title
	subtitle_label.text = p_subtitle
	
	# Limpa opções anteriores de forma segura
	for child in options_host.get_children():
		child.queue_free()
	
	# Cria os novos botões
	for opt in options:
		var btn = _create_option_button(opt.get("emoji", "❓"), opt.id)
		options_host.add_child(btn)
	
	visible = true
	is_open = true
	
	# Reset de layout para centralização perfeita
	balloon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	balloon.reset_size()
	
	# Pequeno ajuste: garante que o balloon esteja exatamente no centro após o cálculo dos botões
	await get_tree().process_frame
	if is_instance_valid(balloon):
		balloon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

func _create_option_button(emoji: String, id: String) -> Button:
	var btn = Button.new()
	btn.text = emoji
	btn.custom_minimum_size = Vector2(80, 80)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var normal = StyleBoxFlat.new()
	normal.set_corner_radius_all(40)
	normal.bg_color = Color(0.95, 0.95, 0.95)
	normal.set_border_width_all(4)
	normal.border_color = Color(0.1, 0.1, 0.1)
	
	var hover = normal.duplicate()
	hover.bg_color = Color.WHITE
	hover.border_color = Color.MEDIUM_SLATE_BLUE
	
	var pressed = hover.duplicate()
	pressed.bg_color = Color(0.8, 0.8, 1.0)
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.add_theme_font_size_override("font_size", 36)
	
	btn.pressed.connect(func(): _on_option_clicked(id))
	return btn

func _on_option_clicked(id: String) -> void:
	option_selected.emit(id)
	close()

func _on_mask_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Se o clique for fora do balloon, cancela
		if not balloon.get_global_rect().has_point(event.global_position):
			cancelled.emit()
			close()

func close() -> void:
	visible = false
	is_open = false