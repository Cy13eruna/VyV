# res://src/systems/entities/Domain.gd
extends Node2D

var color: Color
var outer_r: float
var inner_r: float
var font: Font

func _ready() -> void:
	# Carrega a fonte padrão do sistema para garantir que o texto apareça
	font = ThemeDB.fallback_font

func setup(p_pos: Vector2, p_color: Color, p_tile_size: float):
	self.global_position = p_pos
	self.color = p_color
	self.z_index = 0 
	
	# Mantendo a calibração de precisão anterior
	self.outer_r = p_tile_size * 0.92
	self.inner_r = p_tile_size * 0.55
	
	queue_redraw()

func _draw():
	# 1. Desenho da Estrela (Geometria do Domínio)
	var pts = PackedVector2Array()
	for i in range(12):
		# Alinhamento Flat-top (-30 graus)
		var angle = deg_to_rad(i * 30 - 30)
		var r = outer_r if i % 2 != 0 else inner_r
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	
	pts.append(pts[0])
	draw_polyline(pts, color, 4.0, true)
	
	# 3. Desenho dos dizeres "DOMAIN"
	var text = "DOMAIN"
	var font_size = 14
	# Calcula a largura do texto para centralizar perfeitamente
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	
	# Posicionamento: Logo abaixo do raio externo (outer_r)
	# O offset Y (outer_r + 10) garante que não sobreponha a ponta da estrela
	var text_pos = Vector2(-text_size.x / 2, outer_r + 10)
	
	# Desenha uma sombra leve para leitura sobre qualquer terreno
	draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)
	# Desenha o texto principal
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)