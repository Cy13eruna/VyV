# res://src/systems/entities/Domain.gd
extends "res://src/systems/entities/MapEntity.gd"

# --- CONTROLE DE UNICIDADE (ESTÁTICO) ---
static var used_initials: Array[String] = []

# --- PROPRIEDADES ESPECÍFICAS ---
var outer_r: float
var inner_r: float
var tile_size: float = 64.0
var high_res_font: SystemFont
var label_node: Node2D

var domain_name: String = ""

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
	high_res_font.set_antialiasing(1) 
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
	draw_polyline(pts, Color(1, 1, 1, 0.4), 10.0 * upscale, true)
	draw_polyline(pts, Color(1, 1, 1, 0.7), 6.0 * upscale, true)
	draw_polyline(pts, entity_color, 4.0 * upscale, true)
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_label() -> void:
	if not high_res_font: return
	
	var upscale = 4.0
	var downscale = 1.0 / upscale
	label_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2(downscale, downscale))

	var text = domain_name
	var font_size = 56 
	var text_size = high_res_font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	
	var text_pos = Vector2(-text_size.x / 2.0, (outer_r * upscale) + 20.0)
	
	var o_dist = 6.0 
	var outline_color = Color.BLACK
	var dirs = [
		Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1),
		Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)
	]
	
	for d in dirs:
		label_node.draw_string(high_res_font, text_pos + (d * o_dist), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, outline_color)

	label_node.draw_string(high_res_font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, entity_color)
	label_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# --- LÓGICA DE GERAÇÃO ÚNICA COM ACENTUAÇÃO ---

func _generate_unique_initial_name(length: int) -> String:
	var standard_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var accented_alphabet = "ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇÖÜËÏ"
	
	var available_initials = ""
	
	# 1. Tenta buscar no alfabeto padrão
	for char in standard_alphabet:
		if not char in used_initials:
			available_initials += char
			
	# 2. Se o padrão esgotou, tenta o acentuado
	if available_initials.length() == 0:
		for char in accented_alphabet:
			if not char in used_initials:
				available_initials += char
				
	# 3. Fallback final: se absolutamente tudo esgotar, limpa e reinicia
	if available_initials.length() == 0:
		used_initials.clear()
		available_initials = standard_alphabet
		
	# Sorteia a inicial dentro do que sobrou
	var initial = available_initials[randi() % available_initials.length()]
	used_initials.append(initial)
	
	# O resto do nome continua sendo gerado com o alfabeto padrão para manter legibilidade
	var rest = ""
	for i in range(length - 1):
		rest += standard_alphabet[randi() % standard_alphabet.length()]
		
	return initial + rest

static func reset_domain_registry() -> void:
	used_initials.clear()