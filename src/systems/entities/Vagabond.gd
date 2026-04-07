# res://src/systems/entities/Vagabond.gd
extends "res://src/systems/entities/MapEntity.gd"

class_name Vagabond

## Emitido quando os pontos de ação mudam.
signal action_points_changed(current_ap: int, max_ap: int)
## Emitido quando a unidade fica sem AP.
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

# Nome de 3 caracteres (Ex: ARX, KLO)
var vagabond_name: String = ""

# Cache para controle de processamento
var _last_grid_x: float = 0.0
var _last_grid_pos_checked: Vector2 = Vector2.INF

# --- CICLO DE VIDA ---

func setup(p_global_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int, p_name: String = "") -> void:
	# Importante: MapEntity.gd deve ter as propriedades grid_pos e entity_color
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
	
	# Se o domínio de origem não tiver poder, a unidade já nasce "cansada"
	if not _check_domain_has_power():
		ap = 0
		print("[Vagabond] %s exausto na criação (falta de energia no domínio)." % vagabond_name)

	_update_visual_state(true)
	add_to_group("Units")

func _process(_delta: float) -> void:
	# 1. Lógica de Flip (Inverte o emoji baseado na direção horizontal)
	if abs(grid_pos.x - _last_grid_x) > 0.01:
		var emoji_flip = get_node_or_null("View/HiresContainer/EmojiFlip")
		if emoji_flip:
			emoji_flip.scale.x = -1.0 if grid_pos.x > _last_grid_x else 1.0
		_last_grid_x = grid_pos.x
	
	# 2. Lógica de Colonização (Validação de posição apenas quando mudar de hex)
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

		# Feedback visual se clicar em unidade sem energia
		if not _check_domain_has_power() or not has_ap():
			_apply_fail_visual_feedback()
			# Mesmo sem AP, emitimos a seleção para que a UI/Controller limpe estados antigos
			if is_instance_valid(Signals) and Signals.has_signal("unit_selected"):
				Signals.unit_selected.emit(self)
			return

		# Notifica o ActionController para decidir o fluxo
		if is_instance_valid(Signals) and Signals.has_signal("unit_selected"):
			Signals.unit_selected.emit(self)

func _setup_font_resource() -> void:
	if _high_res_font: return
	_high_res_font = SystemFont.new()
	_high_res_font.multichannel_signed_distance_field = true
	_high_res_font.msdf_pixel_range = 16
	_high_res_font.msdf_size = 128 
	
	_emoji_font = SystemFont.new()
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
	
	var emoji_size = _emoji_font.get_string_size(emoji.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 112)
	emoji.position = Vector2(-emoji_size.x / 2.0, -emoji_size.y + 12.0) 
	emoji_flip.add_child(emoji)

	# --- BANDEIRA DE COLONIZADOR ---
	var flag = Label.new()
	flag.name = "SettlerFlag"
	flag.text = "🚩"
	flag.visible = false 
	var flag_settings = LabelSettings.new()
	flag_settings.font = _emoji_font
	flag_settings.font_size = 70 
	flag.label_settings = flag_settings
	
	# Posição relativa ao topo do emoji
	flag.position = Vector2(20, -emoji_size.y - 20.0) 
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
	
	var text_size = _high_res_font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 42)
	label.position = Vector2(-text_size.x / 2.0, 30) 
	hires_container.add_child(label)

# --- LÓGICA DE AÇÕES ---

func get_available_actions() -> Array:
	var actions = []
	if not has_ap(): return actions

	# 1. Wander (Movimento padrão)
	actions.append({
		"id": "move",
		"emoji": "👣",
		"title": "Wander",
		"subtitle": "Explore the map"
	})
	
	# 2. Settle (Fundar Domínio - Só aparece se a bandeira estiver ativa)
	var flag_node = get_node_or_null("View/HiresContainer/EmojiFlip/SettlerFlag")
	if flag_node and flag_node.visible:
		actions.append({
			"id": "settle",
			"emoji": "🚩",
			"title": "Settle",
			"subtitle": "Found a new domain"
		})
	
	return actions

func _check_domain_has_power() -> bool:
	var domain_mgr = get_tree().get_first_node_in_group("domain_manager")
	if is_instance_valid(domain_mgr) and domain_mgr.has_method("get_domain_power_at"):
		return domain_mgr.get_domain_power_at(home_domain_pos) > 0
	return true 

func use_ap() -> bool:
	if not has_ap(): return false
	
	var domain_mgr = get_tree().get_first_node_in_group("domain_manager")
	if is_instance_valid(domain_mgr) and domain_mgr.has_method("consume_power_at"):
		var success = domain_mgr.consume_power_at(home_domain_pos, 1)
		if success:
			ap -= 1 
			_play_action_animation()
			return true
		return false
		
	ap -= 1
	return true

# --- REGRAS DE COLONIZAÇÃO ---

func update_settler_status() -> void:
	var flag_node = get_node_or_null("View/HiresContainer/EmojiFlip/SettlerFlag")
	if not flag_node: return

	var domain_mgr = get_tree().get_first_node_in_group("domain_manager")
	var grid_mgr = get_tree().get_first_node_in_group("grid_manager")
	
	if not is_instance_valid(domain_mgr) or not is_instance_valid(grid_mgr):
		flag_node.visible = false
		return
	
	# Verifica se a tecnologia foi destravada (usando meta do manager ou propriedade)
	if not domain_mgr.get_meta("tech_settlers_unlocked", false):
		flag_node.visible = false
		return

	var my_pos = grid_pos.snapped(Vector2(0.1, 0.1))
	
	# Verifica se o grid tem dados para esta posição
	if not grid_mgr.data or not grid_mgr.data.nodes.has(my_pos):
		flag_node.visible = false
		return
		
	var node_data = grid_mgr.data.nodes.get(my_pos)
	
	# Exige hexágono completo (6 vizinhos) para fundar
	if node_data.neighbors.size() < 6:
		flag_node.visible = false
		return

	# Não pode colonizar onde já existe um domínio
	if is_instance_valid(domain_mgr.get_domain_at(my_pos)):
		flag_node.visible = false
		return
		
	# Regra de distanciamento: Não pode ser vizinho imediato de outro domínio
	for neighbor_pos in node_data.neighbors:
		var clean_neighbor = neighbor_pos.snapped(Vector2(0.1, 0.1))
		if is_instance_valid(domain_mgr.get_domain_at(clean_neighbor)):
			flag_node.visible = false
			return

	flag_node.visible = true

# --- AUXILIARES E VISUAIS ---

func restore_ap() -> void:
	ap = max_ap if _check_domain_has_power() else 0
	update_settler_status()

func set_highlight(active: bool) -> void:
	_is_highlighted = active
	_update_visual_state()

func _apply_fail_visual_feedback() -> void:
	var view = get_node_or_null("View")
	if view:
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(view, "position:x", 8, 0.05)
		tween.tween_property(view, "position:x", -8, 0.05)
		tween.tween_property(view, "position:x", 0, 0.05)

func _play_action_animation() -> void:
	var view = get_node_or_null("View")
	if view:
		var jump = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		jump.tween_property(view, "position:y", -30, 0.12)
		jump.chain().tween_property(view, "position:y", 0, 0.1)

func _update_visual_state(instant: bool = false) -> void:
	var view = get_node_or_null("View")
	if not view: return
	
	var target_scale = Vector2(1.25, 1.25) if _is_highlighted else Vector2.ONE
	var target_alpha = 1.0 if ap > 0 else 0.5
	
	if instant:
		view.scale = target_scale
		view.modulate.a = target_alpha
	else:
		var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT)
		tween.tween_property(view, "scale", target_scale, 0.15).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(view, "modulate:a", target_alpha, 0.2)

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