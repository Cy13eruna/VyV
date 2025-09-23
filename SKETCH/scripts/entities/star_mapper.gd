## StarMapper - Sistema Minimalista
class_name StarMapper
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Posições das estrelas (índice = ID)
var star_positions: Array[Vector2] = []

## Mapear estrelas do hex_grid
func map_stars(dot_positions: Array[Vector2]) -> void:
	star_positions = dot_positions
	Logger.info("%d estrelas mapeadas" % star_positions.size(), "StarMapper")

## Obter posição de uma estrela
func get_star_position(star_id: int) -> Vector2:
	if star_id >= 0 and star_id < star_positions.size():
		return star_positions[star_id]
	return Vector2.ZERO

## Encontrar estrela mais próxima de uma posição
func get_nearest_star_id(world_pos: Vector2) -> int:
	var nearest_id = -1
	var min_distance = INF
	
	for i in range(star_positions.size()):
		var distance = world_pos.distance_to(star_positions[i])
		if distance < min_distance:
			min_distance = distance
			nearest_id = i
	
	return nearest_id

## Total de estrelas
func get_star_count() -> int:
	return star_positions.size()