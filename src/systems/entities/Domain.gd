# res://src/systems/entities/Domain.gd
extends "res://src/systems/entities/MapEntity.gd"

# --- PROPRIEDADES ESPECÍFICAS ---
var outer_r: float
var inner_r: float
var tile_size: float = 64.0

var high_res_font: SystemFont

func _ready() -> void:
	_setup_high_res_font()
	self.z_index = 5
	self.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	if Signals.has_signal("domains_visibility_updated"):
		if not Signals.domains_visibility_updated.is_connected(_on_visibility_updated):
			Signals.domains_visibility_updated.connect(_on_visibility_updated)

func _setup_high_res_font() -> void:
	high_res_font = SystemFont.new()
	high_res_font.multichannel_signed_distance_field = true
	high_res_font.msdf_pixel_range = 16
	high_res_font.msdf_size = 128 
	high_res_font.set_antialiasing(1) 
	high_res_font.generate_mipmaps = true

func setup_domain(p_world_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int, p_tile_size: float) -> void:
	self.tile_size = p_tile_size
	super.setup(p_world_pos, p_grid_pos, p_color, p_owner_id)

func _apply_visuals() -> void:
	self.outer_r = tile_size * 0.92
	self.inner_r = tile_size * 0.55
	queue_redraw()

func _on_visibility_updated(visible_domains: Array) -> void:
	var is_visible_to_player = false
	for d_data in visible_domains:
		if d_data.has("pos") and d_data.pos.distance_to(self.global_position) < 5.0:
			is_visible_to_player = true
			break
	self.visible = is_visible_to_player

func _draw() -> void:
	if not high_res_font: return
	
	var upscale = 4.0
	var downscale = 1.0 / upscale
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(downscale, downscale))

	# 1. Preparação dos pontos da Estrela
	var pts = PackedVector2Array()
	for i in range(13):
		var angle = deg_to_rad(i * 30 - 30)
		var r = (outer_r if i % 2 != 0 else inner_r) * upscale
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	
	# --- EFEITO DE LUZ DA ESTRELA ---
	draw_polyline(pts, Color(1, 1, 1, 0.2), 16.0 * upscale, true)
	draw_polyline(pts, Color(1, 1, 1, 0.4), 10.0 * upscale, true)
	draw_polyline(pts, Color(1, 1, 1, 0.7), 6.0 * upscale, true)
	draw_polyline(pts, entity_color, 4.0 * upscale, true)

	# 2. Desenho do Texto "DOMAIN"
	var text = "DOMAIN"
	var font_size = 56 
	var text_size = high_res_font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = Vector2(-text_size.x / 2.0, (outer_r * upscale))
	
	# --- SIMULAÇÃO DE OUTLINE (Compatível com todas as versões 4.x) ---
	# Desenhamos o texto em branco 4 vezes com micro-deslocamentos para criar um contorno grosso
	var o_dist = 4.0 # Distância do "outline" no espaço upscaled
	var outline_color = Color.BLACK
	
	draw_string(high_res_font, text_pos + Vector2(o_dist, o_dist), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, outline_color)
	draw_string(high_res_font, text_pos + Vector2(-o_dist, o_dist), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, outline_color)
	draw_string(high_res_font, text_pos + Vector2(o_dist, -o_dist), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, outline_color)
	draw_string(high_res_font, text_pos + Vector2(-o_dist, -o_dist), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, outline_color)

	# --- TEXTO PRINCIPAL ---
	draw_string(high_res_font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, entity_color)
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)