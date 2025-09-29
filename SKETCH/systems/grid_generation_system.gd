extends Node

# GridGenerationSystem - Centralized grid generation and coordinate mathematics
# Extracted from main_game.gd as part of Step 12 refactoring

## Initialize the grid generation system
func initialize() -> void:
	print("🔢 GridGenerationSystem initialized and ready")

## Generate hexagonal grid
func generate_hex_grid(radius: int, hex_size: float, hex_center: Vector2) -> Dictionary:
	var points = []
	var hex_coords = []
	var paths = []
	
	# Generate points in axial coordinates
	var point_id = 0
	for grid_radius in range(radius + 1):  # Radius 0 to radius
		if grid_radius == 0:
			# Center
			hex_coords.append(Vector2(0, 0))
			points.append(hex_to_pixel(0, 0, hex_size, hex_center))
			point_id += 1
		else:
			# Points around center
			for i in range(6):  # 6 directions
				for j in range(grid_radius):  # Points along each direction
					var q = hex_direction(i).x * (grid_radius - j) + hex_direction((i + 1) % 6).x * j
					var r = hex_direction(i).y * (grid_radius - j) + hex_direction((i + 1) % 6).y * j
					hex_coords.append(Vector2(q, r))
					points.append(hex_to_pixel(q, r, hex_size, hex_center))
					point_id += 1
	
	# Generate paths connecting neighbors
	paths = generate_hex_paths(hex_coords, points.size())
	
	print("🔢 GridGenerationSystem: Generated %d points, %d paths" % [points.size(), paths.size()])
	
	return {
		"points": points,
		"hex_coords": hex_coords,
		"paths": paths
	}

## Convert axial coordinates to pixel (rotated 60°)
func hex_to_pixel(q: float, r: float, hex_size: float, hex_center: Vector2) -> Vector2:
	# Original coordinates
	var x = hex_size * (3.0/2.0 * q)
	var y = hex_size * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r)
	
	# Apply 60° rotation (pi/3 radians)
	var angle = PI / 3.0  # 60 degrees
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	
	var rotated_x = x * cos_angle - y * sin_angle
	var rotated_y = x * sin_angle + y * cos_angle
	
	return hex_center + Vector2(rotated_x, rotated_y)

## Get hexagonal direction
func hex_direction(direction: int) -> Vector2:
	var directions = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	return directions[direction]

## Generate hexagonal paths
func generate_hex_paths(hex_coords: Array, point_count: int) -> Array:
	var paths = []
	var path_set = {}  # To avoid duplicates
	
	for i in range(hex_coords.size()):
		var coord = hex_coords[i]
		# Check 6 neighbors
		for dir in range(6):
			var neighbor_coord = coord + hex_direction(dir)
			var neighbor_index = find_hex_coord_index(neighbor_coord, hex_coords)
			
			if neighbor_index != -1:
				# Create unique ID for path (always smaller index first)
				var path_id = "%d_%d" % [min(i, neighbor_index), max(i, neighbor_index)]
				
				if not path_set.has(path_id):
					var field_type = GameConstants.EdgeType.FIELD if GameConstants else 0  # EdgeType.FIELD
					paths.append({"points": [i, neighbor_index], "type": field_type})
					path_set[path_id] = true
	
	return paths

## Find hexagonal coordinate index
func find_hex_coord_index(coord: Vector2, hex_coords: Array) -> int:
	for i in range(hex_coords.size()):
		if hex_coords[i].is_equal_approx(coord):
			return i
	return -1

## Calculate hexagonal distance between two coordinates
func hex_distance(coord1: Vector2, coord2: Vector2) -> int:
	# Axial coordinate distance formula
	return int((abs(coord1.x - coord2.x) + abs(coord1.x + coord1.y - coord2.x - coord2.y) + abs(coord1.y - coord2.y)) / 2)

## Detect the six map corners (points with only 3 edges)
func get_map_corners(paths: Array, point_count: int) -> Array:
	var corners = []
	print("🔢 GridGenerationSystem: Detecting corners from %d points..." % point_count)
	
	# Count paths connected to each point
	for i in range(point_count):
		var path_count = 0
		
		# Count how many paths connect to this point
		for path in paths:
			var path_points = path.points
			if path_points[0] == i or path_points[1] == i:
				path_count += 1
		
		# Debug: print all points with their path counts
		if path_count <= 4:  # Only show points with low connectivity
			print("🔢 GridGenerationSystem: Point %d has %d paths" % [i, path_count])
		
		# Hexagon corners have only 3 paths
		if path_count == 3:
			corners.append(i)
			print("🔴 GridGenerationSystem: Found corner %d" % i)
	
	print("🔢 GridGenerationSystem: Total corners found: %d" % corners.size())
	return corners

## Mark map corners for debugging
func mark_map_corners(paths: Array, point_count: int, hex_coords: Array) -> void:
	var corners = get_map_corners(paths, point_count)
	
	print("🔍 GridGenerationSystem: Corners detected: %d points with 3 paths" % corners.size())
	for corner_index in corners:
		if corner_index < hex_coords.size():
			print("  Corner %d: coordinate %s" % [corner_index, hex_coords[corner_index]])

## Analyze grid connectivity for debugging
func analyze_grid_connectivity(points: Array, paths: Array, hex_coords: Array) -> void:
	print("🔍 GridGenerationSystem: GRID ANALYSIS - Analyzing %d points:" % points.size())
	
	# Count points by connectivity
	var connectivity_count = {}
	var point_connectivity = []
	
	for i in range(points.size()):
		var path_count = 0
		for path in paths:
			var path_points = path.points
			if path_points[0] == i or path_points[1] == i:
				path_count += 1
		
		point_connectivity.append({"index": i, "connections": path_count, "coord": hex_coords[i]})
		
		if not connectivity_count.has(path_count):
			connectivity_count[path_count] = 0
		connectivity_count[path_count] += 1
	
	# Print connectivity summary
	print("📊 GridGenerationSystem: Connectivity Summary:")
	for connections in connectivity_count.keys():
		print("  %d connections: %d points" % [connections, connectivity_count[connections]])
	
	# Print corners (3 connections)
	print("🔴 GridGenerationSystem: Corners (3 connections):")
	for point_data in point_connectivity:
		if point_data.connections == 3:
			print("  Point %d: %s" % [point_data.index, point_data.coord])
	
	# Print good domain spots (4+ connections)
	print("🟢 GridGenerationSystem: Good domain spots (4+ connections):")
	for point_data in point_connectivity:
		if point_data.connections >= 4:
			print("  Point %d: %d connections at %s" % [point_data.index, point_data.connections, point_data.coord])
	
	# Print best domain spots (6 connections)
	print("🌟 GridGenerationSystem: Best domain spots (6 connections):")
	for point_data in point_connectivity:
		if point_data.connections == 6:
			print("  Point %d: 6 connections at %s" % [point_data.index, point_data.coord])

## Convert pixel coordinates back to axial coordinates
func pixel_to_hex(pixel: Vector2, hex_size: float, hex_center: Vector2) -> Vector2:
	# Remove center offset
	var local_pixel = pixel - hex_center
	
	# Reverse 60° rotation
	var angle = -PI / 3.0  # -60 degrees
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	
	var unrotated_x = local_pixel.x * cos_angle - local_pixel.y * sin_angle
	var unrotated_y = local_pixel.x * sin_angle + local_pixel.y * cos_angle
	
	# Convert back to axial coordinates
	var q = (2.0/3.0 * unrotated_x) / hex_size
	var r = (-1.0/3.0 * unrotated_x + sqrt(3.0)/3.0 * unrotated_y) / hex_size
	
	return Vector2(round(q), round(r))

## Get all neighbors of a hex coordinate
func get_hex_neighbors(coord: Vector2) -> Array:
	var neighbors = []
	for dir in range(6):
		neighbors.append(coord + hex_direction(dir))
	return neighbors

## Check if a coordinate is within the grid bounds
func is_coord_in_bounds(coord: Vector2, radius: int) -> bool:
	var distance_from_center = hex_distance(Vector2.ZERO, coord)
	return distance_from_center <= radius

## Get all coordinates within a certain radius
func get_coords_in_radius(center: Vector2, radius: int) -> Array:
	var coords = []
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			coords.append(center + Vector2(q, r))
	return coords

## Get ring of coordinates at specific distance
func get_coord_ring(center: Vector2, radius: int) -> Array:
	if radius == 0:
		return [center]
	
	var ring = []
	var coord = center + hex_direction(4) * radius  # Start at "southwest"
	
	for direction in range(6):
		for step in range(radius):
			ring.append(coord)
			coord = coord + hex_direction(direction)
	
	return ring

## Calculate area of hexagonal region
func calculate_hex_area(radius: int) -> int:
	if radius == 0:
		return 1
	return 3 * radius * (radius + 1) + 1

## Get edge length between adjacent points
func get_edge_length(point_index: int, points: Array, hex_coords: Array) -> float:
	# Find an adjacent point and calculate distance
	var point_coord = hex_coords[point_index]
	for dir in range(6):
		var neighbor_coord = point_coord + hex_direction(dir)
		var neighbor_index = find_hex_coord_index(neighbor_coord, hex_coords)
		if neighbor_index != -1 and neighbor_index < points.size():
			# Calculate distance between points
			var distance = points[point_index].distance_to(points[neighbor_index])
			return distance
	
	# Fallback to default hex_size if no neighbor found
	return 40.0