# res://src/systems/entities/Domain.gd
# PLANO B: Usar o caminho direto do arquivo para garantir que a base seja encontrada
extends "res://src/systems/entities/MapEntity.gd"

# --- PROPRIEDADES ESPECÍFICAS ---
var outer_r: float
var inner_r: float
var tile_size: float = 64.0

# Usamos SystemFont para forçar o MSDF via código e manter tudo nítido
var high_res_font: SystemFont

func _ready() -> void:
	_setup_high_res_font()
	self.z_index = 5
	
	# Mudamos para LINEAR para suavizar as bordas da estrela e do texto no zoom
	self.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	# Conexão segura ao Autoload de Sinais
	if Signals.has_signal("domains_visibility_updated"):
		if not Signals.domains_visibility_updated.is_connected(_on_visibility_updated):
			Signals.domains_visibility_updated.connect(_on_visibility_updated)

func _setup_high_res_font() -> void:
	high_res_font = SystemFont.new()
	# Ativa o modo matemático vetorial MSDF
	high_res_font.multichannel_signed_distance_field = true
	high_res_font.msdf_pixel_range = 16
	high_res_font.msdf_size = 128 # Máxima qualidade possível para zooms extremos
	
	high_res_font.set_antialiasing(1) # 1 = Grayscale
	high_res_font.generate_mipmaps = true

## Override do setup para incluir o tile_size
func setup_domain(p_world_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int, p_tile_size: float) -> void:
	self.tile_size = p_tile_size
	# super.setup chama o método em MapEntity.gd
	super.setup(p_world_pos, p_grid_pos, p_color, p_owner_id)

## Implementação do método virtual definido em MapEntity
func _apply_visuals() -> void:
	self.outer_r = tile_size * 0.92
	self.inner_r = tile_size * 0.55
	queue_redraw()

## Atualiza visibilidade com base no Fog of War/Memória
func _on_visibility_updated(visible_domains: Array) -> void:
	var is_visible_to_player = false
	
	for d_data in visible_domains:
		if d_data.has("pos") and d_data.pos.distance_to(self.global_position) < 5.0:
			is_visible_to_player = true
			break
	
	self.visible = is_visible_to_player

func _draw() -> void:
	if not high_res_font: return
	
	# 1. Desenho da Estrela (Usando entity_color da classe pai)
	var pts = PackedVector2Array()
	for i in range(13):
		var angle = deg_to_rad(i * 30 - 30)
		var r = outer_r if i % 2 != 0 else inner_r
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	
	# Desenhamos uma sombra de fundo preta para a linha da estrela
	draw_polyline(pts, Color(0, 0, 0, 0.6), 5.0, true)
	# Linha principal (antialiased = true impede o serrilhado da geometria)
	draw_polyline(pts, entity_color, 3.0, true)
	
	# 2. Desenho do Texto "DOMAIN" (Super-amostrado para o Zoom)
	var text = "DOMAIN"
	var font_size = 56 # Tamanho original 14 * 4
	var scale_factor = 0.25
	
	# Mede a string no tamanho gigante
	var text_size = high_res_font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	
	# Calcula a posição aplicando o fator de redução
	var text_pos = Vector2(-text_size.x * scale_factor / 2.0, outer_r + 5.0)
	
	# Dizemos ao motor para renderizar tudo o que vier a seguir na escala 0.25x
	draw_set_transform(text_pos, 0.0, Vector2(scale_factor, scale_factor))
	
	# Sombra do texto (Afastamos 4px porque na escala 0.25 representará 1px real)
	draw_string(high_res_font, Vector2(4, 4), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, 0.8))
	
	# Texto principal (Desenhado no zero relativo ao transform que setamos acima)
	draw_string(high_res_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, entity_color)
	
	# Sempre resetamos o transform ao final para não quebrar outros desenhos do motor!
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)