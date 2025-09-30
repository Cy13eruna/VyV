# 🎮 V&V INFRASTRUCTURE TEST
# Purpose: Test complete Infrastructure implementation
# Layer: Presentation

extends Node2D

# Preload clean Use Cases
const InitializeGameUseCase = preload("res://application/use_cases/initialize_game_clean.gd")
const MoveUnitUseCase = preload("res://application/use_cases/move_unit_clean.gd")
const SkipTurnUseCase = preload("res://application/use_cases/skip_turn_clean.gd")
const ToggleFogUseCase = preload("res://application/use_cases/toggle_fog_clean.gd")

# Preload clean services
const TurnService = preload("res://application/services/turn_service_clean.gd")
const MovementService = preload("res://application/services/movement_service_clean.gd")

# Preload clean infrastructure
const InputManager = preload("res://infrastructure/input/input_manager_clean.gd")
const GridRenderer = preload("res://infrastructure/rendering/grid_renderer_clean.gd")
const UnitRenderer = preload("res://infrastructure/rendering/unit_renderer_clean.gd")
const GameState = preload("res://infrastructure/persistence/game_state_clean.gd")

# Game state and infrastructure
var game_state: Dictionary = {}
var input_manager
var selected_unit_id: int = -1
var valid_movement_targets: Array = []
var game_over: bool = false
var winner_player = null

func _ready():
	print("=== V&V INFRASTRUCTURE TEST ===")
	setup_infrastructure_game()
	setup_input_system()
	print("Infrastructure test ready!")

func setup_infrastructure_game():
	print("Initializing game using complete infrastructure...")
	
	# Use InitializeGameUseCase to set up complete game
	var init_result = InitializeGameUseCase.execute(2)
	
	if init_result.success:
		game_state = init_result.game_state
		print("✅ Game initialized successfully!")
		
		# Validate game state using GameState infrastructure
		var validation = GameState.validate_game_state(game_state)
		if "valid" in validation and validation.valid:
			print("✅ Game state validation passed")
		else:
			if "warnings" in validation and validation.warnings.size() > 0:
				print("⚠️ Game state validation warnings: %s" % validation.warnings)
			if "errors" in validation and validation.errors.size() > 0:
				print("❌ Game state validation errors: %s" % validation.errors)
		
		# Get game summary
		var summary = GameState.get_game_state_summary(game_state)
		print("📊 Game Summary:")
		print("  - Grid: %d points, %d edges" % [summary.grid_points, summary.grid_edges])
		print("  - Players: %d" % summary.player_count)
		print("  - Units: %d" % summary.unit_count)
		print("  - Domains: %d" % summary.domain_count)
		print("  - Current: %s (Turn %d)" % [summary.current_player, summary.current_turn])
		print("  - Fog: %s" % ("ON" if summary.fog_enabled else "OFF"))
	else:
		print("❌ Failed to initialize game: %s" % init_result.message)
		game_state = GameState.create_empty_game_state()

func setup_input_system():
	print("Setting up infrastructure input system...")
	
	# Create input manager
	input_manager = InputManager.new()
	
	# Connect input signals
	input_manager.point_clicked.connect(_on_point_clicked)
	input_manager.point_hovered.connect(_on_point_hovered)
	input_manager.point_unhovered.connect(_on_point_unhovered)
	input_manager.unit_clicked.connect(_on_unit_clicked)
	input_manager.unit_hovered.connect(_on_unit_hovered)
	input_manager.unit_unhovered.connect(_on_unit_unhovered)
	input_manager.fog_toggle_requested.connect(_on_fog_toggle)
	input_manager.skip_turn_requested.connect(_on_skip_turn)
	input_manager.game_quit_requested.connect(_on_quit_game)
	
	print("✅ Infrastructure input system ready")

func _unhandled_input(event):
	if game_state.is_empty() or not input_manager:
		return
	
	# Use InputManager to handle all input
	input_manager.handle_input_event(event, game_state.grid, game_state.units)

func _on_point_clicked(point_id: int):
	if game_over:
		return
	
	print("Point clicked: %d" % point_id)
	
	# If we have a selected unit, try to move it
	if selected_unit_id != -1:
		var clicked_position = game_state.grid.points[point_id].position
		_attempt_move_unit(clicked_position)

func _on_point_hovered(point_id: int):
	# Point hover feedback handled by renderer
	queue_redraw()

func _on_point_unhovered(point_id: int):
	queue_redraw()

func _on_unit_clicked(unit_id: int):
	if game_over:
		return
	
	print("Unit clicked: %d" % unit_id)
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player:
		return
	
	var unit = game_state.units[unit_id]
	if unit.owner_id == current_player.id:
		_select_unit(unit_id)
	else:
		print("Cannot select enemy unit")

func _on_unit_hovered(unit_id: int):
	queue_redraw()

func _on_unit_unhovered(unit_id: int):
	queue_redraw()

func _on_fog_toggle():
	var fog_result = ToggleFogUseCase.execute(game_state)
	if fog_result.success:
		print("👁️ %s" % fog_result.message)
	queue_redraw()

func _on_skip_turn():
	var skip_result = SkipTurnUseCase.execute(game_state)
	if skip_result.success:
		print("⏭️ %s" % skip_result.message)
		if skip_result.game_over:
			game_over = true
			winner_player = skip_result.winner
			print("🏆 GAME OVER! Winner: %s" % (winner_player.name if winner_player else "Draw"))
	_clear_selection()
	queue_redraw()

func _on_quit_game():
	print("Quit requested")
	get_tree().quit()

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
	
	# Use MoveUnitUseCase to execute movement
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
	var hover_state = input_manager.get_hover_state() if input_manager else {}
	
	# Use GridRenderer to draw grid
	if fog_settings.fog_enabled:
		# TODO: Implement visibility calculation for fog
		GridRenderer.render_grid(self, game_state.grid, hover_state)
	else:
		GridRenderer.render_grid(self, game_state.grid, hover_state)
	
	# Use UnitRenderer to draw units
	var font = ThemeDB.fallback_font
	if fog_settings.fog_enabled:
		# TODO: Implement visible units calculation
		UnitRenderer.render_units(self, game_state.units, selected_unit_id, hover_state, font)
	else:
		UnitRenderer.render_units(self, game_state.units, selected_unit_id, hover_state, font)
	
	# Use UnitRenderer to draw movement targets
	if valid_movement_targets.size() > 0:
		UnitRenderer.render_movement_targets(self, valid_movement_targets, font)
	
	# Draw UI
	_draw_ui()

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
	
	# Game summary using GameState infrastructure
	var summary = GameState.get_game_state_summary(game_state)
	var summary_text = "Turn: %d | Fog: %s" % [summary.current_turn, "ON" if summary.fog_enabled else "OFF"]
	draw_string(font, Vector2(20, 60), summary_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	
	# Infrastructure status
	draw_string(font, Vector2(20, 90), "✅ Infrastructure Layer Working!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GREEN)
	
	# Input state (if available)
	if input_manager:
		var hover_state = input_manager.get_hover_state()
		if hover_state.has_point_hover or hover_state.has_unit_hover:
			var hover_text = "Hovering: "
			if hover_state.has_unit_hover:
				hover_text += "Unit %d" % hover_state.hovered_unit_id
			elif hover_state.has_point_hover:
				hover_text += "Point %d" % hover_state.hovered_point_id
			draw_string(font, Vector2(20, 110), hover_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLUE)
	
	# Controls
	var controls = [
		"INFRASTRUCTURE CONTROLS:",
		"• Click unit to select",
		"• Click point to move",
		"• Hover for highlights",
		"• SPACE: Toggle fog",
		"• ENTER: Skip turn",
		"• ESC: Quit"
	]
	
	for i in range(controls.size()):
		var text = controls[i]
		var color = Color.WHITE if i == 0 else Color.DARK_GRAY
		draw_string(font, Vector2(20, 150 + i * 16), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)