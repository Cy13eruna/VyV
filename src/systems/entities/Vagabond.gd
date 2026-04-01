# res://src/systems/entities/Vagabond.gd
extends "res://src/systems/entities/MapEntity.gd"

class_name Vagabond

signal action_points_changed(current_ap: int, max_ap: int)
signal exhaustion_triggered()

# --- PROPRIEDADES DE ATRIBUTOS ---

@export var max_ap: int = 1
@export var ap: int = 1:
	set(v):
		ap = clamp(v, 0, max_ap)
		action_points_changed.emit(ap, max_ap)
		if ap == 0: 
			exhaustion_triggered.emit()
		_update_visual_state()

@export var move_range: int = 4 

var _is_highlighted: bool = false
var _high_res_font: SystemFont 

# --- CICLO DE VIDA ---

func setup(p_global_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int) -> void:
	super.setup(p_global_pos, p_grid_pos, p_color, p_owner_id)
	self.z_index = 10 
	
	_setup_font_resource()
	_create_visuals()
	_update_visual_state(true)

func _apply_visuals() -> void:
	_setup_font_resource()
	_create_visuals()
	_update_visual_state(true)

func _setup_font_resource() -> void:
	if _high_res_font: return
	_high_res_font = SystemFont.new()
	_high_res_font.multichannel_signed_distance_field = true
	_high_res_font.msdf_pixel_range = 16
	_high_res_font.msdf_size = 128 
	_high_res_font.set_antialiasing(1) 
	_high_res_font.generate_mipmaps = true

func _create_visuals() -> void:
	var old_view = get_node_or_null("View")
	if old_view:
		old_view.name = "OldView"
		old_view.queue_free()

	var view = Marker2D.new()
	view.name = "View"
	add_child(view)

	var hires_container = Node2D.new()
	hires_container.scale = Vector2(0.25, 0.25)
	view.add_child(hires_container)

	# 1. EMOJI
	var emoji = Label.new()
	emoji.name = "Emoji"
	emoji.text = "🚶‍♀️" 
	
	var emoji_settings = LabelSettings.new()
	emoji_settings.font = _high_res_font
	emoji_settings.font_size = 112 
	emoji_settings.font_color = entity_color 
	
	emoji.label_settings = emoji_settings
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	# --- AJUSTE DE ATERRISSAGEM ---
	var emoji_size = _high_res_font.get_string_size(emoji.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 112)
	emoji.custom_minimum_size = emoji_size
	
	# vertical_offset compensa o respiro interno da fonte do emoji.
	# Aumente este valor (ex: 15, 20) para descer mais os pés.
	var vertical_offset = 12.0 
	
	# X: Centralizado
	# Y: -Altura total + offset para descer e encostar os pés no (0,0)
	emoji.position = Vector2(-emoji_size.x / 2.0, -emoji_size.y + vertical_offset) 
	
	hires_container.add_child(emoji)
	
	# 2. LABEL DE TEXTO (VAGABOND)
	var label = Label.new()
	label.name = "IDLabel"
	label.text = "VAGABOND"
	
	var text_settings = LabelSettings.new()
	text_settings.font = _high_res_font
	text_settings.font_size = 40 
	text_settings.font_color = entity_color 
	text_settings.outline_size = 16 
	text_settings.outline_color = Color.BLACK 
	
	label.label_settings = text_settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	# --- ALINHAMENTO DO TEXTO ---
	var text_size = _high_res_font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 40)
	label.custom_minimum_size = text_size
	# Posicionado logo abaixo do ponto central
	label.position = Vector2(-text_size.x / 2.0, 10) 
	
	hires_container.add_child(label)

# --- FEEDBACKS VISUAIS ---

func _update_visual_state(instant: bool = false) -> void:
	var view = get_node_or_null("View")
	if not view: return

	var target_scale = Vector2(1.25, 1.25) if _is_highlighted else Vector2.ONE
	var target_alpha = 1.0 if ap > 0 else 0.7
	
	var emoji = view.find_child("Emoji", true)
	if emoji and emoji.label_settings:
		emoji.label_settings.font_color = entity_color
	
	var label = view.find_child("IDLabel", true)
	if label and label.label_settings:
		label.label_settings.font_color = entity_color

	if instant:
		view.scale = target_scale
		view.modulate.a = target_alpha
	else:
		var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT)
		tween.tween_property(view, "scale", target_scale, 0.2).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(view, "modulate:a", target_alpha, 0.25)

# --- LÓGICA DE JOGO ---

func use_ap() -> bool:
	if has_ap():
		ap -= 1 
		_play_action_animation()
		return true
	return false

func restore_ap() -> void:
	ap = max_ap 

func set_highlight(active: bool) -> void:
	_is_highlighted = active
	_update_visual_state()

func _play_action_animation() -> void:
	var view = get_node_or_null("View")
	if view:
		var jump = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		jump.tween_property(view, "position:y", -15, 0.1)
		jump.chain().tween_property(view, "position:y", 0, 0.1)

func update_fow_visibility(lit_nodes: Array, instant: bool = false) -> void:
	var is_lit = self.grid_pos in lit_nodes
	var target_alpha = 1.0 if is_lit else 0.0
	
	if instant:
		self.modulate.a = target_alpha
		self.visible = is_lit
	else:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", target_alpha, 0.3)
		if is_lit: self.visible = true
		else: tween.finished.connect(func(): if is_instance_valid(self): self.visible = false)

func has_ap() -> bool:
	return ap > 0