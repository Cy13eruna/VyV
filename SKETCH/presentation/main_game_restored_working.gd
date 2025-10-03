# 🎮 V&V RESTORED GAMEPLAY
# Purpose: Restored original gameplay with all requested changes
# Layer: Presentation (ONION Coordinator)

extends Node2D

# Preload complete ONION architecture
const InitializeGameUseCase = preload("res://application/use_cases/initialize_game_clean.gd")
const MoveUnitUseCase = preload("res://application/use_cases/move_unit_clean.gd")
const SkipTurnUseCase = preload("res://application/use_cases/skip_turn_clean.gd")
const ToggleFogUseCase = preload("res://application/use_cases/toggle_fog_clean.gd")
# Build structure functionality removed during cleanup

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

# Menu state
var in_menu: bool = true
var selected_player_count: int = 0

# Structure building system removed during cleanup
# var build_mode: bool = false
# var selected_structure_type: int = 0
# var buildable_edges: Array = []
# var hovered_edge_id: int = -1

# Debug system (simple)
var debug_enabled: bool = true

# RESTORED GAMEPLAY CONSTANTS
const BOARD_ROTATION = 30.0
const PATH_THICKNESS = 13.3  # Reduced 3x from 40.0
const HEX_SIZE = 40.0  # From game constants
const DOMAIN_RADIUS = HEX_SIZE * 1.95  # Increased from 1.85 to 1.95
const TERRAIN_COLORS = {
	"FIELD": Color(0.0, 1.0, 0.0),      # 00FF00 - bright green
	"FOREST": Color(0.0, 0.4, 0.0),     # 006600 - dark green
	"MOUNTAIN": Color(0.4, 0.4, 0.4),   # 666666 - gray
	"WATER": Color(0.0, 1.0, 1.0)       # 00FFFF - cyan
}

# Remembered terrain colors (50% lighter than normal terrain)
const REMEMBERED_TERRAIN_COLORS = {
	"FIELD": Color(0.5, 1.0, 0.5),      # 50% lighter bright green
	"FOREST": Color(0.5, 0.7, 0.5),     # 50% lighter dark green
	"MOUNTAIN": Color(0.7, 0.7, 0.7),   # 50% lighter gray
	"WATER": Color(0.5, 1.0, 1.0)       # 50% lighter cyan
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

# Texture system for terrain
var terrain_textures: Dictionary = {}
var textures_loaded: bool = false



func _ready():
	print("=== 🎮 V&V GAME STARTING 🎮 ===")
	print("🏗️ Complete ONION Architecture Implementation")
	print("📊 All Technical Systems Integrated")
	print("==================================================")
	
	setup_debug_and_analytics()
	
	# Load terrain textures
	_load_terrain_textures()
	
	# Start in menu mode - wait for player count selection
	print("🎮 Waiting for player count selection...")
	print("Press 2, 3, 4, or 6 to select number of players")
	queue_redraw()

# Load terrain textures from files
func _load_terrain_textures():
	print("🎨 Loading terrain textures...")
	print("🔍 Current working directory: %s" % OS.get_executable_path().get_base_dir())
	
	# Define texture paths for each terrain type (relative to project root)
	var texture_paths = {
		"FIELD": "res://textures/field/texture.png",
		"FOREST": "res://textures/forest/texture.png",
		"MOUNTAIN": "res://textures/mountain/texture.png",
		"WATER": "res://textures/water/texture.png"
	}
	
	# Also try .tres files as fallback
	var texture_paths_tres = {
		"FIELD": "res://textures/field/texture.tres",
		"FOREST": "res://textures/forest/texture.tres",
		"MOUNTAIN": "res://textures/mountain/texture.tres",
		"WATER": "res://textures/water/texture.tres"
	}
	
	# Load each texture
	for terrain_name in texture_paths:
		var texture_path = texture_paths[terrain_name]
		var texture_path_tres = texture_paths_tres[terrain_name]
		
		print("🔍 Checking texture: %s" % terrain_name)
		
		# Try PNG first
		if FileAccess.file_exists(texture_path):
			print("📁 Found PNG file: %s" % texture_path)
			var texture = load(texture_path) as Texture2D
			if texture:
				terrain_textures[terrain_name] = texture
				print("✅ Loaded PNG texture: %s" % texture_path)
			else:
				print("❌ Failed to load PNG texture: %s" % texture_path)
		# Try TRES as fallback
		elif FileAccess.file_exists(texture_path_tres):
			print("📁 Found TRES file: %s" % texture_path_tres)
			var texture = load(texture_path_tres) as Texture2D
			if texture:
				terrain_textures[terrain_name] = texture
				print("✅ Loaded TRES texture: %s" % texture_path_tres)
			else:
				print("❌ Failed to load TRES texture: %s" % texture_path_tres)
		else:
			print("📁 No texture files found for %s (using solid color)" % terrain_name)
			print("   Checked: %s" % texture_path)
			print("   Checked: %s" % texture_path_tres)
	
	textures_loaded = true
	print("🎨 Texture loading completed. Loaded %d textures." % terrain_textures.size())
	if terrain_textures.size() == 0:
		print("⚠️  No textures loaded - using solid colors as fallback")
	else:
		print("✅ Textures available: %s" % str(terrain_textures.keys()))



func setup_debug_and_analytics():
	print("🔍 Setting up debug systems...")
	
	# Initialize simple debug system
	debug_enabled = true
	
	print("✅ Simple debug system ready")

func setup_final_game():
	# This function is now deprecated - use setup_final_game_with_count instead
	setup_final_game_with_count(2)

func setup_final_game_with_count(player_count: int):
	print("🎲 Initializing complete game with %d players..." % player_count)
	
	# Initialize game with selected player count
	var init_result = InitializeGameUseCase.execute(player_count)
	
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

# Get player count from console input
func _get_player_count_from_input() -> int:
	print("\n=== 🎮 V&V GAME SETUP ===")
	print("Choose number of players:")
	print("2 players -> Map diameter: 7 stars")
	print("3 players -> Map diameter: 9 stars")
	print("4 players -> Map diameter: 13 stars")
	print("6 players -> Map diameter: 18 stars")
	print("\nEnter number of players (2, 3, 4, or 6): ")
	
	# For now, we'll use a default since Godot console input is complex
	# In a real implementation, this would read from console
	var valid_counts = [2, 3, 4, 6]
	var default_count = 2
	
	# Try to read from command line arguments if available
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--players="):
			var count_str = arg.split("=")[1]
			var count = count_str.to_int()
			if count in valid_counts:
				print("Using player count from command line: %d" % count)
				return count
	
	# For development, cycle through different counts based on time
	# This allows testing different map sizes easily
	var time_based_index = int(Time.get_unix_time_from_system()) % valid_counts.size()
	var selected_count = valid_counts[time_based_index]
	
	print("Using player count: %d (auto-selected for testing)" % selected_count)
	print("To specify player count, use: --players=N (where N is 2, 3, 4, or 6)")
	print("========================\n")
	
	return selected_count

# Handle menu input for player count selection
func _handle_menu_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_2:
				_start_game_with_players(2)
			KEY_3:
				_start_game_with_players(3)
			KEY_4:
				_start_game_with_players(4)
			KEY_6:
				_start_game_with_players(6)
			KEY_ESCAPE:
				print("Game cancelled")
				get_tree().quit()

# Start game with selected number of players
func _start_game_with_players(player_count: int):
	print("\n=== Starting game with %d players ===" % player_count)
	selected_player_count = player_count
	in_menu = false
	
	# Now initialize the game
	setup_final_game_with_count(player_count)
	setup_complete_input_system()
	
	print("🚀 V&V Game Ready!")
	print("🎯 Click units to select, click positions to move")
	print("⌨️  SPACE: Toggle fog | ENTER: Skip turn | F1: Debug info")
	print("🔍 F6: Analytics Dashboard | F7: Debug Overlay | F8: Performance Graph")
	
	queue_redraw()

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
	# Handle menu input first
	if in_menu:
		_handle_menu_input(event)
		return
	
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
			KEY_F9:
				# NEW: Test domain visibility logic
				_test_domain_visibility()
			KEY_F10:
				# NEW: Test detailed domain position visibility
				_test_detailed_domain_visibility()
			KEY_F11:
				# NEW: Debug position structure
				_debug_position_structure()
			KEY_F12:
				# NEW: Debug texture system
				_debug_texture_system()
			KEY_F5:
				# NEW: Debug emoji colors
				_debug_emoji_colors()
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
			# KEY_B:
				# Toggle build mode - DISABLED
				# _toggle_build_mode()
			# KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				# Select structure type in build mode - DISABLED
				# if build_mode:
				#	selected_structure_type = event.keycode - KEY_1
				#	_update_buildable_edges()
				#	queue_redraw()
	
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
	if game_over:
		return
	
	# Handle build mode clicks - DISABLED
	# if build_mode:
	#	_handle_build_mode_click(point_id)
	#	return
	
	# Get point position
	var point = game_state.grid.points.get(point_id)
	if not point:
		return
	
	var target_position = point.position
	
	# Check if there's a unit at this point
	var unit_at_point = _find_unit_at_position(target_position)
	
	if unit_at_point != -1:
		# There's a unit at this point - check if it's own or enemy
		var unit = game_state.units[unit_at_point]
		var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
		
		if current_player and unit.owner_id == current_player.id:
			# Own unit - select it
			_attempt_unit_selection(unit_at_point)
		else:
			# Enemy unit - try to move to this position (may trigger forest blocking)
			if selected_unit_id != -1:
				_attempt_unit_movement(target_position)
	else:
		# No unit at point - try to move selected unit here
		if selected_unit_id != -1:
			# Check if target position is a valid movement target
			var is_valid_target = false
			for valid_target in valid_movement_targets:
				if valid_target.equals(target_position):
					is_valid_target = true
					break
			
			if is_valid_target:
				_attempt_unit_movement(target_position)
			else:
				# Clicked outside valid targets - deselect unit
				print("❌ Clicked outside valid targets - deselecting unit")
				_clear_selection()
				queue_redraw()

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

# Structure building functions removed during cleanup
# func _toggle_build_mode():
#	print("🏗️ Build mode temporarily disabled - domains need internal structure implementation")
#	return

# func _update_buildable_edges():
#	if not build_mode:
#		return

# func _attempt_structure_build(edge_id: int):
#	if not build_mode or edge_id not in buildable_edges:
#		return

# func _handle_build_mode_click(point_id: int):
#	# In build mode, we need to find edges connected to this point
#	# and check if any are buildable
#	var point = game_state.grid.points.get(point_id)
#	if not point:
#		return

# NEW: Test domain visibility logic
func _test_domain_visibility():
	print("\n=== 🔍 TESTING DOMAIN VISIBILITY LOGIC ===")
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player:
		print("❌ No current player found")
		return
	
	# Test visibility for current player
	var test_result = ToggleFogUseCase.test_domain_visibility(game_state, current_player.id)
	
	print("\n📊 DETAILED RESULTS:")
	for detail in test_result.details:
		var status = "👁️ VISIBLE" if detail.is_visible else "🙈 HIDDEN"
		var ownership = "👤 OWN" if detail.is_own else "👥 ENEMY"
		var structure = "🏗️ REAL" if detail.has_structure else "📋 DICT"
		
		print("  Domain %d (%s, %s, %s): %s" % [
			detail.domain_id,
			ownership,
			structure,
			"Player %d" % detail.owner_id,
			status
		])
	
	print("\n🎯 SUMMARY:")
	print("  ✅ New visibility rule: Domain visible if ANY of 7 points is seen")
	print("  📊 Results: %d/%d enemy domains visible" % [test_result.enemy_domains_visible, test_result.total_domains - test_result.own_domains])
	print("  🔄 Press F9 again to re-test after moving units")
	print("  🔎 Press F10 to test specific domain positions")
	print("=== 🔍 TEST COMPLETED ===\n")

# NEW: Test detailed domain position visibility
func _test_detailed_domain_visibility():
	print("\n=== 🔎 DETAILED DOMAIN POSITION TEST ===")
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player:
		print("❌ No current player found")
		return
	
	# Test each enemy domain's positions
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		var domain_owner = domain.get("owner_id", -1)
		
		if domain_owner != current_player.id:
			print("\n🏰 Testing Enemy Domain %d (Player %d):" % [domain_id, domain_owner])
			
			# Test center position
			var center_pos = domain.get("center_position")
			if center_pos:
				print("  🎯 Center position test:")
				var center_result = ToggleFogUseCase.debug_position_visibility(game_state, current_player.id, center_pos)
				
				# Test surrounding positions
				print("  🔄 Surrounding positions test:")
				var surrounding = ToggleFogUseCase._get_surrounding_positions(center_pos)
				for i in range(surrounding.size()):
					var pos = surrounding[i]
					print("    Position %d:" % (i + 1))
					var pos_result = ToggleFogUseCase.debug_position_visibility(game_state, current_player.id, pos)
				
				# Final domain visibility test
				var domain_visible = ToggleFogUseCase._is_domain_visible(domain, current_player.id, game_state)
				print("  👁️ Final domain visibility: %s" % ("✅ VISIBLE" if domain_visible else "❌ HIDDEN"))
	
	print("\n=== 🔎 DETAILED TEST COMPLETED ===\n")

# NEW: Debug position structure
func _debug_position_structure():
	print("\n=== 🔧 POSITION STRUCTURE DEBUG ===")
	
	# Debug domain positions
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		var center_pos = domain.get("center_position")
		
		print("\n🏰 Domain %d:" % domain_id)
		print("  Domain type: %s" % typeof(domain))
		print("  Domain keys: %s" % str(domain.keys()))
		
		if center_pos:
			print("  Center position type: %s" % typeof(center_pos))
			print("  Center position methods: %s" % str(center_pos.get_method_list()))
			
			if "hex_coord" in center_pos:
				var hex_coord = center_pos.hex_coord
				print("  Hex coord type: %s" % typeof(hex_coord))
				if hex_coord:
					print("  Hex coord methods: %s" % str(hex_coord.get_method_list()))
					if "q" in hex_coord and "r" in hex_coord:
						print("  Hex coord q,r: (%d, %d)" % [hex_coord.q, hex_coord.r])
					else:
						print("  Hex coord missing q,r properties")
			else:
				print("  No hex_coord property found")
			
			if center_pos.has_method("get_string"):
				print("  Position string: %s" % center_pos.get_string())
		else:
			print("  No center_position found")
	
	print("\n=== 🔧 STRUCTURE DEBUG COMPLETED ===\n")

# NEW: Debug texture system
func _debug_texture_system():
	print("\n=== 🎨 TEXTURE SYSTEM DEBUG ===")
	
	print("Textures loaded: %s" % textures_loaded)
	print("Terrain textures count: %d" % terrain_textures.size())
	
	for terrain_name in terrain_textures:
		var texture = terrain_textures[terrain_name]
		print("  %s: %s (class: %s)" % [terrain_name, texture, texture.get_class() if texture else "null"])
		if texture:
			print("    Size: %dx%d" % [texture.get_width(), texture.get_height()])
	
	# Test texture retrieval
	print("\nTesting texture retrieval:")
	for i in range(4):
		var texture = _get_terrain_texture(i)
		var terrain_names = ["FIELD", "FOREST", "MOUNTAIN", "WATER"]
		print("  Type %d (%s): %s" % [i, terrain_names[i], "Found" if texture else "Not found"])
	
	print("\n=== 🎨 TEXTURE DEBUG COMPLETED ===\n")

# NEW: Debug emoji colors
func _debug_emoji_colors():
	print("\n=== 🌈 EMOJI COLOR DEBUG ===")
	
	print("Testing emoji colors for all terrain types:")
	
	for terrain_type in range(4):
		var terrain_names = ["FIELD", "FOREST", "MOUNTAIN", "WATER"]
		var terrain_name = terrain_names[terrain_type]
		
		print("\n%s (Type %d):" % [terrain_name, terrain_type])
		
		# Test normal color
		var normal_color = _get_terrain_emoji_color(terrain_type, false)
		print("  Normal: %s" % normal_color)
		
		# Test remembered color
		var remembered_color = _get_terrain_emoji_color(terrain_type, true)
		print("  Remembered: %s" % remembered_color)
		
		# Calculate difference
		var diff_r = remembered_color.r - normal_color.r
		var diff_g = remembered_color.g - normal_color.g
		var diff_b = remembered_color.b - normal_color.b
		var diff_a = remembered_color.a - normal_color.a
		
		print("  Difference: R:%.2f G:%.2f B:%.2f A:%.2f" % [diff_r, diff_g, diff_b, diff_a])
		
		if diff_r > 0 or diff_g > 0 or diff_b > 0:
			print("  ✅ Color is lighter when remembered")
		else:
			print("  ❌ Color is NOT lighter when remembered")
	
	print("\n=== 🌈 EMOJI COLOR DEBUG COMPLETED ===\n")

# Game logic
func _select_unit(unit_id: int):
	selected_unit_id = unit_id
	var unit = game_state.units[unit_id]
	
	valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units, game_state)
	
	print("✅ Unit selected: %s (%d valid moves)" % [unit.name, valid_movement_targets.size()])
	queue_redraw()

func _attempt_unit_movement(target_position):
	if selected_unit_id == -1:
		return
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
		_clear_selection()
	
	queue_redraw()

func _clear_selection():
	selected_unit_id = -1
	valid_movement_targets.clear()

# Find unit at specific position
func _find_unit_at_position(position) -> int:
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.position.equals(position):
			return unit_id
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

func _get_restored_terrain_color(terrain_type: int, is_remembered: bool = false) -> Color:
	var color_set = REMEMBERED_TERRAIN_COLORS if is_remembered else TERRAIN_COLORS
	match terrain_type:
		0:  # FIELD
			return color_set["FIELD"]
		1:  # FOREST
			return color_set["FOREST"]
		2:  # MOUNTAIN
			return color_set["MOUNTAIN"]
		3:  # WATER
			return color_set["WATER"]
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
	# Show menu if in menu state
	if in_menu:
		_render_menu()
		return
	
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
	
	# Render grid with restored style (edges only)
	_render_grid_edges(hover_state)
	
	# Render domains
	_render_domains(fog_settings)
	
	# Render movement targets BEFORE stars so glow appears behind them
	if valid_movement_targets.size() > 0:
		_render_movement_targets_with_terrain(font)
	
	# Render grid points (stars) AFTER movement targets to overlay them
	_render_grid_points(hover_state)
	
	# Render units using UnitRenderer with fog settings
	_render_units_with_fog(fog_settings, hover_state, font)
	
	# Build mode rendering disabled
	# if build_mode:
	#	_render_build_mode(font)
	
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

# Render player count selection menu
func _render_menu():
	# Draw background
	draw_rect(Rect2(0, 0, 1024, 768), Color(0.1, 0.1, 0.2))
	
	var font = ThemeDB.fallback_font
	if not font:
		return
	
	# Title
	draw_string(font, Vector2(512, 150), "V&V - Vales & Vales", HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color.WHITE)
	draw_string(font, Vector2(512, 200), "Strategy Game", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.LIGHT_GRAY)
	
	# Instructions
	draw_string(font, Vector2(512, 280), "Choose Number of Players:", HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color.YELLOW)
	
	# Player options
	var options = [
		{"key": "2", "players": 2, "diameter": 7, "y": 350},
		{"key": "3", "players": 3, "diameter": 9, "y": 400},
		{"key": "4", "players": 4, "diameter": 13, "y": 450},
		{"key": "6", "players": 6, "diameter": 18, "y": 500}
	]
	
	for option in options:
		var text = "Press [%s] - %d Players (Map: %d stars diameter)" % [option.key, option.players, option.diameter]
		draw_string(font, Vector2(512, option.y), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.WHITE)
	
	# Footer
	draw_string(font, Vector2(512, 600), "Press ESC to quit", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.LIGHT_GRAY)
	
	# Game info
	draw_string(font, Vector2(512, 680), "Features: Fog of War, Terrain Variety, Strategic Combat", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.CYAN)
	draw_string(font, Vector2(512, 710), "Architecture: Clean ONION Design with Use Cases", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.GREEN)

func _render_domains(fog_settings: Dictionary):
	if not ("domains" in game_state):
		return
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		# Check domain visibility based on fog settings for outline
		var domain_visible = true
		if fog_settings.fog_enabled:
			domain_visible = ToggleFogUseCase.is_visible_to_player("domain", domain, fog_settings.player_id, game_state)
		
		if domain_visible:
			var center_pos = _apply_board_rotation(domain.center_position.pixel_pos)
			var player = game_state.players[domain.owner_id]
			var color = player.color
			
			# UPDATED: Hexagonal domains with solid outline, rotated 30°
			_draw_hexagon_solid_outline(center_pos, DOMAIN_RADIUS, color, 6.0)
			
			# Draw domain info below the domain (bold and italic)
			var font = ThemeDB.fallback_font
			if font:
				# Domain name with space and power on same line - moved more down
				var domain_info = "%s ⭐%d" % [domain.name, domain.power]
				var domain_pos = center_pos + Vector2(0, DOMAIN_RADIUS + 25)
				_draw_bold_italic_text(font, domain_pos, domain_info, 14, color)

# Draw text with bold and italic effect (properly centered)
func _draw_bold_italic_text(font: Font, position: Vector2, text: String, size: int, color: Color) -> void:
	# Calculate text size for proper centering
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
	var centered_pos = position - Vector2(text_size.x / 2, 0)
	
	# REAL Italic effect: multiple draws with progressive slant
	var italic_offsets = [
		Vector2(0, 0),   # Base
		Vector2(1, -2),  # Top slant
		Vector2(2, -4),  # More top slant
		Vector2(-1, 2),  # Bottom slant
		Vector2(-2, 4)   # More bottom slant
	]
	
	# Bold effect: multiple draws with slight offsets
	var bold_offsets = [
		Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
		Vector2(-1, 0),                   Vector2(1, 0),
		Vector2(-1, 1),  Vector2(0, 1),  Vector2(1, 1)
	]
	
	# Draw italic slanted versions for italic effect
	for italic_offset in italic_offsets:
		# Draw bold outline
		for bold_offset in bold_offsets:
			draw_string(font, centered_pos + italic_offset + bold_offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.BLACK)
	
	# Draw main text with slight italic slant
	draw_string(font, centered_pos + Vector2(1, -1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)



# Draw diamond-shaped path between two points with emoji support
func _draw_diamond_path(start_pos: Vector2, end_pos: Vector2, color: Color, thickness: float, terrain_type: int = 0, is_remembered: bool = false) -> void:
	# Calculate path direction and perpendicular
	var direction = (end_pos - start_pos).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	# Calculate diamond dimensions (width slightly more than half for better mesh)
	var path_length = start_pos.distance_to(end_pos)
	var diamond_width = path_length * 0.6  # Width is 60% of length for slightly thicker diamonds
	var diamond_length = path_length  # Length spans the entire path
	
	# Calculate diamond vertices
	# Acute angles at the tips (sharp points)
	# Obtuse angles at the sides (wide angles)
	var center = (start_pos + end_pos) / 2
	
	# Diamond vertices: acute tips at start/end, obtuse sides
	var tip_start = start_pos  # Acute vertex (sharp)
	var tip_end = end_pos      # Acute vertex (sharp)
	var side_top = center + perpendicular * (diamond_width / 2)    # Obtuse vertex
	var side_bottom = center - perpendicular * (diamond_width / 2) # Obtuse vertex
	
	# Create diamond polygon
	var diamond_points = PackedVector2Array([
		tip_start,    # Acute tip
		side_top,     # Obtuse side
		tip_end,      # Acute tip
		side_bottom   # Obtuse side
	])
	
	# NOVA ABORDAGEM: Desenhar emojis DIRETAMENTE no diamante
	# Primeiro desenhar o diamante com cor de fundo
	draw_colored_polygon(diamond_points, color)
	
	# Depois desenhar os emojis DIRETAMENTE por cima
	_draw_emoji_on_diamond(diamond_points, terrain_type, is_remembered)

# NOVA FUNÇÃO: Desenhar emojis diretamente no diamante
func _draw_emoji_on_diamond(diamond_points: PackedVector2Array, terrain_type: int, is_remembered: bool = false) -> void:
	# Debug: Log emoji drawing
	if debug_enabled and randf() < 0.02:
		print("[EMOJI] Drawing emoji for terrain type %d, is_remembered: %s" % [terrain_type, is_remembered])
	
	# Calcular centro do diamante
	var center = Vector2.ZERO
	for point in diamond_points:
		center += point
	center /= diamond_points.size()
	
	# Obter emoji e cor para o tipo de terreno
	var emoji_text = _get_terrain_emoji(terrain_type)
	var emoji_color = _get_terrain_emoji_color(terrain_type, is_remembered)
	
	# Debug: Log final color
	if debug_enabled and randf() < 0.02:
		print("[EMOJI] Final emoji color: %s" % emoji_color)
	
	# Desenhar múltiplos emojis espalhados no diamante
	var font = ThemeDB.fallback_font
	if font and emoji_text != "":
		# Desenhar emoji no centro (sem blur - removido conforme solicitado)
		draw_string(font, center + Vector2(-6, 3), emoji_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, emoji_color)
		
		# Desenhar emojis adicionais espalhados (sem blur)
		if terrain_type == 0:  # FIELD - semicolons espalhados
			draw_string(font, center + Vector2(-15, -8), "؛", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, emoji_color)
			draw_string(font, center + Vector2(10, -5), "؛", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, emoji_color)
			draw_string(font, center + Vector2(-8, 12), "؛", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, emoji_color)
			draw_string(font, center + Vector2(15, 8), "؛", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, emoji_color)
		elif terrain_type == 1:  # FOREST - árvores espalhadas
			draw_string(font, center + Vector2(-12, -6), "🌳", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, emoji_color)
			draw_string(font, center + Vector2(8, -3), "🌳", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, emoji_color)
			draw_string(font, center + Vector2(-5, 10), "🌳", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, emoji_color)
		elif terrain_type == 2:  # MOUNTAIN - montanhas espalhadas
			draw_string(font, center + Vector2(-10, -4), "⛰", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, emoji_color)
			draw_string(font, center + Vector2(12, -2), "⛰", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, emoji_color)
			draw_string(font, center + Vector2(-3, 8), "⛰", HORIZONTAL_ALIGNMENT_CENTER, -1, 7, emoji_color)
		elif terrain_type == 3:  # WATER - ondas espalhadas
			draw_string(font, center + Vector2(-14, -6), "〰", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, emoji_color)
			draw_string(font, center + Vector2(6, -2), "〰", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, emoji_color)
			draw_string(font, center + Vector2(-8, 8), "〰", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, emoji_color)
			draw_string(font, center + Vector2(12, 6), "〰", HORIZONTAL_ALIGNMENT_CENTER, -1, 7, emoji_color)

# Obter emoji para tipo de terreno
func _get_terrain_emoji(terrain_type: int) -> String:
	match terrain_type:
		0:  # FIELD
			return "؛"  # Semicolon invertido
		1:  # FOREST
			return "🌳"  # Árvore
		2:  # MOUNTAIN
			return "⛰"  # Montanha
		3:  # WATER
			return "〰"  # Onda
		_:
			return ""

# Obter cor do emoji para tipo de terreno (com suporte a terreno lembrado)
func _get_terrain_emoji_color(terrain_type: int, is_remembered: bool = false) -> Color:
	var base_color: Color
	
	match terrain_type:
		0:  # FIELD
			base_color = Color(0.2, 0.4, 0.2)  # Verde escuro para semicolons
		1:  # FOREST
			base_color = Color(0.1, 0.6, 0.1)  # Verde brilhante para árvores
		2:  # MOUNTAIN
			base_color = Color(0.3, 0.3, 0.4)  # Cinza escuro para montanhas
		3:  # WATER
			base_color = Color(0.1, 0.3, 0.6)  # Azul escuro para ondas
		_:
			base_color = Color.BLACK
	
	# Emojis mantêm cor original mesmo em terreno lembrado (removido empalidecimento)
	# if is_remembered: # Código removido conforme solicitado
	
	return base_color

# Função auxiliar para desenhar emoji com ou sem blur
func _draw_emoji_with_blur_check(font: Font, position: Vector2, emoji: String, size: int, color: Color, apply_blur: bool) -> void:
	if apply_blur:
		_draw_blurred_emoji(font, position, emoji, size, color)
	else:
		draw_string(font, position, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, color)

# Função para desenhar emoji com efeito de blur
func _draw_blurred_emoji(font: Font, position: Vector2, emoji: String, size: int, color: Color) -> void:
	# Criar efeito de blur mais intenso desenhando o emoji múltiplas vezes
	var blur_offsets = [
		# Camada 1: Blur próximo
		Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
		Vector2(-1, 0),                   Vector2(1, 0),
		Vector2(-1, 1),  Vector2(0, 1),  Vector2(1, 1),
		# Camada 2: Blur médio
		Vector2(-2, -2), Vector2(0, -2), Vector2(2, -2),
		Vector2(-2, 0),                   Vector2(2, 0),
		Vector2(-2, 2),  Vector2(0, 2),  Vector2(2, 2),
		# Camada 3: Blur distante
		Vector2(-3, -3), Vector2(0, -3), Vector2(3, -3),
		Vector2(-3, 0),                   Vector2(3, 0),
		Vector2(-3, 3),  Vector2(0, 3),  Vector2(3, 3)
	]
	
	# Desenhar camadas de blur com opacidade muito reduzida
	var blur_color = Color(color.r, color.g, color.b, color.a * 0.15)
	for offset in blur_offsets:
		draw_string(font, position + offset, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, blur_color)
	
	# Desenhar emoji principal com opacidade reduzida para efeito desfocado
	var main_color = Color(color.r, color.g, color.b, color.a * 0.5)
	draw_string(font, position, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, main_color)

# Get terrain texture by type
func _get_terrain_texture(terrain_type: int) -> Texture2D:
	if not textures_loaded:
		return null
	
	match terrain_type:
		0:  # FIELD
			return terrain_textures.get("FIELD")
		1:  # FOREST
			return terrain_textures.get("FOREST")
		2:  # MOUNTAIN
			return terrain_textures.get("MOUNTAIN")
		3:  # WATER
			return terrain_textures.get("WATER")
		_:
			return null

# Draw textured diamond using UV mapping
func _draw_textured_diamond(diamond_points: PackedVector2Array, texture: Texture2D, tint_color: Color) -> void:
	# Debug: Log texture drawing attempt
	if debug_enabled and randf() < 0.05:  # Log occasionally
		print("[TEXTURE] Drawing textured diamond with texture: %s" % texture)
	
	# Try simple approach first - just draw with texture
	try_simple_textured_draw(diamond_points, texture, tint_color)

func try_simple_textured_draw(diamond_points: PackedVector2Array, texture: Texture2D, tint_color: Color) -> void:
	# Simple UV mapping - map diamond to full texture
	var uv_points = PackedVector2Array([
		Vector2(0.5, 0.0),  # Top tip
		Vector2(1.0, 0.5),  # Right side
		Vector2(0.5, 1.0),  # Bottom tip
		Vector2(0.0, 0.5)   # Left side
	])
	
	# Check if texture is valid
	if texture == null:
		if debug_enabled:
			print("[TEXTURE] Texture is null, using solid color")
		draw_colored_polygon(diamond_points, tint_color)
		return
	
	# Try to draw textured polygon
	draw_colored_polygon(diamond_points, tint_color, uv_points, texture)
	if debug_enabled and randf() < 0.01:
		print("[TEXTURE] Drew textured polygon with %s" % texture.get_class())

# Draw hexagon with solid outline and 30° rotation
func _draw_hexagon_solid_outline(center: Vector2, radius: float, color: Color, width: float):
	var points = []
	# Add 30° rotation (PI/6 radians) to each angle
	var rotation_offset = PI / 6.0
	for i in range(6):
		var angle = i * PI / 3.0 + rotation_offset
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	# Draw solid lines between points
	for i in range(6):
		var start_point = points[i]
		var end_point = points[(i + 1) % 6]
		draw_line(start_point, end_point, color, width)

# Draw hexagon with striped outline (color + white) and 30° rotation
func _draw_hexagon_striped_outline(center: Vector2, radius: float, color: Color, width: float):
	var points = []
	# Add 30° rotation (PI/6 radians) to each angle
	var rotation_offset = PI / 6.0
	for i in range(6):
		var angle = i * PI / 3.0 + rotation_offset
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	# Draw striped lines between points
	for i in range(6):
		var start_point = points[i]
		var end_point = points[(i + 1) % 6]
		_draw_striped_line(start_point, end_point, color, Color.WHITE, width)

# Draw hexagon with dashed outline and 30° rotation (kept for compatibility)
func _draw_hexagon_dashed_outline(center: Vector2, radius: float, color: Color, width: float):
	var points = []
	# Add 30° rotation (PI/6 radians) to each angle
	var rotation_offset = PI / 6.0
	for i in range(6):
		var angle = i * PI / 3.0 + rotation_offset
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	# Draw dashed lines between points
	for i in range(6):
		var start_point = points[i]
		var end_point = points[(i + 1) % 6]
		_draw_dashed_line(start_point, end_point, color, width)

# Draw dashed line between two points
func _draw_dashed_line(start: Vector2, end: Vector2, color: Color, width: float):
	var direction = end - start
	var length = direction.length()
	var normalized_dir = direction.normalized()
	
	# Dash parameters
	var dash_length = 8.0
	var gap_length = 4.0
	var segment_length = dash_length + gap_length
	
	var current_pos = 0.0
	while current_pos < length:
		var dash_start = start + normalized_dir * current_pos
		var dash_end_pos = min(current_pos + dash_length, length)
		var dash_end = start + normalized_dir * dash_end_pos
		
		# Draw dash segment
		draw_line(dash_start, dash_end, color, width)
		
		current_pos += segment_length

# Draw striped line between two points (alternating two colors)
func _draw_striped_line(start: Vector2, end: Vector2, color1: Color, color2: Color, width: float):
	var direction = end - start
	var length = direction.length()
	var normalized_dir = direction.normalized()
	
	# Stripe parameters
	var stripe_length = 8.0
	
	var current_pos = 0.0
	var use_color1 = true
	while current_pos < length:
		var stripe_start = start + normalized_dir * current_pos
		var stripe_end_pos = min(current_pos + stripe_length, length)
		var stripe_end = start + normalized_dir * stripe_end_pos
		
		# Draw stripe segment with alternating color
		var stripe_color = color1 if use_color1 else color2
		draw_line(stripe_start, stripe_end, stripe_color, width)
		
		current_pos += stripe_length
		use_color1 = not use_color1  # Alternate colors


# Draw 6-pointed star (Star of David) rotated 30 degrees
func _draw_six_pointed_star(center: Vector2, radius: float, color: Color) -> void:
	# Create two overlapping triangles to form a 6-pointed star
	# Add 30 degree rotation (PI/6 radians)
	var rotation_offset = PI / 6.0
	
	# First triangle (pointing up, rotated 30°)
	var triangle1_points = PackedVector2Array()
	for i in range(3):
		var angle = i * (2 * PI / 3) - PI / 2 + rotation_offset
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		triangle1_points.append(point)
	
	# Second triangle (pointing down, rotated 30°)
	var triangle2_points = PackedVector2Array()
	for i in range(3):
		var angle = i * (2 * PI / 3) + PI / 2 + rotation_offset
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		triangle2_points.append(point)
	
	# Draw both triangles
	draw_colored_polygon(triangle1_points, color)
	draw_colored_polygon(triangle2_points, color)

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

# Render only grid edges
func _render_grid_edges(hover_state: Dictionary):
	if not ("grid" in game_state):
		return
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	var current_player_id = current_player.id if current_player else 1
	
	# Draw edges with restored colors and thickness (with fog of war and remembered terrain)
	for edge_id in game_state.grid.edges:
		var edge = game_state.grid.edges[edge_id]
		
		# Check if edge is currently visible or remembered
		var is_visible = true
		var is_remembered = false
		
		if game_state.get("fog_of_war_enabled", false):
			is_visible = ToggleFogUseCase._is_edge_visible_to_player(edge, current_player_id, game_state)
			if not is_visible:
				is_remembered = ToggleFogUseCase.is_remembered_by_player("edge", edge_id, current_player_id, game_state)
		
		if is_visible or is_remembered:
			var point_a = game_state.grid.points[edge.point_a_id]
			var point_b = game_state.grid.points[edge.point_b_id]
			
			# Get terrain color from restored palette (no paleness for remembered)
			var terrain_color = _get_restored_terrain_color(edge.get("terrain_type", 0), false)
			
			# Draw diamond-shaped path with emojis (pass remembered state)
			_draw_diamond_path(
				_apply_board_rotation(point_a.position.pixel_pos),
				_apply_board_rotation(point_b.position.pixel_pos),
				terrain_color,
				PATH_THICKNESS,
				edge.get("terrain_type", 0),
				is_remembered and not is_visible  # Pass remembered state
			)

# Render only grid points (stars) - called after domains to overlay them
func _render_grid_points(hover_state: Dictionary):
	if not ("grid" in game_state):
		return
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	var current_player_id = current_player.id if current_player else 1
	
	# Draw points (with fog of war and remembered terrain)
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		
		# Check if point is currently visible or remembered
		var is_visible = true
		var is_remembered = false
		var is_hidden = false
		
		if game_state.get("fog_of_war_enabled", false):
			is_visible = ToggleFogUseCase._is_position_visible_to_player(point.position, current_player_id, game_state)
			if not is_visible:
				is_remembered = ToggleFogUseCase.is_remembered_by_player("point", point_id, current_player_id, game_state)
				if not is_remembered:
					is_hidden = true
		
		# Draw star based on visibility state
		var star_color: Color
		var star_pos = _apply_board_rotation(point.position.pixel_pos)
		
		# Draw stars based on visibility with placeholder system
		if is_visible:
			# Visible: White star
			star_color = Color.WHITE
		elif is_remembered:
			# Remembered: Black star
			star_color = Color.BLACK
		elif is_hidden:
			# Hidden/Undiscovered: Black placeholder star
			star_color = Color.BLACK
		else:
			# Default: Black placeholder star
			star_color = Color.BLACK
		
		# Draw star (reduced size)
		_draw_six_pointed_star(star_pos, 12.0, star_color)

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
		
		# TEMPORARY: Structure system disabled
		# if "structures" in game_state:
		#	var StructureService = load("res://application/services/structure_service.gd")
		#	var player_structures = StructureService.get_player_structures(current_player.id, game_state)
		#	var structure_power = StructureService.calculate_structure_power_generation(current_player.id, game_state)
		#	
		#	var structures_text = "Structures: %d (+%d power)" % [player_structures.size(), structure_power]
		#	draw_string(font, Vector2(20, 120), structures_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	
	# Controls panel
	var controls_rect = Rect2(10, 680, 400, 80)
	draw_rect(controls_rect, Color(0, 0, 0, 0.7))
	
	var controls = [
		"🎮 CONTROLS: Click unit → Click position | SPACE: Fog | ENTER: Skip | F1: Debug",
		"🏆 OBJECTIVE: Eliminate all enemy units to win! | 🔍 F9: Test | 🔎 F10: Detail | 🔧 F11: Debug"
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
			var emoji_color = unit_color  # Use team color for emoji
			
			if not has_actions:
				# Unit has no actions - make emoji whitish
				emoji_color = unit_color.lerp(Color.WHITE, 0.7)  # Blend with white
			
			# Draw emoji (removed colored circle background)
			draw_string(font, pos + Vector2(-12, 0), "🚶🏻‍♀️", HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color.WHITE)
			
			# Unit name below the unit (bold and italic) - moved more up
			var unit_name_pos = pos + Vector2(0, 15)
			_draw_bold_italic_text(font, unit_name_pos, unit.name, 12, unit_color)
			
			# Selection indicator: team color glow behind emoji when selected
			if is_selected:
				_draw_team_color_glow(pos, unit_color)
				
			# Hover indicator (adjusted for doubled star size)
			if is_hovered:
				draw_arc(pos, 31.0, 0, TAU, 32, Color.WHITE, 2.0)
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

# Render movement targets with white glow around stars
func _render_movement_targets_with_terrain(font: Font) -> void:
	if not font or selected_unit_id == -1:
		return
	
	var unit = game_state.units[selected_unit_id]
	
	for target_pos in valid_movement_targets:
		var pos = target_pos.pixel_pos
		
		# Get terrain cost for this movement
		var terrain_cost = MovementService.get_terrain_movement_cost(unit, target_pos, game_state.grid)
		
		# Draw team color glow around the star at this position
		var rotated_pos = _apply_board_rotation(pos)
		var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
		var team_color = current_player.color if current_player else Color.WHITE
		_draw_team_color_glow_around_star(rotated_pos, terrain_cost, team_color)
		
		# Draw terrain cost indicator if needed
		if terrain_cost > 1 and terrain_cost < 999:
			draw_string(font, rotated_pos + Vector2(-4, 4), str(terrain_cost), HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.BLACK)
		elif terrain_cost >= 999:
			draw_string(font, rotated_pos + Vector2(-4, 4), "X", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.RED)

# Draw team color glow around star for movement targets
func _draw_team_color_glow_around_star(position: Vector2, terrain_cost: int, team_color: Color) -> void:
	# Create gradient glow effect with multiple circles (increased brightness)
	var glow_layers = [
		{"radius": 20.0, "alpha": 0.15},
		{"radius": 16.0, "alpha": 0.25},
		{"radius": 12.0, "alpha": 0.35},
		{"radius": 8.0, "alpha": 0.45}
	]
	
	# Use team color as base, adjust intensity based on terrain cost
	var glow_color: Color
	match terrain_cost:
		1:  # Normal movement - team color glow
			glow_color = team_color
		2:  # Difficult terrain - team color mixed with orange
			glow_color = team_color.lerp(Color.ORANGE, 0.3)
		999:  # Impassable - red glow
			glow_color = Color.RED
		_:
			glow_color = team_color
	
	# Draw gradient glow layers
	for layer in glow_layers:
		var layer_color = Color(glow_color.r, glow_color.g, glow_color.b, layer.alpha)
		draw_circle(position, layer.radius, layer_color)

# Draw white glow around star for movement targets (kept for compatibility)
func _draw_white_glow_around_star(position: Vector2, terrain_cost: int) -> void:
	_draw_team_color_glow_around_star(position, terrain_cost, Color.WHITE)

# Draw team color outline around selected unit (following emoji shape)
func _draw_team_color_outline(position: Vector2, team_color: Color) -> void:
	# Draw outline that follows the emoji shape more closely
	var outline_color = Color(team_color.r, team_color.g, team_color.b, 0.9)
	
	# Draw a rounded rectangle that better fits the emoji
	var emoji_width = 24.0
	var emoji_height = 32.0
	var outline_thickness = 3.0
	
	# Calculate outline rectangle
	var outline_rect = Rect2(
		position.x - emoji_width/2 - outline_thickness,
		position.y - emoji_height/2 - outline_thickness,
		emoji_width + outline_thickness * 2,
		emoji_height + outline_thickness * 2
	)
	
	# Draw rounded rectangle outline
	_draw_rounded_rect_outline(outline_rect, 8.0, outline_color, outline_thickness)

# Draw team color glow behind selected unit
func _draw_team_color_glow(position: Vector2, team_color: Color) -> void:
	# Draw multiple circles with decreasing opacity for glow effect
	var glow_layers = [
		{"radius": 25.0, "alpha": 0.1},
		{"radius": 20.0, "alpha": 0.15},
		{"radius": 15.0, "alpha": 0.2},
		{"radius": 10.0, "alpha": 0.25}
	]
	
	for layer in glow_layers:
		var glow_color = Color(team_color.r, team_color.g, team_color.b, layer.alpha)
		draw_circle(position, layer.radius, glow_color)

# Helper function to draw rounded rectangle outline
func _draw_rounded_rect_outline(rect: Rect2, corner_radius: float, color: Color, thickness: float) -> void:
	# Draw rounded rectangle by drawing multiple lines and arcs
	var top_left = rect.position
	var top_right = Vector2(rect.position.x + rect.size.x, rect.position.y)
	var bottom_left = Vector2(rect.position.x, rect.position.y + rect.size.y)
	var bottom_right = rect.position + rect.size
	
	# Draw the four sides (with corner radius offset)
	# Top side
	draw_line(Vector2(top_left.x + corner_radius, top_left.y), 
			 Vector2(top_right.x - corner_radius, top_right.y), color, thickness)
	# Right side
	draw_line(Vector2(top_right.x, top_right.y + corner_radius), 
			 Vector2(bottom_right.x, bottom_right.y - corner_radius), color, thickness)
	# Bottom side
	draw_line(Vector2(bottom_right.x - corner_radius, bottom_right.y), 
			 Vector2(bottom_left.x + corner_radius, bottom_left.y), color, thickness)
	# Left side
	draw_line(Vector2(bottom_left.x, bottom_left.y - corner_radius), 
			 Vector2(top_left.x, top_left.y + corner_radius), color, thickness)
	
	# Draw corner arcs
	draw_arc(top_left + Vector2(corner_radius, corner_radius), corner_radius, PI, PI * 1.5, 8, color, thickness)
	draw_arc(top_right + Vector2(-corner_radius, corner_radius), corner_radius, PI * 1.5, PI * 2, 8, color, thickness)
	draw_arc(bottom_right + Vector2(-corner_radius, -corner_radius), corner_radius, 0, PI * 0.5, 8, color, thickness)
	draw_arc(bottom_left + Vector2(corner_radius, -corner_radius), corner_radius, PI * 0.5, PI, 8, color, thickness)

# Build mode rendering functions removed during cleanup
# func _render_build_mode(font: Font) -> void:
#	if not font or not build_mode:
#		return

# func _get_structure_icon(structure_type: int) -> String:
#	match structure_type:
#		0:  # FARM
#			return "🌾"
#		1:  # VILLAGE
#			return "🏠"
#		2:  # FORTRESS
#			return "🏰"
#		3:  # MARKET
#			return "🏪"
#		4:  # TEMPLE
#			return "⛪"
#		_:
#			return "🏗️"

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