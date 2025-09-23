## HexGridCache
## 
## Intelligent caching system for hexagonal grid geometry and rendering data.
## Provides optimized storage and retrieval of pre-calculated geometric data
## with automatic invalidation and memory management.
##
## @author: V&V Game Studio
## @version: 2.0

class_name HexGridCache
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Cache invalidation signal - emitted when cache is cleared
signal cache_invalidated()

## Cache rebuild signal - emitted when cache is rebuilt
signal cache_rebuilt(cache_size: int)

## Cached geometric data structures
var cached_hex_positions: Array[Vector2] = []
var cached_dot_positions: Array[Vector2] = []
var cached_connections: Array[Dictionary] = []
var cached_diamond_geometry: Array[PackedVector2Array] = []
var cached_star_geometry: Array[PackedVector2Array] = []
var cached_diamond_colors: Array[Color] = []

## Spatial partitioning for fast neighbor lookup
var spatial_grid: Dictionary = {}
var spatial_cell_size: float = 0.0

## Cache state management
var is_cache_valid: bool = false
var cache_config_hash: int = 0
var cache_build_time: float = 0.0
var cache_memory_usage: int = 0

## Performance metrics
var cache_hit_count: int = 0
var cache_miss_count: int = 0
var last_rebuild_duration: float = 0.0

## Configuration reference
var _config
var _geometry

## Initialize cache system
func _init():
	pass

## Setup cache with dependencies
## @param config: Configuration object
## @param geometry: Geometry calculator
func setup_cache(config, geometry):
	_config = config
	_geometry = geometry
	
	# Connect to configuration changes
	if _config and _config.has_signal("config_changed"):
		_config.config_changed.connect(_on_config_changed)

## Check if cache is valid for current configuration
## @return bool: True if cache can be used
func is_valid() -> bool:
	if not is_cache_valid:
		return false
	
	# Check if configuration has changed
	var current_hash = _calculate_config_hash()
	return current_hash == cache_config_hash

## Build complete cache from current configuration
## @param force_rebuild bool: Force rebuild even if cache is valid
func build_cache(force_rebuild: bool = false) -> void:
	if is_valid() and not force_rebuild:
		cache_hit_count += 1
		return
	
	cache_miss_count += 1
	var start_time = Time.get_time_dict_from_system()
	var start_unix = Time.get_unix_time_from_system()
	
	Logger.debug("Building cache...", "HexGridCache")
	
	# Clear existing cache
	invalidate_cache()
	
	# Generate base positions
	cached_hex_positions = _geometry.calculate_hex_positions(_config)
	Logger.debug("Generated %d hex positions" % cached_hex_positions.size(), "HexGridCache")
	cached_dot_positions = _geometry.calculate_all_dot_positions(cached_hex_positions, _config.hex_size)
	Logger.debug("Generated %d dot positions" % cached_dot_positions.size(), "HexGridCache")
	
	# Apply global rotation if configured
	if not is_zero_approx(_config.global_rotation_degrees):
		var center = _geometry.calculate_center(cached_hex_positions)
		cached_hex_positions = _geometry.apply_global_rotation(cached_hex_positions, center, _config.global_rotation_degrees)
		cached_dot_positions = _geometry.apply_global_rotation(cached_dot_positions, center, _config.global_rotation_degrees)
	
	# Build spatial grid for fast neighbor lookup
	_build_spatial_grid()
	
	# Generate connections and geometry
	_build_connections_and_geometry()
	
	# Generate diamond colors
	_generate_diamond_colors()
	
	# Update cache state
	is_cache_valid = true
	cache_config_hash = _calculate_config_hash()
	cache_build_time = Time.get_unix_time_from_system()
	_calculate_memory_usage()
	
	var end_unix = Time.get_unix_time_from_system()
	last_rebuild_duration = (end_unix - start_unix) * 1000.0  # Convert to milliseconds
	
	var total_size = get_total_cache_size()
	Logger.info("Cache built in %.2f ms, %d elements" % [last_rebuild_duration, total_size], "HexGridCache")
	Logger.debug("Hex positions: %d, Dot positions: %d, Connections: %d" % [cached_hex_positions.size(), cached_dot_positions.size(), cached_connections.size()], "HexGridCache")
	cache_rebuilt.emit(get_total_cache_size())

## Get cached hexagon positions
## @return Array[Vector2]: Cached hexagon center positions
func get_hex_positions() -> Array[Vector2]:
	if not is_valid():
		build_cache()
	return cached_hex_positions

## Get cached dot positions
## @return Array[Vector2]: Cached dot positions for stars
func get_dot_positions() -> Array[Vector2]:
	if not is_valid():
		build_cache()
	return cached_dot_positions

## Get cached connection data
## @return Array[Dictionary]: Cached connection information
func get_connections() -> Array[Dictionary]:
	if not is_valid():
		build_cache()
	return cached_connections

## Get cached diamond geometry
## @return Array[PackedVector2Array]: Cached diamond shapes
func get_diamond_geometry() -> Array[PackedVector2Array]:
	if not is_valid():
		build_cache()
	return cached_diamond_geometry

## Get cached star geometry
## @return Array[PackedVector2Array]: Cached star shapes
func get_star_geometry() -> Array[PackedVector2Array]:
	if not is_valid():
		build_cache()
	return cached_star_geometry

## Get cached diamond colors
## @return Array[Color]: Cached diamond colors
func get_diamond_colors() -> Array[Color]:
	if not is_valid():
		build_cache()
	return cached_diamond_colors

## Find nearby dots using spatial grid
## @param position Vector2: Position to search around
## @param max_distance float: Maximum search distance
## @return Array[int]: Indices of nearby dots
func find_nearby_dots(position: Vector2, max_distance: float) -> Array[int]:
	# Don't rebuild cache during connection building to avoid infinite recursion
	# But allow search during cache building process
	if not is_cache_valid and cached_dot_positions.is_empty():
		return []
	
	var nearby: Array[int] = []
	if spatial_cell_size <= 0:
		return nearby
	
	var search_radius = int(max_distance / spatial_cell_size) + 1
	
	var center_x = int(position.x / spatial_cell_size)
	var center_y = int(position.y / spatial_cell_size)
	
	for dx in range(-search_radius, search_radius + 1):
		for dy in range(-search_radius, search_radius + 1):
			var cell_key = str(center_x + dx) + "," + str(center_y + dy)
			if spatial_grid.has(cell_key):
				for index in spatial_grid[cell_key]:
					if index < cached_dot_positions.size() and position.distance_to(cached_dot_positions[index]) <= max_distance:
						nearby.append(index)
	
	return nearby

## Get cache performance statistics
## @return Dictionary: Performance metrics
func get_performance_stats() -> Dictionary:
	return {
		"cache_hits": cache_hit_count,
		"cache_misses": cache_miss_count,
		"hit_ratio": float(cache_hit_count) / max(1, cache_hit_count + cache_miss_count),
		"last_rebuild_duration_ms": last_rebuild_duration,
		"memory_usage_bytes": cache_memory_usage,
		"total_elements": get_total_cache_size(),
		"is_valid": is_cache_valid
	}

## Get total number of cached elements
## @return int: Total cache size
func get_total_cache_size() -> int:
	return cached_hex_positions.size() + cached_dot_positions.size() + \
		   cached_connections.size() + cached_diamond_geometry.size() + \
		   cached_star_geometry.size() + cached_diamond_colors.size()

## Invalidate cache (mark as dirty)
func invalidate_cache() -> void:
	is_cache_valid = false
	cache_config_hash = 0
	
	# Clear all cached data
	cached_hex_positions.clear()
	cached_dot_positions.clear()
	cached_connections.clear()
	cached_diamond_geometry.clear()
	cached_star_geometry.clear()
	cached_diamond_colors.clear()
	spatial_grid.clear()
	
	cache_invalidated.emit()

## Optimize cache memory usage
func optimize_memory() -> void:
	if not is_cache_valid:
		return
	
	# Remove unused spatial grid cells
	var used_cells = {}
	for dot_pos in cached_dot_positions:
		var cell_x = int(dot_pos.x / spatial_cell_size)
		var cell_y = int(dot_pos.y / spatial_cell_size)
		var cell_key = str(cell_x) + "," + str(cell_y)
		used_cells[cell_key] = true
	
	# Remove unused cells from spatial grid
	var keys_to_remove = []
	for key in spatial_grid.keys():
		if not used_cells.has(key):
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		spatial_grid.erase(key)
	
	_calculate_memory_usage()

## Handle configuration changes
## @param property_name String: Name of changed property
## @param old_value: Previous value
## @param new_value: New value
func _on_config_changed(property_name: String, old_value, new_value) -> void:
	Logger.debug("Configuration changed (%s), invalidating cache" % property_name, "HexGridCache")
	invalidate_cache()

## Build spatial grid for fast neighbor lookup
func _build_spatial_grid() -> void:
	spatial_grid.clear()
	spatial_cell_size = _config.hex_size * 2.0  # Cell size based on hex size
	Logger.debug("Building spatial grid with cell size: %.2f" % spatial_cell_size, "HexGridCache")
	
	for i in range(cached_dot_positions.size()):
		var dot = cached_dot_positions[i]
		var cell_x = int(dot.x / spatial_cell_size)
		var cell_y = int(dot.y / spatial_cell_size)
		var cell_key = str(cell_x) + "," + str(cell_y)
		
		if not spatial_grid.has(cell_key):
			spatial_grid[cell_key] = []
		spatial_grid[cell_key].append(i)
	
	Logger.debug("Spatial grid built with %d cells" % spatial_grid.size(), "HexGridCache")

## Build connections and pre-calculate geometry
func _build_connections_and_geometry() -> void:
	cached_connections.clear()
	cached_diamond_geometry.clear()
	cached_star_geometry.clear()
	
	if cached_dot_positions.is_empty():
		Logger.warning("No dot positions available for connections", "HexGridCache")
		return
	
	var connection_distance = _geometry.calculate_connection_distance(_config.hex_size)
	Logger.debug("Connection distance: %.2f" % connection_distance, "HexGridCache")
	var processed_connections = {}  # Avoid duplicate connections
	
	# Build connections between nearby dots
	Logger.debug("Starting connection building for %d dots" % cached_dot_positions.size(), "HexGridCache")
	for i in range(cached_dot_positions.size()):
		if i >= cached_dot_positions.size():
			Logger.error("Index %d out of bounds for dot_positions size %d" % [i, cached_dot_positions.size()], "HexGridCache")
			break
		
		var dot_a = cached_dot_positions[i]
		var nearby_indices = find_nearby_dots(dot_a, connection_distance)
		
		if i < 5:  # Debug first few dots
			Logger.debug("Dot %d at %s found %d nearby dots" % [i, dot_a, nearby_indices.size()], "HexGridCache")
		
		for j in nearby_indices:
			if i >= j:  # Avoid duplicate connections
				continue
			
			var dot_b = cached_dot_positions[j]
			var distance = dot_a.distance_to(dot_b)
			
			if distance <= connection_distance:
				# Store connection data
				cached_connections.append({
					"point_a": dot_a,
					"point_b": dot_b,
					"index_a": i,
					"index_b": j,
					"distance": distance
				})
				
				# Pre-calculate diamond geometry
				var diamond_geometry = _geometry.calculate_diamond_geometry(dot_a, dot_b)
				cached_diamond_geometry.append(diamond_geometry)
	
	# Pre-calculate star geometry for all dots
	for dot_pos in cached_dot_positions:
		var star_geometry = _geometry.calculate_star_geometry(dot_pos, _config.dot_radius, _config.dot_star_size)
		cached_star_geometry.append(star_geometry)

## Generate diamond colors based on configuration
func _generate_diamond_colors() -> void:
	cached_diamond_colors.clear()
	
	var total_diamonds = cached_connections.size()
	if total_diamonds == 0:
		return
	
	var colors = _config.generate_diamond_colors(total_diamonds)
	cached_diamond_colors = colors

## Calculate hash of current configuration for cache validation
## @return int: Configuration hash
func _calculate_config_hash() -> int:
	var hash_string = str(_config.grid_width) + str(_config.grid_height) + \
					  str(_config.hex_size) + str(_config.global_rotation_degrees) + \
					  str(_config.dot_radius) + str(_config.dot_star_size)
	return hash_string.hash()

## Calculate approximate memory usage of cache
func _calculate_memory_usage() -> void:
	cache_memory_usage = 0
	
	# Estimate memory usage (rough calculation)
	cache_memory_usage += cached_hex_positions.size() * 8  # Vector2 = 8 bytes
	cache_memory_usage += cached_dot_positions.size() * 8
	cache_memory_usage += cached_connections.size() * 64  # Dictionary overhead
	cache_memory_usage += cached_diamond_geometry.size() * 32  # PackedVector2Array
	cache_memory_usage += cached_star_geometry.size() * 96  # Larger PackedVector2Array
	cache_memory_usage += cached_diamond_colors.size() * 16  # Color = 16 bytes
	cache_memory_usage += spatial_grid.size() * 32  # Dictionary overhead