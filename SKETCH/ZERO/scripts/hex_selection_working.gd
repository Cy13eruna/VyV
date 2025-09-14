## HexSelectionWorking
## 
## Sistema de seleção que funciona com o grid hexagonal
## Versão robusta sem dependências problemáticas
##
## @author: V&V Game Studio
## @version: 1.0 - WORKING

extends Node2D

## Estado de seleção
var selected_hex_index: int = -1
var hovered_hex_index: int = -1
var mouse_pos: Vector2

## Cores
var selection_color: Color = Color.YELLOW
var hover_color: Color = Color.CYAN

## Referência ao grid (será encontrada automaticamente)
var hex_grid_node: Node2D

func _ready() -> void:
	print("HexSelectionWorking: Starting...")
	
	# Encontrar o grid hexagonal
	hex_grid_node = find_child("HexGridV2Enhanced")
	if not hex_grid_node:
		hex_grid_node = get_node_or_null("HexGridV2Enhanced")
	if not hex_grid_node:
		hex_grid_node = find_child("HexGridV2")
	if not hex_grid_node:
		hex_grid_node = get_node_or_null("HexGridV2")
	
	if hex_grid_node:
		print("HexSelectionWorking: Found hex grid!")
		# Aguardar um pouco para o grid estar pronto
		await get_tree().create_timer(1.0).timeout
		print("HexSelectionWorking: Ready for selection")
	else:
		print("HexSelectionWorking: No hex grid found, running in test mode")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_deselect()
	
	elif event is InputEventMouseMotion:
		mouse_pos = get_global_mouse_position()
		_handle_hover(mouse_pos)

func _handle_click(click_pos: Vector2) -> void:
	print("Click at: %s" % click_pos)
	
	if hex_grid_node and hex_grid_node.has_method("get_hexagon_at_position"):
		var hex_index = hex_grid_node.get_hexagon_at_position(click_pos)
		if hex_index >= 0:
			selected_hex_index = hex_index
			print("Selected hexagon: %d" % hex_index)
			queue_redraw()
		else:
			_deselect()
	else:
		# Modo de teste - apenas marcar posição
		selected_hex_index = 1
		print("Test mode - marked position")
		queue_redraw()

func _handle_hover(hover_pos: Vector2) -> void:
	if hex_grid_node and hex_grid_node.has_method("get_hexagon_at_position"):
		var hex_index = hex_grid_node.get_hexagon_at_position(hover_pos)
		if hex_index != hovered_hex_index:
			hovered_hex_index = hex_index
			queue_redraw()

func _deselect() -> void:
	if selected_hex_index >= 0:
		print("Deselected")
		selected_hex_index = -1
		queue_redraw()

func _draw() -> void:
	# Draw mouse position
	draw_circle(mouse_pos, 3, Color.RED)
	
	if not hex_grid_node:
		# Modo de teste
		draw_circle(Vector2(400, 300), 50, Color.GREEN)
		return
	
	# Tentar obter posições dos hexágonos
	if hex_grid_node.has_method("get_hexagon_at_position") and _has_cache():
		_draw_hex_highlights()
	else:
		# Fallback - desenhar indicador
		draw_circle(Vector2(400, 300), 20, Color.BLUE)

func _has_cache() -> bool:
	return hex_grid_node.has_method("get") and hex_grid_node.get("cache") != null

func _draw_hex_highlights() -> void:
	var cache = hex_grid_node.get("cache")
	var geometry = hex_grid_node.get("geometry")
	var config = hex_grid_node.get("config")
	
	if not cache or not geometry or not config:
		return
	
	if not cache.has_method("get_hex_positions"):
		return
	
	var hex_positions = cache.get_hex_positions()
	var hex_size = config.get("hex_size") if config.has_method("get") else 35.0
	
	# Draw selection
	if selected_hex_index >= 0 and selected_hex_index < hex_positions.size():
		var center = hex_positions[selected_hex_index]
		_draw_hex_border(center, hex_size, selection_color, 4.0)
	
	# Draw hover
	if hovered_hex_index >= 0 and hovered_hex_index < hex_positions.size() and hovered_hex_index != selected_hex_index:
		var center = hex_positions[hovered_hex_index]
		_draw_hex_border(center, hex_size, hover_color, 2.0)

func _draw_hex_border(center: Vector2, size: float, color: Color, width: float) -> void:
	# Desenhar hexágono simples
	var points: PackedVector2Array = []
	for i in range(6):
		var angle = deg_to_rad(60.0 * i - 30.0)
		var point = center + Vector2(cos(angle), sin(angle)) * size
		points.append(point)
	
	# Desenhar bordas
	for i in range(6):
		var start = points[i]
		var end = points[(i + 1) % 6]
		draw_line(start, end, color, width)