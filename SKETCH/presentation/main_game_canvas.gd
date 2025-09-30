# 🎮 CANVAS TEST
# Purpose: Test using CanvasLayer for rendering

extends Control

func _ready():
	print("=== CANVAS TEST STARTING ===")
	# Set size to full screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Force redraw
	queue_redraw()

func _draw():
	print("=== CANVAS DRAW START ===")
	
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, get_size()), Color.LIGHT_BLUE)
	print("Background drawn: ", get_size())
	
	# Draw test rectangle
	draw_rect(Rect2(50, 50, 200, 100), Color.RED)
	print("Red rectangle drawn")
	
	# Draw text
	var font = ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(50, 30), "CANVAS TEST - SUCCESS!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.BLACK)
		draw_string(font, Vector2(50, 200), "If you see this, Control rendering works!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.DARK_BLUE)
		print("Text drawn")
	else:
		print("No font available")
	
	# Draw circles
	for i in range(5):
		draw_circle(Vector2(100 + i * 80, 300), 25, Color.GREEN)
	print("Circles drawn")
	
	print("=== CANVAS DRAW END ===")

func _gui_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()