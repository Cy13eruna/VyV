## HexGridGeometry
## 
## Handles all geometric calculations for the hexagonal grid system.
## Provides optimized mathematical functions for hexagon positioning,
## vertex calculations, rotations, and spatial relationships.
##
## @author: V&V Game Studio
## @version: 2.0

class_name HexGridGeometry
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Mathematical constants for hexagon calculations
const SQRT_3: float = 1.732050807568877
const HEX_ANGLE_STEP: float = 60.0  # Degrees between hexagon vertices
const FLAT_TOP_OFFSET: float = -30.0  # Offset for flat-top hexagons

## Cached trigonometric values for performance
var cached_cos: Array[float] = []
var cached_sin: Array[float] = []
var _cos_cache: Array[float] = []
var _sin_cache: Array[float] = []
var _is_trig_cache_built: bool = false

## Initialize geometry calculator
func _init():
	_build_trigonometric_cache()

## Calculate hexagon grid positions in hexagonal pattern
## @param config: Configuration object with grid parameters
## @return Array[Vector2]: Array of hexagon center positions
func calculate_hex_positions(config) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	
	# Use grid_width as the radius of the hexagonal pattern
	var hex_radius = config.grid_width
	
	# Precise calculations for perfect hexagon tiling
	var hex_width = config.hex_size * SQRT_3  # Width of flat-top hexagon
	var hex_height = config.hex_size * 2.0    # Height of flat-top hexagon
	var horizontal_spacing = hex_width
	var vertical_spacing = hex_height * 0.75  # 75% overlap for tiling
	
	# Generate hexagonal pattern using complete coordinate iteration
	# This ensures no gaps by checking all valid positions
	for q in range(-hex_radius + 1, hex_radius):
		var r1 = max(-hex_radius + 1, -q - hex_radius + 1)
		var r2 = min(hex_radius - 1, -q + hex_radius - 1)
		
		for r in range(r1, r2 + 1):
			# Convert axial coordinates (q, r) to pixel coordinates
			var x = horizontal_spacing * (q + r * 0.5)
			var y = vertical_spacing * r
			
			positions.append(Vector2(x, y))
	
	Logger.debug("Generated %d hexagons in hexagonal pattern (radius %d)" % [positions.size(), hex_radius], "HexGridGeometry")
	return positions

## Calculate all dot positions (hexagon centers + vertices)
## @param hex_positions Array[Vector2]: Hexagon center positions
## @param hex_size float: Size of hexagons
## @return Array[Vector2]: All dot positions for stars and connections
func calculate_all_dot_positions(hex_positions: Array[Vector2], hex_size: float) -> Array[Vector2]:
	var all_dots: Array[Vector2] = []
	var vertex_set: Dictionary = {}  # Use dictionary to avoid duplicate vertices
	
	# Add all hexagon centers first
	for center in hex_positions:
		all_dots.append(center)
	
	# Add all unique vertices with more precise rounding
	for center in hex_positions:
		var vertices = calculate_hex_vertices(center, hex_size)
		for vertex in vertices:
			# Use more precise rounding to avoid losing vertices
			var rounded_vertex = Vector2(round(vertex.x * 10) / 10, round(vertex.y * 10) / 10)
			var key = str(rounded_vertex.x) + "," + str(rounded_vertex.y)
			if not vertex_set.has(key):
				vertex_set[key] = true
				all_dots.append(vertex)
	
	Logger.debug("Generated %d total dots (%d hex centers + %d unique vertices)" % [all_dots.size(), hex_positions.size(), all_dots.size() - hex_positions.size()], "HexGridGeometry")
	return all_dots

## Calculate vertices of a single hexagon
## @param center Vector2: Center position of the hexagon
## @param size float: Size (radius) of the hexagon
## @return Array[Vector2]: Six vertex positions
func calculate_hex_vertices(center: Vector2, size: float) -> Array[Vector2]:
	var vertices: Array[Vector2] = []
	
	for i in range(6):
		var angle_deg = HEX_ANGLE_STEP * i + FLAT_TOP_OFFSET
		var angle_rad = deg_to_rad(angle_deg)
		var vertex = center + Vector2(cos(angle_rad), sin(angle_rad)) * size
		vertices.append(vertex)
	
	return vertices

## Calculate diamond geometry for connection between two points
## @param point_a Vector2: First connection point
## @param point_b Vector2: Second connection point
## @return PackedVector2Array: Diamond vertices in drawing order
func calculate_diamond_geometry(point_a: Vector2, point_b: Vector2) -> PackedVector2Array:
	var direction = (point_b - point_a).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	var distance = point_a.distance_to(point_b)
	
	# Sharp vertices touch the connection points
	var tip_a = point_a
	var tip_b = point_b
	
	# Calculate optimal width for perfect tiling
	var optimal_width = distance * 0.6  # 60% of distance for good fit
	var half_width = optimal_width / 2.0
	
	# Center of the diamond
	var center = (point_a + point_b) / 2.0
	
	# Obtuse vertices positioned for seamless connections
	var side_left = center + perpendicular * half_width
	var side_right = center - perpendicular * half_width
	
	return PackedVector2Array([tip_a, side_left, tip_b, side_right])

## Calculate six-pointed star geometry
## @param center Vector2: Center position of the star
## @param outer_radius float: Radius of outer points
## @param inner_radius float: Radius of inner points
## @return PackedVector2Array: Star vertices in drawing order
func calculate_star_geometry(center: Vector2, outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	
	# Create a proper 6-pointed star (Star of David)
	for i in range(12):  # 6 outer + 6 inner points
		var angle_deg = 30.0 * i  # 30 degrees between each point
		var angle_rad = deg_to_rad(angle_deg)
		var radius = outer_radius if i % 2 == 0 else inner_radius
		var point = center + Vector2(cos(angle_rad), sin(angle_rad)) * radius
		points.append(point)
	
	return points

## Apply rotation to a point around a center
## @param point Vector2: Point to rotate
## @param center Vector2: Center of rotation
## @param angle_rad float: Rotation angle in radians
## @return Vector2: Rotated point
func rotate_point_around_center(point: Vector2, center: Vector2, angle_rad: float) -> Vector2:
	# Use cached trigonometric values for better performance
	var cos_angle = cos(angle_rad)
	var sin_angle = sin(angle_rad)
	
	# Translate to origin
	var translated = point - center
	
	# Apply rotation matrix
	var rotated = Vector2(
		translated.x * cos_angle - translated.y * sin_angle,
		translated.x * sin_angle + translated.y * cos_angle
	)
	
	# Translate back
	return rotated + center

## Apply global rotation to all positions
## @param positions Array[Vector2]: Positions to rotate
## @param center Vector2: Center of rotation
## @param angle_degrees float: Rotation angle in degrees
## @return Array[Vector2]: Rotated positions
func apply_global_rotation(positions: Array[Vector2], center: Vector2, angle_degrees: float) -> Array[Vector2]:
	var rotated_positions: Array[Vector2] = []
	var angle_rad = deg_to_rad(angle_degrees)
	
	for position in positions:
		rotated_positions.append(rotate_point_around_center(position, center, angle_rad))
	
	return rotated_positions

## Calculate center point of a collection of positions
## @param positions Array[Vector2]: Positions to find center of
## @return Vector2: Geometric center point
func calculate_center(positions: Array[Vector2]) -> Vector2:
	if positions.is_empty():
		return Vector2.ZERO
	
	var sum_pos = Vector2.ZERO
	for pos in positions:
		sum_pos += pos
	
	return sum_pos / positions.size()

## Find nearby points within a given distance using spatial optimization
## @param target_position Vector2: Position to search around
## @param all_positions Array[Vector2]: All positions to search through
## @param max_distance float: Maximum search distance
## @return Array[int]: Indices of nearby positions
func find_nearby_positions(target_position: Vector2, all_positions: Array[Vector2], max_distance: float) -> Array[int]:
	var nearby_indices: Array[int] = []
	var max_distance_squared = max_distance * max_distance  # Avoid sqrt in distance check
	
	for i in range(all_positions.size()):
		var distance_squared = target_position.distance_squared_to(all_positions[i])
		if distance_squared <= max_distance_squared:
			nearby_indices.append(i)
	
	return nearby_indices

## Check if a point is within the visible area (for culling)
## @param point Vector2: Point to check
## @param viewport_rect Rect2: Visible area rectangle
## @param margin float: Additional margin around viewport
## @return bool: True if point should be rendered
func is_point_visible(point: Vector2, viewport_rect: Rect2, margin: float = 0.0) -> bool:
	var expanded_rect = viewport_rect.grow(margin)
	return expanded_rect.has_point(point)

## Calculate bounding rectangle for a set of points
## @param points Array[Vector2]: Points to calculate bounds for
## @return Rect2: Bounding rectangle
func calculate_bounding_rect(points: Array[Vector2]) -> Rect2:
	if points.is_empty():
		return Rect2()
	
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y
	
	for point in points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

## Build trigonometric cache for performance
func _build_trigonometric_cache() -> void:
	if _is_trig_cache_built:
		return
	
	cached_cos.clear()
	cached_sin.clear()
	_cos_cache.clear()
	_sin_cache.clear()
	
	# Pre-calculate common trigonometric values for hexagons
	for i in range(7):  # 0 to 6 for hexagon vertices
		var angle_deg = 60.0 * i
		var angle_rad = deg_to_rad(angle_deg)
		cached_cos.append(cos(angle_rad))
		cached_sin.append(sin(angle_rad))
	
	# Cache values for common angles (every degree from 0 to 360)
	for angle_deg in range(361):
		var angle_rad = deg_to_rad(angle_deg)
		_cos_cache.append(cos(angle_rad))
		_sin_cache.append(sin(angle_rad))
	
	_is_trig_cache_built = true



## Get cached cosine value for integer degree angles
## @param angle_deg int: Angle in degrees (0-360)
## @return float: Cosine value
func get_cached_cos(angle_deg: int) -> float:
	angle_deg = angle_deg % 360
	if angle_deg < 0:
		angle_deg += 360
	return _cos_cache[angle_deg]

## Get cached sine value for integer degree angles
## @param angle_deg int: Angle in degrees (0-360)
## @return float: Sine value
func get_cached_sin(angle_deg: int) -> float:
	angle_deg = angle_deg % 360
	if angle_deg < 0:
		angle_deg += 360
	return _sin_cache[angle_deg]

## Calculate optimal connection distance based on hex size
## @param hex_size float: Size of hexagons
## @return float: Optimal distance for connecting nearby points
func calculate_connection_distance(hex_size: float) -> float:
	return hex_size * 1.1  # Slightly larger than hex size for good connections

## Validate geometric parameters
## @param hex_size float: Hexagon size to validate
## @param grid_width int: Grid width to validate
## @param grid_height int: Grid height to validate
## @return bool: True if parameters are valid for geometry calculations
func validate_parameters(hex_size: float, grid_width: int, grid_height: int) -> bool:
	return hex_size > 0.0 and grid_width > 0 and grid_height > 0