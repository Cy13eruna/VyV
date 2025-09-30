# 🔍 MINIMAL GAME
# Purpose: Absolute minimal version to test Godot loading

extends Node2D

func _ready():
	print("=== MINIMAL GAME READY ===")

func _draw():
	draw_rect(Rect2(0, 0, 1024, 768), Color.WHITE)
	var font = ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(100, 100), "MINIMAL GAME WORKING", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.BLACK)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()