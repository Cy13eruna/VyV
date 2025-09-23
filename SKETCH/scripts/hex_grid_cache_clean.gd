## HexGridCache - Versão Ultra-Limpa
## Sistema de cache sem logs desnecessários

class_name HexGridCacheClean
extends RefCounted

signal cache_invalidated()
signal cache_rebuilt(cache_size: int)

var config_ref = null
var geometry_ref = null

var cached_hex_positions: Array[Vector2] = []
var cached_dot_positions: Array[Vector2] = []
var cached_connections: Array = []
var cached_diamond_colors: Array[Color] = []

var is_cache_valid: bool = false
var cache_memory_usage: int = 0
var last_rebuild_duration: float = 0.0

func setup_cache(config, geometry):
	config_ref = config
	geometry_ref = geometry
	
	if config_ref:
		config_ref.config_changed.connect(_on_config_changed)

func build_cache(force_rebuild: bool = false):
	if is_cache_valid and not force_rebuild:
		return
	
	var start_time = Time.get_unix_time_from_system()
	
	_clear_cache()
	_build_hex_positions()
	_build_dot_positions()
	_build_connections()
	_build_diamond_colors()
	
	is_cache_valid = true
	var end_time = Time.get_unix_time_from_system()
	last_rebuild_duration = (end_time - start_time) * 1000.0
	
	_calculate_memory_usage()
	cache_rebuilt.emit(get_total_cache_size())

func get_hex_positions() -> Array[Vector2]:
	return cached_hex_positions

func get_dot_positions() -> Array[Vector2]:
	return cached_dot_positions

func get_connections() -> Array:
	return cached_connections

func get_diamond_colors() -> Array[Color]:
	return cached_diamond_colors

func get_diamond_geometry() -> Array:
	# Retornar geometria dos diamantes (conexões)
	var diamond_geometry = []
	for i in range(cached_connections.size()):
		var connection = cached_connections[i]
		if connection.index_a < cached_dot_positions.size() and connection.index_b < cached_dot_positions.size():
			var pos_a = cached_dot_positions[connection.index_a]
			var pos_b = cached_dot_positions[connection.index_b]
			var center = (pos_a + pos_b) / 2.0
			diamond_geometry.append({
				"center": center,
				"width": 20.0,
				"height": 30.0,
				"rotation": pos_a.angle_to_point(pos_b)
			})
	return diamond_geometry

func get_star_geometry() -> Array:
	# Retornar geometria das estrelas como PackedVector2Array
	var star_geometry = []
	for pos in cached_dot_positions:
		# Criar pontos da estrela
		var points = PackedVector2Array()
		for i in range(12):
			var angle = deg_to_rad(30.0 * i)
			var radius = 6.0 if i % 2 == 0 else 3.0
			var point = pos + Vector2(cos(angle), sin(angle)) * radius
			points.append(point)
		star_geometry.append(points)
	return star_geometry

func is_valid() -> bool:
	return is_cache_valid

func get_total_cache_size() -> int:
	return cached_hex_positions.size() + cached_dot_positions.size() + cached_connections.size()

func get_performance_stats() -> Dictionary:
	return {
		"cache_valid": is_cache_valid,
		"hex_positions": cached_hex_positions.size(),
		"dot_positions": cached_dot_positions.size(),
		"connections": cached_connections.size(),
		"memory_usage": cache_memory_usage,
		"last_rebuild_duration": last_rebuild_duration
	}

func _clear_cache():
	cached_hex_positions.clear()
	cached_dot_positions.clear()
	cached_connections.clear()
	cached_diamond_colors.clear()
	is_cache_valid = false

func _build_hex_positions():
	if not geometry_ref or not config_ref:
		return
	
	cached_hex_positions = geometry_ref.generate_hex_positions(config_ref.grid_width, config_ref.grid_height, config_ref.hex_size)

func _build_dot_positions():
	if not geometry_ref or not config_ref:
		return
	
	cached_dot_positions = geometry_ref.generate_dot_positions(cached_hex_positions, config_ref.hex_size)

func _build_connections():
	if cached_dot_positions.size() == 0:
		return
	
	var connection_distance = config_ref.hex_size * 0.6 if config_ref else 30.0
	
	for i in range(cached_dot_positions.size()):
		var dot_a = cached_dot_positions[i]
		
		for j in range(i + 1, cached_dot_positions.size()):
			var dot_b = cached_dot_positions[j]
			var distance = dot_a.distance_to(dot_b)
			
			if distance <= connection_distance:
				cached_connections.append({
					"index_a": i,
					"index_b": j,
					"distance": distance
				})

func _build_diamond_colors():
	# Gerar cores para os diamantes (conexões)
	for i in range(cached_connections.size()):
		var hue = (i * 0.618033988749895) # Golden ratio
		hue = hue - floor(hue) # Keep fractional part
		cached_diamond_colors.append(Color.from_hsv(hue, 0.7, 0.9))

func _calculate_memory_usage():
	cache_memory_usage = 0
	cache_memory_usage += cached_hex_positions.size() * 8  # Vector2 = 8 bytes
	cache_memory_usage += cached_dot_positions.size() * 8
	cache_memory_usage += cached_connections.size() * 24  # Rough estimate for dictionary
	cache_memory_usage += cached_diamond_colors.size() * 16  # Color = 16 bytes

func _on_config_changed(property_name: String, old_value, new_value):
	invalidate_cache()

func invalidate_cache():
	is_cache_valid = false
	cache_invalidated.emit()