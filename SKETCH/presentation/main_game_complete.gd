# 🎮 V&V COMPLETE GAME
# Purpose: Full game implementation with all mechanics
# Layer: Presentation (ONION Coordinator)

extends Node2D

# Preload all required scripts
const HexCoordinate = preload("res://core/value_objects/hex_coordinate.gd")
const Position = preload("res://core/value_objects/position.gd")
const HexPoint = preload("res://core/entities/hex_point.gd")
const HexEdge = preload("res://core/entities/hex_edge.gd")
const Unit = preload("res://core/entities/unit.gd")
const Domain = preload("res://core/entities/domain.gd")
const Player = preload("res://core/entities/player.gd")
const GridService = preload("res://application/services/grid_service.gd")
const MovementService = preload("res://application/services/movement_service.gd")
const VisibilityService = preload("res://application/services/visibility_service.gd")
const TurnService = preload("res://application/services/turn_service.gd")
const DomainService = preload("res://application/services/domain_service.gd")
const InitializeGameUseCase = preload("res://application/use_cases/initialize_game.gd")
const MoveUnitUseCase = preload("res://application/use_cases/move_unit.gd")
const SkipTurnUseCase = preload("res://application/use_cases/skip_turn.gd")
const ToggleFogUseCase = preload("res://application/use_cases/toggle_fog.gd")
const InputManager = preload("res://infrastructure/input/input_manager.gd")

# Game state
var game_state: Dictionary = {}
var input_manager
var selected_unit_id: int = -1
var valid_movement_targets: Array = []
var hovered_point_id: int = -1

# UI state
var show_fps: bool = true
var game_over: bool = false
var winner_player = null

func _ready():
	print("=== V&V COMPLETE GAME STARTING ===")
	print("Step 1: Starting setup_complete_game()")
	setup_complete_game()
	print("Step 2: Starting setup_input_system()")
	setup_input_system()
	print("Step 3: Game ready! Click units to select, click valid positions to move!")
	print("=== INITIALIZATION COMPLETE ===")

func setup_complete_game():
	print("  - Creating InitializeGameUseCase...")
	# Initialize complete game with 2 players
	print("  - Executing InitializeGameUseCase.execute(2)...")
	var init_result = InitializeGameUseCase.execute(2)
	print("  - InitializeGameUseCase completed, success: ", init_result.success if init_result else "NULL")
	if init_result.success:
		game_state = init_result.game_state
		print("✅ Complete game initialized!")
		print("- Grid: %d points, %d edges" % [game_state.grid.points.size(), game_state.grid.edges.size()])
		print("- Players: %d" % game_state.players.size())
		print("- Units: %d" % game_state.units.size())
		print("- Domains: %d" % game_state.domains.size())
	else:
		print("❌ Failed to initialize game: ", init_result.message)
		game_state = {"grid": {"points": {}, "edges": {}}, "players": {}, "units": {}, "domains": {}, "turn_data": {}, "fog_of_war_enabled": true}

func setup_input_system():
	print("  - Creating InputManager...")
	input_manager = InputManager.new()
	print("  - Connecting signals...")
	input_manager.point_clicked.connect(_on_point_clicked)
	input_manager.point_hovered.connect(_on_point_hovered)
	input_manager.point_unhovered.connect(_on_point_unhovered)
	input_manager.fog_toggle_requested.connect(_on_fog_toggle)
	input_manager.skip_turn_requested.connect(_on_skip_turn)
	print("  - Input system setup complete")

func _unhandled_input(event):
	if game_state.is_empty():
		return
	input_manager.handle_input_event(event, game_state.grid)

func _on_point_clicked(point_id: int):
	if game_over:
		return
		
	var clicked_position = game_state.grid.points[point_id].position
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	
	if not current_player:
		return
	
	# Check if clicking on unit to select
	var unit_at_position = _find_unit_at_position(clicked_position)
	if unit_at_position and unit_at_position.owner_id == current_player.id:
		_select_unit(unit_at_position.id)
		return
	
	# Check if moving selected unit
	if selected_unit_id != -1:
		_attempt_move_unit(clicked_position)

func _on_point_hovered(point_id: int):
	hovered_point_id = point_id
	queue_redraw()

func _on_point_unhovered(point_id: int):
	hovered_point_id = -1
	queue_redraw()

func _on_fog_toggle():
	var result = ToggleFogUseCase.execute(game_state)
	print("Fog of war: ", "ON" if result.fog_enabled else "OFF")
	queue_redraw()

func _on_skip_turn():
	var result = SkipTurnUseCase.execute(game_state)
	if result.success:
		_clear_selection()
		print("Turn skipped - Now: Player %d" % result.new_player_id)
		
		if result.game_over:
			game_over = true
			winner_player = result.winner
			print("🏆 GAME OVER! Winner: %s" % (winner_player.name if winner_player else "Draw"))
	
	queue_redraw()

func _select_unit(unit_id: int):
	selected_unit_id = unit_id
	var unit = game_state.units[unit_id]
	valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units)
	print("Unit selected: %s (%d valid moves)" % [unit.name, valid_movement_targets.size()])
	queue_redraw()

func _attempt_move_unit(target_position):
	if selected_unit_id == -1:
		return
	
	var result = MoveUnitUseCase.execute(selected_unit_id, target_position, game_state)
	if result.success:
		print("✅ Unit moved successfully!")
		if result.power_consumed:
			print("⚡ Power consumed")
		_clear_selection()
		
		# Check if turn should advance (no more actions)
		var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
		if not TurnService.can_current_player_act(game_state.turn_data, game_state.players, game_state.units):
			_on_skip_turn()
	else:
		print("❌ Movement failed: %s" % result.message)
	
	queue_redraw()

func _clear_selection():
	selected_unit_id = -1
	valid_movement_targets.clear()

func _find_unit_at_position(position):
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.position.equals(position):
			return unit
	return null

func _draw():
	if game_state.is_empty():
		return
	
	# Draw background
	draw_rect(Rect2(0, 0, 1024, 768), Color.WHITE)
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	
	# Draw grid
	_draw_grid(current_player.id if current_player else 1)
	
	# Draw domains
	_draw_domains(current_player.id if current_player else 1)
	
	# Draw units
	_draw_units(current_player.id if current_player else 1)
	
	# Draw movement targets
	if selected_unit_id != -1:
		_draw_movement_targets()
	
	# Draw hover highlight
	if hovered_point_id != -1:
		_draw_hover_highlight()
	
	# Draw UI
	_draw_ui(current_player)

func _draw_grid(current_player_id: int):
	var visible_points = VisibilityService.get_visible_points_for_player(
		current_player_id, game_state.grid, game_state.units, game_state.domains, game_state.fog_of_war_enabled
	)
	var visible_edges = VisibilityService.get_visible_edges_for_player(
		current_player_id, game_state.grid, game_state.units, game_state.domains, game_state.fog_of_war_enabled
	)
	
	# Draw edges
	for edge_id in game_state.grid.edges:
		if not game_state.fog_of_war_enabled or edge_id in visible_edges:
			var edge = game_state.grid.edges[edge_id]
			var point_a = game_state.grid.points[edge.point_a_id]
			var point_b = game_state.grid.points[edge.point_b_id]
			
			draw_line(
				point_a.position.pixel_pos,
				point_b.position.pixel_pos,
				edge.get_terrain_color(),
				8.0
			)
	
	# Draw points
	for point_id in game_state.grid.points:
		if not game_state.fog_of_war_enabled or point_id in visible_points:
			var point = game_state.grid.points[point_id]
			var color = Color.RED if point.is_corner else Color.BLACK
			draw_circle(point.position.pixel_pos, 8.0, color)

func _draw_domains(current_player_id: int):
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if VisibilityService.is_domain_visible_to_player(
			domain, current_player_id, game_state.grid, game_state.units, game_state.domains, game_state.fog_of_war_enabled
		):
			var center_pos = domain.center_position.pixel_pos
			var color = domain.get_color()
			var outline_color = domain.get_outline_color()
			
			# Draw domain area
			draw_circle(center_pos, 40.0, Color(color.r, color.g, color.b, 0.3))
			draw_arc(center_pos, 40.0, 0, TAU, 32, outline_color, 4.0)
			
			# Draw domain info
			var font = ThemeDB.fallback_font
			if font:
				var text = "%s\nPower: %d" % [domain.name, domain.power]
				draw_string(font, center_pos + Vector2(-30, -60), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)

func _draw_units(current_player_id: int):
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if VisibilityService.is_unit_visible_to_player(
			unit, current_player_id, game_state.grid, game_state.units, game_state.domains, game_state.fog_of_war_enabled
		):
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
			
			# Draw unit name and actions
			if font:
				var info = "%s\nActions: %d" % [unit.name, unit.actions_remaining]
				draw_string(font, position + Vector2(-25, 25), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)

func _draw_movement_targets():
	for target in valid_movement_targets:
		draw_circle(target.pixel_pos, 12.0, Color.MAGENTA)

func _draw_hover_highlight():
	if hovered_point_id in game_state.grid.points:
		var point = game_state.grid.points[hovered_point_id]
		draw_circle(point.position.pixel_pos, 12.0, Color(1, 1, 0, 0.5))

func _draw_ui(current_player):
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
	if current_player:
		var player_text = "Current Player: %s" % current_player.name
		draw_string(font, Vector2(20, 30), player_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, current_player.color)
		
		var total_power = DomainService.get_total_power_for_player(current_player.id, game_state.domains)
		var power_text = "Total Power: %d" % total_power
		draw_string(font, Vector2(20, 55), power_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
		
		var units_with_actions = 0
		for unit_id in current_player.unit_ids:
			if unit_id in game_state.units:
				var unit = game_state.units[unit_id]
				if unit.can_move():
					units_with_actions += 1
		
		var actions_text = "Units with actions: %d" % units_with_actions
		draw_string(font, Vector2(20, 80), actions_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	
	# Turn info
	var turn_text = "Turn: %d" % game_state.turn_data.turn_number
	draw_string(font, Vector2(20, 120), turn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	
	# Fog status
	var fog_text = "Fog of War: %s" % ("ON" if game_state.fog_of_war_enabled else "OFF")
	draw_string(font, Vector2(20, 140), fog_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	
	# Controls
	var controls = [
		"CONTROLS:",
		"• Click unit to select",
		"• Click position to move",
		"• SPACE: Toggle fog",
		"• ENTER: Skip turn",
		"• ESC: Quit"
	]
	
	for i in range(controls.size()):
		draw_string(font, Vector2(20, 180 + i * 16), controls[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.DARK_GRAY)
	
	# FPS
	if show_fps:
		var fps_text = "FPS: %d" % Engine.get_frames_per_second()
		draw_string(font, Vector2(900, 30), fps_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.DARK_GRAY)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_F:
				show_fps = not show_fps
				queue_redraw()