# 🎮 V&V FUNCTIONAL GAME
# Purpose: Working game without complex static dependencies
# Layer: Presentation

extends Node2D

# Game state
var game_state: Dictionary = {}
var selected_unit_id: int = -1
var valid_movement_targets: Array = []
var hovered_point_id: int = -1
var current_player_id: int = 1
var game_over: bool = false

func _ready():
	print("=== V&V FUNCTIONAL GAME STARTING ===")
	setup_simple_game()
	print("Game ready! Click units to select, click valid positions to move!")

func setup_simple_game():
	# Create simple functional game
	game_state = {
		"grid": {"points": {}, "edges": {}},
		"players": {},
		"units": {},
		"domains": {},
		"turn_data": {"current_player_id": 1, "turn_number": 1, "is_game_active": true},
		"fog_of_war_enabled": true
	}
	
	# Create simple grid (7 points in line)
	for i in range(7):
		var coord_script = load("res://core/value_objects/hex_coordinate.gd")
		var pos_script = load("res://core/value_objects/position.gd")
		var point_script = load("res://core/entities/hex_point.gd")
		
		var coord = coord_script.new(i - 3, 0)
		var position = pos_script.from_hex(coord)
		var point = point_script.new(i, coord)
		game_state.grid.points[i] = point
	
	# Create players
	var player_script = load("res://core/entities/player.gd")
	var player1 = player_script.new(1, "Player 1", Color.RED)
	var player2 = player_script.new(2, "Player 2", Color.BLUE)
	game_state.players = {1: player1, 2: player2}
	
	# Create units
	var unit_script = load("res://core/entities/unit.gd")
	var unit1_pos = game_state.grid.points[1].position
	var unit2_pos = game_state.grid.points[5].position
	
	var unit1 = unit_script.new(1, 1, "Unit1", unit1_pos)
	var unit2 = unit_script.new(2, 2, "Unit2", unit2_pos)
	
	game_state.units = {1: unit1, 2: unit2}
	player1.add_unit(1)
	player2.add_unit(2)
	
	print("✅ Functional game initialized!")
	print("- Grid: %d points" % game_state.grid.points.size())
	print("- Players: %d" % game_state.players.size())
	print("- Units: %d" % game_state.units.size())

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				game_state.fog_of_war_enabled = not game_state.fog_of_war_enabled
				print("Fog of war: ", "ON" if game_state.fog_of_war_enabled else "OFF")
				queue_redraw()
			KEY_ENTER:
				_skip_turn()
			KEY_ESCAPE:
				get_tree().quit()

func _handle_click(mouse_pos: Vector2):
	if game_over:
		return
	
	# Find clicked point
	var clicked_point_id = _find_point_at_mouse(mouse_pos)
	if clicked_point_id == -1:
		return
	
	var clicked_position = game_state.grid.points[clicked_point_id].position
	var current_player = game_state.players[current_player_id]
	
	# Check if clicking on unit to select
	var unit_at_position = _find_unit_at_position(clicked_position)
	if unit_at_position and unit_at_position.owner_id == current_player_id:
		_select_unit(unit_at_position.id)
		return
	
	# Check if moving selected unit
	if selected_unit_id != -1:
		_attempt_move_unit(clicked_position)

func _find_point_at_mouse(mouse_pos: Vector2) -> int:
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.pixel_pos.distance_to(mouse_pos) <= 20.0:
			return point_id
	return -1

func _find_unit_at_position(position):
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.position.equals(position):
			return unit
	return null

func _select_unit(unit_id: int):
	selected_unit_id = unit_id
	var unit = game_state.units[unit_id]
	
	# Calculate valid targets (adjacent positions)
	valid_movement_targets.clear()
	var unit_coord = unit.position.hex_coord
	
	# Check all 6 adjacent positions
	for direction in range(6):
		var neighbor_coord = unit_coord.get_neighbor(direction)
		var neighbor_pos = load("res://core/value_objects/position.gd").from_hex(neighbor_coord)
		
		# Check if position is valid and not occupied
		if _is_valid_move_target(neighbor_pos):
			valid_movement_targets.append(neighbor_pos)
	
	print("Unit selected: %s (%d valid moves)" % [unit.name, valid_movement_targets.size()])
	queue_redraw()

func _is_valid_move_target(target_position) -> bool:
	# Check if position is on grid
	var on_grid = false
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(target_position):
			on_grid = true
			break
	
	if not on_grid:
		return false
	
	# Check if position is occupied
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.position.equals(target_position):
			return false
	
	return true

func _attempt_move_unit(target_position):
	if selected_unit_id == -1:
		return
	
	var unit = game_state.units[selected_unit_id]
	
	# Check if target is valid
	var is_valid = false
	for valid_target in valid_movement_targets:
		if valid_target.equals(target_position):
			is_valid = true
			break
	
	if not is_valid:
		print("❌ Invalid move target")
		return
	
	# Execute movement
	if unit.can_move():
		unit.move_to(target_position)
		print("✅ Unit moved successfully!")
		_clear_selection()
		
		# Check if turn should advance
		if not unit.can_move():
			_skip_turn()
	else:
		print("❌ Unit has no actions remaining")
	
	queue_redraw()

func _skip_turn():
	# Switch to next player
	current_player_id = 2 if current_player_id == 1 else 1
	
	# Restore actions for new player's units
	var current_player = game_state.players[current_player_id]
	for unit_id in current_player.unit_ids:
		if unit_id in game_state.units:
			var unit = game_state.units[unit_id]
			unit.restore_actions()
	
	game_state.turn_data.current_player_id = current_player_id
	game_state.turn_data.turn_number += 1
	
	_clear_selection()
	print("Turn skipped - Now: Player %d" % current_player_id)
	queue_redraw()

func _clear_selection():
	selected_unit_id = -1
	valid_movement_targets.clear()

func _draw():
	if game_state.is_empty():
		return
	
	# Draw background
	draw_rect(Rect2(0, 0, 1024, 768), Color.WHITE)
	
	# Draw grid points
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		draw_circle(point.position.pixel_pos, 8.0, Color.BLACK)
	
	# Draw units
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		var position = unit.position.pixel_pos
		var color = unit.get_color()
		
		# Highlight selected unit
		if unit_id == selected_unit_id:
			draw_circle(position, 20.0, Color.YELLOW)
		
		# Draw unit
		draw_circle(position, 15.0, color)
		
		# Draw emoji
		var font = ThemeDB.fallback_font
		if font:
			var emoji = unit.get_emoji()
			var text_size = font.get_string_size(emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
			draw_string(font, position - text_size/2, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.WHITE)
	
	# Draw movement targets
	for target in valid_movement_targets:
		draw_circle(target.pixel_pos, 12.0, Color.MAGENTA)
	
	# Draw UI
	_draw_ui()

func _draw_ui():
	var font = ThemeDB.fallback_font
	if not font:
		return
	
	# Current player info
	var current_player = game_state.players[current_player_id]
	var player_text = "Current Player: %s" % current_player.name
	draw_string(font, Vector2(20, 30), player_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, current_player.color)
	
	# Turn info
	var turn_text = "Turn: %d" % game_state.turn_data.turn_number
	draw_string(font, Vector2(20, 60), turn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	
	# Fog status
	var fog_text = "Fog of War: %s" % ("ON" if game_state.fog_of_war_enabled else "OFF")
	draw_string(font, Vector2(20, 80), fog_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	
	# Controls
	var controls = [
		"CONTROLS:",
		"• Click unit to select",
		"• Click magenta circle to move",
		"• SPACE: Toggle fog",
		"• ENTER: Skip turn",
		"• ESC: Quit"
	]
	
	for i in range(controls.size()):
		draw_string(font, Vector2(20, 120 + i * 16), controls[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.DARK_GRAY)