# 📍 COORDINATES MODULE
# Coordinate system utilities for hexagonal grids
class_name Coordinates
extends RefCounted

# Convert screen position to nearest hex coordinate
static func screen_to_hex(screen_pos: Vector2, hex_center: Vector2, hex_size: float) -> Vector2:
	# Reverse the transformations applied in hex_to_pixel
	var relative_pos = screen_pos - hex_center
	
	# Reverse 60° rotation (PI/3 radians)
	var cos_angle = cos(-PI/3)
	var sin_angle = sin(-PI/3)
	var unrotated_x = relative_pos.x * cos_angle - relative_pos.y * sin_angle
	var unrotated_y = relative_pos.x * sin_angle + relative_pos.y * cos_angle
	
	# Reverse 30° rotation (PI/6 radians)
	cos_angle = cos(-PI/6)
	sin_angle = sin(-PI/6)
	var final_x = unrotated_x * cos_angle - unrotated_y * sin_angle
	var final_y = unrotated_x * sin_angle + unrotated_y * cos_angle
	
	# Convert to hex coordinates
	var q = (2.0/3.0 * final_x) / hex_size
	var r = (-1.0/3.0 * final_x + sqrt(3.0)/3.0 * final_y) / hex_size
	
	return HexMath.hex_round(Vector2(q, r))

# Get the corners of a hexagon at given coordinate
static func get_hex_corners(coord: Vector2, hex_center: Vector2, hex_size: float) -> Array[Vector2]:
	var corners: Array[Vector2] = []
	var center = hex_to_pixel_static(coord, hex_center, hex_size)
	
	for i in range(6):
		var angle = PI/3 * i  # 60 degrees per corner
		var corner = center + Vector2(cos(angle), sin(angle)) * hex_size
		corners.append(corner)
	
	return corners

# Static version of hex_to_pixel for utility use
static func hex_to_pixel_static(coord: Vector2, hex_center: Vector2, hex_size: float) -> Vector2:
	var q = coord.x
	var r = coord.y
	
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

# Check if a point is inside a hexagon
static func is_point_in_hex(point: Vector2, hex_coord: Vector2, hex_center: Vector2, hex_size: float) -> bool:
	var hex_center_pixel = hex_to_pixel_static(hex_coord, hex_center, hex_size)
	var distance = point.distance_to(hex_center_pixel)
	return distance <= hex_size

# Get the edge between two adjacent hex coordinates
static func get_edge_between_hexes(coord1: Vector2, coord2: Vector2, hex_center: Vector2, hex_size: float) -> Array[Vector2]:
	if HexMath.hex_distance(coord1, coord2) != 1:
		return []  # Not adjacent
	
	var center1 = hex_to_pixel_static(coord1, hex_center, hex_size)
	var center2 = hex_to_pixel_static(coord2, hex_center, hex_size)
	
	# Find the shared edge by getting the midpoint and perpendicular
	var midpoint = (center1 + center2) * 0.5
	var direction = (center2 - center1).normalized()
	var perpendicular = Vector2(-direction.y, direction.x) * hex_size * 0.5
	
	return [midpoint - perpendicular, midpoint + perpendicular]

# Get all coordinates in a line between two points
static func get_line_coordinates(start_coord: Vector2, end_coord: Vector2) -> Array[Vector2]:
	var distance = HexMath.hex_distance(start_coord, end_coord)
	var results: Array[Vector2] = []
	
	for i in range(distance + 1):
		var t = float(i) / float(distance) if distance > 0 else 0.0
		var lerped = start_coord.lerp(end_coord, t)
		results.append(HexMath.hex_round(lerped))
	
	return results