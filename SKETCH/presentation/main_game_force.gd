# 🎮 FORCE RENDER TEST
# Purpose: Force all rendering to work

extends Node2D

var frame_count = 0

func _ready():
	print("=== FORCE RENDER TEST ===")
	# Force multiple redraws
	for i in range(5):
		queue_redraw()

func _process(_delta):
	frame_count += 1
	if frame_count < 10:  # Redraw first 10 frames
		queue_redraw()

func _draw():
	print("FORCE DRAW - Frame: ", frame_count)
	
	# Force clear screen first
	RenderingServer.canvas_item_clear(get_canvas_item())
	
	# Draw solid background
	var screen_size = get_viewport().get_visible_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color.WHITE)
	
	# Draw large colored rectangles
	draw_rect(Rect2(0, 0, 200, 100), Color.RED)
	draw_rect(Rect2(200, 0, 200, 100), Color.GREEN) 
	draw_rect(Rect2(400, 0, 200, 100), Color.BLUE)
	
	# Draw text with multiple attempts
	var font = ThemeDB.fallback_font
	if font:
		# Try different positions and sizes
		draw_string(font, Vector2(50, 150), "FORCE RENDER SUCCESS!", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.BLACK)
		draw_string(font, Vector2(50, 200), "Frame: " + str(frame_count), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.BLUE)
		draw_string(font, Vector2(50, 250), "Architecture Working!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.GREEN)
	
	# Draw circles in different positions
	for i in range(10):
		var x = 50 + (i % 5) * 100
		var y = 300 + (i / 5) * 100
		draw_circle(Vector2(x, y), 25, Color.PURPLE)
		
		# Draw number in circle
		if font:
			var text = str(i)
			var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
			draw_string(font, Vector2(x, y) - text_size/2 + Vector2(0, 6), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
	
	print("FORCE DRAW COMPLETED")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_SPACE:
				queue_redraw()
				print("Manual redraw requested")