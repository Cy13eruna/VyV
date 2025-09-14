## SimpleSelectionTest
## 
## Teste simples de seleção de hexágonos sem dependências complexas
## Adiciona highlight visual direto no renderer enhanced
##
## @author: V&V Game Studio
## @version: 1.0 - SIMPLE TEST

extends Node2D

## Referência ao grid
@export var hex_grid: Node2D

## Estado de seleção
var selected_hex_index: int = -1
var hovered_hex_index: int = -1

## Cores de highlight
var selection_color: Color = Color.YELLOW
var hover_color: Color = Color.CYAN

func _ready() -> void:
	print("SimpleSelectionTest: Initialized")
	
	# Debug: verificar se hex_grid foi encontrado
	if not hex_grid:
		hex_grid = $HexGridV2Enhanced
		print("SimpleSelectionTest: Found hex_grid via get_node")
	
	if not hex_grid:
		print("ERROR: No hex_grid found!")
		return
	
	print("SimpleSelectionTest: hex_grid found, waiting for initialization...")
	
	# Aguardar o grid estar pronto
	if not hex_grid.is_initialized:
		print("SimpleSelectionTest: Waiting for grid_initialized signal...")
		await hex_grid.grid_initialized
	
	print("SimpleSelectionTest: Grid ready, selection active")
	print("SimpleSelectionTest: Grid has %d hexagons" % hex_grid.cache.get_hex_positions().size())

func _input(event: InputEvent) -> void:
	if not hex_grid or not hex_grid.is_initialized:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_deselect()
	
	elif event is InputEventMouseMotion:
		_handle_hover(get_global_mouse_position())

func _handle_click(mouse_pos: Vector2) -> void:
	var hex_index = hex_grid.get_hexagon_at_position(mouse_pos)
	
	if hex_index >= 0:
		selected_hex_index = hex_index
		print("Selected hexagon: %d at %s" % [hex_index, mouse_pos])
		queue_redraw()
	else:
		_deselect()

func _handle_hover(mouse_pos: Vector2) -> void:
	var hex_index = hex_grid.get_hexagon_at_position(mouse_pos)
	
	if hex_index != hovered_hex_index:
		hovered_hex_index = hex_index
		queue_redraw()

func _deselect() -> void:
	if selected_hex_index >= 0:
		print("Deselected hexagon: %d" % selected_hex_index)
		selected_hex_index = -1
		queue_redraw()

func _draw() -> void:
	if not hex_grid or not hex_grid.cache:
		return
	
	var hex_positions = hex_grid.cache.get_hex_positions()
	
	# Draw selection highlight
	if selected_hex_index >= 0 and selected_hex_index < hex_positions.size():
		_draw_hex_highlight(hex_positions[selected_hex_index], selection_color, 4.0)
	
	# Draw hover highlight
	if hovered_hex_index >= 0 and hovered_hex_index < hex_positions.size() and hovered_hex_index != selected_hex_index:
		_draw_hex_highlight(hex_positions[hovered_hex_index], hover_color, 2.0)

func _draw_hex_highlight(center: Vector2, color: Color, width: float) -> void:
	var hex_size = hex_grid.config.hex_size
	var vertices = hex_grid.geometry.calculate_hex_vertices(center, hex_size)
	
	# Draw hexagon border
	for i in range(6):
		var start = vertices[i]
		var end = vertices[(i + 1) % 6]
		draw_line(start, end, color, width)