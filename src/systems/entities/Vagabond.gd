# res://src/systems/entities/Vagabond.gd

extends "res://src/systems/entities/MapEntity.gd"

class_name Vagabond

signal action_points_changed(current_ap: int, max_ap: int)
signal exhaustion_triggered()

# --- CONTROLE DE UNICIDADE (ESTÁTICO) ---
static var used_initials: Array[String] = []

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

# Referência à posição do domínio que criou este Vagabond
var home_domain_pos: Vector2 = Vector2.ZERO

var _is_highlighted: bool = false
var _high_res_font: SystemFont 
var _emoji_font: SystemFont 

# Variável para o nome de 3 caracteres
var vagabond_name: String = ""

# --- CICLO DE VIDA ---

func setup(p_global_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int, p_name: String = "") -> void:
	home_domain_pos = p_grid_pos.snapped(Vector2(0.1, 0.1))
	
	if not p_name.is_empty():
		vagabond_name = p_name
	elif vagabond_name.is_empty():
		vagabond_name = _generate_unique_initial_name(3)
		
	super.setup(p_global_pos, p_grid_pos, p_color, p_owner_id)
	
	# Z-index alto para ficar visualmente acima
	self.z_index = 10 
	
	_setup_font_resource()
	_create_visuals()
	_setup_collision() 
	_update_visual_state(true)

	add_to_group("Units")

func _setup_collision() -> void:
	# Remove se já existir para evitar duplicatas em re-setups
	var old = get_node_or_null("ClickBlocker")
	if old: old.queue_free()

	var area = Area2D.new()
	area.name = "ClickBlocker"
	area.input_pickable = true
	# Garante que a colisão processa o clique
	area.input_event.connect(_on_area_input_event)
	add_child(area)
	
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	# Aumentado para 35.0 para garantir cobertura sobre o centro do Domain
	circle.radius = 35.0 
	shape.shape = circle
	area.add_child(shape)

# Callback disparado quando o mouse interage com a colisão do Vagabond
func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Se clicamos no Vagabond, "comemos" o evento para que o Domain abaixo não o receba
		get_viewport().set_input_as_handled()
		# Aqui você pode chamar a lógica de seleção do Vagabond se necessário
		print("[Vagabond] Clique detectado e bloqueado para camadas inferiores: ", vagabond_name)

func _setup_font_resource() -> void:
	if _high_res_font: return
	_high_res_font = SystemFont.new()
	_high_res_font.multichannel_signed_distance_field = true
	_high_res_font.msdf_pixel_range = 16
	_high_res_font.msdf_size = 128 
	_high_res_font.set_antialiasing(1) 
	_high_res_font.generate_mipmaps = true
	
	_emoji_font = SystemFont.new()
	_emoji_font.multichannel_signed_distance_field = false
	_emoji_font.generate_mipmaps = true

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

	var emoji_flip = Node2D.new()
	emoji_flip.name = "EmojiFlip"
	hires_container.add_child(emoji_flip)

	var emoji = Label.new()
	emoji.name = "Emoji"
	emoji.text = "🚶‍♀️" 
	var emoji_settings = LabelSettings.new()
	emoji_settings.font = _emoji_font
	emoji_settings.font_size = 112 
	emoji_settings.font_color = entity_color 
	emoji.label_settings = emoji_settings
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	var emoji_size = _emoji_font.get_string_size(emoji.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 112)
	emoji.custom_minimum_size = emoji_size
	emoji.position = Vector2(-emoji_size.x / 2.0, -emoji_size.y + 12.0) 
	emoji_flip.add_child(emoji)
	
	var label = Label.new()
	label.name = "IDLabel"
	label.text = vagabond_name
	var text_settings = LabelSettings.new()
	text_settings.font = _high_res_font
	text_settings.font_size = 32
	text_settings.font_color = entity_color 
	text_settings.outline_size = 16 
	text_settings.outline_color = Color.BLACK 
	label.label_settings = text_settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	var text_size = _high_res_font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 40)
	label.custom_minimum_size = text_size
	label.position = Vector2(-text_size.x / 2.0, 40) 
	hires_container.add_child(label)

# --- LÓGICA DE JOGO (REVOLTA E CONSUMO) ---

func use_ap() -> bool:
	if not has_ap():
		return false
		
	var domain_mgr = get_tree().get_first_node_in_group("domain_manager")
	
	if is_instance_valid(domain_mgr):
		var in_revolt = domain_mgr.has_method("is_in_revolt") and domain_mgr.is_in_revolt(home_domain_pos, owner_id)
		
		if in_revolt:
			print("[Vagabond] %s em REVOLTA!" % vagabond_name)
			ap -= 1
			_play_action_animation()
			_apply_revolt_visual_feedback()
			return true
			
		if domain_mgr.has_method("consume_power_at"):
			var success = domain_mgr.consume_power_at(home_domain_pos, 1)
			if success:
				ap -= 1 
				_play_action_animation()
				return true
			else:
				print("[Vagabond] Domínio %s sem Poder!" % str(home_domain_pos))
				return false
	
	ap -= 1
	_play_action_animation()
	return true

func _apply_revolt_visual_feedback() -> void:
	var view = get_node_or_null("View")
	if view:
		var tween = create_tween()
		tween.tween_property(view, "modulate", Color.ORANGE_RED, 0.1)
		tween.tween_property(view, "modulate", Color.WHITE, 0.1)

# --- AUXILIARES E VISUAIS ---

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

func _update_visual_state(instant: bool = false) -> void:
	var view = get_node_or_null("View")
	if not view: return
	var target_scale = Vector2(1.25, 1.25) if _is_highlighted else Vector2.ONE
	var target_alpha = 1.0 if ap > 0 else 0.7
	
	var emoji = view.find_child("Emoji", true, false)
	if emoji and emoji.label_settings:
		emoji.label_settings.font_color = entity_color
		
	var label = view.find_child("IDLabel", true, false)
	if label and label.label_settings:
		label.label_settings.font_color = entity_color
		
	if instant:
		view.scale = target_scale
		view.modulate.a = target_alpha
	else:
		var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT)
		tween.tween_property(view, "scale", target_scale, 0.2).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(view, "modulate:a", target_alpha, 0.25)

func has_ap() -> bool:
	return ap > 0

# --- GERAÇÃO DE NOMES ---

func _generate_unique_initial_name(length: int) -> String:
	var standard_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var available_initials = ""
	for char in standard_alphabet:
		if not char in used_initials:
			available_initials += char
	if available_initials.length() == 0:
		used_initials.clear()
		available_initials = standard_alphabet
		
	var initial = available_initials[randi() % available_initials.length()]
	used_initials.append(initial)
	var rest = ""
	for i in range(length - 1):
		rest += standard_alphabet[randi() % standard_alphabet.length()]
	return initial + rest

static func reset_vagabond_registry() -> void:
	used_initials.clear()