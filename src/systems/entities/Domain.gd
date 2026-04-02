# res://src/systems/entities/Domain.gd

extends "res://src/systems/entities/MapEntity.gd"

class_name Domain

# --- CONTROLE DE UNICIDADE (ESTÁTICO) ---
static var used_initials: Array[String] = []

# --- PROPRIEDADES ESPECÍFICAS ---
var outer_r: float
var inner_r: float
var tile_size: float = 64.0
var high_res_font: SystemFont
var label_node: Node2D

var domain_name: String = ""
var power: int = 1 
var domain_level: int = 1 

func _ready() -> void:
	_setup_high_res_font()
	
	self.z_index = -5
	self.z_as_relative = false 
	self.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	_create_text_node()
	
	if Signals.has_signal("domains_visibility_updated"):
		if not Signals.domains_visibility_updated.is_connected(_on_visibility_updated):
			Signals.domains_visibility_updated.connect(_on_visibility_updated)

func _setup_high_res_font() -> void:
	if high_res_font: return
	high_res_font = SystemFont.new()
	high_res_font.multichannel_signed_distance_field = true
	high_res_font.msdf_pixel_range = 16
	high_res_font.msdf_size = 128 
	high_res_font.generate_mipmaps = true

func _create_text_node() -> void:
	label_node = Node2D.new()
	label_node.name = "DomainLabel"
	label_node.z_index = 200 
	label_node.z_as_relative = false 
	add_child(label_node)
	label_node.draw.connect(_draw_label)

func setup_domain(p_world_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int, p_tile_size: float) -> void:
	self.tile_size = p_tile_size
	if domain_name.is_empty():
		domain_name = _generate_unique_initial_name(6)
	super.setup(p_world_pos, p_grid_pos, p_color, p_owner_id)

func _apply_visuals() -> void:
	self.outer_r = tile_size * 0.92
	self.inner_r = tile_size * 0.55
	queue_redraw()
	if label_node: label_node.queue_redraw()

# --- INPUT E INTERAÇÃO ---

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		# 1. PRIORIDADE ABSOLUTA: Se o clique já foi tratado (movimento/UI), pare aqui.
		if get_viewport().is_input_handled():
			return

		# 2. Se houver uma unidade em cima, ignore (o clique é para a unidade)
		if _is_occupied():
			return

		var mouse_pos = get_global_mouse_position()
		
		# 3. Verifica clique no centro (inner_r)
		if mouse_pos.distance_to(self.global_position) < inner_r:
			
			# 4. Checagem de segurança: Se o VagabondManager estiver em modo de movimento,
			# não devemos abrir o menu de upgrade.
			if _is_movement_active():
				return

			if _can_open_upgrade_menu():
				if is_instance_valid(Signals):
					Signals.request_upgrade_menu.emit(self)
				# Marca como resolvido para que ninguém abaixo (como a câmera) use o clique
				get_viewport().set_input_as_handled()

func _is_movement_active() -> bool:
	# Tenta detectar se existe um vagabundo selecionado pronto para mover
	var v_manager = get_tree().get_first_node_in_group("VagabondManager")
	if is_instance_valid(v_manager):
		# Checa se existe a propriedade ou método que indica unidade selecionada
		if v_manager.get("selected_vagabond") != null:
			return true
	return false

func _can_open_upgrade_menu() -> bool:
	return power >= domain_level and not _is_occupied()

func _is_occupied() -> bool:
	var v_manager = get_tree().get_first_node_in_group("VagabondManager")
	if is_instance_valid(v_manager) and v_manager.has_method("is_cell_occupied"):
		if v_manager.is_cell_occupied(self.grid_pos):
			return true
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = self.global_position
	query.collide_with_areas = true
	var results = space_state.intersect_point(query)
	
	for res in results:
		var collider = res.collider
		if collider.is_in_group("Units") or collider.get_parent().is_in_group("Units"):
			return true
		if collider.get_parent().get("vagabond_name") != null:
			return true
			
	return false

# --- SISTEMA DE NÍVEL E PODER ---

func add_power(amount: int) -> void:
	power = max(0, power + amount)
	_refresh_all()

func upgrade_level() -> void:
	domain_level += 1
	_refresh_all()
	if is_instance_valid(Signals):
		Signals.domain_upgraded.emit(self, domain_level)

func _refresh_all() -> void:
	queue_redraw()
	if label_node: label_node.queue_redraw()

func _get_roman_level(lv: int) -> String:
	var roman_map = {1: "I", 2: "II", 3: "III", 4: "IV", 5: "V", 6: "VI", 7: "VII", 8: "VIII", 9: "IX", 10: "X"}
	return roman_map.get(lv, str(lv))

# --- VISIBILIDADE E RENDER ---

func _on_visibility_updated(visible_domains: Array) -> void:
	var is_visible_to_player = false
	for d_data in visible_domains:
		if d_data.has("pos") and d_data.pos.distance_to(self.global_position) < 5.0:
			is_visible_to_player = true
			break
	self.visible = is_visible_to_player

func _draw() -> void:
	var upscale = 4.0
	var downscale = 1.0 / upscale
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(downscale, downscale))

	var pts = PackedVector2Array()
	for i in range(13):
		var angle = deg_to_rad(i * 30 - 30)
		var r = (outer_r if i % 2 != 0 else inner_r) * upscale
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	
	draw_polyline(pts, Color(1, 1, 1, 0.2), 16.0 * upscale, true)
	draw_polyline(pts, Color(1, 1, 1, 0.7), 6.0 * upscale, true)
	draw_polyline(pts, entity_color, 4.0 * upscale, true)
	
	if not _is_occupied():
		var center_color = entity_color if power >= domain_level else Color(0.2, 0.2, 0.2, 0.8)
		draw_circle(Vector2.ZERO, 12.0 * upscale, center_color)
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw_label() -> void:
	if not high_res_font: return
	var upscale = 4.0
	var downscale = 1.0 / upscale
	label_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2(downscale, downscale))

	var roman_lv = _get_roman_level(domain_level)
	var text = "{%s} %s ⭐ %d" % [roman_lv, domain_name.to_upper(), power]
	
	var font_size = 48
	var text_size = high_res_font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = Vector2(-text_size.x / 2.0, (outer_r * upscale) + 20.0)
	
	label_node.draw_string(high_res_font, text_pos + Vector2(2,2), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)
	label_node.draw_string(high_res_font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, entity_color)
	label_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# --- GERAÇÃO DE NOMES ---

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

static func reset_domain_registry() -> void:
	used_initials.clear()