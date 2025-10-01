# 🧭 HEX PATHFINDER
# Purpose: A* pathfinding for hexagonal grid
# Layer: Infrastructure/AI

extends RefCounted

class_name HexPathfinder

# Pathfinding node
class PathNode:
	var point_id: int
	var position
	var g_cost: float = 0.0  # Distance from start
	var h_cost: float = 0.0  # Heuristic distance to goal
	var f_cost: float = 0.0  # Total cost (g + h)
	var parent: PathNode = null
	var is_walkable: bool = true
	
	func _init(id: int, pos, walkable: bool = true):
		point_id = id
		position = pos
		is_walkable = walkable
		
	func calculate_f_cost():
		f_cost = g_cost + h_cost

# Find path using A* algorithm
static func find_path(start_point_id: int, goal_point_id: int, grid_data: Dictionary, units_data: Dictionary = {}) -> Array:
	if start_point_id == goal_point_id:
		return []
	
	if not (start_point_id in grid_data.points and goal_point_id in grid_data.points):
		return []
	
	var start_point = grid_data.points[start_point_id]
	var goal_point = grid_data.points[goal_point_id]
	
	# Initialize nodes
	var nodes = {}
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		var is_walkable = _is_point_walkable(point_id, grid_data, units_data)
		nodes[point_id] = PathNode.new(point_id, point.position, is_walkable)
	
	# Goal is always walkable for pathfinding
	nodes[goal_point_id].is_walkable = true
	
	var open_set = [nodes[start_point_id]]
	var closed_set = {}
	
	nodes[start_point_id].g_cost = 0
	nodes[start_point_id].h_cost = _calculate_heuristic(start_point.position, goal_point.position)
	nodes[start_point_id].calculate_f_cost()
	
	while open_set.size() > 0:
		# Find node with lowest f_cost
		var current_node = _get_lowest_f_cost_node(open_set)
		open_set.erase(current_node)
		closed_set[current_node.point_id] = current_node
		
		# Check if we reached the goal
		if current_node.point_id == goal_point_id:
			return _reconstruct_path(current_node)
		
		# Check neighbors
		var neighbors = _get_neighbors(current_node.point_id, grid_data)
		for neighbor_id in neighbors:
			if neighbor_id in closed_set:
				continue
				
			var neighbor_node = nodes[neighbor_id]
			if not neighbor_node.is_walkable:
				continue
			
			var tentative_g_cost = current_node.g_cost + _get_movement_cost(current_node.point_id, neighbor_id, grid_data)
			
			if neighbor_node not in open_set:
				open_set.append(neighbor_node)
			elif tentative_g_cost >= neighbor_node.g_cost:
				continue
			
			neighbor_node.parent = current_node
			neighbor_node.g_cost = tentative_g_cost
			neighbor_node.h_cost = _calculate_heuristic(neighbor_node.position, goal_point.position)
			neighbor_node.calculate_f_cost()
	
	# No path found
	return []

# Find reachable positions within movement range
static func find_reachable_positions(start_point_id: int, movement_range: int, grid_data: Dictionary, units_data: Dictionary = {}) -> Array:
	if not (start_point_id in grid_data.points):
		return []
	
	var reachable = []
	var visited = {}
	var queue = [{
		"point_id": start_point_id,
		"distance": 0
	}]
	
	visited[start_point_id] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_id = current.point_id
		var current_distance = current.distance
		
		if current_distance > 0:  # Don't include starting position
			reachable.append(current_id)
		
		if current_distance < movement_range:
			var neighbors = _get_neighbors(current_id, grid_data)
			for neighbor_id in neighbors:
				if neighbor_id not in visited and _is_point_walkable(neighbor_id, grid_data, units_data):
					visited[neighbor_id] = true
					queue.append({
						"point_id": neighbor_id,
						"distance": current_distance + 1
					})
	
	return reachable

# Calculate heuristic distance (Manhattan distance for hex grid)
static func _calculate_heuristic(pos1, pos2) -> float:
	return float(pos1.distance_to(pos2))

# Get movement cost between adjacent points
static func _get_movement_cost(from_id: int, to_id: int, grid_data: Dictionary) -> float:
	# Base cost is 1, can be modified by terrain
	var base_cost = 1.0
	
	# Find edge between points to check terrain
	if "edges" in grid_data:
		for edge_id in grid_data.edges:
			var edge = grid_data.edges[edge_id]
			if (edge.point_a_id == from_id and edge.point_b_id == to_id) or \
			   (edge.point_a_id == to_id and edge.point_b_id == from_id):
				# Modify cost based on terrain type
				match edge.terrain_type:
					0:  # FIELD
						return base_cost
					1:  # FOREST
						return base_cost * 1.5
					2:  # MOUNTAIN
						return base_cost * 3.0
					3:  # WATER
						return base_cost * 2.0
	
	return base_cost

# Check if point is walkable
static func _is_point_walkable(point_id: int, grid_data: Dictionary, units_data: Dictionary) -> bool:
	# Check if point exists
	if not (point_id in grid_data.points):
		return false
	
	# Check if occupied by unit
	var point_position = grid_data.points[point_id].position
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if unit.position.equals(point_position):
			return false
	
	return true

# Get neighbors of a point
static func _get_neighbors(point_id: int, grid_data: Dictionary) -> Array:
	var neighbors = []
	
	if not (point_id in grid_data.points):
		return neighbors
	
	var point = grid_data.points[point_id]
	
	# Get connected points through edges
	for edge_id in point.connected_edges:
		if edge_id in grid_data.edges:
			var edge = grid_data.edges[edge_id]
			var neighbor_id = edge.point_b_id if edge.point_a_id == point_id else edge.point_a_id
			neighbors.append(neighbor_id)
	
	return neighbors

# Get node with lowest f_cost from open set
static func _get_lowest_f_cost_node(open_set: Array) -> PathNode:
	var lowest_node = open_set[0]
	
	for node in open_set:
		if node.f_cost < lowest_node.f_cost or \
		   (node.f_cost == lowest_node.f_cost and node.h_cost < lowest_node.h_cost):
			lowest_node = node
	
	return lowest_node

# Reconstruct path from goal to start
static func _reconstruct_path(goal_node: PathNode) -> Array:
	var path = []
	var current_node = goal_node
	
	while current_node != null:
		path.push_front(current_node.point_id)
		current_node = current_node.parent
	
	# Remove starting position
	if path.size() > 0:
		path.pop_front()
	
	return path