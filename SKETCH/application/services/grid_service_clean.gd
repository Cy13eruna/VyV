# 🗺️ GRID SERVICE (CLEAN)
# Purpose: Hexagonal grid generation and management
# Layer: Application/Services
# Dependencies: Clean core entities only

extends RefCounted

# Preload clean classes
const HexCoordinate = preload("res://core/value_objects/hex_coordinate_clean.gd")
const Position = preload("res://core/value_objects/position_clean.gd")

# Generate complete hexagonal grid
static func generate_hex_grid(radius: int = 3) -> Dictionary:
	var grid_data = {
		"points": {},  # id -> point data
		"edges": {},   # id -> edge data
		"point_id_counter": 0,
		"edge_id_counter": 0,
		"radius": radius
	}
	
	var point_id_counter = 0
	var edge_id_counter = 0
	var coord_to_point_id = {}
	
	# Generate all points in hexagonal pattern
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		
		for r in range(r1, r2 + 1):
			var coord = HexCoordinate.new(q, r)
			var position = Position.from_hex(coord)
			
			var point_data = {
				"id": point_id_counter,
				"coordinate": coord,
				"position": position,
				"connected_edges": [],
				"is_corner": false
			}
			
			grid_data.points[point_id_counter] = point_data
			coord_to_point_id[_coord_key(q, r)] = point_id_counter
			point_id_counter += 1
	
	# Generate edges between adjacent points
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		var coord = point.coordinate
		
		# Check all 6 directions for neighbors
		for direction in range(6):
			var neighbor_coord = coord.get_neighbor(direction)
			var neighbor_key = _coord_key(neighbor_coord.q, neighbor_coord.r)
			
			if neighbor_key in coord_to_point_id:
				var neighbor_id = coord_to_point_id[neighbor_key]
				
				# Only create edge if we haven't created it yet (avoid duplicates)
				if point_id < neighbor_id:
					var edge_data = {
						"id": edge_id_counter,
						"point_a_id": point_id,
						"point_b_id": neighbor_id,
						"terrain_type": 0,  # FIELD by default
						"structures": []
					}
					
					grid_data.edges[edge_id_counter] = edge_data
					
					# Add edge to both points
					point.connected_edges.append(edge_id_counter)
					grid_data.points[neighbor_id].connected_edges.append(edge_id_counter)
					
					edge_id_counter += 1
	
	# Mark corner points (points with exactly 3 connections)
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		point.is_corner = (point.connected_edges.size() == 3)
	
	grid_data.point_id_counter = point_id_counter
	grid_data.edge_id_counter = edge_id_counter
	
	return grid_data

# Helper function to create coordinate key
static func _coord_key(q: int, r: int) -> String:
	return "%d,%d" % [q, r]

# Get all points within distance from center
static func get_points_within_distance(grid_data: Dictionary, center_coord, max_distance: int) -> Array:
	var result = []
	
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		var distance = center_coord.distance_to(point.coordinate)
		
		if distance <= max_distance:
			result.append(point)
	
	return result

# Get neighbors of a point
static func get_point_neighbors(grid_data: Dictionary, point_id: int) -> Array:
	var neighbors = []
	
	if point_id not in grid_data.points:
		return neighbors
	
	var point = grid_data.points[point_id]
	
	# Get all connected points through edges
	for edge_id in point.connected_edges:
		if edge_id in grid_data.edges:
			var edge = grid_data.edges[edge_id]
			var neighbor_id = edge.point_b_id if edge.point_a_id == point_id else edge.point_a_id
			
			if neighbor_id in grid_data.points:
				neighbors.append(grid_data.points[neighbor_id])
	
	return neighbors

# Find point at pixel position
static func find_point_at_pixel(grid_data: Dictionary, pixel_pos: Vector2, tolerance: float = 20.0) -> int:
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		var distance = point.position.pixel_pos.distance_to(pixel_pos)
		
		if distance <= tolerance:
			return point_id
	
	return -1

# Get grid statistics
static func get_grid_stats(grid_data: Dictionary) -> Dictionary:
	var corner_count = 0
	
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.is_corner:
			corner_count += 1
	
	return {
		"total_points": grid_data.points.size(),
		"total_edges": grid_data.edges.size(),
		"corner_points": corner_count,
		"radius": grid_data.radius
	}