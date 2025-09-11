extends Node2D

func _ready():
	print("TestWindow READY - window should be visible")
	# Force window to be visible and on top
	get_window().move_to_foreground()
	get_window().grab_focus()

func _draw():
	# Draw a big red background so it's impossible to miss
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color.RED)
	
	# Draw a big white circle in the center
	var center = get_viewport_rect().size / 2
	draw_circle(center, 200, Color.WHITE)
	
	# Draw text
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(100, 100), "TEST WINDOW - YOU SHOULD SEE THIS!", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.BLACK)
	draw_string(font, Vector2(100, 150), "If you see this, the window is working!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.BLACK)