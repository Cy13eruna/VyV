## Star Test
## Simple test to verify star rendering

extends Node2D

func _draw():
	# Test 1: Simple white circle
	draw_circle(Vector2(100, 100), 10, Color.WHITE)
	
	# Test 2: Simple white star using polygon
	var star_points = PackedVector2Array()
	var center = Vector2(200, 100)
	var outer_radius = 15.0
	var inner_radius = 7.0
	
	# Create a 6-pointed star
	for i in range(12):
		var angle_deg = 30.0 * i
		var angle_rad = deg_to_rad(angle_deg)
		var radius = outer_radius if i % 2 == 0 else inner_radius
		var point = center + Vector2(cos(angle_rad), sin(angle_rad)) * radius
		star_points.append(point)
	
	draw_colored_polygon(star_points, Color.WHITE)
	
	# Test 3: Force white with explicit values
	var test_color = Color(1.0, 1.0, 1.0, 1.0)
	draw_circle(Vector2(300, 100), 10, test_color)
	
	print("Star test rendered - circles and star should be WHITE")