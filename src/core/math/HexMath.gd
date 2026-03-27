# res://src/core/math/HexMath.gd
extends Node
class_name HexMath

const SQRT3: float = 1.73205080757

# --- COORDENADAS E DISTÂNCIA ---

## Converte Axial (Vector2i) para Cúbico (Vector3i) para cálculos de distância
static func axial_to_cube(hex: Vector2i) -> Vector3i:
	var q = hex.x
	var r = hex.y
	var s = -q - r
	return Vector3i(q, r, s)

## Calcula a distância hexagonal real entre dois pontos (essencial para o formato do mapa)
static func get_hex_dist(a: Vector2i, b: Vector2i = Vector2i.ZERO) -> int:
	var ac = axial_to_cube(a)
	var bc = axial_to_cube(b)
	return int((abs(ac.x - bc.x) + abs(ac.y - bc.y) + abs(ac.z - bc.z)) / 2)

static func round_hex(q: float, r: float) -> Vector2i:
	return Vector2i(int(round(q)), int(round(r)))

# --- POSICIONAMENTO ---

static func axial_to_pixel(coords: Vector2i, side_length: float) -> Vector2:
	var h = (SQRT3 / 2.0) * side_length
	# X anda em passos de metade do lado
	var x = coords.x * (side_length / 2.0)
	# Y fixo por linha hexagonal
	var y = coords.y * h
	return Vector2(x, y)

# --- GEOMETRIA DE TRIÂNGULOS ---

static func get_triangle_points(coords: Vector2i, side_length: float) -> PackedVector2Array:
	var pos = axial_to_pixel(coords, side_length)
	var h = (SQRT3 / 2.0) * side_length
	var points = PackedVector2Array()
	
	var is_up: bool = (coords.x + coords.y) % 2 == 0
	
	if is_up:
		points.append(pos)
		points.append(pos + Vector2(side_length / 2.0, h))
		points.append(pos + Vector2(-side_length / 2.0, h))
	else:
		points.append(pos + Vector2(0, h))
		points.append(pos + Vector2(side_length / 2.0, 0))
		points.append(pos + Vector2(-side_length / 2.0, 0))
		
	return points

static func get_neighbors(id: Vector2i) -> Array[Vector2i]:
	var is_up: bool = (id.x + id.y) % 2 == 0
	if is_up:
		return [id + Vector2i(-1, 0), id + Vector2i(1, 0), id + Vector2i(0, 1)]
	else:
		return [id + Vector2i(-1, 0), id + Vector2i(1, 0), id + Vector2i(0, -1)]