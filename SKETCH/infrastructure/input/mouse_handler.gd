# 🖱️ MOUSE HANDLER
# Purpose: Handle mouse input events
# Layer: Infrastructure/Input
# Dependencies: Core entities only

class_name MouseHandler
extends RefCounted

signal point_clicked(point_id: int)
signal point_hovered(point_id: int)
signal point_unhovered(point_id: int)

var current_hovered_point: int = -1

func handle_mouse_motion(mouse_pos: Vector2, grid_data: Dictionary) -> void:
	var hovered_point = _find_point_at_mouse(mouse_pos, grid_data)
	
	if hovered_point != current_hovered_point:
		# Unhover previous point
		if current_hovered_point != -1:
			point_unhovered.emit(current_hovered_point)
		
		# Hover new point
		current_hovered_point = hovered_point
		if current_hovered_point != -1:
			point_hovered.emit(current_hovered_point)

func handle_mouse_click(mouse_pos: Vector2, grid_data: Dictionary) -> void:
	var clicked_point = _find_point_at_mouse(mouse_pos, grid_data)
	if clicked_point != -1:
		point_clicked.emit(clicked_point)

func _find_point_at_mouse(mouse_pos: Vector2, grid_data: Dictionary) -> int:
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.is_mouse_over(mouse_pos):
			return point_id
	return -1

func get_hovered_point() -> int:
	return current_hovered_point

func clear_hover() -> void:
	if current_hovered_point != -1:
		point_unhovered.emit(current_hovered_point)
		current_hovered_point = -1