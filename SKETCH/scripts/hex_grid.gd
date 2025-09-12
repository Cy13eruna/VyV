extends Node2D
class_name HexGrid

@export var hex_size: float = 30.0
@export var grid_width: int = 25
@export var grid_height: int = 15
@export var hex_color: Color = Color.CYAN
@export var border_color: Color = Color.BLUE
@export var border_width: float = 2.0

var hex_positions: Array[Vector2] = []

func _ready():
	generate_hex_grid()

func _draw():
	draw_hex_grid()

func generate_hex_grid():
	hex_positions.clear()
	
	var hex_width = hex_size * 2.0
	var hex_height = sqrt(3.0) * hex_size
	var horizontal_spacing = hex_width * 0.75
	var vertical_spacing = hex_height
	
	for row in range(grid_height):
		for col in range(grid_width):
			var x = col * horizontal_spacing
			var y = row * vertical_spacing
			
			if row % 2 == 1:
				x += horizontal_spacing * 0.5
			
			hex_positions.append(Vector2(x, y))

func draw_hex_grid():
	for pos in hex_positions:
		draw_hexagon(pos, hex_size, hex_color, border_color, border_width)

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