## HexGridGeometry - Versão Ultra-Limpa
## Cálculos geométricos sem logs desnecessários

class_name HexGridGeometryClean
extends RefCounted

func generate_hex_positions(grid_width: int, grid_height: int, hex_size: float) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var hex_radius = min(grid_width, grid_height)
	
	for q in range(-hex_radius, hex_radius + 1):
		var r1 = max(-hex_radius, -q - hex_radius)
		var r2 = min(hex_radius, -q + hex_radius)
		
		for r in range(r1, r2 + 1):
			var hex_pos = _hex_to_pixel(q, r, hex_size)
			positions.append(hex_pos)
	
	return positions

func generate_dot_positions(hex_positions: Array[Vector2], hex_size: float) -> Array[Vector2]:
	var all_dots: Array[Vector2] = []
	var unique_dots: Array[Vector2] = []
	
	# Adicionar centros dos hexágonos
	for hex_pos in hex_positions:
		unique_dots.append(hex_pos)
	
	# Adicionar vértices únicos
	for hex_pos in hex_positions:
		var vertices = _calculate_hex_vertices(hex_pos, hex_size)
		for vertex in vertices:
			if not _is_position_duplicate(vertex, unique_dots, 5.0):
				unique_dots.append(vertex)
	
	return unique_dots

func calculate_star_geometry(center: Vector2, outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	
	for i in range(12):  # 6 outer + 6 inner points
		var angle_deg = 30.0 * i  # 30 degrees between each point
		var angle_rad = deg_to_rad(angle_deg)
		var radius = outer_radius if i % 2 == 0 else inner_radius
		var point = center + Vector2(cos(angle_rad), sin(angle_rad)) * radius
		points.append(point)
	
	return points

func _hex_to_pixel(q: int, r: int, hex_size: float) -> Vector2:
	var x = hex_size * (3.0/2.0 * q)
	var y = hex_size * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r)
	return Vector2(x, y)

func _calculate_hex_vertices(center: Vector2, hex_size: float) -> Array[Vector2]:
	var vertices: Array[Vector2] = []
	
	for i in range(6):
		var angle_deg = 60.0 * i
		var angle_rad = deg_to_rad(angle_deg)
		var vertex = center + Vector2(cos(angle_rad), sin(angle_rad)) * hex_size
		vertices.append(vertex)
	
	return vertices

func _is_position_duplicate(pos: Vector2, existing_positions: Array[Vector2], tolerance: float) -> bool:
	for existing_pos in existing_positions:
		if pos.distance_to(existing_pos) < tolerance:
			return true
	return false