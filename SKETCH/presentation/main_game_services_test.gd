# 🎮 V&V SERVICES TEST
# Purpose: Test clean services implementation
# Layer: Presentation

extends Node2D

# Preload clean classes
const HexCoordinate = preload("res://core/value_objects/hex_coordinate_clean.gd")
const Position = preload("res://core/value_objects/position_clean.gd")
const Unit = preload("res://core/entities/unit_clean.gd")
const Player = preload("res://core/entities/player_clean.gd")

# Preload clean services
const GridService = preload("res://application/services/grid_service_clean.gd")
const MovementService = preload("res://application/services/movement_service_clean.gd")
const TurnService = preload("res://application/services/turn_service_clean.gd")

# Game state
var game_state: Dictionary = {}
var selected_unit_id: int = -1
var valid_movement_targets: Array = []

func _ready():
	print("=== V&V SERVICES TEST ===")
	setup_services_game()
	print("Services test ready!")

func setup_services_game():
	# Initialize game state
	game_state = {
		"grid": {},
		"players": {},
		"units": {},
		"turn_data": {}
	}
	
	# Generate full hexagonal grid using GridService
	print("Generating hexagonal grid...")
	game_state.grid = GridService.generate_hex_grid(3)
	var stats = GridService.get_grid_stats(game_state.grid)
	print("✅ Grid generated: %d points, %d edges, %d corners" % [stats.total_points, stats.total_edges, stats.corner_points])
	
	# Create players
	var player1 = Player.new(1, "Player 1", Color.RED)
	var player2 = Player.new(2, "Player 2", Color.BLUE)
	game_state.players = {1: player1, 2: player2}
	
	# Create units at corner positions
	var corner_positions = []
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.is_corner:
			corner_positions.append(point.position)
	
	if corner_positions.size() >= 2:
		var unit1 = Unit.new(1, 1, "Unit1", corner_positions[0])
		var unit2 = Unit.new(2, 2, "Unit2", corner_positions[1])
		
		game_state.units = {1: unit1, 2: unit2}
		player1.add_unit(1)
		player2.add_unit(2)
	
	# Initialize turn system using TurnService
	game_state.turn_data = TurnService.initialize_turn_system(game_state.players)
	
	print("✅ Services game initialized!")
	print("- Grid: %d points" % game_state.grid.points.size())
	print("- Players: %d" % game_state.players.size())
	print("- Units: %d" % game_state.units.size())
	print("- Current player: %d" % game_state.turn_data.current_player_id)

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
	# Find clicked point using GridService
	var clicked_point_id = GridService.find_point_at_pixel(game_state.grid, mouse_pos)
	if clicked_point_id == -1:
		return
	
	var clicked_position = game_state.grid.points[clicked_point_id].position
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	
	if not current_player:
		return
	
	# Check if clicking on unit to select
	var unit_at_position = MovementService.get_unit_at_position(clicked_position, game_state.units)
	if unit_at_position and unit_at_position.owner_id == current_player.id:
		_select_unit(unit_at_position.id)
		return
	
	# Check if moving selected unit
	if selected_unit_id != -1:
		_attempt_move_unit(clicked_position)

func _select_unit(unit_id: int):
	selected_unit_id = unit_id
	var unit = game_state.units[unit_id]
	
	# Get valid movement targets using MovementService
	valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units)
	
	print("Unit selected: %s (%d valid moves)" % [unit.name, valid_movement_targets.size()])
	queue_redraw()

func _attempt_move_unit(target_position):
	if selected_unit_id == -1:
		return
	
	var unit = game_state.units[selected_unit_id]
	
	# Use MovementService to execute movement
	if MovementService.move_unit_to(unit, target_position, game_state.grid, game_state.units):
		print("✅ Unit moved successfully!")
		_clear_selection()
		
		# Check if turn should advance using TurnService
		if not TurnService.can_current_player_act(game_state.turn_data, game_state.players, game_state.units):
			_skip_turn()
	else:
		print("❌ Movement failed")
	
	queue_redraw()

func _skip_turn():
	# Use TurnService to advance turn
	if TurnService.advance_to_next_turn(game_state.turn_data, game_state.players, game_state.units):
		var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
		print("Turn advanced - Now: %s" % current_player.name)
		
		# Check if game is over
		if TurnService.is_game_over(game_state.turn_data, game_state.players):
			var winner = TurnService.get_winner(game_state.players)
			print("🏆 GAME OVER! Winner: %s" % (winner.name if winner else "Draw"))
	else:
		print("Failed to advance turn")
	
	_clear_selection()
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
		var color = Color.RED if point.is_corner else Color.BLACK
		draw_circle(point.position.pixel_pos, 6.0, color)
	
	# Draw grid edges
	for edge_id in game_state.grid.edges:
		var edge = game_state.grid.edges[edge_id]
		var point_a = game_state.grid.points[edge.point_a_id]
		var point_b = game_state.grid.points[edge.point_b_id]
		
		draw_line(point_a.position.pixel_pos, point_b.position.pixel_pos, Color.GRAY, 2.0)
	
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
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if current_player:
		var player_text = "Current Player: %s" % current_player.name
		draw_string(font, Vector2(20, 30), player_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, current_player.color)
	
	# Turn info
	var stats = TurnService.get_turn_stats(game_state.turn_data, game_state.players)
	var turn_text = "Turn: %d" % stats.turn_number
	draw_string(font, Vector2(20, 60), turn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	
	# Grid info
	var grid_stats = GridService.get_grid_stats(game_state.grid)
	var grid_text = "Grid: %d points, %d edges" % [grid_stats.total_points, grid_stats.total_edges]
	draw_string(font, Vector2(20, 80), grid_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	
	# Services status
	draw_string(font, Vector2(20, 110), "✅ Services Layer Working!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GREEN)
	
	# Controls
	var controls = [
		"CONTROLS:",
		"• Click unit to select",
		"• Click magenta circle to move",
		"• ENTER: Skip turn",
		"• ESC: Quit"
	]
	
	for i in range(controls.size()):
		draw_string(font, Vector2(20, 150 + i * 16), controls[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.DARK_GRAY)