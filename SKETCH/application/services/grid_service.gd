# 🔷 GRID SERVICE
# Purpose: Hexagonal grid generation and management
# Layer: Application/Services
# Dependencies: Core entities only (HexPoint, HexEdge, HexCoordinate)

extends RefCounted

# Preload dependencies
const HexPoint = preload("res://core/entities/hex_point.gd")
const HexEdge = preload("res://core/entities/hex_edge.gd")
const HexCoordinate = preload("res://core/value_objects/hex_coordinate.gd")

# Generate complete hexagonal grid
static func generate_hex_grid(radius: int = 3) -> Dictionary:
	var grid_data = {
		"points": {},  # id -> HexPoint
		"edges": {},   # id -> HexEdge
		"point_id_counter": 0,
		"edge_id_counter": 0
	}
	
	# Generate all points in hexagonal pattern
	var point_coords = _generate_hex_coordinates(radius)
	for coord in point_coords:
		var point_id = grid_data.point_id_counter
		var hex_point = HexPoint.new(point_id, coord)
		grid_data.points[point_id] = hex_point
		grid_data.point_id_counter += 1
	
	# Generate edges between adjacent points
	_generate_hex_edges(grid_data)
	
	# Update corner status for all points
	_update_corner_status(grid_data)
	
	return grid_data

# Generate all hex coordinates within radius
static func _generate_hex_coordinates(radius: int) -> Array:
	var coordinates = []
	
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			coordinates.append(HexCoordinate.new(q, r))
	
	return coordinates

# Generate edges between adjacent points
static func _generate_hex_edges(grid_data: Dictionary) -> void:
	var points = grid_data.points
	
	for point_id in points:
		var point = points[point_id]
		var neighbors = point.get_neighbors()
		
		for neighbor_coord in neighbors:
			var neighbor_point = _find_point_by_coordinate(points, neighbor_coord)
			if neighbor_point != null:
				var edge_id = _create_edge_if_not_exists(grid_data, point.id, neighbor_point.id)
				if edge_id != -1:
					point.add_edge_connection(edge_id)
					neighbor_point.add_edge_connection(edge_id)

# Find point by hex coordinate
static func _find_point_by_coordinate(points: Dictionary, coord):
	for point_id in points:
		var point = points[point_id]
		if point.position.hex_coord.equals(coord):
			return point
	return null

# Create edge if it doesn't exist
static func _create_edge_if_not_exists(grid_data: Dictionary, point_a_id: int, point_b_id: int) -> int:
	var edges = grid_data.edges
	
	# Check if edge already exists
	for edge_id in edges:
		var edge = edges[edge_id]
		if (edge.point_a_id == point_a_id and edge.point_b_id == point_b_id) or \
		   (edge.point_a_id == point_b_id and edge.point_b_id == point_a_id):
			return -1  # Edge already exists
	
	# Create new edge
	var edge_id = grid_data.edge_id_counter
	var new_edge = HexEdge.new(edge_id, point_a_id, point_b_id)
	grid_data.edges[edge_id] = new_edge
	grid_data.edge_id_counter += 1
	
	return edge_id

# Update corner status for all points
static func _update_corner_status(grid_data: Dictionary) -> void:
	var points = grid_data.points
	for point_id in points:
		var point = points[point_id]
		point.update_corner_status()

# Get corner points (for spawn positioning)
static func get_corner_points(grid_data: Dictionary) -> Array:
	var corners = []
	var points = grid_data.points
	
	for point_id in points:
		var point = points[point_id]
		if point.is_corner:
			corners.append(point)
	
	return corners

# Calculate distance between two points
static func calculate_distance(grid_data: Dictionary, point_a_id: int, point_b_id: int) -> int:
	var points = grid_data.points
	if point_a_id in points and point_b_id in points:
		var point_a = points[point_a_id]
		var point_b = points[point_b_id]
		return point_a.position.distance_to(point_b.position)
	return -1

# Get all points within distance of target point
static func get_points_within_distance(grid_data: Dictionary, center_point_id: int, max_distance: int) -> Array[int]:
	var result: Array[int] = []
	var points = grid_data.points
	
	if center_point_id not in points:
		return result
	
	var center_point = points[center_point_id]
	
	for point_id in points:
		var point = points[point_id]
		if center_point.position.distance_to(point.position) <= max_distance:
			result.append(point_id)
	
	return result