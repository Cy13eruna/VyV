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
var core_symbol_node: Node2D 

var domain_name: String = ""
var power: int = 1 
var domain_level: int = 1 

func _ready() -> void:
	_setup_high_res_font()
	
	self.z_index = -5
	self.z_as_relative = false 
	self.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	_create_core_symbol_node() 
	_create_text_node()
	
	if Signals.has_signal("domains_visibility_updated"):
		if not Signals.domains_visibility_updated.is_connected(_on_visibility_updated):
			Signals.domains_visibility_updated.connect(_on_visibility_updated)
	
	add_to_group("domains")

func _setup_high_res_font() -> void:
	if high_res_font: return
	high_res_font = SystemFont.new()
	high_res_font.multichannel_signed_distance_field = true
	high_res_font.msdf_pixel_range = 16
	high_res_font.msdf_size = 128 
	high_res_font.generate_mipmaps = true

func _create_core_symbol_node() -> void:
	core_symbol_node = Node2D.new()
	core_symbol_node.name = "CoreSymbol"
	core_symbol_node.z_index = 0 
	core_symbol_node.z_as_relative = false
	add_child(core_symbol_node)
	core_symbol_node.draw.connect(_draw_hexagram)

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
	_apply_visuals()

func _apply_visuals() -> void:
	self.outer_r = tile_size * 0.92
	self.inner_r = tile_size * 0.55
	queue_redraw()
	if core_symbol_node: core_symbol_node.queue_redraw()
	if label_node: label_node.queue_redraw()

# --- INPUT E INTERAÇÃO ---

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if get_viewport().is_input_handled():
			return

		if _is_occupied():
			return

		var mouse_pos = get_global_mouse_position()
		if mouse_pos.distance_to(self.global_position) < inner_r:
			if _is_movement_active():
				return

			if _can_open_upgrade_menu():
				if is_instance_valid(Signals):
					Signals.request_upgrade_menu.emit(self, self.global_position)
				get_viewport().set_input_as_handled()

func _is_movement_active() -> bool:
	var v_manager = get_tree().get_first_node_in_group("vagabond_manager")
	if is_instance_valid(v_manager):
		if v_manager.get("selected_vagabond") != null:
			return true
	return false

func _can_open_upgrade_menu() -> bool:
	return power >= domain_level and not _is_occupied()

func _is_occupied() -> bool:
	var v_manager = get_tree().get_first_node_in_group("vagabond_manager")
	if is_instance_valid(v_manager) and v_manager.has_method("get_vagabond_at"):
		if v_manager.get_vagabond_at(self.global_position) != null:
			return true
	return false

# --- SISTEMA DE RECRUTAMENTO (UPGRADE) ---

func upgrade_level() -> void:
	add_power(-domain_level)
	domain_level += 1
	_spawn_vagabond_on_upgrade()
	_refresh_all()
	
	if is_instance_valid(Signals):
		Signals.domain_upgraded.emit(self, domain_level)

func _spawn_vagabond_on_upgrade() -> void:
	var v_manager = get_tree().get_first_node_in_group("vagabond_manager")
	if is_instance_valid(v_manager) and v_manager.has_method("spawn_vagabond"):
		var v_name = _generate_vagabond_name_3_letters()
		v_manager.spawn_vagabond(self.grid_pos, self.entity_color, self.owner_id, v_name)

func _generate_vagabond_name_3_letters() -> String:
	var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var initial = domain_name.left(1).to_upper()
	var n2 = alphabet[randi() % alphabet.length()]
	var n3 = alphabet[randi() % alphabet.length()]
	return initial + n2 + n3

func add_power(amount: int) -> void:
	power = max(0, power + amount)
	if power <= 0 and is_instance_valid(Signals):
		Signals.domain_power_depleted.emit(owner_id)
	_refresh_all()

func _refresh_all() -> void:
	queue_redraw()
	if core_symbol_node: core_symbol_node.queue_redraw()
	if label_node: label_node.queue_redraw()

func _get_roman_level(lv: int) -> String:
	var roman_map = {1: "I", 2: "II", 3: "III", 4: "IV", 5: "V", 6: "VI", 7: "VII", 8: "VIII", 9: "IX", 10: "X"}
	return roman_map.get(lv, str(lv))

# --- VISIBILIDADE E RENDER ---

func _on_visibility_updated(visible_domains: Array) -> void:
	var is_visible_to_player = false
	for d_data in visible_domains:
		if d_data is Dictionary and d_data.has("pos"):
			if d_data.pos.distance_to(self.global_position) < 5.0:
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
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_hexagram() -> void:
	if _is_occupied(): return 
	
	var upscale = 4.0
	var downscale = 1.0 / upscale
	core_symbol_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2(downscale, downscale))
	
	var radius = 10.0 * upscale 
	var symbol_color = entity_color if power >= domain_level else Color.WHITE
	# Garante que a cor de preenchimento seja totalmente opaca
	var opaque_fill = Color(symbol_color.r, symbol_color.g, symbol_color.b, 1.0)
	
	# Rotação de 30 graus convertida para radianos
	var rotation_offset = deg_to_rad(30)
	
	for orientation in [1, -1]:
		var tri_pts = PackedVector2Array()
		for i in range(4):
			# Base 90/-90 + 30 graus de rotação solicitada
			var angle = deg_to_rad(i * 120 + (90 if orientation > 0 else -90)) + rotation_offset
			tri_pts.append(Vector2(cos(angle), sin(angle)) * radius)
		
		# Preenchimento opaco
		core_symbol_node.draw_colored_polygon(tri_pts, opaque_fill)
		# Borda
		core_symbol_node.draw_polyline(tri_pts, symbol_color, 2.5 * upscale, true)

	core_symbol_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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

# --- GERAÇÃO DE NOMES DO DOMÍNIO ---

func _generate_unique_initial_name(length: int) -> String:
	var standard_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZÇ"
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