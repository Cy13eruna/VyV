## HexGridGeometry
## Simple geometry calculations for hex grid
class_name HexGridGeometry
extends RefCounted

func calculate_hex_vertices(center: Vector2, size: float) -> Array[Vector2]:
	var vertices: Array[Vector2] = []
	for i in range(6):
		var angle = deg_to_rad(60.0 * i)
		var vertex = center + Vector2(cos(angle), sin(angle)) * size
		vertices.append(vertex)
	return vertices

func is_point_visible(point: Vector2, viewport_rect: Rect2, margin: float) -> bool:
	var expanded_rect = viewport_rect.grow(margin)
	return expanded_rect.has_point(point)

func calculate_bounding_rect(positions: Array[Vector2]) -> Rect2:
	if positions.is_empty():
		return Rect2()
	
	var min_pos = positions[0]
	var max_pos = positions[0]
	
	for pos in positions:
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)
	
	return Rect2(min_pos, max_pos - min_pos)