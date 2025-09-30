# 🔢 HEX MATH MODULE
# Mathematical utilities for hexagonal grids
class_name HexMath
extends RefCounted

# Calculate distance between two hexagonal coordinates
static func hex_distance(coord1: Vector2, coord2: Vector2) -> int:
	var dq = abs(coord1.x - coord2.x)
	var dr = abs(coord1.y - coord2.y)
	var ds = abs(coord1.x + coord1.y - coord2.x - coord2.y)
	return int(max(dq, max(dr, ds)))

# Calculate distance between two points by their indices
static func hex_distance_by_index(hex_coords: Array, index1: int, index2: int) -> int:
	if not GameHelpers.is_valid_index(hex_coords, index1) or not GameHelpers.is_valid_index(hex_coords, index2):
		return -1
	
	return hex_distance(hex_coords[index1], hex_coords[index2])

# Get all points within a certain distance from a center point
static func get_points_within_distance(hex_coords: Array, center_index: int, max_distance: int) -> Array[int]:
	var result: Array[int] = []
	
	if not GameHelpers.is_valid_index(hex_coords, center_index):
		return result
	
	var center_coord = hex_coords[center_index]
	
	for i in range(hex_coords.size()):
		if hex_distance(center_coord, hex_coords[i]) <= max_distance:
			result.append(i)
	
	return result

# Check if two points are adjacent (distance = 1)
static func are_adjacent(hex_coords: Array, index1: int, index2: int) -> bool:
	return hex_distance_by_index(hex_coords, index1, index2) == 1

# Get ring of points at specific distance from center
static func get_ring_at_distance(hex_coords: Array, center_index: int, distance: int) -> Array[int]:
	var result: Array[int] = []
	
	if not GameHelpers.is_valid_index(hex_coords, center_index):
		return result
	
	var center_coord = hex_coords[center_index]
	
	for i in range(hex_coords.size()):
		if hex_distance(center_coord, hex_coords[i]) == distance:
			result.append(i)
	
	return result

# Convert axial coordinates to cube coordinates
static func axial_to_cube(coord: Vector2) -> Vector3:
	var q = coord.x
	var r = coord.y
	var s = -q - r
	return Vector3(q, r, s)

# Convert cube coordinates to axial coordinates
static func cube_to_axial(cube: Vector3) -> Vector2:
	return Vector2(cube.x, cube.y)

# Round floating point hex coordinates to nearest hex
static func hex_round(coord: Vector2) -> Vector2:
	var cube = axial_to_cube(coord)
	var rounded_cube = cube_round(cube)
	return cube_to_axial(rounded_cube)

# Round cube coordinates
static func cube_round(cube: Vector3) -> Vector3:
	var rounded_q = round(cube.x)
	var rounded_r = round(cube.y)
	var rounded_s = round(cube.z)
	
	var q_diff = abs(rounded_q - cube.x)
	var r_diff = abs(rounded_r - cube.y)
	var s_diff = abs(rounded_s - cube.z)
	
	if q_diff > r_diff and q_diff > s_diff:
		rounded_q = -rounded_r - rounded_s
	elif r_diff > s_diff:
		rounded_r = -rounded_q - rounded_s
	else:
		rounded_s = -rounded_q - rounded_r
	
	return Vector3(rounded_q, rounded_r, rounded_s)