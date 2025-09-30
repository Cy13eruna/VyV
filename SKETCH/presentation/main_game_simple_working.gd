# 🎮 V&V SIMPLE WORKING GAME
# Purpose: Ultra simple version that definitely works
# Layer: Presentation

extends Node2D

# Simple game state
var players = []
var units = []
var grid_points = []
var selected_unit_index = -1
var current_player_index = 0
var valid_targets = []

# Simple classes
class SimplePlayer:
	var id: int
	var name: String
	var color: Color
	
	func _init(player_id: int, player_name: String, player_color: Color):
		id = player_id
		name = player_name
		color = player_color

class SimpleUnit:
	var id: int
	var owner_id: int
	var name: String
	var position: Vector2
	var actions_remaining: int = 1
	
	func _init(unit_id: int, player_id: int, unit_name: String, pos: Vector2):
		id = unit_id
		owner_id = player_id
		name = unit_name
		position = pos
	
	func can_move() -> bool:
		return actions_remaining > 0
	
	func move_to(new_pos: Vector2):
		position = new_pos
		actions_remaining -= 1
	
	func restore_actions():
		actions_remaining = 1
	
	func get_color() -> Color:
		return Color.RED if owner_id == 1 else Color.BLUE

class SimplePoint:
	var id: int
	var position: Vector2
	
	func _init(point_id: int, pos: Vector2):
		id = point_id
		position = pos

func _ready():
	print("=== V&V SIMPLE WORKING GAME ===")
	setup_game()
	print("Game ready! Click units to select, click points to move!")

func setup_game():
	# Create players
	players.append(SimplePlayer.new(1, "Player 1", Color.RED))
	players.append(SimplePlayer.new(2, "Player 2", Color.BLUE))
	
	# Create grid points (7 points in line)
	for i in range(7):
		var pos = Vector2(200 + i * 100, 300)
		grid_points.append(SimplePoint.new(i, pos))
	
	# Create units
	units.append(SimpleUnit.new(1, 1, "Unit1", grid_points[1].position))
	units.append(SimpleUnit.new(2, 2, "Unit2", grid_points[5].position))
	
	print("✅ Simple game setup complete!")
	print("- Players: %d" % players.size())
	print("- Units: %d" % units.size())
	print("- Grid points: %d" % grid_points.size())

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				_skip_turn()
			KEY_ESCAPE:
				get_tree().quit()

func _handle_click(mouse_pos: Vector2):
	# Check if clicking on unit
	for i in range(units.size()):
		var unit = units[i]
		if unit.position.distance_to(mouse_pos) <= 20.0 and unit.owner_id == players[current_player_index].id:
			_select_unit(i)
			return
	
	# Check if clicking on valid target
	if selected_unit_index != -1:
		for target_pos in valid_targets:
			if target_pos.distance_to(mouse_pos) <= 20.0:
				_move_unit_to(target_pos)
				return

func _select_unit(unit_index: int):
	selected_unit_index = unit_index
	var unit = units[unit_index]
	
	# Calculate valid targets (adjacent grid points)
	valid_targets.clear()
	for point in grid_points:
		var distance = unit.position.distance_to(point.position)
		if distance > 80 and distance < 120:  # Adjacent (roughly 100 units apart)
			# Check if position is not occupied
			var occupied = false
			for other_unit in units:
				if other_unit.position.distance_to(point.position) < 50:
					occupied = true
					break
			
			if not occupied:
				valid_targets.append(point.position)
	
	print("Unit selected: %s (%d valid moves)" % [unit.name, valid_targets.size()])
	queue_redraw()

func _move_unit_to(target_pos: Vector2):
	if selected_unit_index == -1:
		return
	
	var unit = units[selected_unit_index]
	if unit.can_move():
		unit.move_to(target_pos)
		print("✅ Unit moved!")
		_clear_selection()
		
		# Check if turn should advance
		if not unit.can_move():
			_skip_turn()
	else:
		print("❌ Unit has no actions")
	
	queue_redraw()

func _skip_turn():
	# Switch player
	current_player_index = (current_player_index + 1) % players.size()
	
	# Restore actions for current player's units
	for unit in units:
		if unit.owner_id == players[current_player_index].id:
			unit.restore_actions()
	
	_clear_selection()
	print("Turn: Player %s" % players[current_player_index].name)
	queue_redraw()

func _clear_selection():
	selected_unit_index = -1
	valid_targets.clear()

func _draw():
	# Draw background
	draw_rect(Rect2(0, 0, 1024, 768), Color.WHITE)
	
	# Draw grid points
	for point in grid_points:
		draw_circle(point.position, 8.0, Color.BLACK)
	
	# Draw units
	for i in range(units.size()):
		var unit = units[i]
		
		# Highlight selected unit
		if i == selected_unit_index:
			draw_circle(unit.position, 25.0, Color.YELLOW)
		
		# Draw unit
		draw_circle(unit.position, 20.0, unit.get_color())
		
		# Draw unit emoji
		var font = ThemeDB.fallback_font
		if font:
			draw_string(font, unit.position + Vector2(-8, 5), "🚶", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	
	# Draw valid targets
	for target in valid_targets:
		draw_circle(target, 15.0, Color.MAGENTA)
	
	# Draw UI
	_draw_ui()

func _draw_ui():
	var font = ThemeDB.fallback_font
	if not font:
		return
	
	# Current player
	var current_player = players[current_player_index]
	draw_string(font, Vector2(20, 30), "Current Player: %s" % current_player.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, current_player.color)
	
	# Controls
	var controls = [
		"CONTROLS:",
		"• Click your unit to select",
		"• Click magenta circle to move",
		"• ENTER: Skip turn",
		"• ESC: Quit"
	]
	
	for i in range(controls.size()):
		draw_string(font, Vector2(20, 70 + i * 16), controls[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK)