extends Node2D
class_name HexGrid

@export var hex_size: float = 50.0
@export var grid_width: int = 15
@export var grid_height: int = 10
@export var hex_color: Color = Color.WHITE
@export var border_color: Color = Color.BLACK
@export var border_width: float = 2.0
@export var dot_radius: float = 6.0
@export var dot_color: Color = Color.BLACK
@export var line_width: float = 2.0
@export var line_color: Color = Color.BLACK

var hex_positions: Array[Vector2] = []
var all_dots: Array[Vector2] = []  # Todas as bolinhas (vértices + centros)

func _ready():
	generate_hex_grid()

func _draw():
	draw_hex_grid()

func generate_hex_grid():
	hex_positions.clear()
	all_dots.clear()
	
	# Cálculos precisos para encaixe perfeito
	var hex_width = hex_size * sqrt(3.0)  # Largura real do hexágono flat-top
	var hex_height = hex_size * 2.0       # Altura real do hexágono
	var horizontal_spacing = hex_width     # Espaçamento horizontal sem gaps
	var vertical_spacing = hex_height * 0.75  # Espaçamento vertical para encaixe
	
	for row in range(grid_height):
		for col in range(grid_width):
			var x = col * horizontal_spacing
			var y = row * vertical_spacing
			
			# Offset para linhas ímpares (encaixe perfeito)
			if row % 2 == 1:
				x += horizontal_spacing * 0.5
			
			var center = Vector2(x, y)
			hex_positions.append(center)
			
			# Adicionar centro à lista de pontos
			all_dots.append(center)
			
			# Adicionar vértices à lista de pontos
			for i in range(6):
				var angle = deg_to_rad(60 * i - 30)
				var vertex_pos = center + Vector2(cos(angle), sin(angle)) * hex_size
				all_dots.append(vertex_pos)

func draw_hex_grid():
	# Desenhar linhas conectando pontos adjacentes
	draw_connections()
	
	# Desenhar todas as bolinhas
	for dot_pos in all_dots:
		draw_circle(dot_pos, dot_radius, dot_color)

func draw_hexagon(center: Vector2, size: float, fill_color: Color, stroke_color: Color, stroke_width: float):
	var points: PackedVector2Array = []
	
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		var point = center + Vector2(cos(angle), sin(angle)) * size
		points.append(point)
	
	if fill_color.a > 0:
		draw_colored_polygon(points, fill_color)
	
	if stroke_width > 0 and stroke_color.a > 0:
		for i in range(6):
			var start = points[i]
			var end = points[(i + 1) % 6]
			draw_line(start, end, stroke_color, stroke_width)

func draw_hex_vertices(center: Vector2, size: float):
	# Desenha bolinhas nos 6 vértices do hexágono
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		var vertex_pos = center + Vector2(cos(angle), sin(angle)) * size
		draw_circle(vertex_pos, dot_radius, dot_color)

func draw_connections():
	# Conecta cada ponto aos seus 6 vizinhos mais próximos
	var connection_distance = hex_size * 1.1  # Distância máxima para conexão
	
	for i in range(all_dots.size()):
		var dot_a = all_dots[i]
		var connections_made = 0
		
		for j in range(all_dots.size()):
			if i == j or connections_made >= 6:
				continue
				
			var dot_b = all_dots[j]
			var distance = dot_a.distance_to(dot_b)
			
			# Conectar se estiver dentro da distância e não passou de 6 conexões
			if distance <= connection_distance:
				draw_line(dot_a, dot_b, line_color, line_width)
				connections_made += 1