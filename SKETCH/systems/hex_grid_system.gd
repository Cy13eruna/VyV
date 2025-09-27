extends Node

# Hexagonal grid generation and coordinate system
# Handles hex grid creation, coordinate conversion, and pathfinding

signal grid_generated(points_count: int, paths_count: int)

# Generate complete hexagonal grid with specified radius
static func generate_hex_grid(radius: int = 3, hex_size: float = 40.0, hex_center: Vector2 = Vector2(400, 300)) -> Dictionary:
	var points = []
	var hex_coords = []
	var paths = []
	
	print("🔷 Generating hexagonal grid (radius: %d)..." % radius)
	
	# Generate points in axial coordinates
	var point_id = 0
	for r in range(radius + 1):  # Radius 0 to specified radius
		if r == 0:
			# Center point
			hex_coords.append(Vector2(0, 0))
			points.append(hex_to_pixel(0, 0, hex_size, hex_center))
			point_id += 1
		else:
			# Points around center in rings
			for i in range(6):  # 6 directions
				for j in range(r):  # Points along each direction
					var q = get_hex_direction(i).x * (r - j) + get_hex_direction((i + 1) % 6).x * j
					var r_coord = get_hex_direction(i).y * (r - j) + get_hex_direction((i + 1) % 6).y * j
					hex_coords.append(Vector2(q, r_coord))
					points.append(hex_to_pixel(q, r_coord, hex_size, hex_center))
					point_id += 1
	
	# Generate paths connecting neighbors
	paths = generate_hex_paths(hex_coords, points)
	
	print("✨ Hexagonal grid generated: %d points, %d paths" % [points.size(), paths.size()])
	
	return {
		"points": points,
		"hex_coords": hex_coords,
		"paths": paths,
		"total_points": points.size(),
		"total_paths": paths.size()
	}

# Convert axial coordinates to pixel position (with 60° rotation)
static func hex_to_pixel(q: float, r: float, hex_size: float = 40.0, hex_center: Vector2 = Vector2(400, 300)) -> Vector2:
	# Original hexagonal coordinates
	var x = hex_size * (3.0/2.0 * q)
	var y = hex_size * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r)
	
	# Apply 60° rotation (pi/3 radians)
	var angle = PI / 3.0  # 60 degrees
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	
	var rotated_x = x * cos_angle - y * sin_angle
	var rotated_y = x * sin_angle + y * cos_angle
	
	return hex_center + Vector2(rotated_x, rotated_y)

# Get hexagonal direction vector for specified direction (0-5)
static func get_hex_direction(direction: int) -> Vector2:
	var directions = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	return directions[direction % 6]

# Generate paths connecting neighboring hexagonal points
static func generate_hex_paths(hex_coords: Array, points: Array) -> Array:
	var paths = []
	var path_set = {}  # To avoid duplicates
	
	for i in range(hex_coords.size()):
		var coord = hex_coords[i]
		# Check all 6 hexagonal neighbors
		for dir in range(6):
			var neighbor_coord = coord + get_hex_direction(dir)
			var neighbor_index = find_hex_coord_index(neighbor_coord, hex_coords)
			
			if neighbor_index != -1:
				# Create unique ID for path (always smaller index first)
				var path_id = "%d_%d" % [min(i, neighbor_index), max(i, neighbor_index)]
				
				if not path_set.has(path_id):
					var field_type = GameConstants.EdgeType.FIELD if GameConstants else 0  # Default to FIELD
					paths.append({"points": [i, neighbor_index], "type": field_type})
					path_set[path_id] = true
	
	return paths

# Find index of hexagonal coordinate in array
static func find_hex_coord_index(coord: Vector2, hex_coords: Array) -> int:
	for i in range(hex_coords.size()):
		if hex_coords[i].is_equal_approx(coord):
			return i
	return -1

# Get outer points at specified radius
static func get_outer_points(hex_coords: Array, radius: int = 3) -> Array[int]:
	var outer_points: Array[int] = []
	for i in range(hex_coords.size()):
		var coord = hex_coords[i]
		var distance = max(abs(coord.x), abs(coord.y), abs(-coord.x - coord.y))
		if distance == radius:
			outer_points.append(i)
	return outer_points

# Get map corners (points with only 3 connections)
static func get_map_corners(paths: Array, total_points: int) -> Array[int]:
	var corners: Array[int] = []
	
	# Count paths connected to each point
	for i in range(total_points):
		var path_count = 0
		
		# Count how many paths connect to this point
		for path in paths:
			var path_points = path.points
			if path_points[0] == i or path_points[1] == i:
				path_count += 1
		
		# Hexagon corners have only 3 paths
		if path_count == 3:
			corners.append(i)
	
	return corners

# Calculate distance between two hexagonal coordinates
static func hex_distance(coord1: Vector2, coord2: Vector2) -> int:
	return int((abs(coord1.x - coord2.x) + abs(coord1.x + coord1.y - coord2.x - coord2.y) + abs(coord1.y - coord2.y)) / 2)

# Get all neighbors of a hexagonal coordinate
static func get_hex_neighbors(coord: Vector2) -> Array[Vector2]:
	var neighbors: Array[Vector2] = []
	for dir in range(6):
		neighbors.append(coord + get_hex_direction(dir))
	return neighbors

# Check if coordinate is within specified radius from center
static func is_within_radius(coord: Vector2, radius: int) -> bool:
	var distance = max(abs(coord.x), abs(coord.y), abs(-coord.x - coord.y))
	return distance <= radius

# Get ring of coordinates at specified distance from center
static func get_hex_ring(center: Vector2, radius: int) -> Array[Vector2]:
	var ring: Array[Vector2] = []
	if radius == 0:
		ring.append(center)
		return ring
	
	var coord = center + get_hex_direction(4) * radius  # Start from direction 4
	for dir in range(6):
		for step in range(radius):
			ring.append(coord)
			coord = coord + get_hex_direction(dir)
	
	return ring

# Get all coordinates within specified radius (filled hexagon)
static func get_hex_area(center: Vector2, radius: int) -> Array[Vector2]:
	var area: Array[Vector2] = []
	for r in range(radius + 1):
		var ring = get_hex_ring(center, r)
		area.append_array(ring)
	return area

# Convert pixel position back to hexagonal coordinates (approximate)
static func pixel_to_hex(pixel: Vector2, hex_size: float = 40.0, hex_center: Vector2 = Vector2(400, 300)) -> Vector2:
	# Reverse the rotation and conversion
	var relative_pos = pixel - hex_center
	
	# Reverse 60° rotation
	var angle = -PI / 3.0  # -60 degrees
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	
	var unrotated_x = relative_pos.x * cos_angle - relative_pos.y * sin_angle
	var unrotated_y = relative_pos.x * sin_angle + relative_pos.y * cos_angle
	
	# Convert back to axial coordinates
	var q = (2.0/3.0 * unrotated_x) / hex_size
	var r = (-1.0/3.0 * unrotated_x + sqrt(3.0)/3.0 * unrotated_y) / hex_size
	
	return Vector2(round(q), round(r))

# Get grid statistics
static func get_grid_stats(radius: int) -> Dictionary:
	var total_points = 1  # Center point
	for r in range(1, radius + 1):
		total_points += 6 * r  # Each ring has 6*r points
	
	var total_paths = 0
	for r in range(radius + 1):
		if r == 0:
			total_paths += 0  # Center has no internal paths
		else:
			total_paths += 6 * r  # Each ring connects to inner ring
	
	# Add connections within rings
	total_paths += 6 * radius  # Outer ring connections
	
	return {
		"radius": radius,
		"total_points": total_points,
		"estimated_paths": total_paths * 3,  # Rough estimate
		"corner_points": 6,
		"center_point": 1,
		"ring_points": total_points - 1
	}