# res://src/systems/grid/Sky.gd
extends Node2D

const HexMath = preload("res://src/core/math/HexMath.gd")

@export var star_count: int = 200
@export var star_min_size: float = 1.0
@export var star_max_size: float = 2.5
@export var star_opacity_min: float = 0.1
@export var star_opacity_max: float = 0.7

var star_data: Array = []

func _ready() -> void:
	z_index = -10 # Garante que está atrás de tudo
	_generate_stars()

func _generate_stars() -> void:
	star_data.clear()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Definimos uma área grande para cobrir movimentações de câmera
	var area = Vector2(2500, 1500) 
	
	for i in range(star_count):
		var star = {
			"pos": Vector2(rng.randf_range(-area.x, area.x), rng.randf_range(-area.y, area.y)),
			"size": rng.randf_range(star_min_size, star_max_size),
			"alpha": rng.randf_range(star_opacity_min, star_opacity_max),
			"pulse_speed": rng.randf_range(1.0, 3.0),
			"offset": rng.randf_range(0, PI * 2)
		}
		star_data.append(star)

func _draw() -> void:
	var time = Time.get_ticks_msec() / 1000.0
	
	for star in star_data:
		# Efeito opcional de cintilação (pulso no alpha)
		var pulse = (sin(time * star.pulse_speed + star.offset) + 1.0) * 0.5
		var final_alpha = lerp(star_opacity_min, star.alpha, pulse)
		var color = Color(1, 1, 1, final_alpha)
		
		# Estrela hexagonal
		var tris = HexMath.get_hexagram_triangles(star.pos, star.size, 0.0)
		draw_colored_polygon(tris[0], color)
		draw_colored_polygon(tris[1], color)

func _process(_delta: float) -> void:
	queue_redraw() # Necessário para a animação de brilho