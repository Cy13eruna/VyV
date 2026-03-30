# res://src/core/math/HexMath.gd
extends Node
class_name HexMath

const SQRT3: float = 1.73205080757

# --- COORDENADAS E DISTÂNCIA ---

static func axial_to_cube(hex: Vector2i) -> Vector3i:
	return Vector3i(hex.x, hex.y, -hex.x - hex.y)

static func get_hex_dist(a: Vector2i, b: Vector2i = Vector2i.ZERO) -> int:
	var ac = axial_to_cube(a)
	var bc = axial_to_cube(b)
	return int((abs(ac.x - bc.x) + abs(ac.y - bc.y) + abs(ac.z - bc.z)) / 2)

# --- POSICIONAMENTO E TRIÂNGULOS ---

static func axial_to_pixel(coords: Vector2i, side_length: float) -> Vector2:
	var h = (SQRT3 / 2.0) * side_length
	return Vector2(coords.x * (side_length / 2.0), coords.y * h)

static func get_triangle_points(coords: Vector2i, side_length: float) -> PackedVector2Array:
	var pos = axial_to_pixel(coords, side_length)
	var h = (SQRT3 / 2.0) * side_length
	var pts = PackedVector2Array()
	var is_up: bool = (coords.x + coords.y) % 2 == 0
	if is_up:
		pts.append(pos)
		pts.append(pos + Vector2(side_length / 2.0, h))
		pts.append(pos + Vector2(-side_length / 2.0, h))
	else:
		pts.append(pos + Vector2(0, h))
		pts.append(pos + Vector2(side_length / 2.0, 0))
		pts.append(pos + Vector2(-side_length / 2.0, 0))
	return pts

# --- GEOMETRIA UNIFICADA (ATUALIZADA) ---

## Gera dois triângulos que formam um Hexagrama (Estrela de 6 pontas)
## p_rotation: Rotação adicional em radianos (ex: deg_to_rad(30))
static func get_hexagram_triangles(pos: Vector2, radius: float, p_rotation: float = 0.0) -> Array[PackedVector2Array]:
	var t1 = PackedVector2Array()
	var t2 = PackedVector2Array()
	
	# Offset base de -90 graus para ponta virada para cima
	var base_rot = deg_to_rad(-90) + p_rotation
	
	for i in range(3):
		# Triângulo 1 (0, 120, 240 graus)
		var angle1 = base_rot + deg_to_rad(i * 120)
		t1.append(pos + Vector2(cos(angle1), sin(angle1)) * radius)
		
		# Triângulo 2 (Invertido: 60, 180, 300 graus em relação ao primeiro)
		var angle2 = base_rot + deg_to_rad(i * 120 + 60)
		t2.append(pos + Vector2(cos(angle2), sin(angle2)) * radius)
		
	return [t1, t2]

static func get_capital_star_points(pos: Vector2, size: float) -> PackedVector2Array:
	var outer_r = size * 0.92 
	var inner_r = size * 0.55
	var pts = PackedVector2Array()
	for i in range(12):
		var angle = deg_to_rad(i * 30 - 30) 
		var r = outer_r if i % 2 != 0 else inner_r
		pts.append(pos + Vector2(cos(angle), sin(angle)) * r)
	pts.append(pts[0])
	return pts

static func get_edge_polygon(p1: Vector2, p2: Vector2, tile_size: float) -> PackedVector2Array:
	var d_width = tile_size / 1.73205081
	var mid = (p1 + p2) / 2.0
	var dir = (p2 - p1).normalized()
	var perp = Vector2(-dir.y, dir.x) * (d_width / 2.0)
	return PackedVector2Array([p1, mid + perp, p2, mid - perp])