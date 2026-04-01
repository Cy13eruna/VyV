# res://src/systems/entities/Domain.gd
extends "res://src/systems/entities/MapEntity.gd"

# --- PROPRIEDADES ESPECÍFICAS ---
var outer_r: float
var inner_r: float
var tile_size: float = 64.0
var high_res_font: SystemFont
var label_node: Node2D

func _ready() -> void:
	_setup_high_res_font()
	
	# --- CONFIGURAÇÃO DA ESTRELA (BASE) ---
	# Definimos um Z bem baixo para ficar atrás dos NodesLayer (z=2) e Indicators (z=1)
	self.z_index = -5
	self.z_as_relative = false # Garante que o -10 seja absoluto no mundo 2D
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
	# Criamos um nó separado para o texto para que ele ignore o Z negativo do pai
	label_node = Node2D.new()
	label_node.name = "DomainLabel"
	label_node.z_index = 200 # No topo absoluto (acima de unidades z=10)
	label_node.z_as_relative = false # Força o Z 200 independente do pai ser -10
	add_child(label_node)
	label_node.draw.connect(_draw_label)

func setup_domain(p_world_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int, p_tile_size: float) -> void:
	self.tile_size = p_tile_size
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
	# --- DESENHA APENAS A ESTRELA (Z = -10) ---
	var upscale = 4.0
	var downscale = 1.0 / upscale
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(downscale, downscale))

	var pts = PackedVector2Array()
	for i in range(13):
		var angle = deg_to_rad(i * 30 - 30)
		var r = (outer_r if i % 2 != 0 else inner_r) * upscale
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	
	# Efeito de brilho
	draw_polyline(pts, Color(1, 1, 1, 0.2), 16.0 * upscale, true)
	draw_polyline(pts, Color(1, 1, 1, 0.4), 10.0 * upscale, true)
	draw_polyline(pts, Color(1, 1, 1, 0.7), 6.0 * upscale, true)
	draw_polyline(pts, entity_color, 4.0 * upscale, true)
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_label() -> void:
	# --- DESENHA APENAS O TEXTO (Z = 200) ---
	if not high_res_font: return
	
	var upscale = 4.0
	var downscale = 1.0 / upscale
	label_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2(downscale, downscale))

	var text = "DOMAIN"
	var font_size = 56 
	var text_size = high_res_font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	
	# Flutuando um pouco acima da ponta da estrela
	var text_pos = Vector2(-text_size.x / 2.0, (outer_r * upscale) + 20.0)
	
	# Outline em 8 direções para legibilidade total
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