# 🎮 MINIMAL TEST
# Purpose: Test basic rendering step by step

extends Node2D

func _ready():
	print("=== MINIMAL TEST STARTING ===")

func _draw():
	print("=== DRAW START ===")
	
	# Test 1: Try to draw background
	print("Drawing background...")
	draw_rect(Rect2(0, 0, 1024, 768), Color.YELLOW)
	
	# Test 2: Draw simple shapes
	print("Drawing shapes...")
	draw_rect(Rect2(50, 50, 100, 100), Color.RED)
	draw_circle(Vector2(200, 200), 50, Color.GREEN)
	
	# Test 3: Try text without font
	print("Drawing text...")
	var font = ThemeDB.fallback_font
	if font:
		print("Font found, drawing...")
		draw_string(font, Vector2(300, 100), "TEST TEXT", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.BLACK)
	else:
		print("NO FONT FOUND!")
	
	# Test 4: Draw more circles (these work)
	print("Drawing test circles...")
	for i in range(3):
		draw_circle(Vector2(100 + i * 100, 400), 30, Color.BLUE)
	
	print("=== DRAW END ===")

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()