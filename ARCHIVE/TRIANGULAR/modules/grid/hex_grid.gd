# 🔷 HEX GRID MODULE
# Duplicated and modularized from main_game.gd - DO NOT MODIFY ORIGINAL
class_name HexGrid
extends RefCounted

# Grid data
var points: Array = []
var hex_coords: Array = []  # Axial coordinates (q, r) for each point
var hex_size: float = GameConstants.HEX_SIZE
var hex_center: Vector2 = GameConstants.HEX_CENTER

# Generate expanded hexagonal grid (37 points: radius 3)
func generate_hex_grid() -> void:
	points.clear()
	hex_coords.clear()
	
	var radius = GameConstants.GRID_RADIUS
	
	# Center point
	hex_coords.append(Vector2(0, 0))
	points.append(hex_to_pixel(0, 0))
	
	# Generate points in rings
	for ring in range(1, radius + 1):
		for i in range(6):  # 6 sides of hexagon
			for j in range(ring):  # Points along each side
				var q = hex_direction(i).x * (ring - j) + hex_direction((i + 1) % 6).x * j
				var r = hex_direction(i).y * (ring - j) + hex_direction((i + 1) % 6).y * j
				hex_coords.append(Vector2(q, r))
				points.append(hex_to_pixel(q, r))

# Convert hexagonal coordinates to pixel coordinates
func hex_to_pixel(q: float, r: float) -> Vector2:
	# Flat-top hexagon orientation with 30° rotation (pointy-top)
	var x = hex_size * (3.0/2.0 * q)
	var y = hex_size * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r)
	
	# Apply 30° rotation (PI/6 radians) for pointy-top orientation
	var cos_angle = cos(PI/6)
	var sin_angle = sin(PI/6)
	var rotated_x = x * cos_angle - y * sin_angle
	var rotated_y = x * sin_angle + y * cos_angle
	
	# Apply 60° rotation (PI/3 radians) for board rotation
	cos_angle = cos(PI/3)
	sin_angle = sin(PI/3)
	var final_x = rotated_x * cos_angle - rotated_y * sin_angle
	var final_y = rotated_x * sin_angle + rotated_y * cos_angle
	
	return hex_center + Vector2(final_x, final_y)

# Get hexagonal direction vector
func hex_direction(direction: int) -> Vector2:
	var directions = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	return directions[direction % 6]

# Find index of hexagonal coordinate in the hex_coords array
func find_hex_coord_index(coord: Vector2) -> int:
	for i in range(hex_coords.size()):
		if hex_coords[i] == coord:
			return i
	return -1

# Get adjacent points to a given point
func get_adjacent_points(point_index: int) -> Array[int]:
	if not GameHelpers.is_valid_index(hex_coords, point_index):
		return []
	
	var adjacent: Array[int] = []
	var coord = hex_coords[point_index]
	
	for dir in range(6):
		var neighbor_coord = coord + hex_direction(dir)
		var neighbor_index = find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1:
			adjacent.append(neighbor_index)
	
	return adjacent

# Get all points data
func get_points() -> Array:
	return points.duplicate()

# Get all hex coordinates data
func get_hex_coords() -> Array:
	return hex_coords.duplicate()

# Get specific point position
func get_point_position(index: int) -> Vector2:
	return GameHelpers.safe_get_array_element(points, index, Vector2.ZERO)

# Get specific hex coordinate
func get_hex_coord(index: int) -> Vector2:
	return GameHelpers.safe_get_array_element(hex_coords, index, Vector2.ZERO)

# Get total number of points
func get_point_count() -> int:
	return points.size()

# Check if point index is valid
func is_valid_point_index(index: int) -> bool:
	return GameHelpers.is_valid_index(points, index)