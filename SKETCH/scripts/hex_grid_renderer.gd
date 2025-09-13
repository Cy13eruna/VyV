## HexGridRenderer
## 
## Optimized rendering system for hexagonal grid visualization.
## Provides layered rendering with culling, dirty region tracking,
## and performance optimizations for large grids.
##
## @author: V&V Game Studio
## @version: 2.0

class_name HexGridRenderer
extends RefCounted

## Rendering layer enumeration
enum RenderLayer {
	BACKGROUND,    # Background elements
	DIAMONDS,      # Diamond connections
	HEXAGONS,      # Hexagon outlines (if enabled)
	STARS,         # Star decorations
	HIGHLIGHTS,    # Interactive highlights
	DEBUG          # Debug information
}

## Rendering statistics
var render_stats: Dictionary = {
	"diamonds_rendered": 0,
	"stars_rendered": 0,
	"hexagons_rendered": 0,
	"culled_elements": 0,
	"total_draw_calls": 0,
	"last_render_time_ms": 0.0
}

## Culling and optimization
var viewport_rect: Rect2 = Rect2()
var culling_enabled: bool = true
var culling_margin: float = 100.0
var dirty_regions: Array[Rect2] = []

## Layer visibility control
var layer_visibility: Dictionary = {
	RenderLayer.BACKGROUND: true,
	RenderLayer.DIAMONDS: true,
	RenderLayer.HEXAGONS: false,  # Disabled by default for performance
	RenderLayer.STARS: true,
	RenderLayer.HIGHLIGHTS: true,
	RenderLayer.DEBUG: false
}

## Performance settings
var max_elements_per_frame: int = 10000
var use_batch_rendering: bool = true
var enable_lod: bool = true  # Level of detail
var lod_distance_threshold: float = 500.0

## Component references
var _config
var _cache
var _geometry

## Initialize renderer
func _init():
	pass

## Setup renderer with dependencies
## @param config: Configuration object
## @param cache: Cache system
## @param geometry: Geometry calculator
func setup_renderer(config, cache, geometry):
	_config = config
	_cache = cache
	_geometry = geometry
	
	# Update settings from config
	if _config:
		culling_enabled = _config.enable_culling
		culling_margin = _config.culling_margin

## Render complete grid to a CanvasItem
## @param canvas_item CanvasItem: Target for rendering (usually Node2D)
## @param camera_transform Transform2D: Camera transformation for culling
func render_grid(canvas_item: CanvasItem, camera_transform: Transform2D = Transform2D()) -> void:
	var start_unix = Time.get_unix_time_from_system()
	
	# Reset render statistics
	_reset_render_stats()
	
	# Update viewport for culling
	_update_viewport(camera_transform)
	
	# Render layers in order
	if layer_visibility[RenderLayer.BACKGROUND]:
		_render_background(canvas_item)
	
	if layer_visibility[RenderLayer.DIAMONDS]:
		_render_diamonds(canvas_item)
	
	if layer_visibility[RenderLayer.HEXAGONS]:
		_render_hexagons(canvas_item)
	
	if layer_visibility[RenderLayer.STARS]:
		_render_stars(canvas_item)
	
	if layer_visibility[RenderLayer.HIGHLIGHTS]:
		_render_highlights(canvas_item)
	
	if layer_visibility[RenderLayer.DEBUG]:
		_render_debug_info(canvas_item)
	
	# Calculate render time
	var end_unix = Time.get_unix_time_from_system()
	render_stats.last_render_time_ms = (end_unix - start_unix) * 1000.0

## Set layer visibility
## @param layer RenderLayer: Layer to modify
## @param visible bool: Visibility state
func set_layer_visibility(layer: RenderLayer, visible: bool) -> void:
	layer_visibility[layer] = visible

## Get layer visibility
## @param layer RenderLayer: Layer to check
## @return bool: Current visibility state
func get_layer_visibility(layer: RenderLayer) -> bool:
	return layer_visibility.get(layer, false)

## Enable/disable culling
## @param enabled bool: Culling state
## @param margin float: Culling margin (optional)
func set_culling_enabled(enabled: bool, margin: float = -1.0) -> void:
	culling_enabled = enabled
	if margin >= 0.0:
		culling_margin = margin

## Add dirty region for selective rendering
## @param region Rect2: Region that needs re-rendering
func add_dirty_region(region: Rect2) -> void:
	dirty_regions.append(region)

## Clear all dirty regions
func clear_dirty_regions() -> void:
	dirty_regions.clear()

## Get current rendering statistics
## @return Dictionary: Rendering performance data
func get_render_stats() -> Dictionary:
	return render_stats.duplicate()

## Check if a point should be rendered (culling test)
## @param point Vector2: Point to test
## @return bool: True if point should be rendered
func should_render_point(point: Vector2) -> bool:
	if not culling_enabled:
		return true
	
	return _geometry.is_point_visible(point, viewport_rect, culling_margin)

## Check if a shape should be rendered (culling test)
## @param shape_points PackedVector2Array: Shape vertices to test
## @return bool: True if shape should be rendered
func should_render_shape(shape_points: PackedVector2Array) -> bool:
	if not culling_enabled:
		return true
	
	# Check if any vertex is visible
	for point in shape_points:
		if should_render_point(point):
			return true
	
	return false

## Render diamond connections
## @param canvas_item CanvasItem: Target for rendering
func _render_diamonds(canvas_item: CanvasItem) -> void:
	var diamond_geometry = _cache.get_diamond_geometry()
	var diamond_colors = _cache.get_diamond_colors()
	
	var rendered_count = 0
	var culled_count = 0
	
	for i in range(diamond_geometry.size()):
		if rendered_count >= max_elements_per_frame:
			break
		
		var geometry = diamond_geometry[i]
		
		# Disable culling for diamonds to ensure all render
		# Culling test
		# if not should_render_shape(geometry):
		#	culled_count += 1
		#	continue
		
		# Get color for this diamond
		var color = diamond_colors[i] if i < diamond_colors.size() else Color.GREEN
		
		# Render diamond
		canvas_item.draw_colored_polygon(geometry, color)
		rendered_count += 1
		render_stats.total_draw_calls += 1
	
	render_stats.diamonds_rendered = rendered_count
	render_stats.culled_elements += culled_count

## Render star decorations
## @param canvas_item CanvasItem: Target for rendering
func _render_stars(canvas_item: CanvasItem) -> void:
	var star_geometry = _cache.get_star_geometry()
	var dot_positions = _cache.get_dot_positions()
	
	var rendered_count = 0
	var culled_count = 0
	
	for i in range(star_geometry.size()):
		if rendered_count >= max_elements_per_frame:
			break
		
		var geometry = star_geometry[i]
		
		# Disable culling for diamonds too to ensure all render
		# Culling test
		# if not should_render_shape(geometry):
		#	culled_count += 1
		#	continue
		
		# Always render full star (disable LOD temporarily)
		canvas_item.draw_colored_polygon(geometry, _config.dot_color)
		
		rendered_count += 1
		render_stats.total_draw_calls += 1
	
	render_stats.stars_rendered = rendered_count
	render_stats.culled_elements += culled_count

## Render hexagon outlines (optional)
## @param canvas_item CanvasItem: Target for rendering
func _render_hexagons(canvas_item: CanvasItem) -> void:
	var hex_positions = _cache.get_hex_positions()
	
	var rendered_count = 0
	var culled_count = 0
	
	for hex_center in hex_positions:
		if rendered_count >= max_elements_per_frame:
			break
		
		# Culling test
		if not should_render_point(hex_center):
			culled_count += 1
			continue
		
		# Calculate hexagon vertices
		var vertices = _geometry.calculate_hex_vertices(hex_center, _config.hex_size)
		
		# Draw hexagon outline
		if _config.border_width > 0:
			for i in range(6):
				var start = vertices[i]
				var end = vertices[(i + 1) % 6]
				canvas_item.draw_line(start, end, _config.border_color, _config.border_width)
				render_stats.total_draw_calls += 1
		
		rendered_count += 1
	
	render_stats.hexagons_rendered = rendered_count
	render_stats.culled_elements += culled_count

## Render background elements
## @param canvas_item CanvasItem: Target for rendering
func _render_background(canvas_item: CanvasItem) -> void:
	# Background rendering can be implemented here
	# For now, this is a placeholder for future background elements
	pass

## Render highlight effects
## @param canvas_item CanvasItem: Target for rendering
func _render_highlights(canvas_item: CanvasItem) -> void:
	# Highlight rendering can be implemented here
	# For now, this is a placeholder for future interactive highlights
	pass

## Render debug information
## @param canvas_item CanvasItem: Target for rendering
func _render_debug_info(canvas_item: CanvasItem) -> void:
	if not layer_visibility[RenderLayer.DEBUG]:
		return
	
	# Draw viewport bounds
	if culling_enabled:
		canvas_item.draw_rect(viewport_rect, Color.RED, false, 2.0)
	
	# Draw performance info
	var debug_text = "Diamonds: %d, Stars: %d, Culled: %d, Draw Calls: %d, Render Time: %.2f ms" % [
		render_stats.diamonds_rendered,
		render_stats.stars_rendered,
		render_stats.culled_elements,
		render_stats.total_draw_calls,
		render_stats.last_render_time_ms
	]
	
	# Note: Text rendering would need a font resource
	# canvas_item.draw_string(font, Vector2(10, 30), debug_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

## Update viewport rectangle for culling
## @param camera_transform Transform2D: Camera transformation
func _update_viewport(camera_transform: Transform2D) -> void:
	if not culling_enabled:
		return
	
	# Get actual viewport size from the current viewport
	var viewport = Engine.get_main_loop().current_scene.get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	
	# Get camera information
	var camera = viewport.get_camera_2d()
	if camera:
		var camera_position = camera.global_position
		var camera_zoom = camera.zoom
		
		# Calculate actual visible area with proper zoom
		var actual_size = viewport_size / camera_zoom
		viewport_rect = Rect2(
			camera_position - actual_size * 0.5,
			actual_size
		)
		
		print("HexGridRenderer: Viewport updated - size: %s, camera pos: %s, zoom: %s" % [actual_size, camera_position, camera_zoom])
	else:
		# Fallback if no camera
		viewport_rect = Rect2(Vector2.ZERO, viewport_size)

## Check if level of detail should be used for a position
## @param position Vector2: Position to check
## @return bool: True if LOD should be used
func _should_use_lod(position: Vector2) -> bool:
	if not enable_lod:
		return false
	
	# Calculate distance from viewport center
	var viewport_center = viewport_rect.get_center()
	var distance = position.distance_to(viewport_center)
	
	return distance > lod_distance_threshold

## Reset rendering statistics
func _reset_render_stats() -> void:
	render_stats.diamonds_rendered = 0
	render_stats.stars_rendered = 0
	render_stats.hexagons_rendered = 0
	render_stats.culled_elements = 0
	render_stats.total_draw_calls = 0

## Optimize rendering settings based on performance
## @param target_fps float: Target frame rate
func optimize_for_performance(target_fps: float = 60.0) -> void:
	var current_render_time = render_stats.last_render_time_ms
	var target_frame_time = 1000.0 / target_fps  # Convert to milliseconds
	
	if current_render_time > target_frame_time:
		# Performance is below target, enable optimizations
		enable_lod = true
		lod_distance_threshold *= 0.8  # Reduce LOD threshold
		max_elements_per_frame = int(max_elements_per_frame * 0.9)  # Reduce max elements
		
		print("HexGridRenderer: Performance optimization enabled (render time: %.2f ms)" % current_render_time)
	elif current_render_time < target_frame_time * 0.5:
		# Performance is well above target, can increase quality
		lod_distance_threshold *= 1.1  # Increase LOD threshold
		max_elements_per_frame = int(max_elements_per_frame * 1.05)  # Increase max elements
		
		print("HexGridRenderer: Quality increased (render time: %.2f ms)" % current_render_time)