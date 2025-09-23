## StarMapper - Versão Ultra-Limpa
## Mapeamento de estrelas sem logs desnecessários

class_name StarMapperClean
extends RefCounted

var star_positions: Array[Vector2] = []

func map_stars(positions: Array[Vector2]) -> void:
	star_positions = positions.duplicate()

func get_star_count() -> int:
	return star_positions.size()

func get_star_position(star_id: int) -> Vector2:
	if star_id >= 0 and star_id < star_positions.size():
		return star_positions[star_id]
	return Vector2.ZERO

func get_nearest_star_id(position: Vector2) -> int:
	var closest_id = -1
	var closest_distance = 999999.0
	
	for i in range(star_positions.size()):
		var distance = position.distance_to(star_positions[i])
		if distance < closest_distance:
			closest_distance = distance
			closest_id = i
	
	return closest_id