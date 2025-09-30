# 🎮 DEBUG MAIN GAME
# Purpose: Ultra simple version to test rendering
# Layer: Presentation

extends Node2D

func _ready():
	print("=== DEBUG GAME STARTING ===")
	print("Node2D ready, should call _draw() automatically")

func _draw():
	print("_draw() called!")
	
	# Draw white background FIRST
	draw_rect(Rect2(0, 0, 1024, 768), Color.WHITE)
	print("Background drawn")
	
	# Draw BIG test rectangle
	draw_rect(Rect2(100, 100, 400, 200), Color.RED)
	print("Red rectangle drawn")
	
	# Draw test circles with fixed colors
	for i in range(5):
		var colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.MAGENTA]
		draw_circle(Vector2(200 + i * 80, 400), 30, colors[i])
	print("Circles drawn")
	
	# Try drawing text with fallback
	var font = ThemeDB.fallback_font
	if font:
		print("Font available, drawing text")
		draw_string(font, Vector2(50, 50), "RENDERING TEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.BLACK)
		draw_string(font, Vector2(50, 100), "Text should be visible", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.BLUE)
	else:
		print("No font available!")
	
	print("_draw() completed")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				print("ESC pressed - quitting")
				get_tree().quit()
			KEY_SPACE:
				print("SPACE pressed - redrawing")
				queue_redraw()