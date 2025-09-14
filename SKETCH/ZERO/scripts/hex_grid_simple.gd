## HexGrid Simple
## 
## Versão simplificada do grid hexagonal para compatibilidade
##
## @author: V&V Game Studio
## @version: ZERO - STABLE

extends Node2D
class_name HexGridSimple

## Grid system events
signal grid_initialized()

## Exported configuration properties
@export_group("Grid Dimensions")
@export var grid_width: int = 25
@export var grid_height: int = 18

@export_group("Hexagon Properties")
@export var hex_size: float = 35.0
@export var hex_color: Color = Color.WHITE
@export var border_color: Color = Color.BLACK
@export var border_width: float = 2.0

@export_group("Star Properties")
@export var dot_radius: float = 6.0
@export var dot_color: Color = Color.WHITE
@export var dot_star_size: float = 3.0

@export_group("Diamond Properties")
@export var diamond_width: float = 35.0
@export var diamond_height: float = 60.0
@export var diamond_color: Color = Color.GREEN

@export_group("Global Transform")
@export var grid_rotation_degrees: float = 30.0

@export_group("Performance")
@export var enable_culling: bool = true
@export var show_debug_info: bool = false

## State management
var is_initialized: bool = false

## Cached positions
var hex_positions: Array[Vector2] = []
var dot_positions: Array[Vector2] = []
var diamond_geometry: Array[PackedVector2Array] = []
var diamond_colors: Array[Color] = []

## Initialize the grid system
func _ready() -> void:
	_build_cache()
	is_initialized = true
	grid_initialized.emit()
	print("HexGridSimple: Initialized successfully")

## Build cache of positions and geometry
func _build_cache() -> void:
	hex_positions.clear()
	dot_positions.clear()
	diamond_geometry.clear()
	diamond_colors.clear()
	
	var hex_width = hex_size * 2.0
	var hex_height = hex_size * sqrt(3.0)
	
	for row in range(grid_height):
		for col in range(grid_width):
			var x = col * hex_width * 0.75
			var y = row * hex_height
			
			# Offset every other row
			if row % 2 == 1:
				x += hex_width * 0.375
			
			var hex_center = Vector2(x, y)
			hex_positions.append(hex_center)
			
			# Create star position (center of hex)
			dot_positions.append(hex_center)
			
			# Create diamond geometry
			var diamond_points = _create_diamond_geometry(hex_center)
			diamond_geometry.append(diamond_points)
			
			# Assign diamond color
			var color_index = (row * grid_width + col) % 4
			match color_index:
				0: diamond_colors.append(Color(0.0, 1.0, 0.0))  # Light green
				1: diamond_colors.append(Color(0.0, 0.5, 0.0))  # Dark green
				2: diamond_colors.append(Color(0.0, 1.0, 1.0))  # Cyan
				3: diamond_colors.append(Color(0.4, 0.4, 0.4))  # Gray

## Create diamond geometry for a hex center
func _create_diamond_geometry(center: Vector2) -> PackedVector2Array:
	var points = PackedVector2Array()
	var half_width = diamond_width * 0.5
	var half_height = diamond_height * 0.5
	
	points.append(center + Vector2(0, -half_height))  # Top
	points.append(center + Vector2(half_width, 0))    # Right
	points.append(center + Vector2(0, half_height))   # Bottom
	points.append(center + Vector2(-half_width, 0))   # Left
	
	return points

## Main drawing function
func _draw() -> void:
	if not is_initialized:
		return
	
	# Apply rotation
	var transform = Transform2D()
	transform = transform.rotated(deg_to_rad(grid_rotation_degrees))
	
	# Draw diamonds
	for i in range(diamond_geometry.size()):
		var geometry = diamond_geometry[i]
		var color = diamond_colors[i]
		
		# Transform points
		var transformed_points = PackedVector2Array()
		for point in geometry:
			transformed_points.append(transform * point)
		
		draw_colored_polygon(transformed_points, color)
	
	# Draw stars (dots)
	for dot_pos in dot_positions:
		var transformed_pos = transform * dot_pos
		draw_circle(transformed_pos, dot_radius, dot_color)
	
	# Draw hexagon outlines if enabled
	if border_width > 0:
		for hex_pos in hex_positions:
			var hex_vertices = _calculate_hex_vertices(hex_pos, hex_size)
			for i in range(6):
				var start = transform * hex_vertices[i]
				var end = transform * hex_vertices[(i + 1) % 6]
				draw_line(start, end, border_color, border_width)

## Calculate hexagon vertices
func _calculate_hex_vertices(center: Vector2, size: float) -> Array[Vector2]:
	var vertices: Array[Vector2] = []
	for i in range(6):
		var angle = deg_to_rad(60.0 * i)
		var vertex = center + Vector2(cos(angle), sin(angle)) * size
		vertices.append(vertex)
	return vertices

## Get hexagon at world position
func get_hexagon_at_position(world_pos: Vector2) -> int:
	if not is_initialized:
		return -1
	
	var min_distance = INF
	var closest_index = -1
	
	for i in range(hex_positions.size()):
		var distance = world_pos.distance_to(hex_positions[i])
		if distance < hex_size and distance < min_distance:
			min_distance = distance
			closest_index = i
	
	return closest_index

## Get dot at world position
func get_dot_at_position(world_pos: Vector2) -> int:
	if not is_initialized:
		return -1
	
	for i in range(dot_positions.size()):
		var distance = world_pos.distance_to(dot_positions[i])
		if distance <= dot_radius:
			return i
	
	return -1

## Force redraw
func redraw_grid() -> void:
	queue_redraw()

## Get cached positions for external use
func get_hex_positions() -> Array[Vector2]:
	return hex_positions

func get_dot_positions() -> Array[Vector2]:
	return dot_positions