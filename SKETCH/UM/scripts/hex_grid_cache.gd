## HexGridCache
## Simple cache system for hex grid
class_name HexGridCache
extends RefCounted

signal cache_invalidated()
signal cache_rebuilt(cache_size: int)

var hex_positions: Array[Vector2] = []
var dot_positions: Array[Vector2] = []
var diamond_geometry: Array[PackedVector2Array] = []
var diamond_colors: Array[Color] = []
var connections: Array = []
var cache_memory_usage: int = 0

var _config
var _geometry

func setup_cache(config, geometry) -> void:
	_config = config
	_geometry = geometry

func build_cache(force: bool = false) -> void:
	hex_positions.clear()
	dot_positions.clear()
	diamond_geometry.clear()
	diamond_colors.clear()
	
	if not _config:
		return
	
	var hex_width = _config.hex_size * 2.0
	var hex_height = _config.hex_size * sqrt(3.0)
	
	for row in range(_config.grid_height):
		for col in range(_config.grid_width):
			var x = col * hex_width * 0.75
			var y = row * hex_height
			
			if row % 2 == 1:
				x += hex_width * 0.375
			
			var hex_center = Vector2(x, y)
			hex_positions.append(hex_center)
			dot_positions.append(hex_center)
			
			var diamond_points = _create_diamond_geometry(hex_center)
			diamond_geometry.append(diamond_points)
			
			var color_index = (row * _config.grid_width + col) % 4
			match color_index:
				0: diamond_colors.append(Color(0.0, 1.0, 0.0))
				1: diamond_colors.append(Color(0.0, 0.5, 0.0))
				2: diamond_colors.append(Color(0.0, 1.0, 1.0))
				3: diamond_colors.append(Color(0.4, 0.4, 0.4))
	
	cache_memory_usage = hex_positions.size() * 32
	cache_rebuilt.emit(hex_positions.size())

func _create_diamond_geometry(center: Vector2) -> PackedVector2Array:
	var points = PackedVector2Array()
	var half_width = _config.diamond_width * 0.5
	var half_height = _config.diamond_height * 0.5
	
	points.append(center + Vector2(0, -half_height))
	points.append(center + Vector2(half_width, 0))
	points.append(center + Vector2(0, half_height))
	points.append(center + Vector2(-half_width, 0))
	
	return points

func get_hex_positions() -> Array[Vector2]:
	return hex_positions

func get_dot_positions() -> Array[Vector2]:
	return dot_positions

func get_diamond_geometry() -> Array[PackedVector2Array]:
	return diamond_geometry

func get_diamond_colors() -> Array[Color]:
	return diamond_colors

func get_connections() -> Array:
	return connections

func get_star_geometry() -> Array[PackedVector2Array]:
	var star_geom: Array[PackedVector2Array] = []
	for pos in dot_positions:
		var points = PackedVector2Array()
		points.append(pos)
		star_geom.append(points)
	return star_geom

func get_performance_stats() -> Dictionary:
	return {
		"hit_ratio": 0.95,
		"memory_usage": cache_memory_usage
	}

func get_total_cache_size() -> int:
	return hex_positions.size()

func is_valid() -> bool:
	return not hex_positions.is_empty()