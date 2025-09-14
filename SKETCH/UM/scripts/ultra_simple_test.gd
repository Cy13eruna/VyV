## UltraSimpleTest
## 
## Teste ultra simples apenas para verificar se conseguimos detectar cliques
## Sem dependências complexas
##
## @author: V&V Game Studio
## @version: 1.0 - ULTRA SIMPLE

extends Node2D

## Estado básico
var mouse_pos: Vector2
var clicked_positions: Array[Vector2] = []

func _ready() -> void:
	print("UltraSimpleTest: Ready - Click anywhere to test")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_pos = get_global_mouse_position()
			clicked_positions.append(mouse_pos)
			print("Clicked at: %s" % mouse_pos)
			queue_redraw()
	
	elif event is InputEventMouseMotion:
		mouse_pos = get_global_mouse_position()
		queue_redraw()

func _draw() -> void:
	# Draw mouse position
	draw_circle(mouse_pos, 5, Color.RED)
	
	# Draw all clicked positions
	for i in range(clicked_positions.size()):
		var pos = clicked_positions[i]
		draw_circle(pos, 10, Color.YELLOW)
		
		# Draw number
		var text = str(i + 1)
		draw_circle(pos, 15, Color.BLACK)
		draw_circle(pos, 12, Color.YELLOW)
	
	# Draw instructions
	var instructions = "Click to mark positions. Red circle follows mouse."
	# Simple text simulation using rectangles
	var text_pos = Vector2(10, 30)
	draw_rect(Rect2(text_pos - Vector2(2, 2), Vector2(instructions.length() * 8, 20)), Color.BLACK)
	
	print("Drawing - Mouse: %s, Clicks: %d" % [mouse_pos, clicked_positions.size()])