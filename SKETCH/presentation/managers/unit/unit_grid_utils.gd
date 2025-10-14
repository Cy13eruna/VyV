# 🗺️ UNIT GRID UTILITIES
# Purpose: Grid-related utility functions for units
# Layer: Presentation Manager Utility

extends RefCounted
class_name UnitGridUtils

# Find unit at specific position
static func find_unit_at_position(position, game_state: Dictionary) -> int:
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.position.equals(position):
			return unit_id
	return -1

# Check if unit is away from map border (not on edge or corner)
static func is_unit_away_from_border(unit, game_state: Dictionary) -> bool:
	if not ("grid" in game_state):
		return false
	
	# Find the point at unit's position
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(unit.position):
			# Check if point is a corner (3 connections) or edge (less than 6 connections)
			var connections = point.get("connected_edges", [])
			if connections.size() < 6:
				return false  # Point is on border or corner
			return true  # Point has 6 connections (interior)
	
	return false  # Position not found on grid

# Get neighbors of a grid point
static func get_point_neighbors(point, game_state: Dictionary) -> Array:
	var neighbors = []
	if not point or not ("connected_edges" in point):
		return neighbors
	
	# Get all connected edges and find their other endpoints
	for edge_id in point.connected_edges:
		if edge_id in game_state.grid.edges:
			var edge = game_state.grid.edges[edge_id]
			# Find the other point of this edge
			var other_point_id = -1
			if "point_a_id" in edge and "point_b_id" in edge:
				other_point_id = edge.point_a_id if edge.point_b_id == point.id else edge.point_b_id
			elif "point1_id" in edge and "point2_id" in edge:
				other_point_id = edge.point1_id if edge.point2_id == point.id else edge.point2_id
			elif "point1" in edge and "point2" in edge:
				other_point_id = edge.point1 if edge.point2 == point.id else edge.point2
			else:
				continue  # Skip malformed edge
			
			if other_point_id != -1 and other_point_id in game_state.grid.points:
				neighbors.append(game_state.grid.points[other_point_id])
	
	return neighbors

# Calculate hex distance between two positions
static func calculate_hex_distance(pos1, pos2) -> int:
	# Use the built-in distance calculation from Position class
	return pos1.distance_to(pos2)

# Check if domain can be placed without sharing paths with existing domains
static func can_domain_be_placed_without_sharing_paths(unit, game_state: Dictionary) -> bool:
	if not ("domains" in game_state):
		return true  # No existing domains, can place anywhere
	
	# Get the grid point where unit is located
	var unit_point = null
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(unit.position):
			unit_point = point
			break
	
	if not unit_point:
		return false  # Unit position not found on grid
	
	# Get the "influence area" of the new domain (center + neighbors)
	var new_domain_positions = []
	# Add center position
	new_domain_positions.append(unit.position)
	var unit_neighbors = get_point_neighbors(unit_point, game_state)
	for neighbor in unit_neighbors:
		# Add neighbor positions
		new_domain_positions.append(neighbor.position)
	
	# Check each existing domain
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		# Get the domain's center point
		var domain_point = null
		for point_id in game_state.grid.points:
			var point = game_state.grid.points[point_id]
			if point.position.equals(domain.center_position):
				domain_point = point
				break
		
		if not domain_point:
			continue  # Domain position not found, skip
		
		# Get the "influence area" of the existing domain (center + neighbors)
		var existing_domain_positions = []
		# Add center position
		existing_domain_positions.append(domain.center_position)
		var domain_neighbors = get_point_neighbors(domain_point, game_state)
		for neighbor in domain_neighbors:
			# Add neighbor positions
			existing_domain_positions.append(neighbor.position)
		
		# Count shared positions between the two influence areas
		var shared_count = 0
		for new_pos in new_domain_positions:
			for existing_pos in existing_domain_positions:
				if new_pos.equals(existing_pos):  # Use Position.equals() method
					shared_count += 1
					break  # Avoid double counting same position
		
		# If sharing more than one position, domains would share paths (not allowed)
		if shared_count > 1:
			return false
	
	return true