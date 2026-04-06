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

# Nome de 3 caracteres
var vagabond_name: String = ""

# Cache para controle de movimento e lógica
var _last_grid_x: float = 0.0
var _last_grid_pos_checked: Vector2 = Vector2.INF

# --- CICLO DE VIDA ---

func setup(p_global_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int, p_name: String = "") -> void:
	home_domain_pos = p_grid_pos.snapped(Vector2(0.1, 0.1))
	_last_grid_x = p_grid_pos.x
	
	if not p_name.is_empty():
		vagabond_name = p_name
	elif vagabond_name.is_empty():
		vagabond_name = _generate_unique_initial_name(3)
		
	super.setup(p_global_pos, p_grid_pos, p_color, p_owner_id)
	
	self.z_index = 10 
	
	_setup_font_resource()
	_create_visuals()
	_setup_collision() 
	
	if not _check_domain_has_power():
		ap = 0
		print("[Vagabond] %s nasceu em domínio seco. Iniciando exausto." % vagabond_name)

	_update_visual_state(true)
	add_to_group("Units")

# Monitora o movimento para inverter emoji e atualizar status de colonização
func _process(_delta: float) -> void:
	# 1. Lógica de Flip (Direção)
	if abs(grid_pos.x - _last_grid_x) > 0.01:
		var emoji_flip = get_node_or_null("View/HiresContainer/EmojiFlip")
		if emoji_flip:
			emoji_flip.scale.x = -1.0 if grid_pos.x > _last_grid_x else 1.0
		_last_grid_x = grid_pos.x
	
	# 2. Lógica de Colonização (Validação de Nó)
	var current_snapped = grid_pos.snapped(Vector2(0.1, 0.1))
	if current_snapped != _last_grid_pos_checked:
		update_settler_status()
		_last_grid_pos_checked = current_snapped

func _setup_collision() -> void:
	var old = get_node_or_null("ClickBlocker")
	if old: old.queue_free()

	var area = Area2D.new()
	area.name = "ClickBlocker"
	area.input_pickable = true
	area.input_event.connect(_on_area_input_event)
	add_child(area)
	
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 35.0 
	shape.shape = circle
	area.add_child(shape)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()

		if not _check_domain_has_power():
			ap = 0 
			_apply_fail_visual_feedback()
			return

		if not has_ap():
			_apply_fail_visual_feedback()
			return

		if is_instance_valid(Signals) and Signals.has_signal("unit_selected"):
			Signals.unit_selected.emit(self)

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
	if old_view: old_view.queue_free()

	var view = Marker2D.new()
	view.name = "View"
	add_child(view)

	var hires_container = Node2D.new()
	hires_container.name = "HiresContainer"
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

	# --- IMPLEMENTAÇÃO DA BANDEIRA DE COLONIZADOR ---
	var flag = Label.new()
	flag.name = "SettlerFlag"
	flag.text = "🚩"
	flag.visible = false 
	var flag_settings = LabelSettings.new()
	flag_settings.font = _emoji_font
	flag_settings.font_size = 70 
	flag.label_settings = flag_settings
	flag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var flag_size = _emoji_font.get_string_size(flag.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 70)
	flag.custom_minimum_size = flag_size
	# Posicionada levemente acima e à direita do Vagabond
	flag.position = Vector2(10, -emoji_size.y - 10.0) 
	emoji_flip.add_child(flag)
	
	var label = Label.new()
	label.name = "IDLabel"
	label.text = vagabond_name
	var text_settings = LabelSettings.new()
	text_settings.font = _high_res_font
	text_settings.font_size = 42 
	text_settings.font_color = entity_color 
	text_settings.outline_size = 18 
	text_settings.outline_color = Color.BLACK 
	label.label_settings = text_settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	var text_size = _high_res_font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 42)
	label.custom_minimum_size = text_size
	label.position = Vector2(-text_size.x / 2.0, 30) 
	hires_container.add_child(label)

# --- LÓGICA DE JOGO ---

func _check_domain_has_power() -> bool:
	var domain_mgr = get_tree().get_first_node_in_group("domain_manager")
	if is_instance_valid(domain_mgr) and domain_mgr.has_method("get_domain_power_at"):
		return domain_mgr.get_domain_power_at(home_domain_pos) > 0
	return true 

func use_ap() -> bool:
	if not has_ap(): return false
	var domain_mgr = get_tree().get_first_node_in_group("domain_manager")
	if is_instance_valid(domain_mgr):
		if domain_mgr.has_method("consume_power_at"):
			var success = domain_mgr.consume_power_at(home_domain_pos, 1)
			if success:
				ap -= 1 
				_play_action_animation()
				return true
	ap -= 1
	return true

# --- LÓGICA DE COLONIZAÇÃO (SETTLERS) ---

func update_settler_status() -> void:
	var flag_node = get_node_or_null("View/HiresContainer/EmojiFlip/SettlerFlag")
	if not flag_node: return

	var domain_mgr = get_tree().get_first_node_in_group("domain_manager")
	var grid_mgr = get_tree().get_first_node_in_group("grid_manager")
	
	if not is_instance_valid(domain_mgr) or not is_instance_valid(grid_mgr): 
		flag_node.visible = false
		return
	
	# 1. Tech Check
	if not domain_mgr.get_meta("tech_settlers_unlocked", false):
		flag_node.visible = false
		return

	# 2. Borda Check
	var my_pos = grid_pos.snapped(Vector2(0.1, 0.1))
	var node_data = grid_mgr.data.nodes.get(my_pos)
	
	if not node_data or node_data.neighbors.size() < 6:
		flag_node.visible = false
		return

	# 3. Adjacência Check (CORRIGIDO)
	# Primeiro: Não pode colonizar em cima de um domínio existente
	if is_instance_valid(domain_mgr.get_domain_at(my_pos)):
		flag_node.visible = false
		return
		
	# Segundo: Verifica os vizinhos REAIS vindos do GridManager
	# node_data.neighbors contém as chaves (Vector2) de todos os nós adjacentes
	for neighbor_pos in node_data.neighbors:
		var clean_neighbor = neighbor_pos.snapped(Vector2(0.1, 0.1))
		if is_instance_valid(domain_mgr.get_domain_at(clean_neighbor)):
			# Encontrou um domínio vizinho!
			flag_node.visible = false
			return

	# Se passou por todos os vizinhos e nenhum era domínio
	flag_node.visible = true

# --- AUXILIARES E VISUAIS ---

func _apply_fail_visual_feedback() -> void:
	var view = get_node_or_null("View")
	if view:
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(view, "position:x", 5, 0.05)
		tween.tween_property(view, "position:x", -5, 0.05)
		tween.tween_property(view, "position:x", 0, 0.05)

func restore_ap() -> void:
	ap = max_ap if _check_domain_has_power() else 0
	update_settler_status()

func set_highlight(active: bool) -> void:
	_is_highlighted = active
	_update_visual_state()

func _play_action_animation() -> void:
	var view = get_node_or_null("View")
	if view:
		var jump = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		jump.tween_property(view, "position:y", -20, 0.1)
		jump.chain().tween_property(view, "position:y", 0, 0.1)

func _update_visual_state(instant: bool = false) -> void:
	var view = get_node_or_null("View")
	if not view: return
	var target_scale = Vector2(1.3, 1.3) if _is_highlighted else Vector2.ONE
	var target_alpha = 1.0 if ap > 0 else 0.4
	
	if instant:
		view.scale = target_scale
		view.modulate.a = target_alpha
	else:
		var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT)
		tween.tween_property(view, "scale", target_scale, 0.2).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(view, "modulate:a", target_alpha, 0.25)

func has_ap() -> bool:
	return ap > 0

func _generate_unique_initial_name(length: int) -> String:
	var standard_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var available_initials = ""
	for char in standard_alphabet:
		if not char in used_initials: available_initials += char
	if available_initials.length() == 0:
		used_initials.clear()
		available_initials = standard_alphabet
	var initial = available_initials[randi() % available_initials.length()]
	used_initials.append(initial)
	var rest = ""
	for i in range(length - 1): rest += standard_alphabet[randi() % standard_alphabet.length()]
	return initial + rest

static func reset_vagabond_registry() -> void:
	used_initials.clear()