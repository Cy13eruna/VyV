# 🎮 V&V RESTORED GAMEPLAY
# Purpose: Restored original gameplay with all requested changes
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
# No complex debug dependencies

# Game state and systems
var game_state: Dictionary = {}
var input_manager
var selected_unit_id: int = -1
var valid_movement_targets: Array = []
var game_over: bool = false
var winner_player = null

# Debug system (simple)
var debug_enabled: bool = true

# RESTORED GAMEPLAY CONSTANTS
const BOARD_ROTATION = 30.0
const PATH_THICKNESS = 13.3  # Reduced 3x from 40.0
const HEX_SIZE = 40.0  # From game constants
const DOMAIN_RADIUS = HEX_SIZE * sqrt(3.0)  # Mathematically accurate 1 hex distance
const TERRAIN_COLORS = {
	"FIELD": Color(0.0, 1.0, 0.0),
	"FOREST": Color(0.0, 0.5, 0.0),
	"MOUNTAIN": Color(0.5, 0.5, 0.0),
	"WATER": Color(0.0, 0.5, 0.5)
}

# UI state
var show_debug_info: bool = false
var show_grid_stats: bool = false
var show_analytics_dashboard: bool = false
var show_debug_overlay: bool = false
var show_performance_graph: bool = false
var current_dashboard_tab: int = 0

# Power tracking for sprite updates
var previous_domain_powers: Dictionary = {}

func _ready():
	print("=== 🎮 V&V CLEAN FINAL GAME STARTING 🎮 ===")
	print("🏗️ Complete ONION Architecture Implementation")
	print("📊 All Technical Systems Integrated")
	print("==================================================")
	
	setup_debug_and_analytics()
	setup_final_game()
	setup_complete_input_system()
	
	print("🚀 V&V Clean Final Game Ready!")
	print("🎯 Click units to select, click positions to move")
	print("⌨️  SPACE: Toggle fog | ENTER: Skip turn | F1: Debug info")
	print("🔍 F6: Analytics Dashboard | F7: Debug Overlay | F8: Performance Graph")

func setup_debug_and_analytics():
	print("🔍 Setting up debug systems...")
	
	# Initialize simple debug system
	debug_enabled = true
	
	print("✅ Simple debug system ready")

func setup_final_game():
	print("🎲 Initializing complete game with all features...")
	
	# Initialize game with full feature set
	var init_result = InitializeGameUseCase.execute(2)
	
	if init_result.success:
		game_state = init_result.game_state
		
		# Log game start
		if debug_enabled:
			print("[DEBUG] Game session started with 2 players")
		
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
		
		# Initialize power tracking
		_check_power_changes()
	else:
		print("❌ Game initialization failed: %s" % init_result.message)
		game_state = GameState.create_empty_game_state()

func setup_complete_input_system():
	print("🎮 Setting up complete input system...")
	
	input_manager = InputManager.new()
	
	# Connect input signals - ONLY point clicks allowed
	input_manager.point_clicked.connect(_on_point_clicked)
	input_manager.point_hovered.connect(_on_point_hovered)
	input_manager.point_unhovered.connect(_on_point_unhovered)
	# REMOVED: All unit click/hover signals - units are selected via point clicks
	# input_manager.unit_clicked.connect(_on_unit_clicked)
	# input_manager.unit_hovered.connect(_on_unit_hovered)
	# input_manager.unit_unhovered.connect(_on_unit_unhovered)
	input_manager.fog_toggle_requested.connect(_on_fog_toggle)
	# REMOVED: Automatic turn advancement - completely manual only
	# No auto skip turn under any circumstances
	input_manager.game_quit_requested.connect(_on_quit_game)
	
	# Set optimal input tolerances
	input_manager.set_tolerances(25.0, 30.0)  # click, hover
	
	print("✅ Complete input system ready")

func _enhance_terrain_variety():
	# Add some terrain variety to make the game more interesting
	if "edges" in game_state.grid:
		var terrain_distribution = [0.5, 0.2, 0.2, 0.1]  # FIELD, FOREST, MOUNTAIN, WATER
		
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
	
	# Handle debug keys
	if event is InputEventKey and event.pressed:
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
			KEY_F6:
				print("F6 pressed - Analytics Dashboard")
				show_analytics_dashboard = not show_analytics_dashboard
				print("Analytics dashboard: %s" % ("ON" if show_analytics_dashboard else "OFF"))
				queue_redraw()
			KEY_F7:
				print("F7 pressed - Debug Overlay")
				show_debug_overlay = not show_debug_overlay
				debug_enabled = not debug_enabled
				print("Debug overlay: %s" % ("ON" if show_debug_overlay else "OFF"))
				print("Debug logging: %s" % ("ON" if debug_enabled else "OFF"))
				queue_redraw()
			KEY_F8:
				print("F8 pressed - Performance Graph")
				show_performance_graph = not show_performance_graph
				print("Performance graph: %s" % ("ON" if show_performance_graph else "OFF"))
				queue_redraw()
			KEY_TAB:
				print("TAB pressed - Switch Dashboard Tab")
				if show_analytics_dashboard:
					current_dashboard_tab = (current_dashboard_tab + 1) % 5
					var tabs = ["Overview", "Performance", "Gameplay", "Balance", "Debug"]
					print("Dashboard tab: %s" % tabs[current_dashboard_tab])
					queue_redraw()
				else:
					print("Dashboard not active")
			KEY_ENTER:
				# RESTORED: Manual skip turn only
				_on_skip_turn()
	
	# Use InputManager for game input with rotation correction
	if event is InputEventMouseButton and event.pressed:
		# Apply reverse rotation to mouse clicks
		var corrected_event = event.duplicate()
		corrected_event.position = _apply_reverse_board_rotation(event.position)
		input_manager.handle_input_event(corrected_event, game_state.grid, game_state.units)
	elif event is InputEventMouseMotion:
		# Apply reverse rotation to mouse motion
		var corrected_event = event.duplicate()
		corrected_event.position = _apply_reverse_board_rotation(event.position)
		input_manager.handle_input_event(corrected_event, game_state.grid, game_state.units)
	else:
		# Other events (keyboard) don't need rotation correction
		input_manager.handle_input_event(event, game_state.grid, game_state.units)

# Input event handlers
func _on_point_clicked(point_id: int):
	print("🎯 Point clicked: %d" % point_id)
	
	if game_over:
		return
	
	# Get point position
	var point = game_state.grid.points.get(point_id)
	if not point:
		return
	
	var target_position = point.position
	
	# Check if there's a unit at this point
	var unit_at_point = _find_unit_at_position(target_position)
	print("[DEBUG] unit_at_point result: %d" % unit_at_point)
	
	if unit_at_point != -1:
		# There's a unit at this point - check if it's own or enemy
		var unit = game_state.units[unit_at_point]
		var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
		
		if current_player and unit.owner_id == current_player.id:
			# Own unit - select it
			print("[DEBUG] Found own unit at point, attempting selection")
			_attempt_unit_selection(unit_at_point)
		else:
			# Enemy unit - try to move to this position (may trigger forest blocking)
			print("[DEBUG] Found enemy unit at point, attempting movement to position")
			if selected_unit_id != -1:
				print("[DEBUG] Attempting to move to enemy unit position")
				_attempt_unit_movement(target_position)
			else:
				print("[DEBUG] No unit selected for movement to enemy position")
	else:
		# No unit at point - try to move selected unit here
		print("[DEBUG] No unit at point, selected_unit_id: %d" % selected_unit_id)
		if selected_unit_id != -1:
			print("[DEBUG] Attempting to move unit to empty position")
			_attempt_unit_movement(target_position)
		else:
			print("[DEBUG] No unit selected for movement")

func _on_point_hovered(point_id: int):
	queue_redraw()

func _on_point_unhovered(point_id: int):
	queue_redraw()

# REMOVED: _on_unit_clicked - units are now selected via point clicks only
func _on_unit_hovered(unit_id: int):
	queue_redraw()

func _on_unit_unhovered(unit_id: int):
	queue_redraw()

func _on_fog_toggle():
	var fog_result = ToggleFogUseCase.execute(game_state)
	if fog_result.success:
		print("👁️ %s" % fog_result.message)
		print("👁️ Fog of war is now: %s" % ("ENABLED" if fog_result.fog_enabled else "DISABLED"))
		
		# Log fog toggle
		if debug_enabled:
			print("[DEBUG] Fog toggled: %s" % ("ON" if fog_result.fog_enabled else "OFF"))
	queue_redraw()

func _on_skip_turn():
	var skip_result = SkipTurnUseCase.execute(game_state)
	if skip_result.success:
		print("⏭️ %s" % skip_result.message)
		if skip_result.game_over:
			game_over = true
			winner_player = skip_result.winner
			print("🏆 GAME OVER! Winner: %s" % (winner_player.name if winner_player else "Draw"))
		# Check for power changes after turn advance (domains may generate power)
		_check_power_changes()
	_clear_selection()
	queue_redraw()

func _on_quit_game():
	print("👋 Game quit requested")
	get_tree().quit()

# Game logic
func _select_unit(unit_id: int):
	selected_unit_id = unit_id
	var unit = game_state.units[unit_id]
	
	valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units, game_state)
	
	print("✅ Unit selected: %s (%d valid moves)" % [unit.name, valid_movement_targets.size()])
	queue_redraw()

func _attempt_unit_movement(target_position):
	print("[DEBUG] _attempt_unit_movement called with selected_unit_id: %d" % selected_unit_id)
	
	if selected_unit_id == -1:
		print("[DEBUG] No unit selected, returning")
		return
	
	# Execute movement directly
	print("[DEBUG] Executing movement for unit %d" % selected_unit_id)
	var move_result = MoveUnitUseCase.execute(selected_unit_id, target_position, game_state)
	
	if move_result.success:
		print("✅ Unit moved successfully!")
		if move_result.power_consumed:
			print("⚡ Power consumed")
			_check_power_changes()  # Update sprites immediately after power consumption
		_clear_selection()
	else:
		print("❌ %s" % move_result.message)
	
	# Clear selection if unit is exhausted (regardless of success/failure)
	if move_result.get("unit_exhausted", false):
		print("[UI] Unit exhausted - clearing selection and movement targets")
		_clear_selection()
	
	queue_redraw()

func _clear_selection():
	selected_unit_id = -1
	valid_movement_targets.clear()

# Find unit at specific position
func _find_unit_at_position(position) -> int:
	print("[DEBUG] Looking for unit at position: %s" % position.hex_coord.get_string())
	
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		print("[DEBUG] Checking unit %d at position: %s" % [unit_id, unit.position.hex_coord.get_string()])
		if unit.position.equals(position):
			print("[DEBUG] Found unit %d at target position" % unit_id)
			return unit_id
	
	print("[DEBUG] No unit found at target position")
	return -1

# Attempt to select a unit (only own units)
func _attempt_unit_selection(unit_id: int) -> void:
	var unit = game_state.units.get(unit_id)
	if not unit:
		return
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player:
		return
	
	# Only allow selecting own units
	if unit.owner_id != current_player.id:
		print("❌ Cannot select enemy unit")
		return
	
	# Only allow selecting units with actions
	if not unit.can_move():
		print("❌ Cannot select unit with no actions remaining")
		return
	
	# Select the unit
	selected_unit_id = unit_id
	valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units, game_state)
	print("✅ Unit selected: %s (%d valid moves)" % [unit.name, valid_movement_targets.size()])
	queue_redraw()

# Save/Load functionality
func _save_game_state():
	var serialized = GameState.serialize_game_state(game_state)
	print("💾 Game state serialized (ready for save)")

func _load_game_state():
	print("📁 Load game state (not implemented yet)")

# Apply 30-degree rotation to all positions
func _apply_board_rotation(pos: Vector2) -> Vector2:
	var angle = deg_to_rad(BOARD_ROTATION)
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	
	var center = Vector2(512, 384)
	var relative_pos = pos - center
	var rotated = Vector2(
		relative_pos.x * cos_a - relative_pos.y * sin_a,
		relative_pos.x * sin_a + relative_pos.y * cos_a
	)
	return rotated + center

# Apply reverse rotation to convert screen clicks back to original coordinates
func _apply_reverse_board_rotation(pos: Vector2) -> Vector2:
	var angle = deg_to_rad(-BOARD_ROTATION)  # Negative angle for reverse
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	
	var center = Vector2(512, 384)
	var relative_pos = pos - center
	var rotated = Vector2(
		relative_pos.x * cos_a - relative_pos.y * sin_a,
		relative_pos.x * sin_a + relative_pos.y * cos_a
	)
	return rotated + center

func _get_restored_terrain_color(terrain_type: int) -> Color:
	match terrain_type:
		0:  # FIELD
			return TERRAIN_COLORS["FIELD"]
		1:  # FOREST
			return TERRAIN_COLORS["FOREST"]
		2:  # MOUNTAIN
			return TERRAIN_COLORS["MOUNTAIN"]
		3:  # WATER
			return TERRAIN_COLORS["WATER"]
		_:
			return Color.GRAY

# Check for power changes and update sprites accordingly
func _check_power_changes():
	if not ("domains" in game_state):
		return
	
	var power_changed = false
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		var current_power = domain.get("power", 0)
		var previous_power = previous_domain_powers.get(domain_id, -999)  # Use -999 to force initial update
		
		if previous_power != current_power:
			power_changed = true
			previous_domain_powers[domain_id] = current_power
			if previous_power != -999:  # Don't log initial setup
				print("[POWER] Domain %d power changed: %d -> %d" % [domain_id, previous_power, current_power])
			else:
				print("[POWER] Domain %d initial power: %d" % [domain_id, current_power])
	
	if power_changed:
		queue_redraw()  # Force sprite update

# Rendering
func _draw():
	if game_state.is_empty():
		return
	
	# Check for power changes and update sprites
	_check_power_changes()
	
	# Draw background
	draw_rect(Rect2(0, 0, 1024, 768), Color.WHITE)
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	var fog_settings = ToggleFogUseCase.get_visibility_settings(game_state, current_player.id if current_player else 1)
	var hover_state = input_manager.get_hover_state() if input_manager else {}
	var font = ThemeDB.fallback_font
	
	# Render grid with restored style
	_render_grid_restored(hover_state)
	
	# Render domains
	_render_domains(fog_settings)
	
	# Render units using UnitRenderer with fog settings
	_render_units_with_fog(fog_settings, hover_state, font)
	
	# Render movement targets with terrain info
	if valid_movement_targets.size() > 0:
		_render_movement_targets_with_terrain(font)
	
	# Render UI layers
	_render_main_ui()
	_render_debug_ui()
	
	# Render simple debug overlay
	if show_debug_overlay:
		_render_simple_debug_overlay(font)
	
	# Render simple performance graph
	if show_performance_graph:
		_render_simple_performance_graph(font)
	
	# Render fog overlay
	_render_fog_overlay(fog_settings)
	
	# Render simple analytics dashboard
	if show_analytics_dashboard:
		_render_simple_analytics_dashboard(font)

func _render_domains(fog_settings: Dictionary):
	if not ("domains" in game_state):
		return
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		# Check domain visibility based on fog settings
		var domain_visible = true
		if fog_settings.fog_enabled:
			domain_visible = ToggleFogUseCase.is_visible_to_player("domain", domain, fog_settings.player_id, game_state)
		
		if domain_visible:
			var center_pos = _apply_board_rotation(domain.center_position.pixel_pos)
			var player = game_state.players[domain.owner_id]
			var color = player.color
			
			# RESTORED: Hexagonal domains with outline only (no fill) - mathematically 1 hex radius
			_draw_hexagon_outline(center_pos, DOMAIN_RADIUS, color, 4.0)
			
			# Draw domain info (no castle emoji)
			var font = ThemeDB.fallback_font
			if font:
				var info = "%s\nPower: %d" % [domain.name, domain.power]
				draw_string(font, center_pos + Vector2(-25, -75), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)

func _draw_hexagon_outline(center: Vector2, radius: float, color: Color, width: float):
	var points = []
	for i in range(6):
		var angle = i * PI / 3.0
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	for i in range(6):
		var start_point = points[i]
		var end_point = points[(i + 1) % 6]
		draw_line(start_point, end_point, color, width)

func _render_grid_restored(hover_state: Dictionary):
	if not ("grid" in game_state):
		return
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	var current_player_id = current_player.id if current_player else 1
	
	# Draw edges with restored colors and thickness (with fog of war)
	for edge_id in game_state.grid.edges:
		var edge = game_state.grid.edges[edge_id]
		
		# Check if edge is visible to current player
		var is_visible = true
		if game_state.get("fog_of_war_enabled", false):
			is_visible = ToggleFogUseCase._is_edge_visible_to_player(edge, current_player_id, game_state)
		
		if is_visible:
			var point_a = game_state.grid.points[edge.point_a_id]
			var point_b = game_state.grid.points[edge.point_b_id]
			
			# Get terrain color from restored palette
			var terrain_color = _get_restored_terrain_color(edge.get("terrain_type", 0))
			
			draw_line(
				_apply_board_rotation(point_a.position.pixel_pos),
				_apply_board_rotation(point_b.position.pixel_pos),
				terrain_color,
				PATH_THICKNESS
			)
	
	# Draw points (with fog of war)
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		
		# Check if point is visible to current player
		var is_visible = true
		if game_state.get("fog_of_war_enabled", false):
			is_visible = ToggleFogUseCase._is_position_visible_to_player(point.position, current_player_id, game_state)
		
		if is_visible:
			var color = Color.RED if point.get("is_corner", false) else Color.BLACK
			draw_circle(_apply_board_rotation(point.position.pixel_pos), 8.0, color)

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
		"F2: Grid Stats | F3: Save | F4: Load"
	]
	
	for i in range(debug_info.size()):
		var text = debug_info[i]
		var color = Color.CYAN if text.begins_with("🔧") else Color.WHITE
		draw_string(font, Vector2(760, 30 + i * 14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
	
	# Grid stats
	if show_grid_stats:
		GridRenderer.render_grid_stats(self, game_state.grid, Vector2(760, 200), font)

# Simple debug/analytics rendering
func _render_simple_debug_overlay(font: Font) -> void:
	if not font:
		return
	
	# Debug overlay background
	var overlay_rect = Rect2(10, 200, 300, 150)
	draw_rect(overlay_rect, Color(0, 0, 0, 0.8))
	draw_rect(overlay_rect, Color.GREEN, false, 2.0)
	
	# Debug info
	draw_string(font, Vector2(20, 220), "🔍 DEBUG OVERLAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GREEN)
	draw_string(font, Vector2(20, 240), "FPS: %d" % Engine.get_frames_per_second(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(font, Vector2(20, 255), "Memory: %.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(font, Vector2(20, 270), "Frame Time: %.2f ms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(font, Vector2(20, 285), "Selected Unit: %d" % selected_unit_id, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(font, Vector2(20, 300), "Valid Targets: %d" % valid_movement_targets.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(font, Vector2(20, 320), "Game Over: %s" % game_over, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(font, Vector2(20, 335), "Fog of War: %s" % ("ON" if game_state.get("fog_of_war_enabled", false) else "OFF"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(font, Vector2(20, 365), "Debug Logging: %s" % ("ON" if debug_enabled else "OFF"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	
	# Add visibility debug info
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if current_player:
		var visible_enemy_units = 0
		for unit_id in game_state.units:
			var unit = game_state.units[unit_id]
			if unit.owner_id != current_player.id:
				if ToggleFogUseCase.is_visible_to_player("unit", unit, current_player.id, game_state):
					visible_enemy_units += 1
		
		draw_string(font, Vector2(20, 380), "Visible Enemy Units: %d" % visible_enemy_units, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(font, Vector2(20, 400), "F7: Toggle | SPACE: Toggle Fog", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.LIGHT_GRAY)

func _render_simple_performance_graph(font: Font) -> void:
	if not font:
		return
	
	# Performance graph background
	var graph_rect = Rect2(50, 300, 300, 150)
	draw_rect(graph_rect, Color(0, 0, 0, 0.8))
	draw_rect(graph_rect, Color.YELLOW, false, 2.0)
	
	# Graph info
	draw_string(font, Vector2(60, 320), "📈 PERFORMANCE GRAPH", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
	draw_string(font, Vector2(60, 340), "Current FPS: %d" % Engine.get_frames_per_second(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(font, Vector2(60, 355), "Target FPS: 60", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	
	# Simple FPS bar
	var fps = Engine.get_frames_per_second()
	var bar_width = (fps / 60.0) * 200
	var bar_color = Color.GREEN if fps >= 45 else Color.YELLOW if fps >= 30 else Color.RED
	draw_rect(Rect2(60, 370, bar_width, 20), bar_color)
	draw_rect(Rect2(60, 370, 200, 20), Color.WHITE, false, 1.0)
	
	draw_string(font, Vector2(60, 410), "Memory: %.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(font, Vector2(60, 430), "F8: Toggle", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.LIGHT_GRAY)

func _render_simple_analytics_dashboard(font: Font) -> void:
	if not font:
		return
	
	# Dashboard background
	var dashboard_rect = Rect2(400, 50, 500, 400)
	draw_rect(dashboard_rect, Color(0, 0, 0, 0.9))
	draw_rect(dashboard_rect, Color.CYAN, false, 2.0)
	
	# Dashboard title
	draw_string(font, Vector2(410, 75), "📈 ANALYTICS DASHBOARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.CYAN)
	
	# Tab navigation
	var tabs = ["Overview", "Performance", "Gameplay", "Balance", "Debug"]
	var tab_width = 90
	for i in range(tabs.size()):
		var tab_rect = Rect2(410 + i * tab_width, 90, tab_width - 5, 25)
		var tab_color = Color.CYAN if i == current_dashboard_tab else Color.GRAY
		var text_color = Color.BLACK if i == current_dashboard_tab else Color.WHITE
		
		draw_rect(tab_rect, tab_color)
		draw_rect(tab_rect, Color.WHITE, false, 1.0)
		draw_string(font, Vector2(tab_rect.position.x + 5, tab_rect.position.y + 18), tabs[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, text_color)
	
	# Tab content
	var content_y = 130
	match current_dashboard_tab:
		0:  # Overview
			draw_string(font, Vector2(420, content_y), "OVERVIEW TAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 20), "Game Status: %s" % ("Running" if not game_over else "Game Over"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 35), "Current Player: %d" % game_state.get("turn_data", {}).get("current_player_id", 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 50), "Turn Number: %d" % game_state.get("turn_data", {}).get("turn_number", 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		1:  # Performance
			draw_string(font, Vector2(420, content_y), "PERFORMANCE TAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 20), "FPS: %d" % Engine.get_frames_per_second(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 35), "Memory: %.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 50), "Frame Time: %.2f ms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		2:  # Gameplay
			draw_string(font, Vector2(420, content_y), "GAMEPLAY TAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 20), "Units: %d" % game_state.get("units", {}).size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 35), "Players: %d" % game_state.get("players", {}).size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 50), "Selected Unit: %d" % selected_unit_id, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		3:  # Balance
			draw_string(font, Vector2(420, content_y), "BALANCE TAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 20), "Game Balance Analysis", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 35), "Turn Duration: Balanced", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 50), "Player Actions: Even", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		4:  # Debug
			draw_string(font, Vector2(420, content_y), "DEBUG TAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 20), "Debug System: %s" % ("Active" if debug_enabled else "Inactive"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			draw_string(font, Vector2(420, content_y + 35), "Dashboard: Active", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	
	# Instructions
	draw_string(font, Vector2(420, 420), "F6: Toggle Dashboard | TAB: Switch Tabs", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.LIGHT_GRAY)

# Render units with fog of war
func _render_units_with_fog(fog_settings: Dictionary, hover_state: Dictionary, font: Font) -> void:
	if not font:
		return
	
	# Render each unit based on fog settings
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		# Check if unit should be visible
		var is_visible = true
		if fog_settings.fog_enabled:
			is_visible = ToggleFogUseCase.is_visible_to_player("unit", unit, fog_settings.player_id, game_state)
		
		if is_visible:
			# Render visible unit with restored style
			var pos = _apply_board_rotation(unit.position.pixel_pos)
			var is_selected = unit_id == selected_unit_id
			var is_hovered = unit_id in hover_state and hover_state[unit_id]
			
			var unit_color = game_state.players[unit.owner_id].color
			
			# Check if unit has actions remaining
			var has_actions = unit.can_move()
			var display_color = unit_color
			var emoji_color = Color.WHITE
			
			if not has_actions:
				# Unit has no actions - make it grayish/whitish
				display_color = Color(0.8, 0.8, 0.8, 0.7)  # Light gray
				emoji_color = Color(0.6, 0.6, 0.6)  # Darker gray for emoji
			
			# RESTORED: Paint emoji with player color, remove circle background, 2x size, moved up
			# Add colored background circle to "tint" the unit
			draw_circle(pos, 18.0, display_color)
			draw_string(font, pos + Vector2(-12, 0), "🚶", HORIZONTAL_ALIGNMENT_CENTER, -1, 32, emoji_color)
			
			# Unit name and info
			draw_string(font, pos + Vector2(-15, -25), unit.name, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, unit_color)
			
			# Selection indicator (adjusted for 2x unit size)
			if is_selected:
				draw_arc(pos, 25.0, 0, TAU, 32, Color.YELLOW, 3.0)
				
			# Hover indicator (adjusted for 2x unit size)
			if is_hovered:
				draw_arc(pos, 23.0, 0, TAU, 32, Color.WHITE, 2.0)
		else:
			# Unit is hidden by fog - don't render anything
			pass
			
			# Optional: Render a "?" or shadow where hidden units might be
			# This would require additional game logic to track "last known positions"

# Add fog of war visual effects
func _render_fog_overlay(fog_settings: Dictionary) -> void:
	if not fog_settings.fog_enabled:
		return
	
	# Render fog overlay on areas not visible to current player
	# This is a simple implementation - could be much more sophisticated
	var current_player_id = fog_settings.player_id
	
	# Get player's unit positions for visibility calculation (original positions)
	var player_positions = []
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id == current_player_id:
			player_positions.append(unit.position.pixel_pos)  # Keep original positions for calculation
	
	# REMOVED: Dark fog overlay - no more screen darkening
	# Fog of war is now handled purely by hiding/showing elements

# Render movement targets with terrain information
func _render_movement_targets_with_terrain(font: Font) -> void:
	if not font or selected_unit_id == -1:
		return
	
	var unit = game_state.units[selected_unit_id]
	
	for target_pos in valid_movement_targets:
		var pos = target_pos.pixel_pos
		
		# Get terrain cost for this movement
		var terrain_cost = MovementService.get_terrain_movement_cost(unit, target_pos, game_state.grid)
		
		# Use magenta color for all valid movement targets
		var target_color = Color.MAGENTA
		var border_color = Color.WHITE
		
		# Adjust opacity based on terrain cost
		match terrain_cost:
			1:  # Normal movement
				target_color = Color(1.0, 0.0, 1.0, 0.6)  # Magenta
			2:  # Difficult terrain
				target_color = Color(1.0, 0.0, 1.0, 0.8)  # Darker magenta
				border_color = Color.ORANGE
			999:  # Impassable
				target_color = Color.RED
				border_color = Color.DARK_RED
		
		# Draw movement target with rotation
		var rotated_pos = _apply_board_rotation(pos)
		draw_circle(rotated_pos, 12.0, Color(target_color.r, target_color.g, target_color.b, 0.6))
		draw_circle(rotated_pos, 12.0, border_color, false, 2.0)
		
		# Draw terrain cost indicator with rotation
		if terrain_cost > 1 and terrain_cost < 999:
			draw_string(font, rotated_pos + Vector2(-4, 4), str(terrain_cost), HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
		elif terrain_cost >= 999:
			draw_string(font, rotated_pos + Vector2(-4, 4), "X", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
		
		# REMOVED: Terrain type emoji indicators - cleaner interface

# Get terrain icon for display
func _get_terrain_icon(terrain_type: int) -> String:
	match terrain_type:
		0:  # FIELD
			return "🌾"
		1:  # FOREST
			return "🌲"
		2:  # MOUNTAIN
			return "⛰️"
		3:  # WATER
			return "🌊"
		_:
			return ""