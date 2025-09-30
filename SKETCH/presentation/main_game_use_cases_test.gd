# 🎮 V&V USE CASES TEST
# Purpose: Test complete Use Cases implementation
# Layer: Presentation

extends Node2D

# Preload clean Use Cases
const InitializeGameUseCase = preload("res://application/use_cases/initialize_game_clean.gd")
const MoveUnitUseCase = preload("res://application/use_cases/move_unit_clean.gd")
const SkipTurnUseCase = preload("res://application/use_cases/skip_turn_clean.gd")
const ToggleFogUseCase = preload("res://application/use_cases/toggle_fog_clean.gd")

# Preload clean services for additional functionality
const GridService = preload("res://application/services/grid_service_clean.gd")
const MovementService = preload("res://application/services/movement_service_clean.gd")
const TurnService = preload("res://application/services/turn_service_clean.gd")

# Game state
var game_state: Dictionary = {}
var selected_unit_id: int = -1
var valid_movement_targets: Array = []
var game_over: bool = false
var winner_player = null

func _ready():
	print("=== V&V USE CASES TEST ===")
	setup_use_cases_game()
	print("Use Cases test ready!")

func setup_use_cases_game():
	print("Initializing game using InitializeGameUseCase...")
	
	# Use InitializeGameUseCase to set up complete game
	var init_result = InitializeGameUseCase.execute(2)
	
	if init_result.success:
		game_state = init_result.game_state
		print("✅ Game initialized successfully!")
		print("- %s" % init_result.message)
		
		var grid_stats = GridService.get_grid_stats(game_state.grid)
		print("- Grid: %d points, %d edges, %d corners" % [grid_stats.total_points, grid_stats.total_edges, grid_stats.corner_points])
		print("- Players: %d" % game_state.players.size())
		print("- Units: %d" % game_state.units.size())
		print("- Domains: %d" % game_state.domains.size())
		
		var turn_info = SkipTurnUseCase.get_turn_info(game_state)
		print("- Current player: %s" % turn_info.current_player.name)
		print("- Turn: %d" % turn_info.turn_number)
		
		var fog_status = ToggleFogUseCase.get_fog_status(game_state)
		print("- Fog of war: %s" % ("ON" if fog_status.fog_enabled else "OFF"))
	else:
		print("❌ Failed to initialize game: %s" % init_result.message)
		game_state = {}

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_toggle_fog()
			KEY_ENTER:
				_skip_turn()
			KEY_ESCAPE:
				get_tree().quit()

func _handle_click(mouse_pos: Vector2):
	if game_over or game_state.is_empty():
		return
	
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
	
	# Use MoveUnitUseCase to execute movement with all validations
	var move_result = MoveUnitUseCase.execute(selected_unit_id, target_position, game_state)
	
	if move_result.success:
		print("✅ %s" % move_result.message)
		
		if move_result.power_consumed:
			print("⚡ Power consumed")
		
		if move_result.turn_advanced:
			print("🔄 Turn advanced to Player %d" % move_result.new_player_id)
		
		_clear_selection()
	else:
		print("❌ %s" % move_result.message)
	
	queue_redraw()

func _toggle_fog():
	# Use ToggleFogUseCase to toggle fog of war
	var fog_result = ToggleFogUseCase.execute(game_state)
	
	if fog_result.success:
		print("👁️ %s" % fog_result.message)
	else:
		print("❌ Failed to toggle fog: %s" % fog_result.message)
	
	queue_redraw()

func _skip_turn():
	# Use SkipTurnUseCase to skip turn
	var skip_result = SkipTurnUseCase.execute(game_state)
	
	if skip_result.success:
		print("⏭️ %s" % skip_result.message)
		
		if skip_result.game_over:
			game_over = true
			winner_player = skip_result.winner
			print("🏆 GAME OVER! Winner: %s" % (winner_player.name if winner_player else "Draw"))
	else:
		print("❌ Failed to skip turn: %s" % skip_result.message)
	
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
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	var fog_settings = ToggleFogUseCase.get_visibility_settings(game_state, current_player.id if current_player else 1)
	
	# Draw grid
	_draw_grid(fog_settings)
	
	# Draw domains
	_draw_domains(fog_settings)
	
	# Draw units
	_draw_units(fog_settings)
	
	# Draw movement targets
	if selected_unit_id != -1:
		_draw_movement_targets()
	
	# Draw UI
	_draw_ui()

func _draw_grid(fog_settings: Dictionary):
	# Draw grid edges
	for edge_id in game_state.grid.edges:
		var edge = game_state.grid.edges[edge_id]
		var point_a = game_state.grid.points[edge.point_a_id]
		var point_b = game_state.grid.points[edge.point_b_id]
		
		draw_line(point_a.position.pixel_pos, point_b.position.pixel_pos, Color.LIGHT_GRAY, 1.0)
	
	# Draw grid points
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		var color = Color.RED if point.is_corner else Color.BLACK
		draw_circle(point.position.pixel_pos, 4.0, color)

func _draw_domains(fog_settings: Dictionary):
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		if fog_settings.show_all_domains or ToggleFogUseCase.is_visible_to_player("domain", domain, fog_settings.player_id, game_state):
			var center_pos = domain.center_position.pixel_pos
			var player = game_state.players[domain.owner_id]
			var color = player.color
			
			# Draw domain area
			draw_circle(center_pos, 30.0, Color(color.r, color.g, color.b, 0.3))
			draw_arc(center_pos, 30.0, 0, TAU, 32, color, 3.0)
			
			# Draw domain info
			var font = ThemeDB.fallback_font
			if font:
				var text = "%s\nPower: %d" % [domain.name, domain.power]
				draw_string(font, center_pos + Vector2(-25, -50), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)

func _draw_units(fog_settings: Dictionary):
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		if fog_settings.show_all_units or ToggleFogUseCase.is_visible_to_player("unit", unit, fog_settings.player_id, game_state):
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
			
			# Draw unit info
			if font:
				var info = "%s\nActions: %d" % [unit.name, unit.actions_remaining]
				draw_string(font, position + Vector2(-20, 25), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)

func _draw_movement_targets():
	for target in valid_movement_targets:
		draw_circle(target.pixel_pos, 10.0, Color.MAGENTA)

func _draw_ui():
	var font = ThemeDB.fallback_font
	if not font:
		return
	
	# Game Over screen
	if game_over:
		draw_rect(Rect2(0, 0, 1024, 768), Color(0, 0, 0, 0.7))
		var winner_text = "🏆 GAME OVER! 🏆\n\nWinner: %s" % (winner_player.name if winner_player else "Draw")
		draw_string(font, Vector2(400, 300), winner_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color.WHITE)
		draw_string(font, Vector2(400, 400), "Press ESC to quit", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.LIGHT_GRAY)
		return
	
	# Current player info
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if current_player:
		var player_text = "Current Player: %s" % current_player.name
		draw_string(font, Vector2(20, 30), player_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, current_player.color)
	
	# Turn info
	var turn_info = SkipTurnUseCase.get_turn_info(game_state)
	var turn_text = "Turn: %d" % turn_info.turn_number
	draw_string(font, Vector2(20, 60), turn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	
	# Fog status
	var fog_status = ToggleFogUseCase.get_fog_status(game_state)
	var fog_text = "Fog of War: %s" % ("ON" if fog_status.fog_enabled else "OFF")
	draw_string(font, Vector2(20, 80), fog_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	
	# Use Cases status
	draw_string(font, Vector2(20, 110), "✅ Use Cases Layer Working!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GREEN)
	
	# Controls
	var controls = [
		"CONTROLS:",
		"• Click unit to select",
		"• Click magenta circle to move",
		"• SPACE: Toggle fog of war",
		"• ENTER: Skip turn",
		"• ESC: Quit"
	]
	
	for i in range(controls.size()):
		draw_string(font, Vector2(20, 150 + i * 16), controls[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.DARK_GRAY)