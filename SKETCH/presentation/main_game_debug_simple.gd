# 🔍 DEBUG SIMPLE GAME
# Purpose: Minimal version to test loading without complex dependencies

extends Node2D

func _ready():
	print("=== DEBUG SIMPLE GAME STARTING ===")
	print("Step 1: Node2D ready")
	
	print("Step 2: Testing basic preloads...")
	test_preloads()
	
	print("Step 3: Testing basic game state...")
	test_basic_game_state()
	
	print("Step 4: Testing draw...")
	queue_redraw()
	
	print("=== DEBUG SIMPLE GAME READY ===")

func test_preloads():
	print("  - Testing HexCoordinate preload...")
	var HexCoordinate = preload("res://core/value_objects/hex_coordinate.gd")
	print("  - HexCoordinate OK")
	
	print("  - Testing Position preload...")
	var Position = preload("res://core/value_objects/position.gd")
	print("  - Position OK")
	
	print("  - Testing Player preload...")
	var Player = preload("res://core/entities/player.gd")
	print("  - Player OK")
	
	print("  - All preloads successful")

func test_basic_game_state():
	print("  - Creating basic game state...")
	var game_state = {
		"grid": {"points": {}, "edges": {}},
		"players": {},
		"units": {},
		"domains": {},
		"fog_of_war_enabled": true
	}
	print("  - Basic game state created: ", game_state.size(), " keys")

func _draw():
	print("_draw() called")
	
	# Draw background
	draw_rect(Rect2(0, 0, 1024, 768), Color.WHITE)
	
	# Draw test elements
	draw_rect(Rect2(100, 100, 200, 100), Color.RED)
	draw_circle(Vector2(400, 300), 50, Color.BLUE)
	
	# Draw text
	var font = ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(50, 50), "DEBUG SIMPLE GAME WORKING", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.BLACK)
		draw_string(font, Vector2(50, 100), "All basic systems functional", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GREEN)
	
	print("_draw() completed")

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("ESC pressed - quitting")
		get_tree().quit()