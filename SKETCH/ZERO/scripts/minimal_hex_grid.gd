## MinimalHexGrid
## 
## Grid hexagonal mínimo e funcional para testes de seleção
## Sem dependências complexas, apenas o essencial
##
## @author: V&V Game Studio
## @version: 1.0 - MINIMAL

extends Node2D
class_name MinimalHexGrid

## Grid properties
@export var grid_size: int = 10
@export var hex_radius: float = 30.0

## Hexagon positions
var hex_positions: Array[Vector2] = []
var dot_positions: Array[Vector2] = []
var diamond_positions: Array[Vector2] = []
var diamond_colors: Array[Color] = []

## Initialize
func _ready() -> void:
	_generate_hex_positions()
	_generate_dots_and_diamonds()
	print("MinimalHexGrid: Generated %d hexagons, %d dots, %d diamonds" % [hex_positions.size(), dot_positions.size(), diamond_positions.size()])

## Generate hexagon positions in a simple pattern
func _generate_hex_positions() -> void:
	hex_positions.clear()
	
	var hex_width = hex_radius * sqrt(3)
	var hex_height = hex_radius * 2
	var row_offset = hex_width / 2
	
	for row in range(grid_size):
		for col in range(grid_size):
			var x = col * hex_width
			var y = row * hex_height * 0.75
			
			# Offset every other row
			if row % 2 == 1:
				x += row_offset
			
			hex_positions.append(Vector2(x, y))

## Draw the grid
func _draw() -> void:
	# Draw diamonds first (background)
	for i in range(diamond_positions.size()):
		var center = diamond_positions[i]
		var color = diamond_colors[i] if i < diamond_colors.size() else Color.GREEN
		_draw_diamond(center, hex_radius * 0.3, color)
	
	# Draw hexagon outlines
	for i in range(hex_positions.size()):
		var center = hex_positions[i]
		_draw_hexagon(center, hex_radius, Color.WHITE, 1.0)
	
	# Draw stars (dots) on top
	for dot_pos in dot_positions:
		_draw_star(dot_pos, hex_radius * 0.15, Color.WHITE)

## Draw a single hexagon
func _draw_hexagon(center: Vector2, radius: float, color: Color, width: float) -> void:
	var points: PackedVector2Array = []
	
	for i in range(6):
		var angle = deg_to_rad(60.0 * i - 30.0)
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	# Draw hexagon outline
	for i in range(6):
		var start = points[i]
		var end = points[(i + 1) % 6]
		draw_line(start, end, color, width)

## Get hexagon at position
func get_hexagon_at_position(world_pos: Vector2) -> int:
	var min_distance = INF
	var closest_index = -1
	
	for i in range(hex_positions.size()):
		var distance = world_pos.distance_to(hex_positions[i])
		if distance < hex_radius and distance < min_distance:
			min_distance = distance
			closest_index = i
	
	return closest_index

## Generate dots and diamonds
func _generate_dots_and_diamonds() -> void:
	dot_positions.clear()
	diamond_positions.clear()
	diamond_colors.clear()
	
	# Add hexagon centers as dots
	for hex_pos in hex_positions:
		dot_positions.append(hex_pos)
	
	# Add hexagon vertices as dots
	var vertex_set: Dictionary = {}
	for hex_pos in hex_positions:
		var vertices = _get_hex_vertices(hex_pos, hex_radius)
		for vertex in vertices:
			var key = str(int(vertex.x)) + "," + str(int(vertex.y))
			if not vertex_set.has(key):
				vertex_set[key] = true
				dot_positions.append(vertex)
	
	# Generate diamonds between nearby dots
	for i in range(dot_positions.size()):
		for j in range(i + 1, dot_positions.size()):
			var pos_a = dot_positions[i]
			var pos_b = dot_positions[j]
			var distance = pos_a.distance_to(pos_b)
			
			# Create diamond if dots are close enough
			if distance < hex_radius * 1.2 and distance > hex_radius * 0.3:
				var diamond_center = (pos_a + pos_b) / 2.0
				diamond_positions.append(diamond_center)
				
				# Assign colors based on distance/type
				var color: Color
				var rand = randf()
				if rand < 0.5:  # 50% green (campo)
					color = Color(0.0, 1.0, 0.0, 1.0)  # Verde claro
				elif rand < 0.75:  # 25% dark green (floresta)
					color = Color(0.0, 0.5, 0.0, 1.0)  # Verde escuro
				elif rand < 0.9:  # 15% gray (montanha)
					color = Color(0.5, 0.5, 0.5, 1.0)  # Cinza
				else:  # 10% blue (água)
					color = Color(0.0, 0.5, 1.0, 1.0)  # Azul
				
				diamond_colors.append(color)

## Get hexagon vertices
func _get_hex_vertices(center: Vector2, radius: float) -> Array[Vector2]:
	var vertices: Array[Vector2] = []
	for i in range(6):
		var angle = deg_to_rad(60.0 * i - 30.0)
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		vertices.append(point)
	return vertices

## Draw a diamond
func _draw_diamond(center: Vector2, size: float, color: Color) -> void:
	var points = PackedVector2Array([
		center + Vector2(0, -size),      # Top
		center + Vector2(size, 0),       # Right
		center + Vector2(0, size),       # Bottom
		center + Vector2(-size, 0)       # Left
	])
	draw_colored_polygon(points, color)

## Draw a star
func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = []
	
	# Create 6-pointed star
	for i in range(12):
		var angle = deg_to_rad(30.0 * i)
		var r = radius if i % 2 == 0 else radius * 0.5
		var point = center + Vector2(cos(angle), sin(angle)) * r
		points.append(point)
	
	draw_colored_polygon(points, color)

## Get hex positions
func get_hex_positions() -> Array[Vector2]:
	return hex_positions