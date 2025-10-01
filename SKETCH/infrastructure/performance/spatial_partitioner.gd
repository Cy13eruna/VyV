# 🗺️ SPATIAL PARTITIONER
# Purpose: Efficient spatial queries for hexagonal grid
# Layer: Infrastructure/Performance

extends RefCounted

class_name SpatialPartitioner

# Spatial grid configuration
var cell_size: float = 100.0
var grid_bounds: Rect2
var spatial_grid: Dictionary = {}

# Initialize spatial partitioner
func _init(bounds: Rect2, partition_size: float = 100.0):
	grid_bounds = bounds
	cell_size = partition_size
	spatial_grid.clear()

# Add object to spatial grid
func add_object(object_id: int, position: Vector2, radius: float = 0.0) -> void:
	var cells = _get_cells_for_object(position, radius)
	
	for cell in cells:
		if not (cell in spatial_grid):
			spatial_grid[cell] = []
		
		if object_id not in spatial_grid[cell]:
			spatial_grid[cell].append(object_id)

# Remove object from spatial grid
func remove_object(object_id: int, position: Vector2, radius: float = 0.0) -> void:
	var cells = _get_cells_for_object(position, radius)
	
	for cell in cells:
		if cell in spatial_grid:
			spatial_grid[cell].erase(object_id)
			if spatial_grid[cell].is_empty():
				spatial_grid.erase(cell)

# Update object position
func update_object(object_id: int, old_position: Vector2, new_position: Vector2, radius: float = 0.0) -> void:
	remove_object(object_id, old_position, radius)
	add_object(object_id, new_position, radius)

# Query objects in radius
func query_radius(center: Vector2, radius: float) -> Array:
	var result = []
	var cells = _get_cells_for_object(center, radius)
	
	for cell in cells:
		if cell in spatial_grid:
			for object_id in spatial_grid[cell]:
				if object_id not in result:
					result.append(object_id)
	
	return result

# Query objects in rectangle
func query_rect(rect: Rect2) -> Array:
	var result = []
	var min_cell = _world_to_cell(rect.position)
	var max_cell = _world_to_cell(rect.position + rect.size)
	
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var cell = Vector2i(x, y)
			if cell in spatial_grid:
				for object_id in spatial_grid[cell]:
					if object_id not in result:
						result.append(object_id)
	
	return result

# Get nearest object
func get_nearest(position: Vector2, max_distance: float = INF) -> int:
	var search_radius = min(max_distance, cell_size)
	var candidates = query_radius(position, search_radius)
	
	# This would need actual object positions to calculate distances
	# For now, return first candidate
	return candidates[0] if candidates.size() > 0 else -1

# Clear all objects
func clear() -> void:
	spatial_grid.clear()

# Get statistics
func get_stats() -> Dictionary:
	var total_objects = 0
	var occupied_cells = spatial_grid.size()
	
	for cell in spatial_grid:
		total_objects += spatial_grid[cell].size()
	
	return {
		"occupied_cells": occupied_cells,
		"total_objects": total_objects,
		"avg_objects_per_cell": float(total_objects) / max(1, occupied_cells),
		"cell_size": cell_size
	}

# Helper functions
func _get_cells_for_object(position: Vector2, radius: float) -> Array:
	var cells = []
	var min_pos = position - Vector2(radius, radius)
	var max_pos = position + Vector2(radius, radius)
	
	var min_cell = _world_to_cell(min_pos)
	var max_cell = _world_to_cell(max_pos)
	
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			cells.append(Vector2i(x, y))
	
	return cells

func _world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / cell_size),
		int(world_pos.y / cell_size)
	)