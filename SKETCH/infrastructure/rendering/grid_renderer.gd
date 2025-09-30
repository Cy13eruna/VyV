# 🔷 GRID RENDERER
# Purpose: Render hexagonal grid elements
# Layer: Infrastructure/Rendering
# Dependencies: Core entities, VisibilityService

class_name GridRenderer
extends RefCounted

static func render_grid(canvas: CanvasItem, grid_data: Dictionary, game_state: Dictionary, current_player_id: int) -> void:
	# Get visibility data
	var visible_points = VisibilityService.get_visible_points_for_player(
		current_player_id, grid_data, game_state.units, game_state.domains, game_state.fog_of_war_enabled
	)
	var visible_edges = VisibilityService.get_visible_edges_for_player(
		current_player_id, grid_data, game_state.units, game_state.domains, game_state.fog_of_war_enabled
	)
	
	# Render edges first
	_render_edges(canvas, grid_data, visible_edges, game_state.fog_of_war_enabled)
	
	# Render points
	_render_points(canvas, grid_data, visible_points, game_state.fog_of_war_enabled)

static func _render_edges(canvas: CanvasItem, grid_data: Dictionary, visible_edges: Array, fog_enabled: bool) -> void:
	for edge_id in grid_data.edges:
		if not fog_enabled or edge_id in visible_edges:
			var edge = grid_data.edges[edge_id]
			var point_a = grid_data.points[edge.point_a_id]
			var point_b = grid_data.points[edge.point_b_id]
			
			canvas.draw_line(
				point_a.position.pixel_pos,
				point_b.position.pixel_pos,
				edge.get_terrain_color(),
				GameConstants.EDGE_WIDTH
			)

static func _render_points(canvas: CanvasItem, grid_data: Dictionary, visible_points: Array, fog_enabled: bool) -> void:
	for point_id in grid_data.points:
		if not fog_enabled or point_id in visible_points:
			var point = grid_data.points[point_id]
			var color = Color.RED if point.is_corner else Color.BLACK
			var radius = GameConstants.POINT_RADIUS
			
			canvas.draw_circle(point.position.pixel_pos, radius, color)

static func render_hover_highlight(canvas: CanvasItem, grid_data: Dictionary, hovered_point_id: int) -> void:
	if hovered_point_id == -1 or hovered_point_id not in grid_data.points:
		return
	
	var point = grid_data.points[hovered_point_id]
	canvas.draw_circle(
		point.position.pixel_pos,
		GameConstants.POINT_RADIUS + 4.0,
		GameConstants.HIGHLIGHT_COLOR
	)