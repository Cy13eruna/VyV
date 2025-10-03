# 🎮 V&V SIMPLE FINAL GAME
# Purpose: Complete V&V game without observability dependencies
# Layer: Presentation (ONION Coordinator)

extends Node2D

# Preload complete ONION architecture
const InitializeGameUseCase = preload("res://application/use_cases/initialize_game_clean.gd")
const MoveUnitUseCase = preload("res://application/use_cases/move_unit_clean.gd")
const SkipTurnUseCase = preload("res://application/use_cases/skip_turn_clean.gd")
const ToggleFogUseCase = preload("res://application/use_cases/toggle_fog_clean.gd")

const TurnService = preload("res://application/services/turn_service_clean.gd")
const MovementService = preload("res://application/services/movement_service_clean.gd")
const GridService = preload("res://application/services/grid_service_clean.gd")

const InputManager = preload("res://infrastructure/input/input_manager_clean.gd")
const GridRenderer = preload("res://infrastructure/rendering/grid_renderer_clean.gd")
const UnitRenderer = preload("res://infrastructure/rendering/unit_renderer_clean.gd")
const GameState = preload("res://infrastructure/persistence/game_state_clean.gd")
# Simple command manager removed during cleanup
# const SimpleCommandManager = preload("res://infrastructure/commands/simple_command_manager.gd")

# Game state and systems
var game_state: Dictionary = {}
var input_manager
# var command_manager  # Removed during cleanup
var selected_unit_id: int = -1
var valid_movement_targets: Array = []
var game_over: bool = false
var winner_player = null

# UI state
var show_debug_info: bool = false
var show_grid_stats: bool = false
# var show_command_history: bool = false  # Removed during cleanup

func _ready():
	print("=== 🎮 V&V SIMPLE FINAL GAME STARTING 🎮 ===")
	print("🏗️ Complete ONION Architecture Implementation")
	print("📊 All Technical Systems Integrated")
	print("==================================================")
	
	# setup_command_system()  # Removed during cleanup
	setup_final_game()
	setup_complete_input_system()
	
	print("🚀 V&V Simple Final Game Ready!")
	print("🎯 Click units to select, click positions to move")
	print("⌨️  SPACE: Toggle fog | ENTER: Skip turn | F1: Debug info")
	print("🔄 CTRL+Z: Undo | CTRL+Y: Redo | F5: Command History")

# Command system removed during cleanup
# func setup_command_system():
#	print("📚 Setting up command system...")
#	
#	# Initialize simple command manager
#	command_manager = SimpleCommandManager.new()
#	
#	# Connect command events
#	if command_manager:
#		command_manager.command_executed.connect(_on_command_executed)
#		command_manager.command_undone.connect(_on_command_undone)
#		command_manager.command_redone.connect(_on_command_redone)
#		command_manager.history_changed.connect(_on_command_history_changed)
#	
#	print("✅ Command system ready")

func setup_final_game():
	print("🎲 Initializing complete game with all features...")
	
	# Initialize game with full feature set
	var init_result = InitializeGameUseCase.execute(2)
	
	if init_result.success:
		game_state = init_result.game_state
		
		# Validate game state
		var validation = GameState.validate_game_state(game_state)
		
		if "valid" in validation and validation.valid:
			print("✅ Game state validation: PASSED")
		else:
			print("⚠️ Game state validation: WARNINGS")
			if "warnings" in validation:
				for warning in validation.warnings:
					print("  - %s" % warning)
		
		# Display comprehensive game summary
		var summary = GameState.get_game_state_summary(game_state)
		print("📊 GAME INITIALIZED:")
		print("  🗺️  Grid: %d points, %d edges" % [summary.grid_points, summary.grid_edges])
		print("  👥 Players: %d active" % summary.player_count)
		print("  🚶 Units: %d total" % summary.unit_count)
		print("  🏰 Domains: %d territories" % summary.domain_count)
		print("  ⏰ Turn: %d (Player: %s)" % [summary.current_turn, summary.current_player])
		print("  👁️  Fog of War: %s" % ("ENABLED" if summary.fog_enabled else "DISABLED"))
		
		# Add terrain variety to edges
		_enhance_terrain_variety()
		
		print("✅ Complete game initialization successful!")
	else:
		print("❌ Game initialization failed: %s" % init_result.message)
		game_state = GameState.create_empty_game_state()

func setup_complete_input_system():
	print("🎮 Setting up complete input system...")
	
	input_manager = InputManager.new()
	
	# Connect all input signals
	input_manager.point_clicked.connect(_on_point_clicked)
	input_manager.point_hovered.connect(_on_point_hovered)
	input_manager.point_unhovered.connect(_on_point_unhovered)
	input_manager.unit_clicked.connect(_on_unit_clicked)
	input_manager.unit_hovered.connect(_on_unit_hovered)
	input_manager.unit_unhovered.connect(_on_unit_unhovered)
	input_manager.fog_toggle_requested.connect(_on_fog_toggle)
	input_manager.skip_turn_requested.connect(_on_skip_turn)
	input_manager.game_quit_requested.connect(_on_quit_game)
	
	# Set optimal input tolerances
	input_manager.set_tolerances(25.0, 30.0)  # click, hover
	
	print("✅ Complete input system ready")

func _enhance_terrain_variety():
	# Add some terrain variety to make the game more interesting
	if "edges" in game_state.grid:
		var terrain_distribution = [6.0/12.0, 2.0/12.0, 2.0/12.0, 2.0/12.0]  # FIELD, FOREST, MOUNTAIN, WATER
		
		for edge_id in game_state.grid.edges:
			var edge = game_state.grid.edges[edge_id]
			var rand_val = randf()
			
			if rand_val < terrain_distribution[0]:
				edge.terrain_type = 0  # FIELD
			elif rand_val < terrain_distribution[0] + terrain_distribution[1]:
				edge.terrain_type = 1  # FOREST
			elif rand_val < terrain_distribution[0] + terrain_distribution[1] + terrain_distribution[2]:
				edge.terrain_type = 2  # MOUNTAIN
			else:
				edge.terrain_type = 3  # WATER

func _unhandled_input(event):
	if game_state.is_empty() or not input_manager:
		return
	
	# Handle debug keys and command shortcuts
	if event is InputEventKey and event.pressed:
		# Undo/redo shortcuts removed during cleanup
		# if event.ctrl_pressed:
		#	match event.keycode:
		#		KEY_Z:
		#			_undo_last_command()
		#		KEY_Y:
		#			_redo_next_command()
		#	return
		
		# Handle function keys
		match event.keycode:
			KEY_F1:
				show_debug_info = not show_debug_info
				queue_redraw()
			KEY_F2:
				show_grid_stats = not show_grid_stats
				queue_redraw()
			KEY_F3:
				_save_game_state()
			KEY_F4:
				_load_game_state()
			# KEY_F5:
			#	show_command_history = not show_command_history
			#	queue_redraw()
	
	# Use InputManager for game input
	input_manager.handle_input_event(event, game_state.grid, game_state.units)

# Input event handlers
func _on_point_clicked(point_id: int):
	if game_over:
		return
	
	print("🎯 Point clicked: %d" % point_id)
	
	if selected_unit_id != -1:
		var clicked_position = game_state.grid.points[point_id].position
		_attempt_move_unit(clicked_position)

func _on_point_hovered(point_id: int):
	queue_redraw()

func _on_point_unhovered(point_id: int):
	queue_redraw()

func _on_unit_clicked(unit_id: int):
	if game_over:
		return
	
	print("🚶 Unit clicked: %d" % unit_id)
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player:
		return
	
	var unit = game_state.units[unit_id]
	if unit.owner_id == current_player.id:
		_select_unit(unit_id)
	else:
		print("❌ Cannot select enemy unit")

func _on_unit_hovered(unit_id: int):
	queue_redraw()

func _on_unit_unhovered(unit_id: int):
	queue_redraw()

func _on_fog_toggle():
	# Use fog toggle use case directly
	var fog_result = ToggleFogUseCase.execute(game_state)
	if fog_result.success:
		print("👁️ %s" % fog_result.message)
	else:
		print("❌ %s" % fog_result.message)
	queue_redraw()

func _on_skip_turn():
	# Use skip turn use case directly
	var skip_result = SkipTurnUseCase.execute(game_state)
	if skip_result.success:
		print("⏭️ %s" % skip_result.message)
		if skip_result.game_over:
			game_over = true
			winner_player = skip_result.winner
			print("🏆 GAME OVER! Winner: %s" % (winner_player.name if winner_player else "Draw"))
	else:
		print("❌ %s" % skip_result.message)
	
	_clear_selection()
	queue_redraw()

func _on_quit_game():
	print("👋 Game quit requested")
	get_tree().quit()

# Game logic
func _select_unit(unit_id: int):
	selected_unit_id = unit_id
	var unit = game_state.units[unit_id]
	
	valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units)
	
	print("✅ Unit selected: %s (%d valid moves)" % [unit.name, valid_movement_targets.size()])
	queue_redraw()

func _attempt_move_unit(target_position):
	if selected_unit_id == -1:
		return
	
	# Use move unit use case directly
	var move_result = MoveUnitUseCase.execute(selected_unit_id, target_position, game_state)
	
	if move_result.success:
		print("✅ Unit moved successfully!")
		if move_result.power_consumed:
			print("⚡ Power consumed")
		_clear_selection()
	else:
		print("❌ %s" % move_result.message)
	
	queue_redraw()

func _clear_selection():
	selected_unit_id = -1
	valid_movement_targets.clear()

# Command system methods removed during cleanup
# func _undo_last_command():
# func _redo_next_command():
# func _on_command_executed(command):
# func _on_command_undone(command):
# func _on_command_redone(command):
# func _on_command_history_changed():

# Save/Load functionality
func _save_game_state():
	var serialized = GameState.serialize_game_state(game_state)
	print("💾 Game state serialized (ready for save)")

func _load_game_state():
	print("📁 Load game state (not implemented yet)")

# Rendering
func _draw():
	if game_state.is_empty():
		return
	
	# Draw background
	draw_rect(Rect2(0, 0, 1024, 768), Color.WHITE)
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	var fog_settings = ToggleFogUseCase.get_visibility_settings(game_state, current_player.id if current_player else 1)
	var hover_state = input_manager.get_hover_state() if input_manager else {}
	var font = ThemeDB.fallback_font
	
	# Render grid using GridRenderer
	GridRenderer.render_grid(self, game_state.grid, hover_state)
	
	# Render domains
	_render_domains(fog_settings)
	
	# Render units using UnitRenderer
	UnitRenderer.render_units(self, game_state.units, selected_unit_id, hover_state, font)
	
	# Render movement targets
	if valid_movement_targets.size() > 0:
		UnitRenderer.render_movement_targets(self, valid_movement_targets, font)
	
	# Render UI layers
	_render_main_ui()
	_render_debug_ui()
	# _render_command_history_ui()  # Removed during cleanup

func _render_domains(fog_settings: Dictionary):
	if not ("domains" in game_state):
		return
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		if fog_settings.show_all_domains or ToggleFogUseCase.is_visible_to_player("domain", domain, fog_settings.player_id, game_state):
			var center_pos = domain.center_position.pixel_pos
			var player = game_state.players[domain.owner_id]
			var color = player.color
			
			# Draw domain influence area
			draw_circle(center_pos, 35.0, Color(color.r, color.g, color.b, 0.2))
			draw_arc(center_pos, 35.0, 0, TAU, 32, color, 3.0)
			
			# Draw domain icon
			var font = ThemeDB.fallback_font
			if font:
				draw_string(font, center_pos + Vector2(-8, 5), "🏰", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, color)
				
				# Draw domain info
				var info = "%s\nPower: %d" % [domain.name, domain.power]
				draw_string(font, center_pos + Vector2(-25, -55), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)

func _render_main_ui():
	var font = ThemeDB.fallback_font
	if not font:
		return
	
	# Game Over screen
	if game_over:
		draw_rect(Rect2(0, 0, 1024, 768), Color(0, 0, 0, 0.8))
		
		var winner_text = "🏆 VICTORY! 🏆"
		draw_string(font, Vector2(512, 300), winner_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color.GOLD)
		
		var winner_name = winner_player.name if winner_player else "Draw"
		draw_string(font, Vector2(512, 360), "Winner: %s" % winner_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color.WHITE)
		
		draw_string(font, Vector2(512, 420), "Press ESC to quit", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.LIGHT_GRAY)
		return
	
	# Current player panel
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if current_player:
		var panel_rect = Rect2(10, 10, 300, 120)
		draw_rect(panel_rect, Color(0, 0, 0, 0.7))
		draw_rect(panel_rect, current_player.color, false, 2.0)
		
		var player_text = "Current Player: %s" % current_player.name
		draw_string(font, Vector2(20, 35), player_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, current_player.color)
		
		var summary = GameState.get_game_state_summary(game_state)
		var turn_text = "Turn: %d" % summary.current_turn
		draw_string(font, Vector2(20, 60), turn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		
		var fog_text = "Fog of War: %s" % ("ON" if summary.fog_enabled else "OFF")
		draw_string(font, Vector2(20, 80), fog_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		
		# Units with actions
		var units_with_actions = 0
		for unit_id in current_player.unit_ids:
			if unit_id in game_state.units:
				var unit = game_state.units[unit_id]
				if unit.can_move():
					units_with_actions += 1
		
		var actions_text = "Units ready: %d" % units_with_actions
		draw_string(font, Vector2(20, 100), actions_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	
	# Controls panel
	var controls_rect = Rect2(10, 680, 400, 80)
	draw_rect(controls_rect, Color(0, 0, 0, 0.7))
	
	var controls = [
		"🎮 CONTROLS: Click unit → Click position | SPACE: Fog | ENTER: Skip | F1: Debug",
		"🏆 OBJECTIVE: Eliminate all enemy units to win!"
	]
	
	for i in range(controls.size()):
		var text = controls[i]
		draw_string(font, Vector2(20, 700 + i * 20), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func _render_debug_ui():
	if not show_debug_info:
		return
	
	var font = ThemeDB.fallback_font
	if not font:
		return
	
	# Debug panel
	var debug_rect = Rect2(750, 10, 260, 180)
	draw_rect(debug_rect, Color(0, 0, 0, 0.8))
	draw_rect(debug_rect, Color.CYAN, false, 1.0)
	
	var debug_info = [
		"🔧 DEBUG INFO:",
		"FPS: %d" % Engine.get_frames_per_second(),
		"Selected Unit: %d" % selected_unit_id,
		"Valid Targets: %d" % valid_movement_targets.size(),
		"",
		"🏗️ ARCHITECTURE:",
		"✅ Core Layer",
		"✅ Application Layer", 
		"✅ Infrastructure Layer",
		"✅ Presentation Layer",
		"",
		"F2: Grid Stats | F3: Save | F4: Load",
		"F5: Command History",
		"",
		"🔄 COMMANDS: Disabled"
	]
	
	for i in range(debug_info.size()):
		var text = debug_info[i]
		var color = Color.CYAN if text.begins_with("🔧") else Color.WHITE
		draw_string(font, Vector2(760, 30 + i * 14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
	
	# Grid stats
	if show_grid_stats:
		GridRenderer.render_grid_stats(self, game_state.grid, Vector2(760, 250), font)

# Command history UI removed during cleanup
# func _render_command_history_ui():
#	if not show_command_history or not command_manager:
#		return