# res://src/systems/entities/Domain.gd
# PLANO B: Usar o caminho direto do arquivo para garantir que a base seja encontrada
extends "res://src/systems/entities/MapEntity.gd"

# --- PROPRIEDADES ESPECÍFICAS ---
var outer_r: float
var inner_r: float
var font: Font
var tile_size: float = 64.0

func _ready() -> void:
	font = ThemeDB.fallback_font
	self.z_index = 5
	
	# Conexão segura ao Autoload de Sinais
	if Signals.has_signal("domains_visibility_updated"):
		if not Signals.domains_visibility_updated.is_connected(_on_visibility_updated):
			Signals.domains_visibility_updated.connect(_on_visibility_updated)

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
	if not font: return
	
	# 1. Desenho da Estrela (usando entity_color da classe pai)
	var pts = PackedVector2Array()
	for i in range(13):
		var angle = deg_to_rad(i * 30 - 30)
		var r = outer_r if i % 2 != 0 else inner_r
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	
	draw_polyline(pts, entity_color, 4.0, true)
	
	# 2. Desenho do Texto "DOMAIN"
	var text = "DOMAIN"
	var font_size = 14
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = Vector2(-text_size.x / 2, outer_r)
	
	draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, entity_color)