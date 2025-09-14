## HexGrid v2.0 (Compatibility Layer)
## 
## Main hexagonal grid system with modular architecture.
## Orchestrates configuration, geometry, caching, and rendering components
## for optimal performance and maintainability.
##
## @author: V&V Game Studio
## @version: 2.0

extends Node2D
class_name HexGrid

# Preload component classes
const HexGridConfig = preload("res://scripts/hex_grid_config.gd")
const HexGridGeometry = preload("res://scripts/hex_grid_geometry.gd")
const HexGridCache = preload("res://scripts/hex_grid_cache.gd")
const HexGridRenderer = preload("res://scripts/hex_grid_renderer.gd")

## Grid system events
signal grid_initialized()
signal grid_updated()
signal performance_warning(message: String)

## Exported configuration properties (for editor)
@export_group("Grid Dimensions")
@export var grid_width: int = 25 : set = set_grid_width
@export var grid_height: int = 18 : set = set_grid_height

@export_group("Hexagon Properties")
@export var hex_size: float = 35.0 : set = set_hex_size
@export var hex_color: Color = Color.WHITE : set = set_hex_color
@export var border_color: Color = Color.BLACK : set = set_border_color
@export var border_width: float = 2.0 : set = set_border_width

@export_group("Star Properties")
@export var dot_radius: float = 6.0 : set = set_dot_radius
@export var dot_color: Color = Color.WHITE : set = set_dot_color
@export var dot_star_size: float = 3.0 : set = set_dot_star_size

@export_group("Diamond Properties")
@export var diamond_width: float = 35.0 : set = set_diamond_width
@export var diamond_height: float = 60.0 : set = set_diamond_height
@export var diamond_color: Color = Color.GREEN : set = set_diamond_color

@export_group("Global Transform")
@export var hex_global_rotation_degrees: float = 30.0 : set = set_hex_global_rotation_degrees

@export_group("Performance")
@export var enable_culling: bool = true : set = set_enable_culling
@export var culling_margin: float = 100.0 : set = set_culling_margin
@export var max_cache_size: int = 10000 : set = set_max_cache_size
@export var show_debug_info: bool = false : set = set_show_debug_info
## Auto-optimization settings
@export var auto_optimize_performance: bool = true

## Performance limits
@export var max_grid_radius: int = 6  # Maximum allowed radius (6 rings)
@export var performance_warning_radius: int = 5  # Warning threshold (5 rings)

## Input protection
var last_input_time: float = 0.0
var input_cooldown: float = 0.3  # 300ms cooldown between inputs
var is_rebuilding: bool = false  # Prevent concurrent rebuilds

## Component system
var config
var geometry
var cache
var renderer

## State management
var is_initialized: bool = false
var needs_redraw: bool = true
var last_camera_transform: Transform2D
var performance_monitor_enabled: bool = true

## Performance tracking
var frame_times: Array[float] = []
var max_frame_time_samples: int = 60
var performance_warning_threshold: float = 16.67  # 60 FPS threshold in ms

## Initialize the grid system
func _ready() -> void:
	_initialize_components()
	_setup_grid()
	_connect_signals()
	
	# Center the grid on screen
	_center_grid_on_screen()
	
	# Initial cache build
	cache.build_cache()
	
	is_initialized = true
	grid_initialized.emit()
	
	print("HexGrid: Initialized successfully")
	
	# Enable input processing for mouse wheel
	set_process_unhandled_input(true)

## Main drawing function
func _draw() -> void:
	if not is_initialized:
		return
	
	var start_unix = Time.get_unix_time_from_system()
	
	# Get camera transform for culling
	var camera_transform = get_global_transform()
	
	
	# Render the grid
	if renderer:
		renderer.render_grid(self, camera_transform)
	last_camera_transform = camera_transform
	
	# Performance monitoring
	if performance_monitor_enabled:
		_track_performance(start_unix)
	
	needs_redraw = false

## Force redraw of the grid
func redraw_grid() -> void:
	needs_redraw = true
	queue_redraw()

## Get grid statistics
## @return Dictionary: Comprehensive grid statistics
func get_grid_stats() -> Dictionary:
	if not is_initialized:
		return {}
	
	var stats = {
		"grid_size": Vector2i(config.grid_width, config.grid_height),
		"total_hexagons": config.grid_width * config.grid_height,
		"total_dots": cache.get_dot_positions().size(),
		"total_connections": cache.get_connections().size(),
		"cache_stats": cache.get_performance_stats(),
		"render_stats": renderer.get_render_stats(),
		"memory_usage_mb": cache.cache_memory_usage / (1024.0 * 1024.0),
		"is_cache_valid": cache.is_valid()
	}
	
	return stats

## Export grid configuration
## @return Dictionary: Current configuration as dictionary
func export_config() -> Dictionary:
	if not config:
		return {}
	return config.to_dict()

## Import grid configuration
## @param config_data Dictionary: Configuration to load
func import_config(config_data: Dictionary) -> void:
	if not config:
		return
	
	config.from_dict(config_data)
	_update_exported_properties()
	redraw_grid()

## Get hexagon at world position
## @param world_pos Vector2: World position to check
## @return int: Index of hexagon (-1 if none)
func get_hexagon_at_position(world_pos: Vector2) -> int:
	if not is_initialized:
		return -1
	
	var hex_positions = cache.get_hex_positions()
	var min_distance = INF
	var closest_index = -1
	
	for i in range(hex_positions.size()):
		var distance = world_pos.distance_to(hex_positions[i])
		if distance < config.hex_size and distance < min_distance:
			min_distance = distance
			closest_index = i
	
	return closest_index

## Get dot at world position
## @param world_pos Vector2: World position to check
## @return int: Index of dot (-1 if none)
func get_dot_at_position(world_pos: Vector2) -> int:
	if not is_initialized:
		return -1
	
	var dot_positions = cache.get_dot_positions()
	
	for i in range(dot_positions.size()):
		var distance = world_pos.distance_to(dot_positions[i])
		if distance <= config.dot_radius:
			return i
	
	return -1

## Set layer visibility
## @param layer: Layer to modify
## @param visible bool: Visibility state
func set_layer_visibility(layer, visible: bool) -> void:
	if renderer:
		renderer.set_layer_visibility(layer, visible)
		redraw_grid()

## Optimize performance automatically
func optimize_performance() -> void:
	if not renderer:
		return
	
	renderer.optimize_for_performance(60.0)  # Target 60 FPS
	
	# Additional optimizations based on grid size
	var total_elements = cache.get_total_cache_size()
	if total_elements > 50000:
		renderer.enable_lod = true
		renderer.max_elements_per_frame = 5000
		performance_warning.emit("Large grid detected, performance optimizations enabled")

## Property setters that update configuration
func set_grid_width(value: int) -> void:
	grid_width = value
	if config: config.set_grid_width(value)

func set_grid_height(value: int) -> void:
	grid_height = value
	if config: config.set_grid_height(value)

func set_hex_size(value: float) -> void:
	hex_size = value
	if config: config.set_hex_size(value)

func set_hex_color(value: Color) -> void:
	hex_color = value
	if config: config.set_hex_color(value)

func set_border_color(value: Color) -> void:
	border_color = value
	if config: config.set_border_color(value)

func set_border_width(value: float) -> void:
	border_width = value
	if config: config.set_border_width(value)

func set_dot_radius(value: float) -> void:
	dot_radius = value
	if config: config.set_dot_radius(value)

func set_dot_color(value: Color) -> void:
	dot_color = value
	if config: config.set_dot_color(value)

func set_dot_star_size(value: float) -> void:
	dot_star_size = value
	if config: config.set_dot_star_size(value)

func set_diamond_width(value: float) -> void:
	diamond_width = value
	if config: config.set_diamond_width(value)

func set_diamond_height(value: float) -> void:
	diamond_height = value
	if config: config.set_diamond_height(value)

func set_diamond_color(value: Color) -> void:
	diamond_color = value
	if config: config.set_diamond_color(value)

func set_hex_global_rotation_degrees(value: float) -> void:
	hex_global_rotation_degrees = value
	if config: config.set_global_rotation_degrees(value)

func set_enable_culling(value: bool) -> void:
	enable_culling = value
	if config: config.set_enable_culling(value)
	if renderer: renderer.set_culling_enabled(value)

func set_culling_margin(value: float) -> void:
	culling_margin = value
	if config: config.set_culling_margin(value)

func set_max_cache_size(value: int) -> void:
	max_cache_size = value
	if config: config.set_max_cache_size(value)

func set_show_debug_info(value: bool) -> void:
	show_debug_info = value
	if renderer: 
		renderer.set_layer_visibility(5, value)  # DEBUG layer
		redraw_grid()

## Initialize all component systems
func _initialize_components() -> void:
	# Create configuration system
	config = HexGridConfig.new()
	print("HexGrid: Config created")
	
	# Create geometry calculator
	geometry = HexGridGeometry.new()
	print("HexGrid: Geometry created")
	
	# Create cache system
	cache = HexGridCache.new()
	cache.setup_cache(config, geometry)
	print("HexGrid: Cache created and setup")
	
	# Create renderer
	renderer = HexGridRenderer.new()
	renderer.setup_renderer(config, cache, geometry)
	print("HexGrid: Renderer created and setup")
	
	print("HexGrid: Components initialized")

## Setup initial grid configuration
func _setup_grid() -> void:
	# Apply exported properties to configuration
	config.set_grid_width(grid_width)
	config.set_grid_height(grid_height)
	config.set_hex_size(hex_size)
	config.set_hex_color(hex_color)
	config.set_border_color(border_color)
	config.set_border_width(border_width)
	config.set_dot_radius(dot_radius)
	config.set_dot_color(dot_color)
	config.set_dot_star_size(dot_star_size)
	config.set_diamond_width(diamond_width)
	config.set_diamond_height(diamond_height)
	config.set_diamond_color(diamond_color)
	config.set_global_rotation_degrees(hex_global_rotation_degrees)
	config.set_enable_culling(enable_culling)
	config.set_culling_margin(culling_margin)
	config.set_max_cache_size(max_cache_size)
	
	# Configure renderer
	renderer.set_layer_visibility(5, show_debug_info)  # DEBUG layer

## Connect component signals
func _connect_signals() -> void:
	# Configuration change signals
	config.config_changed.connect(_on_config_changed)
	
	# Cache signals
	cache.cache_invalidated.connect(_on_cache_invalidated)
	cache.cache_rebuilt.connect(_on_cache_rebuilt)

## Handle configuration changes
## @param property_name String: Name of changed property
## @param old_value: Previous value
## @param new_value: New value
func _on_config_changed(property_name: String, old_value, new_value) -> void:
	print("HexGrid: Configuration changed - %s: %s -> %s" % [property_name, str(old_value), str(new_value)])
	redraw_grid()
	grid_updated.emit()

## Handle cache invalidation
func _on_cache_invalidated() -> void:
	print("HexGrid: Cache invalidated")
	redraw_grid()

## Handle cache rebuild completion
## @param cache_size int: New cache size
func _on_cache_rebuilt(cache_size: int) -> void:
	print("HexGrid: Cache rebuilt with %d elements" % cache_size)
	redraw_grid()

## Update exported properties from configuration
func _update_exported_properties() -> void:
	grid_width = config.grid_width
	grid_height = config.grid_height
	hex_size = config.hex_size
	hex_color = config.hex_color
	border_color = config.border_color
	border_width = config.border_width
	dot_radius = config.dot_radius
	dot_color = config.dot_color
	dot_star_size = config.dot_star_size
	diamond_width = config.diamond_width
	diamond_height = config.diamond_height
	diamond_color = config.diamond_color
	hex_global_rotation_degrees = config.global_rotation_degrees
	enable_culling = config.enable_culling
	culling_margin = config.culling_margin
	max_cache_size = config.max_cache_size

## Track rendering performance
## @param start_unix float: Start time from Time.get_unix_time_from_system()
func _track_performance(start_unix: float) -> void:
	var end_unix = Time.get_unix_time_from_system()
	var frame_time = (end_unix - start_unix) * 1000.0
	
	# Add to frame time history
	frame_times.append(frame_time)
	if frame_times.size() > max_frame_time_samples:
		frame_times.pop_front()
	
	# Check for performance issues
	if frame_time > performance_warning_threshold:
		var warning_msg = "Performance warning: Frame time %.2f ms (target: %.2f ms)" % [frame_time, performance_warning_threshold]
		performance_warning.emit(warning_msg)
		
		if auto_optimize_performance:
			optimize_performance()

## Get average frame time
## @return float: Average frame time in milliseconds
func get_average_frame_time() -> float:
	if frame_times.is_empty():
		return 0.0
	
	var total = 0.0
	for time in frame_times:
		total += time
	
	return total / frame_times.size()

## Handle input events (mouse wheel for zoom, page keys for hexagon count)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		# Handle mouse wheel for zoom
		if mouse_event.pressed:
			var camera = get_viewport().get_camera_2d()
			if camera:
				var zoom_factor = 0.1  # Zoom sensitivity
				var current_zoom = camera.zoom.x
				
				if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
					# Zoom in
					var new_zoom = current_zoom + zoom_factor
					new_zoom = clampf(new_zoom, 0.2, 5.0)  # Limit zoom range
					camera.zoom = Vector2(new_zoom, new_zoom)
					print("HexGrid: Zoom in to %.1fx" % new_zoom)
					get_viewport().set_input_as_handled()
					
				elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					# Zoom out
					var new_zoom = current_zoom - zoom_factor
					new_zoom = clampf(new_zoom, 0.2, 5.0)  # Limit zoom range
					camera.zoom = Vector2(new_zoom, new_zoom)
					print("HexGrid: Zoom out to %.1fx" % new_zoom)
					get_viewport().set_input_as_handled()
	
	elif event is InputEventKey:
		var key_event = event as InputEventKey
		
		# Handle Page Up/Down for hexagon count
		if key_event.pressed:
				if key_event.keycode == KEY_PAGEUP:
					# Increase hexagon count with spam protection
					if _can_process_input():
						_increase_hexagon_count()
					get_viewport().set_input_as_handled()
					
				elif key_event.keycode == KEY_PAGEDOWN:
					# Decrease hexagon count with spam protection
					if _can_process_input():
						_decrease_hexagon_count()
					get_viewport().set_input_as_handled()

## Center the grid on screen automatically
func _center_grid_on_screen() -> void:
	# Get the actual viewport size
	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	
	# Calculate the center of the screen
	var screen_center = viewport_size / 2.0
	
	# Position this node (HexGrid) at the center of the screen
	position = screen_center
	
	# Also center the camera if it exists and adjust zoom to show full hexagon
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.position = screen_center
		
		# Calculate required zoom to show full hexagon
		var hex_radius = grid_width
		var hex_size_pixels = hex_size
		var hex_width = hex_size_pixels * 1.732  # sqrt(3)
		var hex_height = hex_size_pixels * 2.0
		
		# Calculate hexagon bounds
		var hexagon_width = hex_width * (hex_radius * 2 - 1)
		var hexagon_height = hex_height * 0.75 * (hex_radius * 2 - 1)
		
		# Add margin and calculate zoom
		var margin = 1.2  # 20% margin
		var zoom_x = viewport_size.x / (hexagon_width * margin)
		var zoom_y = viewport_size.y / (hexagon_height * margin)
		var zoom_factor = min(zoom_x, zoom_y)
		
		# Clamp zoom to reasonable values
		zoom_factor = clampf(zoom_factor, 0.1, 2.0)
		camera.zoom = Vector2(zoom_factor, zoom_factor)
		
		print("HexGrid: Camera centered at: %s with zoom: %s" % [camera.position, camera.zoom])
	
	print("HexGrid: Viewport size: %s" % viewport_size)
	print("HexGrid: Screen center: %s" % screen_center)
	print("HexGrid: Grid positioned at: %s" % position)

## Check if input can be processed (spam protection)
func _can_process_input() -> bool:
	var current_time = Time.get_unix_time_from_system()
	
	# Check cooldown
	if current_time - last_input_time < input_cooldown:
		print("HexGrid: Input ignored (cooldown active)")
		return false
	
	# Check if already rebuilding
	if is_rebuilding:
		print("HexGrid: Input ignored (rebuild in progress)")
		return false
	
	last_input_time = current_time
	return true

## Increase hexagon count (add another ring)
func _increase_hexagon_count() -> void:
	# Check performance limit
	if grid_width >= max_grid_radius:
		print("HexGrid: Maximum radius reached (%d). Cannot increase further for performance reasons." % max_grid_radius)
		return
	
	grid_width += 1  # Increase radius
	
	# Performance warning and info
	var hex_count = 1 + 3 * grid_width * (grid_width - 1)  # Formula for hexagon count
	var dot_count_estimate = hex_count * 7  # Rough estimate (center + 6 vertices per hex)
	
	if grid_width >= performance_warning_radius:
		print("HexGrid: ⚠️  Performance Warning! Radius %d = %d hexagons (~%d dots). Consider reducing for better performance." % [grid_width, hex_count, dot_count_estimate])
	else:
		print("HexGrid: ✅ Increased radius to %d (%d hexagons, ~%d dots)" % [grid_width, hex_count, dot_count_estimate])
	
	# Update configuration
	if config:
		config.set_grid_width(grid_width)
	
	# Rebuild cache and redraw with protection
	is_rebuilding = true
	if cache:
		cache.build_cache(true)  # Force rebuild
	is_rebuilding = false
	
	# Update camera to fit new size
	_center_grid_on_screen()

## Decrease hexagon count (remove outer ring)
func _decrease_hexagon_count() -> void:
	if grid_width > 1:  # Don't go below 1 (just center hexagon)
		grid_width -= 1  # Decrease radius
		
		# Performance info
		var hex_count = 1 + 3 * grid_width * (grid_width - 1)  # Formula for hexagon count
		var dot_count_estimate = hex_count * 7  # Rough estimate
		print("HexGrid: ⬇️ Decreased radius to %d (%d hexagons, ~%d dots)" % [grid_width, hex_count, dot_count_estimate])
		
		# Update configuration
		if config:
			config.set_grid_width(grid_width)
		
		# Rebuild cache and redraw with protection
		is_rebuilding = true
		if cache:
			cache.build_cache(true)  # Force rebuild
		is_rebuilding = false
		
		# Update camera to fit new size
		_center_grid_on_screen()
	else:
		print("HexGrid: ⛔ Cannot decrease below radius 1 (minimum: 1 hexagon)")

## Clean up resources
func _exit_tree() -> void:
	if config:
		config.config_changed.disconnect(_on_config_changed)
	
	if cache:
		cache.cache_invalidated.disconnect(_on_cache_invalidated)
		cache.cache_rebuilt.disconnect(_on_cache_rebuilt)
	
	print("HexGrid: Cleaned up resources")