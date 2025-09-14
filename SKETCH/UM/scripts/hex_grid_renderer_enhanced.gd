## HexGridRenderer Enhanced
## Simple enhanced renderer for hex grid
class_name HexGridRendererEnhanced
extends RefCounted

enum RenderLayer {
	BACKGROUND,
	DIAMONDS,
	HEXAGONS,
	STARS,
	HIGHLIGHTS,
	DEBUG
}

var render_stats: Dictionary = {
	"diamonds_rendered": 0,
	"stars_rendered": 0,
	"hexagons_rendered": 0,
	"culled_elements": 0,
	"total_draw_calls": 0,
	"last_render_time_ms": 0.0
}

var viewport_rect: Rect2 = Rect2()
var culling_enabled: bool = true
var culling_margin: float = 100.0

var layer_visibility: Dictionary = {
	RenderLayer.BACKGROUND: true,
	RenderLayer.DIAMONDS: true,
	RenderLayer.HEXAGONS: false,
	RenderLayer.STARS: true,
	RenderLayer.HIGHLIGHTS: true,
	RenderLayer.DEBUG: false
}

var max_elements_per_frame: int = 10000
var enable_lod: bool = true
var lod_distance_threshold: float = 500.0

var _config
var _cache
var _geometry

func setup_renderer(config, cache, geometry):
	_config = config
	_cache = cache
	_geometry = geometry
	
	if _config:
		culling_enabled = _config.enable_culling
		culling_margin = _config.culling_margin

func render_grid(canvas_item: CanvasItem, camera_transform: Transform2D = Transform2D()) -> void:
	var start_unix = Time.get_unix_time_from_system()
	
	_reset_render_stats()
	_update_viewport(camera_transform)
	
	if layer_visibility[RenderLayer.DIAMONDS]:
		_render_diamonds(canvas_item)
	
	if layer_visibility[RenderLayer.HEXAGONS]:
		_render_hexagons(canvas_item)
	
	if layer_visibility[RenderLayer.STARS]:
		_render_stars(canvas_item)
	
	if layer_visibility[RenderLayer.DEBUG]:
		_render_debug_info(canvas_item)
	
	var end_unix = Time.get_unix_time_from_system()
	render_stats.last_render_time_ms = (end_unix - start_unix) * 1000.0

func set_layer_visibility(layer: RenderLayer, visible: bool) -> void:
	layer_visibility[layer] = visible

func get_layer_visibility(layer: RenderLayer) -> bool:
	return layer_visibility.get(layer, false)

func set_culling_enabled(enabled: bool, margin: float = -1.0) -> void:
	culling_enabled = enabled
	if margin >= 0.0:
		culling_margin = margin

func get_render_stats() -> Dictionary:
	return render_stats.duplicate()

func should_render_point(point: Vector2) -> bool:
	if not culling_enabled:
		return true
	
	return _geometry.is_point_visible(point, viewport_rect, culling_margin)

func should_render_shape(shape_points: PackedVector2Array) -> bool:
	if not culling_enabled:
		return true
	
	for point in shape_points:
		if should_render_point(point):
			return true
	
	return false

func _render_diamonds(canvas_item: CanvasItem) -> void:
	var diamond_geometry = _cache.get_diamond_geometry()
	var diamond_colors = _cache.get_diamond_colors()
	
	var rendered_count = 0
	var culled_count = 0
	
	for i in range(diamond_geometry.size()):
		if rendered_count >= max_elements_per_frame:
			break
		
		var geometry = diamond_geometry[i]
		
		if not should_render_shape(geometry):
			culled_count += 1
			continue
		
		var color = diamond_colors[i] if i < diamond_colors.size() else Color.GREEN
		canvas_item.draw_colored_polygon(geometry, color)
		rendered_count += 1
		render_stats.total_draw_calls += 1
	
	render_stats.diamonds_rendered = rendered_count
	render_stats.culled_elements += culled_count

func _render_stars(canvas_item: CanvasItem) -> void:
	var dot_positions = _cache.get_dot_positions()
	
	var rendered_count = 0
	var culled_count = 0
	
	for i in range(dot_positions.size()):
		if rendered_count >= max_elements_per_frame:
			break
		
		var position = dot_positions[i]
		
		if not should_render_point(position):
			culled_count += 1
			continue
		
		var star_color = Color(1.0, 1.0, 1.0, 1.0)
		var radius = 4.0
		
		canvas_item.draw_circle(position, radius, star_color)
		
		rendered_count += 1
		render_stats.total_draw_calls += 1
	
	render_stats.stars_rendered = rendered_count
	render_stats.culled_elements += culled_count

func _render_hexagons(canvas_item: CanvasItem) -> void:
	var hex_positions = _cache.get_hex_positions()
	
	var rendered_count = 0
	var culled_count = 0
	
	for hex_center in hex_positions:
		if rendered_count >= max_elements_per_frame:
			break
		
		if not should_render_point(hex_center):
			culled_count += 1
			continue
		
		var vertices = _geometry.calculate_hex_vertices(hex_center, _config.hex_size)
		
		if _config.border_width > 0:
			for i in range(6):
				var start = vertices[i]
				var end = vertices[(i + 1) % 6]
				canvas_item.draw_line(start, end, _config.border_color, _config.border_width)
				render_stats.total_draw_calls += 1
		
		rendered_count += 1
	
	render_stats.hexagons_rendered = rendered_count
	render_stats.culled_elements += culled_count

func _render_debug_info(canvas_item: CanvasItem) -> void:
	if not layer_visibility[RenderLayer.DEBUG]:
		return
	
	if culling_enabled:
		canvas_item.draw_rect(viewport_rect, Color.RED, false, 2.0)
	
	var debug_text = "D:%d S:%d C:%d DC:%d RT:%.1fms" % [
		render_stats.diamonds_rendered,
		render_stats.stars_rendered,
		render_stats.culled_elements,
		render_stats.total_draw_calls,
		render_stats.last_render_time_ms
	]
	
	_draw_debug_text(canvas_item, debug_text, Vector2(10, 30))

func _draw_debug_text(canvas_item: CanvasItem, text: String, position: Vector2) -> void:
	var text_size = Vector2(text.length() * 8, 16)
	canvas_item.draw_rect(Rect2(position - Vector2(2, 2), text_size + Vector2(4, 4)), Color(0, 0, 0, 0.7))
	
	var char_width = 8
	for i in range(text.length()):
		var char_pos = position + Vector2(i * char_width, 0)
		var char = text[i]
		
		if char != ' ':
			canvas_item.draw_rect(Rect2(char_pos, Vector2(6, 12)), Color.WHITE)

func _update_viewport(camera_transform: Transform2D) -> void:
	if not culling_enabled:
		return
	
	var viewport = Engine.get_main_loop().current_scene.get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	
	var camera = viewport.get_camera_2d()
	if camera:
		var camera_position = camera.global_position
		var camera_zoom = camera.zoom
		
		var actual_size = viewport_size / camera_zoom
		viewport_rect = Rect2(
			camera_position - actual_size * 0.5,
			actual_size
		)
	else:
		viewport_rect = Rect2(Vector2.ZERO, viewport_size)

func _should_use_lod(position: Vector2) -> bool:
	if not enable_lod:
		return false
	
	var viewport_center = viewport_rect.get_center()
	var distance = position.distance_to(viewport_center)
	
	return distance > lod_distance_threshold

func _reset_render_stats() -> void:
	render_stats.diamonds_rendered = 0
	render_stats.stars_rendered = 0
	render_stats.hexagons_rendered = 0
	render_stats.culled_elements = 0
	render_stats.total_draw_calls = 0

func optimize_for_performance(target_fps: float = 60.0) -> void:
	var current_render_time = render_stats.last_render_time_ms
	var target_frame_time = 1000.0 / target_fps
	
	if current_render_time > target_frame_time:
		enable_lod = true
		lod_distance_threshold *= 0.8
		max_elements_per_frame = int(max_elements_per_frame * 0.9)
	elif current_render_time < target_frame_time * 0.5:
		lod_distance_threshold *= 1.1
		max_elements_per_frame = int(max_elements_per_frame * 1.05)