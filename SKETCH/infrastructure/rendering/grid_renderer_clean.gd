# 🗺️ GRID RENDERER (CLEAN)
# Purpose: Professional grid rendering with visual enhancements
# Layer: Infrastructure/Rendering
# Dependencies: Clean services for data

extends RefCounted

# Rendering configuration
const POINT_RADIUS = 6.0
const CORNER_RADIUS = 8.0
const EDGE_WIDTH = 2.0
const HOVER_RADIUS = 12.0

const COLOR_POINT = Color.BLACK
const COLOR_CORNER = Color.RED
const COLOR_EDGE = Color.GRAY
const COLOR_HOVER = Color(1, 1, 0, 0.7)  # Yellow with transparency

# Render complete grid
static func render_grid(canvas: CanvasItem, grid_data: Dictionary, hover_state: Dictionary = {}) -> void:
	if grid_data.is_empty():
		return
	
	# Draw edges first (behind points)
	_render_edges(canvas, grid_data)
	
	# Draw points
	_render_points(canvas, grid_data, hover_state)
	
	# Draw hover effects
	_render_hover_effects(canvas, grid_data, hover_state)

# Render grid edges
static func _render_edges(canvas: CanvasItem, grid_data: Dictionary) -> void:
	if not ("edges" in grid_data and "points" in grid_data):
		return
	
	for edge_id in grid_data.edges:
		var edge = grid_data.edges[edge_id]
		
		if edge.point_a_id in grid_data.points and edge.point_b_id in grid_data.points:
			var point_a = grid_data.points[edge.point_a_id]
			var point_b = grid_data.points[edge.point_b_id]
			
			var color = _get_edge_color(edge)
			canvas.draw_line(
				point_a.position.pixel_pos,
				point_b.position.pixel_pos,
				color,
				EDGE_WIDTH
			)

# Render grid points
static func _render_points(canvas: CanvasItem, grid_data: Dictionary, hover_state: Dictionary) -> void:
	if not ("points" in grid_data):
		return
	
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		var position = point.position.pixel_pos
		
		# Choose color and radius based on point type
		var color = COLOR_CORNER if point.is_corner else COLOR_POINT
		var radius = CORNER_RADIUS if point.is_corner else POINT_RADIUS
		
		# Draw point
		canvas.draw_circle(position, radius, color)
		
		# Draw point outline for better visibility
		canvas.draw_arc(position, radius + 1, 0, TAU, 32, Color.WHITE, 1.0)

# Render hover effects
static func _render_hover_effects(canvas: CanvasItem, grid_data: Dictionary, hover_state: Dictionary) -> void:
	if hover_state.is_empty():
		return
	
	# Hover effect for points
	if "hovered_point_id" in hover_state and hover_state.hovered_point_id != -1:
		var point_id = hover_state.hovered_point_id
		if point_id in grid_data.points:
			var point = grid_data.points[point_id]
			canvas.draw_circle(point.position.pixel_pos, HOVER_RADIUS, COLOR_HOVER)

# Get edge color based on terrain type
static func _get_edge_color(edge) -> Color:
	# Future: Different colors for different terrain types
	match edge.terrain_type:
		0:  # FIELD
			return Color.LIGHT_GRAY
		1:  # FOREST
			return Color.GREEN
		2:  # MOUNTAIN
			return Color.BROWN
		3:  # WATER
			return Color.BLUE
		_:
			return COLOR_EDGE

# Render grid with fog of war
static func render_grid_with_fog(canvas: CanvasItem, grid_data: Dictionary, visible_points: Array, visible_edges: Array, hover_state: Dictionary = {}) -> void:
	# Draw only visible edges
	_render_visible_edges(canvas, grid_data, visible_edges)
	
	# Draw only visible points
	_render_visible_points(canvas, grid_data, visible_points, hover_state)
	
	# Draw hover effects only for visible elements
	_render_fog_hover_effects(canvas, grid_data, visible_points, hover_state)

# Render only visible edges
static func _render_visible_edges(canvas: CanvasItem, grid_data: Dictionary, visible_edges: Array) -> void:
	if not ("edges" in grid_data and "points" in grid_data):
		return
	
	for edge_id in visible_edges:
		if edge_id in grid_data.edges:
			var edge = grid_data.edges[edge_id]
			
			if edge.point_a_id in grid_data.points and edge.point_b_id in grid_data.points:
				var point_a = grid_data.points[edge.point_a_id]
				var point_b = grid_data.points[edge.point_b_id]
				
				var color = _get_edge_color(edge)
				canvas.draw_line(
					point_a.position.pixel_pos,
					point_b.position.pixel_pos,
					color,
					EDGE_WIDTH
				)

# Render only visible points
static func _render_visible_points(canvas: CanvasItem, grid_data: Dictionary, visible_points: Array, hover_state: Dictionary) -> void:
	if not ("points" in grid_data):
		return
	
	for point_id in visible_points:
		if point_id in grid_data.points:
			var point = grid_data.points[point_id]
			var position = point.position.pixel_pos
			
			var color = COLOR_CORNER if point.is_corner else COLOR_POINT
			var radius = CORNER_RADIUS if point.is_corner else POINT_RADIUS
			
			canvas.draw_circle(position, radius, color)
			canvas.draw_arc(position, radius + 1, 0, TAU, 32, Color.WHITE, 1.0)

# Render fog hover effects
static func _render_fog_hover_effects(canvas: CanvasItem, grid_data: Dictionary, visible_points: Array, hover_state: Dictionary) -> void:
	if hover_state.is_empty():
		return
	
	if "hovered_point_id" in hover_state and hover_state.hovered_point_id != -1:
		var point_id = hover_state.hovered_point_id
		
		# Only show hover if point is visible
		if point_id in visible_points and point_id in grid_data.points:
			var point = grid_data.points[point_id]
			canvas.draw_circle(point.position.pixel_pos, HOVER_RADIUS, COLOR_HOVER)

# Render grid statistics overlay
static func render_grid_stats(canvas: CanvasItem, grid_data: Dictionary, position: Vector2, font) -> void:
	if not font:
		return
	
	var stats_text = [
		"GRID STATISTICS:",
		"Points: %d" % grid_data.points.size(),
		"Edges: %d" % grid_data.edges.size(),
		"Radius: %d" % grid_data.radius
	]
	
	for i in range(stats_text.size()):
		var text = stats_text[i]
		var y_offset = i * 16
		var color = Color.WHITE if i == 0 else Color.LIGHT_GRAY
		
		canvas.draw_string(font, position + Vector2(0, y_offset), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)