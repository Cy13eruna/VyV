## SimpleHexSelector
## 
## Sistema de seleção simples e funcional para hexágonos
## Funciona com qualquer grid que tenha get_hexagon_at_position()
##
## @author: V&V Game Studio
## @version: 1.0 - SIMPLE

extends Node2D

## Grid reference
var hex_grid: Node2D

## Selection state
var selected_hex: int = -1
var hovered_hex: int = -1

## Colors
var selection_color: Color = Color.YELLOW
var hover_color: Color = Color.CYAN

func _ready() -> void:
	print("SimpleHexSelector: Starting...")
	
	# Create minimal hex grid
	hex_grid = preload("res://scripts/minimal_hex_grid.gd").new()
	add_child(hex_grid)
	
	print("SimpleHexSelector: Minimal grid created and ready!")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_deselect()
	
	elif event is InputEventMouseMotion:
		_handle_hover(get_global_mouse_position())

func _handle_click(click_pos: Vector2) -> void:
	if not hex_grid:
		return
	
	var hex_index = hex_grid.get_hexagon_at_position(click_pos)
	
	if hex_index >= 0:
		selected_hex = hex_index
		print("Selected hexagon: %d at %s" % [hex_index, click_pos])
		queue_redraw()
	else:
		_deselect()

func _handle_hover(hover_pos: Vector2) -> void:
	if not hex_grid:
		return
	
	var hex_index = hex_grid.get_hexagon_at_position(hover_pos)
	
	if hex_index != hovered_hex:
		hovered_hex = hex_index
		queue_redraw()

func _deselect() -> void:
	if selected_hex >= 0:
		print("Deselected hexagon: %d" % selected_hex)
		selected_hex = -1
		queue_redraw()

func _draw() -> void:
	if not hex_grid:
		return
	
	var hex_positions = hex_grid.get_hex_positions()
	
	# Draw selection highlight
	if selected_hex >= 0 and selected_hex < hex_positions.size():
		var center = hex_positions[selected_hex]
		_draw_hex_highlight(center, hex_grid.hex_radius, selection_color, 4.0)
	
	# Draw hover highlight
	if hovered_hex >= 0 and hovered_hex < hex_positions.size() and hovered_hex != selected_hex:
		var center = hex_positions[hovered_hex]
		_draw_hex_highlight(center, hex_grid.hex_radius, hover_color, 2.0)

func _draw_hex_highlight(center: Vector2, radius: float, color: Color, width: float) -> void:
	var points: PackedVector2Array = []
	
	for i in range(6):
		var angle = deg_to_rad(60.0 * i - 30.0)
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	# Draw hexagon border
	for i in range(6):
		var start = points[i]
		var end = points[(i + 1) % 6]
		draw_line(start, end, color, width)