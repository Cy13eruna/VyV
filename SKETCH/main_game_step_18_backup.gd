extends Node2D

# Expanded hexagonal grid (37 points: radius 3)
var points = []
var hex_coords = []  # Axial coordinates (q, r) for each point
var hex_size = 40.0  # Hexagon size
var hex_center = Vector2(400, 300)  # Grid center

# Terrain types (edges) - temporarily back to local enum
enum EdgeType {
	FIELD,          # Green: field (move + see) - 6/12
	FOREST,         # Grayish green: forest (move but don't see) - 2/12
	MOUNTAIN,       # Grayish yellow: mountain (don't move or see) - 2/12
	WATER           # Grayish cyan: water (see but don't move) - 2/12
}

# Paths of the hexagonal grid (generated dynamically)
var paths = []

# Hover state
var hovered_point = -1
var hovered_edge = -1

# Units - will be defined after generating the grid
var unit1_position = 0  # Index of the point where unit 1 is
var unit2_position = 0  # Index of the point where unit 2 is
var unit1_label: Label
var unit2_label: Label
var unit1_actions = 1   # Action points of unit 1
var unit2_actions = 1   # Action points of unit 2
var current_player = 1  # Current player (1 or 2)
var fog_of_war = true   # Fog of war control

# Domains
var unit1_domain_center = 0  # Center of unit 1's domain
var unit2_domain_center = 0  # Center of unit 2's domain
var unit1_domain_name = ""   # Name of unit 1's domain
var unit2_domain_name = ""   # Name of unit 2's domain
var unit1_name = ""          # Name of unit 1
var unit2_name = ""          # Name of unit 2
# REMOVED: Labels for names - now drawn directly on screen as part of domain/unit rendering

# Forced revelation (for forest mechanics)
var unit1_force_revealed = false  # Unit 1 was forcefully revealed
var unit2_force_revealed = false  # Unit 2 was forcefully revealed

# Power System
var unit1_domain_power = 1  # Accumulated power of domain 1 (starts with 1)
var unit2_domain_power = 1  # Accumulated power of domain 2 (starts with 1)

# UI
var skip_turn_button: Button
var action_label: Label

# Performance Profiling (Step 17)
var performance_monitor = {
	"frame_times": [],
	"draw_time": 0.0,
	"process_time": 0.0,
	"input_time": 0.0,
	"frame_count": 0,
	"start_time": 0.0,
	"last_fps_update": 0.0,
	"current_fps": 0.0
}
var profiling_enabled = true
var fps_label: Label

# Caching System (Step 18)
var coordinate_cache = {
	"distances": {},
	"neighbors": {},
	"directions": {},
	"pixels": {},
	"initialized": false
}
var visibility_cache = {
	"player1_visible_points": [],
	"player2_visible_points": [],
	"player1_visible_paths": [],
	"player2_visible_paths": [],
	"cache_valid": false,
	"last_unit1_pos": -1,
	"last_unit2_pos": -1
}
var movement_cache = {
	"valid_moves": {},
	"path_types": {},
	"movement_costs": {},
	"cache_valid": true
}
var render_cache = {
	"last_render_state": {},
	"state_changed": true,
	"cached_colors": {},
	"cached_ui_data": {}
}

func _ready():
	# V&V Game initialization
	
	# Generate hexagonal grid using GridGenerationSystem or HexGridSystem
	if GridGenerationSystem:
		var grid_data = GridGenerationSystem.generate_hex_grid(3, hex_size, hex_center)
		points = grid_data.points
		hex_coords = grid_data.hex_coords
		paths = grid_data.paths
	elif HexGridSystem:
		var grid_data = HexGridSystem.generate_hex_grid(3, hex_size, hex_center)
		points = grid_data.points
		hex_coords = grid_data.hex_coords
		paths = grid_data.paths
	else:
		_generate_hex_grid()
	
	# Set initial unit positions
	if UnitSystem:
		_set_initial_unit_positions_with_system()
	else:
		_set_initial_unit_positions()
	
	# Generate random terrain automatically using TerrainSystem
	if TerrainSystem:
		TerrainSystem.generate_random_terrain(paths)
	else:
		_generate_random_terrain()
	
	# Initialize GameManager with game data
	if GameManager:
		GameManager.initialize_game(points, hex_coords, paths)
	
	# Initialize InputSystem
	if InputSystem:
		InputSystem.initialize(points, paths)
		# Connect InputSystem signals
		InputSystem.point_clicked.connect(_on_input_point_clicked)
		InputSystem.fog_toggle_requested.connect(_on_input_fog_toggle)
		# InputSystem ready
	
	# Initialize RenderSystem
	if RenderSystem:
		RenderSystem.initialize(points, hex_coords, paths)
		# RenderSystem ready
	
	# Initialize UISystem
	if UISystem:
		UISystem.initialize(self, points)
		UISystem.skip_turn_requested.connect(_on_ui_skip_turn)
		# UISystem ready
	
	# Initialize UnitSystem
	if UnitSystem:
		UnitSystem.initialize(points, hex_coords, paths)
		UnitSystem.unit_moved.connect(_on_unit_moved)
		UnitSystem.movement_blocked.connect(_on_movement_blocked)
		# UnitSystem ready
	
	# Initialize PowerSystem
	if PowerSystem:
		PowerSystem.initialize()
		PowerSystem.power_generated.connect(_on_power_generated)
		PowerSystem.power_consumed.connect(_on_power_consumed)
		PowerSystem.domain_occupied.connect(_on_domain_occupied)
		# PowerSystem ready
	
	# Initialize VisibilitySystem
	if VisibilitySystem:
		VisibilitySystem.initialize(points, hex_coords, paths)
		# VisibilitySystem ready
	
	# Initialize MovementSystem
	if MovementSystem:
		MovementSystem.initialize(points, hex_coords, paths)
		# MovementSystem ready
	
	# Initialize GridGenerationSystem
	if GridGenerationSystem:
		GridGenerationSystem.initialize()
		# GridGenerationSystem ready
	
	# Initialize FallbackSystem
	if FallbackSystem:
		FallbackSystem.initialize(points, hex_coords, paths)
		# FallbackSystem ready
	
	# Initialize DrawingSystem
	if DrawingSystem:
		DrawingSystem.initialize(points, hex_coords, paths)
		# DrawingSystem ready
	
	print("Hexagonal grid created: %d points, %d paths" % [points.size(), paths.size()])
	
	# Create UI elements using UISystem or fallback
	if UISystem:
		# REMOVED: Names are now drawn directly, not through UISystem
		# Create all UI elements
		UISystem.create_ui_elements()
		# Get references to UI elements (only unit labels and buttons)
		var ui_elements = UISystem.get_ui_elements()
		unit1_label = ui_elements.unit1_label
		unit2_label = ui_elements.unit2_label
		# REMOVED: name and domain labels - now drawn directly
		skip_turn_button = ui_elements.skip_turn_button
		action_label = ui_elements.action_label
	else:
		# Fallback to local UI creation
		_create_ui_fallback()
	
	# Mark map corners
	if GridGenerationSystem:
		GridGenerationSystem.mark_map_corners(paths, points.size(), hex_coords)
	else:
		_mark_map_corners()
	
	# Update UI positions and visibility
	if UISystem:
		_update_ui_system_state()
		UISystem.update_ui()
	else:
		_update_units_visibility_and_position()
		_create_ui()
	
	# Initialize caching systems
	_initialize_coordinate_cache()
	_initialize_movement_cache()
	
	# Initialize performance monitoring
	if profiling_enabled:
		_initialize_performance_monitoring()
	print("🔥 FIXED VERSION - Game ready! Current player: %d" % current_player)

func _process(_delta):
	# Performance profiling - start timing
	var process_start_time = Time.get_ticks_msec() if profiling_enabled else 0
	
	var mouse_pos = get_global_mouse_position()
	
	# Use InputSystem for hover detection
	if InputSystem:
		var hover_result = InputSystem.process_mouse_hover(mouse_pos)
		hovered_point = hover_result.hovered_point
		hovered_edge = hover_result.hovered_edge
		
		# Redraw if hover state changed
		if hover_result.point_changed or hover_result.edge_changed:
			queue_redraw()
	else:
		# Fallback to FallbackSystem or local hover detection
		if FallbackSystem:
			_update_fallback_system_state()
			var hover_result = FallbackSystem.process_hover_fallback(mouse_pos)
			hovered_point = hover_result.hovered_point
			hovered_edge = hover_result.hovered_edge
			if hover_result.point_changed or hover_result.edge_changed:
				queue_redraw()
		else:
			_process_hover_fallback(mouse_pos)
			queue_redraw()
	
	# Performance profiling - end timing
	if profiling_enabled:
		var process_end_time = Time.get_ticks_msec()
		performance_monitor.process_time = process_end_time - process_start_time
		_update_performance_stats()

func _draw():
	# Performance profiling - start draw timing
	var draw_start_time = Time.get_ticks_msec() if profiling_enabled else 0
	
	# Use RenderSystem if available
	if RenderSystem:
		# Update RenderSystem state
		var render_state = {
			"fog_of_war": fog_of_war,
			"current_player": current_player,
			"hovered_point": hovered_point,
			"hovered_edge": hovered_edge,
			"unit1_position": unit1_position,
			"unit2_position": unit2_position,
			"unit1_domain_center": unit1_domain_center,
			"unit2_domain_center": unit2_domain_center,
			"unit1_name": unit1_name,
			"unit2_name": unit2_name,
			"unit1_domain_name": unit1_domain_name,
			"unit2_domain_name": unit2_domain_name,
			"unit1_domain_power": unit1_domain_power,
			"unit2_domain_power": unit2_domain_power,
			"unit1_label": unit1_label,
			"unit2_label": unit2_label
		}
		RenderSystem.update_state(render_state)
		
		# Render using RenderSystem
		RenderSystem.render_game(self)
	else:
		# Fallback to FallbackSystem or local rendering
		if FallbackSystem:
			_update_fallback_system_state()
			FallbackSystem.render_fallback(self)
		else:
			_draw_fallback()
	
	# Update UI positions and visibility
	if UISystem:
		_update_ui_system_state()
		UISystem.update_ui()
	else:
		_update_units_visibility_and_position()

## Input handling for unit movement and terrain generation
func _unhandled_input(event: InputEvent) -> void:
	# Use InputSystem if available
	if InputSystem:
		var handled = InputSystem.handle_input_event(event)
		if handled:
			get_viewport().set_input_as_handled()
	else:
		# Fallback to FallbackSystem or local input handling
		if FallbackSystem:
			_update_fallback_system_state()
			var handled = FallbackSystem.handle_input_fallback(event)
			if handled:
				get_viewport().set_input_as_handled()
		else:
			_handle_input_fallback(event)

## InputSystem signal callbacks
func _on_input_point_clicked(point_index: int) -> void:
	# Processing point click
	
	# Use UnitSystem if available
	if UnitSystem:
		# Update UnitSystem, PowerSystem, VisibilitySystem and MovementSystem state
		_update_unit_system_state()
		_update_power_system_state()
		_update_visibility_system_state()
		_update_movement_system_state()
		
		# Attempt movement through UnitSystem
		var movement_result = UnitSystem.attempt_unit_movement(point_index)
		
		if movement_result.success:
			# Update local state from UnitSystem
			_sync_from_unit_system()
		else:
			print("⚠️ %s" % movement_result.message)
			# Still sync state in case actions/power were consumed
			_sync_from_unit_system()
		
		# Update UI
		if UISystem:
			_update_ui_system_state()
			UISystem.update_ui()
		else:
			_update_units_visibility_and_position()
			_update_action_display()
		queue_redraw()
	else:
		# Fallback to local movement logic
		_handle_movement_fallback(point_index)

func _on_input_fog_toggle() -> void:
	# Processing fog toggle
	
	# Toggle fog of war
	if GameManager:
		GameManager.toggle_fog_of_war()
		fog_of_war = GameManager.fog_of_war
	else:
		fog_of_war = not fog_of_war
		var fog_status = "ENABLED" if fog_of_war else "DISABLED"
		print("🌫️ Fog of War %s" % fog_status)
	queue_redraw()

## UISystem signal callback
func _on_ui_skip_turn() -> void:
	print("💻 UISystem: Skip Turn requested")
	_on_skip_turn_pressed()

## Update UISystem state
func _update_ui_system_state() -> void:
	if UISystem:
		var ui_state = {
			"current_player": current_player,
			"unit1_actions": unit1_actions,
			"unit2_actions": unit2_actions,
			"unit1_domain_power": unit1_domain_power,
			"unit2_domain_power": unit2_domain_power,
			"fog_of_war": fog_of_war,
			"unit1_position": unit1_position,
			"unit2_position": unit2_position,
			"unit1_domain_center": unit1_domain_center,
			"unit2_domain_center": unit2_domain_center,
			"unit1_force_revealed": unit1_force_revealed,
			"unit2_force_revealed": unit2_force_revealed
		}
		UISystem.update_game_state(ui_state)

## UnitSystem signal callbacks
func _on_unit_moved(unit_id: int, from_point: int, to_point: int) -> void:
	print("🚶‍♀️ UnitSystem: Unit %d moved from %d to %d" % [unit_id, from_point, to_point])

func _on_movement_blocked(unit_id: int, reason: String) -> void:
	print("⚠️ UnitSystem: Unit %d movement blocked - %s" % [unit_id, reason])

## PowerSystem signal callbacks
func _on_power_generated(player_id: int, domain_name: String, new_total: int) -> void:
	print("⚡ PowerSystem: Player %d (%s) generated power (Total: %d)" % [player_id, domain_name, new_total])
	# Update local state
	if player_id == 1:
		unit1_domain_power = new_total
	else:
		unit2_domain_power = new_total

func _on_power_consumed(player_id: int, domain_name: String, remaining: int) -> void:
	print("⚡ PowerSystem: Player %d (%s) consumed power (Remaining: %d)" % [player_id, domain_name, remaining])
	# Update local state
	if player_id == 1:
		unit1_domain_power = remaining
	else:
		unit2_domain_power = remaining

func _on_domain_occupied(player_id: int, domain_name: String, occupied_by: int) -> void:
	print("⚡ PowerSystem: Player %d (%s) domain occupied by Player %d" % [player_id, domain_name, occupied_by])

## Update UnitSystem state
func _update_unit_system_state() -> void:
	if UnitSystem:
		var unit_state = {
			"current_player": current_player,
			"fog_of_war": fog_of_war,
			"unit1_domain_power": unit1_domain_power,
			"unit2_domain_power": unit2_domain_power
		}
		UnitSystem.update_game_state(unit_state)

## Update PowerSystem state
func _update_power_system_state() -> void:
	if PowerSystem:
		var power_state = {
			"current_player": current_player,
			"unit1_position": unit1_position,
			"unit2_position": unit2_position
		}
		PowerSystem.update_game_state(power_state)

## Update VisibilitySystem state
func _update_visibility_system_state() -> void:
	if VisibilitySystem:
		var visibility_state = {
			"current_player": current_player,
			"fog_of_war": fog_of_war,
			"unit1_position": unit1_position,
			"unit2_position": unit2_position,
			"unit1_domain_center": unit1_domain_center,
			"unit2_domain_center": unit2_domain_center,
			"unit1_force_revealed": unit1_force_revealed,
			"unit2_force_revealed": unit2_force_revealed
		}
		VisibilitySystem.update_game_state(visibility_state)

## Update MovementSystem state
func _update_movement_system_state() -> void:
	if MovementSystem:
		var movement_state = {
			"current_player": current_player,
			"unit1_position": unit1_position,
			"unit2_position": unit2_position,
			"unit1_force_revealed": unit1_force_revealed,
			"unit2_force_revealed": unit2_force_revealed,
			"unit1_label": unit1_label,
			"unit2_label": unit2_label
		}
		MovementSystem.update_game_state(movement_state)

## Update FallbackSystem state
func _update_fallback_system_state() -> void:
	if FallbackSystem:
		var fallback_state = {
			"current_player": current_player,
			"fog_of_war": fog_of_war,
			"unit1_position": unit1_position,
			"unit2_position": unit2_position,
			"unit1_actions": unit1_actions,
			"unit2_actions": unit2_actions,
			"unit1_domain_power": unit1_domain_power,
			"unit2_domain_power": unit2_domain_power,
			"unit1_force_revealed": unit1_force_revealed,
			"unit2_force_revealed": unit2_force_revealed,
			"unit1_domain_center": unit1_domain_center,
			"unit2_domain_center": unit2_domain_center,
			"unit1_label": unit1_label,
			"unit2_label": unit2_label,
			"hovered_point": hovered_point,
			"hovered_edge": hovered_edge
		}
		FallbackSystem.update_game_state(fallback_state)

## Update DrawingSystem state
func _update_drawing_system_state() -> void:
	if DrawingSystem:
		var drawing_state = {
			"current_player": current_player,
			"fog_of_war": fog_of_war,
			"unit1_domain_center": unit1_domain_center,
			"unit2_domain_center": unit2_domain_center,
			"unit1_domain_name": unit1_domain_name,
			"unit2_domain_name": unit2_domain_name
		}
		DrawingSystem.update_game_state(drawing_state)

## Sync local state from UnitSystem
func _sync_from_unit_system() -> void:
	if UnitSystem:
		var unit_state = UnitSystem.get_unit_state()
		current_player = unit_state.current_player
		unit1_position = unit_state.unit1_position
		unit2_position = unit_state.unit2_position
		unit1_actions = unit_state.unit1_actions
		unit2_actions = unit_state.unit2_actions
		unit1_domain_power = unit_state.unit1_domain_power
		unit2_domain_power = unit_state.unit2_domain_power
		unit1_force_revealed = unit_state.unit1_force_revealed
		unit2_force_revealed = unit_state.unit2_force_revealed

## Set initial unit positions with UnitSystem - ORIGINAL WORKING VERSION
func _set_initial_unit_positions_with_system() -> void:
	# Get the 6 map corners using HexGridSystem
	var corners
	if GridGenerationSystem:
		corners = GridGenerationSystem.get_map_corners(paths, points.size())
	elif HexGridSystem:
		corners = HexGridSystem.get_map_corners(paths, points.size())
	else:
		corners = _get_map_corners()
	
	if UnitSystem:
		# Ensure UnitSystem has the grid data before positioning
		UnitSystem.initialize(points, hex_coords, paths)
		var result = UnitSystem.set_initial_positions(corners)
		if result.success:
			# Sync positions from UnitSystem
			unit1_position = result.unit1_position
			unit2_position = result.unit2_position
			unit1_domain_center = result.unit1_domain_center
			unit2_domain_center = result.unit2_domain_center
			
			# Generate names for domains and units
			_generate_domain_and_unit_names()
			
			# Setup UnitSystem with names
			UnitSystem.setup_units(unit1_position, unit2_position, unit1_name, unit2_name, unit1_domain_name, unit2_domain_name)
			
			# Setup PowerSystem with domain data
			if PowerSystem:
				PowerSystem.setup_domains(unit1_domain_center, unit2_domain_center, unit1_domain_name, unit2_domain_name)
			
			# Setup GameManager with unit data
			if GameManager:
				GameManager.setup_units(unit1_position, unit2_position, unit1_name, unit2_name, unit1_domain_name, unit2_domain_name)
			
			print("Units positioned at official spawn:")
			print("Unit1 (Red) '%s' at point %d: %s (Domain: %s)" % [unit1_name, unit1_position, hex_coords[unit1_position], unit1_domain_name])
			print("Unit2 (Violet) '%s' at point %d: %s (Domain: %s)" % [unit2_name, unit2_position, hex_coords[unit2_position], unit2_domain_name])
			print("Domains created at spawn points")
		else:
			print("Error: Could not set initial positions")
			# Fallback to local method
			_set_initial_unit_positions()

## Fallback functions for when systems are not available
func _process_hover_fallback(mouse_pos: Vector2) -> void:
	# Check hover on points (including non-rendered ones)
	hovered_point = -1
	for i in range(points.size()):
		if mouse_pos.distance_to(points[i]) < 20:
			hovered_point = i
			break
	
	# Check hover on paths (including non-rendered ones)
	hovered_edge = -1
	if hovered_point == -1:
		for i in range(paths.size()):
			var path = paths[i]
			var path_points = path.points
			var p1 = points[path_points[0]]
			var p2 = points[path_points[1]]
			if (DrawingSystem.point_near_line(mouse_pos, p1, p2, 10) if DrawingSystem else _point_near_line(mouse_pos, p1, p2, 10)):
				hovered_edge = i
				break

func _handle_input_fallback(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		# Check click on points
		for i in range(points.size()):
			if mouse_pos.distance_to(points[i]) < 20:
				_on_input_point_clicked(i)
				get_viewport().set_input_as_handled()
				return
	
	elif event is InputEventKey and event.pressed:
			if event.keycode == KEY_SPACE:
				_on_input_fog_toggle()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_P:
				# Toggle performance monitoring
				toggle_performance_monitoring()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_R:
				# Print performance report
				if profiling_enabled:
					var report = _get_performance_report()
					print("📊 PERFORMANCE REPORT:")
					print("  FPS: %.1f" % report.fps)
					print("  Draw Time: %.1fms" % report.draw_time_ms)
					print("  Process Time: %.1fms" % report.process_time_ms)
					print("  Total Frame Time: %.1fms" % report.total_frame_time_ms)
					print("  Target Frame Time: %.1fms" % report.target_frame_time_ms)
					print("  Performance Ratio: %.2f" % report.performance_ratio)
				get_viewport().set_input_as_handled()

## Fallback movement handling
func _handle_movement_fallback(point_index: int) -> void:
	# If clicked on point that current unit can move to, check actions
	if (MovementSystem.can_current_unit_move_to_point(point_index) if MovementSystem else _can_current_unit_move_to_point(point_index)):
		var current_actions = unit1_actions if current_player == 1 else unit2_actions
		if current_actions > 0:
			# Check if domain has enough power
			var has_power = false
			if PowerSystem:
				_update_power_system_state()
				has_power = PowerSystem.has_domain_power_for_action()
			else:
				has_power = _has_domain_power_for_action()
			
			if not has_power:
				print("⚡ No power! Domain doesn't have power to perform action.")
				return
			
			# Check if there's a hidden unit at destination
			var movement_result
			if MovementSystem:
				_update_movement_system_state()
				movement_result = MovementSystem.attempt_movement(point_index)
				# Sync forced revelations back
				var movement_state = MovementSystem.get_movement_state()
				unit1_force_revealed = movement_state.unit1_force_revealed
				unit2_force_revealed = movement_state.unit2_force_revealed
			else:
				movement_result = _attempt_movement(point_index)
			
			if movement_result.success:
				var old_pos = unit1_position if current_player == 1 else unit2_position
				print("🚶🏻‍♀️ Unit %d moving from point %d to point %d (Actions: %d → %d)" % [current_player, old_pos, point_index, current_actions, current_actions - 1])
				
				# Consume domain power
				if PowerSystem:
					PowerSystem.consume_domain_power()
				else:
					_consume_domain_power()
				
				if current_player == 1:
					unit1_position = point_index
					unit1_actions -= 1
				else:
					unit2_position = point_index
					unit2_actions -= 1
			else:
				# Movement failed due to hidden unit
				print("⚠️ Movement blocked! %s" % movement_result.message)
				# Consume power and lose action anyway
				if PowerSystem:
					PowerSystem.consume_domain_power()
				else:
					_consume_domain_power()
				if current_player == 1:
					unit1_actions -= 1
				else:
					unit2_actions -= 1
			
			if UISystem:
				_update_ui_system_state()
				UISystem.update_ui()
			else:
				_update_units_visibility_and_position()
				_update_action_display()
			queue_redraw()
		else:
			print("❌ No actions remaining! Use 'Skip Turn' to restore.")
	else:
		print("❌ Unit %d cannot move to point %d" % [current_player, point_index])

func _handle_skip_turn_fallback() -> void:
	# Switch player FIRST
	current_player = 3 - current_player  # 1 -> 2, 2 -> 1
	print("🔥 FIXED: Switched to Player %d" % current_player)
	
	# Restore actions for new player
	if current_player == 1:
		unit1_actions = 1
	else:
		unit2_actions = 1
	
	# Reset forced revelations if units are no longer visible
	# Reset forced revelations if units are no longer visible
	if VisibilitySystem:
		_update_visibility_system_state()
		var changes = VisibilitySystem.check_and_reset_forced_revelations()
		if changes.unit1_changed:
			unit1_force_revealed = false
		if changes.unit2_changed:
			unit2_force_revealed = false
	else:
		_check_and_reset_forced_revelations()
	
	# NOW generate power for the NEW current player
	if PowerSystem:
		_update_power_system_state()
		PowerSystem.generate_power_for_current_player()
	else:
		_generate_power_for_current_player_only()

## Fallback rendering function
func _draw_fallback() -> void:
	# Expanded white background
	draw_rect(Rect2(-200, -200, 1200, 1000), Color.WHITE)
	
	# Draw paths (with or without fog of war)
	for i in range(paths.size()):
		var path = paths[i]
		# Render based on fog of war
		var should_render = false
		if fog_of_war:
			# With fog: adjacent to current player, hover OR within current player's domain
			should_render = (MovementSystem.is_path_adjacent_to_current_unit(path) if MovementSystem else _is_path_adjacent_to_current_unit(path)) or hovered_edge == i or (VisibilitySystem.is_path_in_current_player_domain(path) if VisibilitySystem else _is_path_in_current_player_domain(path))
		else:
			# Without fog: all paths
			should_render = true
		
		if should_render:
			var path_points = path.points
			var p1 = points[path_points[0]]
			var p2 = points[path_points[1]]
			var color
			if DrawingSystem:
				color = DrawingSystem.get_path_color(path.type)
			elif TerrainSystem:
				color = TerrainSystem.get_path_color(path.type)
			else:
				color = _get_path_color(path.type)
			if hovered_edge == i:
				color = Color.MAGENTA
			draw_line(p1, p2, color, 8)  # Even thicker paths
	
	# Draw points (with or without fog of war)
	for i in range(points.size()):
		var current_unit_pos = unit1_position if current_player == 1 else unit2_position
		var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
		
		var should_render = false
		
		if fog_of_war:
			# With fog: render based on visibility
			# Always render current player's unit
			if i == current_unit_pos:
				should_render = true
			# Render enemy unit only if it's on a visible point
			# Render enemy unit only if it's on a visible point
			elif i == enemy_unit_pos and (VisibilitySystem.is_point_visible_to_current_unit(i) if VisibilitySystem else _is_point_visible_to_current_unit(i)):
				should_render = true
			# Render points visible to current player
			elif (VisibilitySystem.is_point_visible_to_current_unit(i) if VisibilitySystem else _is_point_visible_to_current_unit(i)):
				should_render = true
			# Render points on hover
			elif hovered_point == i:
				should_render = true
			# Render points within current player's domain
			# Render points within current player's domain
			elif (VisibilitySystem.is_point_in_current_player_domain(i) if VisibilitySystem else _is_point_in_current_player_domain(i)):
				should_render = true
		else:
			# Without fog: render all points
			should_render = true
		
		if should_render:
			var color = Color.BLACK
			
			# Magenta if hovering
			if hovered_point == i:
				color = Color.MAGENTA
			# Magenta if current unit can move there
			elif (MovementSystem.can_current_unit_move_to_point(i) if MovementSystem else _can_current_unit_move_to_point(i)):
				color = Color.MAGENTA
			
			draw_circle(points[i], 8, color)
	
	# Draw domains
	if DrawingSystem:
		_update_drawing_system_state()
		DrawingSystem.draw_domains(self)
	else:
		_draw_domains()
	
	# Draw unit names directly as part of rendering
	_draw_unit_names()

## Fallback UI creation
func _create_ui_fallback() -> void:
	# Create labels for the units
	unit1_label = Label.new()
	unit1_label.text = "🚶🏻‍♀️"  # Walking person emoji
	unit1_label.add_theme_font_size_override("font_size", 24)
	unit1_label.modulate = Color(1.0, 0.0, 0.0)  # Red using modulate
	add_child(unit1_label)
	
	unit2_label = Label.new()
	unit2_label.text = "🚶🏻‍♀️"  # Walking person emoji
	unit2_label.add_theme_font_size_override("font_size", 24)
	unit2_label.modulate = Color(0.5, 0.0, 0.8)  # Violet using modulate
	add_child(unit2_label)
	
	# Create name labels
	# REMOVED: Name labels - now drawn directly as part of rendering
	
	# Create UI
	_create_ui()

func _point_near_line(point, line_start, line_end, tolerance):
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len = line_vec.length()
	
	if line_len == 0:
		return point.distance_to(line_start) <= tolerance
	
	var t = point_vec.dot(line_vec) / (line_len * line_len)
	t = clamp(t, 0.0, 1.0)
	
	var closest_point = line_start + t * line_vec
	return point.distance_to(closest_point) <= tolerance

## Get path color based on type (more saturated colors)
func _get_path_color(path_type: EdgeType) -> Color:
	match path_type:
		EdgeType.FIELD:
			return Color.GREEN          # Green: field
		EdgeType.FOREST:
			return Color(0.2, 0.7, 0.2) # More saturated green: forest
		EdgeType.MOUNTAIN:
			return Color(0.7, 0.7, 0.2) # More saturated yellow: mountain
		EdgeType.WATER:
			return Color(0.2, 0.7, 0.7) # More saturated cyan: water
		_:
			return Color.BLACK

## Check if path is adjacent to current player
func _is_path_adjacent_to_current_unit(path: Dictionary) -> bool:
	# Path is adjacent if one of the points has the current player's unit
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	var path_points = path.points
	return path_points[0] == current_unit_pos or path_points[1] == current_unit_pos

## Check if point is visible to current player
func _is_point_visible_to_current_unit(point_index: int) -> bool:
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	return _is_point_visible_to_unit(point_index, current_unit_pos)

## Check if point is visible to a specific unit
func _is_point_visible_to_unit(point_index: int, unit_pos: int) -> bool:
	# Check if there's a path that allows visibility
	for path in paths:
		var path_points = path.points
		if (path_points[0] == unit_pos and path_points[1] == point_index) or \
		   (path_points[1] == unit_pos and path_points[0] == point_index):
			# Field and Water allow seeing
			var field_type = GameConstants.EdgeType.FIELD if GameConstants else EdgeType.FIELD
			var water_type = GameConstants.EdgeType.WATER if GameConstants else EdgeType.WATER
			if path.type == field_type or path.type == water_type:
				return true
	return false

## Attempt movement and check for hidden units
func _attempt_movement(target_point: int) -> Dictionary:
	# Check if there's an enemy unit at the destination point
	var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	
	# If enemy unit is at destination point
	if enemy_unit_pos == target_point:
		# Check if movement is through forest
		var path_type = (MovementSystem.get_path_type_between_points(current_unit_pos, target_point) if MovementSystem else _get_path_type_between_points(current_unit_pos, target_point))
		
		# Check if enemy unit was hidden (not visible)
		var enemy_was_visible = false
		if current_player == 1:
			enemy_was_visible = unit2_label.visible
		else:
			enemy_was_visible = unit1_label.visible
		
		var forest_type = GameConstants.EdgeType.FOREST if GameConstants else EdgeType.FOREST
		if path_type == forest_type and not enemy_was_visible:
			# Reveal enemy unit in forest
			print("🔍 Enemy unit revealed in forest!")
			# Mark enemy unit as forcefully revealed
			if current_player == 1:
				unit2_force_revealed = true
			else:
				unit1_force_revealed = true
			return {"success": false, "message": "Enemy unit discovered in forest! Movement cancelled."}
		else:
			# Movement blocked by visible unit or non-forest terrain
			return {"success": false, "message": "Point occupied by enemy unit."}
	
	# Successful movement
	return {"success": true, "message": ""}

## Get path type between two points
func _get_path_type_between_points(point1: int, point2: int) -> EdgeType:
	for path in paths:
		var path_points = path.points
		if (path_points[0] == point1 and path_points[1] == point2) or \
		   (path_points[1] == point1 and path_points[0] == point2):
			return path.type
	
	# If no path found, return MOUNTAIN (blocked)
	var mountain_type = GameConstants.EdgeType.MOUNTAIN if GameConstants else EdgeType.MOUNTAIN
	return mountain_type

## Check if domain has power for action
func _has_domain_power_for_action() -> bool:
	# Check if domain center is occupied by enemy
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
	
	# If domain center is occupied by enemy, actions are free
	if enemy_unit_pos == domain_center:
		print("⚡ Domain occupied! Free actions for original units.")
		return true
	
	# Otherwise, check if has power
	var current_power = unit1_domain_power if current_player == 1 else unit2_domain_power
	return current_power > 0

## Consume domain power
func _consume_domain_power() -> void:
	# Check if domain center is occupied by enemy
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
	
	# If center is occupied, don't consume power
	if enemy_unit_pos == domain_center:
		return
	
	# Consume 1 power
	if current_player == 1:
		unit1_domain_power = max(0, unit1_domain_power - 1)
		print("⚡ Domain 1 consumed 1 power (Remaining: %d)" % unit1_domain_power)
	else:
		unit2_domain_power = max(0, unit2_domain_power - 1)
		print("⚡ Domain 2 consumed 1 power (Remaining: %d)" % unit2_domain_power)

## ULTRA SIMPLE POWER GENERATION - ONLY FOR CURRENT PLAYER
func _generate_power_for_current_player_only() -> void:
	print("🔥 FIXED: Player %d is starting their turn" % current_player)
	
	# ONLY generate power for the current player's domain
	if current_player == 1:
		# ONLY Player 1's domain generates power
		if unit2_position != unit1_domain_center:
			unit1_domain_power += 1
			print("🔥 FIXED: ONLY Domain 1 (%s) generated power (Total: %d)" % [unit1_domain_name, unit1_domain_power])
		else:
			print("🔥 FIXED: Domain 1 (%s) occupied - no power generated" % unit1_domain_name)
	elif current_player == 2:
		# ONLY Player 2's domain generates power
		if unit1_position != unit2_domain_center:
			unit2_domain_power += 1
			print("🔥 FIXED: ONLY Domain 2 (%s) generated power (Total: %d)" % [unit2_domain_name, unit2_domain_power])
		else:
			print("🔥 FIXED: Domain 2 (%s) occupied - no power generated" % unit2_domain_name)
	
	print("🔥 FIXED: Power status - Domain 1: %d, Domain 2: %d" % [unit1_domain_power, unit2_domain_power])

## Check if point is within current player's domain
func _is_point_in_current_player_domain(point_index: int) -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	return _is_point_in_specific_domain(point_index, domain_center)

## Check if path is within current player's domain
func _is_path_in_current_player_domain(path: Dictionary) -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var point1 = path.points[0]
	var point2 = path.points[1]
	
	# Path is in domain if both points are in current player's domain
	return _is_point_in_specific_domain(point1, domain_center) and _is_point_in_specific_domain(point2, domain_center)

## Check if point is within a specific domain
func _is_point_in_specific_domain(point_index: int, domain_center: int) -> bool:
	# Point is in domain if it's the center or one of the 6 neighbors
	if point_index == domain_center:
		return true
	
	# Check if it's one of the 6 points around the center
	var domain_coord = hex_coords[domain_center]
	var point_coord = hex_coords[point_index]
	
	for dir in range(6):
		var neighbor_coord = domain_coord + _hex_direction(dir)
		if point_coord.is_equal_approx(neighbor_coord):
			return true
	
	return false

## Check if current unit can move to point
func _can_current_unit_move_to_point(point_index: int) -> bool:
	var unit_pos = unit1_position if current_player == 1 else unit2_position
	return _can_unit_move_to_point(point_index, unit_pos)

## Check if a specific unit can move to point
func _can_unit_move_to_point(point_index: int, unit_pos: int) -> bool:
	# Cannot move to itself
	if point_index == unit_pos:
		return false
	
	# Check if there's a path that allows movement
	for path in paths:
		var path_points = path.points
		if (path_points[0] == unit_pos and path_points[1] == point_index) or \
		   (path_points[1] == unit_pos and path_points[0] == point_index):
			# Field and Forest allow movement
			var field_type = GameConstants.EdgeType.FIELD if GameConstants else EdgeType.FIELD
			var forest_type = GameConstants.EdgeType.FOREST if GameConstants else EdgeType.FOREST
			if path.type == field_type or path.type == forest_type:
				return true
	return false

## Generate random terrain with proportions
func _generate_random_terrain() -> void:
	print("🌍 Generating random terrain...")
	
	# Create pool of types based on proportions
	var terrain_pool = []
	# Field: 6/12 (50%)
	for i in range(6):
		terrain_pool.append(EdgeType.FIELD)
	# Forest: 2/12 (16.7%)
	for i in range(2):
		terrain_pool.append(EdgeType.FOREST)
	# Water: 2/12 (16.7%)
	for i in range(2):
		terrain_pool.append(EdgeType.WATER)
	# Mountain: 2/12 (16.7%)
	for i in range(2):
		terrain_pool.append(EdgeType.MOUNTAIN)
	
	# Shuffle and apply to paths
	terrain_pool.shuffle()
	for i in range(paths.size()):
		var pool_index = i % terrain_pool.size()
		paths[i].type = terrain_pool[pool_index]
	
	print("✨ Random terrain generated! Field: 50%, Forest/Water/Mountain: 16.7% each")

## Generate hexagonal grid
func _generate_hex_grid() -> void:
	points.clear()
	hex_coords.clear()
	paths.clear()
	
	# Generate points in axial coordinates
	var point_id = 0
	for radius in range(4):  # Radius 0 to 3
		if radius == 0:
			# Center
			hex_coords.append(Vector2(0, 0))
			points.append(_hex_to_pixel(0, 0))
			point_id += 1
		else:
			# Points around center
			for i in range(6):  # 6 directions
				for j in range(radius):  # Points along each direction
					var q = _hex_direction(i).x * (radius - j) + _hex_direction((i + 1) % 6).x * j
					var r = _hex_direction(i).y * (radius - j) + _hex_direction((i + 1) % 6).y * j
					hex_coords.append(Vector2(q, r))
					points.append(_hex_to_pixel(q, r))
					point_id += 1
	
	# Generate paths connecting neighbors
	_generate_hex_paths()

## Convert axial coordinates to pixel (rotated 60°)
func _hex_to_pixel(q: float, r: float) -> Vector2:
	# Original coordinates
	var x = hex_size * (3.0/2.0 * q)
	var y = hex_size * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r)
	
	# Apply 60° rotation (pi/3 radians)
	var angle = PI / 3.0  # 60 degrees
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	
	var rotated_x = x * cos_angle - y * sin_angle
	var rotated_y = x * sin_angle + y * cos_angle
	
	return hex_center + Vector2(rotated_x, rotated_y)

## Get hexagonal direction
func _hex_direction(direction: int) -> Vector2:
	var directions = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	return directions[direction]

## Generate hexagonal paths
func _generate_hex_paths() -> void:
	var path_set = {}  # To avoid duplicates
	
	for i in range(hex_coords.size()):
		var coord = hex_coords[i]
		# Check 6 neighbors
		for dir in range(6):
			var neighbor_coord = coord + _hex_direction(dir)
			var neighbor_index = (GridGenerationSystem.find_hex_coord_index(neighbor_coord, hex_coords) if GridGenerationSystem else _find_hex_coord_index(neighbor_coord))
			
			if neighbor_index != -1:
				# Create unique ID for path (always smaller index first)
				var path_id = "%d_%d" % [min(i, neighbor_index), max(i, neighbor_index)]
				
				if not path_set.has(path_id):
					var field_type = GameConstants.EdgeType.FIELD if GameConstants else EdgeType.FIELD
					paths.append({"points": [i, neighbor_index], "type": field_type})
					path_set[path_id] = true

## Find hexagonal coordinate index
func _find_hex_coord_index(coord: Vector2) -> int:
	for i in range(hex_coords.size()):
		if hex_coords[i].is_equal_approx(coord):
			return i
	return -1

## Set initial unit positions (official spawn) - ORIGINAL WORKING VERSION
func _set_initial_unit_positions() -> void:
	# Get the 6 map corners using HexGridSystem
	var corners
	if GridGenerationSystem:
		corners = GridGenerationSystem.get_map_corners(paths, points.size())
	elif HexGridSystem:
		corners = HexGridSystem.get_map_corners(paths, points.size())
	else:
		corners = _get_map_corners()
	
	if corners.size() >= 2:
		# Shuffle and choose 2 random corners
		corners.shuffle()
		var corner1 = corners[0]
		var corner2 = corners[1]
		
		# Find adjacent point with 6 edges
		unit1_position = _find_adjacent_six_edge_point(corner1)
		unit2_position = _find_adjacent_six_edge_point(corner2)
		
		# Set domain centers
		unit1_domain_center = unit1_position
		unit2_domain_center = unit2_position
		
		# Generate names for domains and units
		_generate_domain_and_unit_names()
		
		# Setup GameManager with unit data
		if GameManager:
			GameManager.setup_units(unit1_position, unit2_position, unit1_name, unit2_name, unit1_domain_name, unit2_domain_name)
		
		print("Units positioned at official spawn:")
		print("Unit1 (Red) '%s' at point %d: %s (Domain: %s)" % [unit1_name, unit1_position, hex_coords[unit1_position], unit1_domain_name])
		print("Unit2 (Violet) '%s' at point %d: %s (Domain: %s)" % [unit2_name, unit2_position, hex_coords[unit2_position], unit2_domain_name])
		print("Domains created at spawn points")
	else:
		print("Error: Could not find enough corners")

## Fallback positioning method
func _set_initial_unit_positions_fallback() -> void:
	print("⚠️ Using fallback positioning method...")
	
	# Get the 6 map corners using HexGridSystem
	var corners
	if GridGenerationSystem:
		corners = GridGenerationSystem.get_map_corners(paths, points.size())
	elif HexGridSystem:
		corners = HexGridSystem.get_map_corners(paths, points.size())
	else:
		corners = _get_map_corners()
	
	if corners.size() >= 2:
		# Shuffle and choose 2 random corners
		corners.shuffle()
		var corner1 = corners[0]
		var corner2 = corners[1]
		
		# Find adjacent point with 6 edges
		unit1_position = _find_adjacent_six_edge_point(corner1)
		unit2_position = _find_adjacent_six_edge_point(corner2)
		
		# Set domain centers
		unit1_domain_center = unit1_position
		unit2_domain_center = unit2_position
		
		# Generate names for domains and units
		_generate_domain_and_unit_names()
		
		# Setup GameManager with unit data
		if GameManager:
				GameManager.setup_units(unit1_position, unit2_position, unit1_name, unit2_name, unit1_domain_name, unit2_domain_name)
		
		print("Fallback positioning complete")
	else:
		print("Error: Could not find enough corners even in fallback")

## Generate names for domains and units
func _generate_domain_and_unit_names() -> void:
	# Domain names with unique initials
	var domain_names = ["Aldara", "Belthor", "Caldris", "Drakemoor", "Eldoria", "Frostheim"]
	var unit_names = [
		["Aldric", "Alara", "Arden", "Astrid"],
		["Bjorn", "Brenna", "Baldur", "Bianca"],
		["Castor", "Celia", "Cyrus", "Clara"],
		["Darius", "Diana", "Drake", "Delara"],
		["Elias", "Elena", "Erik", "Evelyn"],
		["Felix", "Freya", "Finn", "Fiona"]
	]
	
	# Shuffle and choose 2 different domains
	domain_names.shuffle()
	unit1_domain_name = domain_names[0]
	unit2_domain_name = domain_names[1]
	
	# Choose unit names based on domain initial
	var domain1_index = _get_domain_index(unit1_domain_name)
	var domain2_index = _get_domain_index(unit2_domain_name)
	
	unit_names[domain1_index].shuffle()
	unit_names[domain2_index].shuffle()
	
	unit1_name = unit_names[domain1_index][0]
	unit2_name = unit_names[domain2_index][0]
	
	# Names generated successfully
	
	# REMOVED: Name labels creation - now drawn directly

## Get domain index based on initial
func _get_domain_index(domain_name: String) -> int:
	var first_letter = domain_name.substr(0, 1)
	match first_letter:
		"A": return 0
		"B": return 1
		"C": return 2
		"D": return 3
		"E": return 4
		"F": return 5
		_: return 0

# REMOVED: _create_name_labels() - Names now drawn directly as part of rendering

## Find best adjacent point for domain - FIXED VERSION
func _find_adjacent_six_edge_point(corner_index: int) -> int:
	print("🏰 FIXED: Finding best domain position for corner %d at %s" % [corner_index, hex_coords[corner_index]])
	var corner_coord = hex_coords[corner_index]
	
	# First, count paths for the corner itself
	var corner_path_count = 0
	for path in paths:
		var path_points = path.points
		if path_points[0] == corner_index or path_points[1] == corner_index:
			corner_path_count += 1
	print("🏰 FIXED: Corner %d has %d paths" % [corner_index, corner_path_count])
	
	# Look for best neighbor (prioritize more connections)
	var best_neighbor = -1
	var best_connections = 0
	
	# Check all 6 hexagonal neighbors of the corner
	for dir in range(6):
		var neighbor_coord = corner_coord + (GridGenerationSystem.hex_direction(dir) if GridGenerationSystem else _hex_direction(dir))
		var neighbor_index = (GridGenerationSystem.find_hex_coord_index(neighbor_coord, hex_coords) if GridGenerationSystem else _find_hex_coord_index(neighbor_coord))
		
		if neighbor_index != -1:
			# Count paths from this neighbor
			var path_count = 0
			for path in paths:
				var path_points = path.points
				if path_points[0] == neighbor_index or path_points[1] == neighbor_index:
					path_count += 1
			
			print("🏰 FIXED: Neighbor %d at %s has %d paths" % [neighbor_index, neighbor_coord, path_count])
			
			# Accept neighbors with 4, 5, or 6 connections (not corners with 3)
			if path_count >= 4 and path_count > best_connections:
				best_neighbor = neighbor_index
				best_connections = path_count
				print("🏰 FIXED: New best neighbor %d with %d connections" % [neighbor_index, path_count])
	
	# If found a good neighbor, use it
	if best_neighbor != -1:
		print("✅ FIXED: Using neighbor %d with %d connections for corner %d" % [best_neighbor, best_connections, corner_index])
		return best_neighbor
	
	# If no good neighbor found, look for points at distance 2 (raio 1 points with 6 connections)
	print("🔍 FIXED: No good neighbor found, searching raio 1 points...")
	for i in range(points.size()):
		var point_coord = hex_coords[i]
		var distance = (GridGenerationSystem.hex_distance(corner_coord, point_coord) if GridGenerationSystem else _hex_distance(corner_coord, point_coord))
		
		# Look for points at distance 2 (raio 1)
		if distance == 2:
			# Count connections
			var path_count = 0
			for path in paths:
				var path_points = path.points
				if path_points[0] == i or path_points[1] == i:
					path_count += 1
			
			# Raio 1 points should have 6 connections
			if path_count == 6:
				print("✅ FIXED: Found raio 1 point %d with 6 connections at distance 2" % i)
				return i
	
	# Ultimate fallback: return the corner itself (should never happen now)
	print("❌ FIXED: No suitable point found, using corner %d as fallback" % corner_index)
	return corner_index

## Calculate hexagonal distance between two coordinates
func _hex_distance(coord1: Vector2, coord2: Vector2) -> int:
	# Axial coordinate distance formula
	return int((abs(coord1.x - coord2.x) + abs(coord1.x + coord1.y - coord2.x - coord2.y) + abs(coord1.y - coord2.y)) / 2)

## Analyze grid connectivity for debugging
func _analyze_grid_connectivity() -> void:
	# Analyzing grid connectivity
	
	# Count points by connectivity
	var connectivity_count = {}
	var point_connectivity = []
	
	for i in range(points.size()):
		var path_count = 0
		for path in paths:
			var path_points = path.points
			if path_points[0] == i or path_points[1] == i:
				path_count += 1
		
		point_connectivity.append({"index": i, "connections": path_count, "coord": hex_coords[i]})
		
		if not connectivity_count.has(path_count):
			connectivity_count[path_count] = 0
		connectivity_count[path_count] += 1
	
	# Connectivity analysis complete

## Find best domain positions - INTELLIGENT APPROACH
func _find_best_domain_positions() -> Array:
	# Finding optimal domain positions
	
	# Get all corners first
	var corners = _get_map_corners()
	print("🔴 Found %d corners: %s" % [corners.size(), corners])
	
	# Analyze all points and their suitability for domains
	var candidates = []
	
	for i in range(points.size()):
		# Count connections
		var connections = 0
		for path in paths:
			var path_points = path.points
			if path_points[0] == i or path_points[1] == i:
				connections += 1
		
		# Skip corners (3 connections)
		if connections == 3:
			continue
		
		# Only consider points with 4+ connections
		if connections >= 4:
			# Calculate minimum distance to any corner
			var min_corner_distance = 999
			for corner in corners:
				var distance = (GridGenerationSystem.hex_distance(hex_coords[i], hex_coords[corner]) if GridGenerationSystem else _hex_distance(hex_coords[i], hex_coords[corner]))
				min_corner_distance = min(min_corner_distance, distance)
			
			candidates.append({
				"index": i,
				"connections": connections,
				"coord": hex_coords[i],
				"corner_distance": min_corner_distance,
				"score": connections * 10 + (4 - min_corner_distance)  # Prefer more connections and closer to corners
			})
	
	# Sort candidates by score (higher is better)
	candidates.sort_custom(func(a, b): return a.score > b.score)
	
	print("🏆 Top domain candidates:")
	for i in range(min(10, candidates.size())):
		var candidate = candidates[i]
		print("  %d. Point %d: %d connections, distance %d from corners, score %d at %s" % [
			i + 1, candidate.index, candidate.connections, candidate.corner_distance, candidate.score, candidate.coord
		])
	
	# Select two best positions that are far enough apart
	var selected_positions = []
	
	for candidate in candidates:
		var too_close = false
		
		# Check if too close to already selected positions
		for selected in selected_positions:
			var distance = (GridGenerationSystem.hex_distance(candidate.coord, hex_coords[selected]) if GridGenerationSystem else _hex_distance(candidate.coord, hex_coords[selected]))
			if distance < 3:  # Minimum distance of 3 hexes
				too_close = true
				break
		
		if not too_close:
			selected_positions.append(candidate.index)
			print("🏰 Selected domain position: Point %d (%d connections) at %s" % [
				candidate.index, candidate.connections, candidate.coord
			])
			
			if selected_positions.size() >= 2:
				break
	
	# Fallback if we couldn't find 2 good positions
	if selected_positions.size() < 2:
		print("⚠️ Warning: Only found %d good positions, using fallback..." % selected_positions.size())
		for candidate in candidates:
			if not selected_positions.has(candidate.index):
				selected_positions.append(candidate.index)
				if selected_positions.size() >= 2:
					break
	
	print("🏁 Final domain positions: %s" % selected_positions)
	return selected_positions

## Draw hexagonal domains
func _draw_domains() -> void:
	# Draw unit 1's domain (red)
	if unit1_domain_center >= 0 and unit1_domain_center < points.size():
		_draw_domain_hexagon(unit1_domain_center, Color(1.0, 0.0, 0.0))
	
	# Draw unit 2's domain (violet)
	if unit2_domain_center >= 0 and unit2_domain_center < points.size():
		_draw_domain_hexagon(unit2_domain_center, Color(0.5, 0.0, 0.8))

## Draw domain hexagon
func _draw_domain_hexagon(center_index: int, color: Color) -> void:
	# Debug print removed for production
	# Check if domain should be visible (fog of war)
	var domain_visible = true
	if fog_of_war:
		domain_visible = (VisibilitySystem.is_domain_visible(center_index) if VisibilitySystem else _is_domain_visible(center_index))
	# Domain visibility check
	if fog_of_war and not domain_visible:
		return
	
	var center_pos = points[center_index]
	# Calculate radius based on real distance between adjacent points
	var radius
	if DrawingSystem:
		radius = DrawingSystem.get_edge_length(center_index)
	elif GridGenerationSystem:
		radius = GridGenerationSystem.get_edge_length(center_index, points, hex_coords)
	else:
		radius = _get_edge_length(center_index)
	
	# Calculate the 6 vertices of the hexagon
	var vertices = []
	for i in range(6):
		var angle = (i * PI / 3.0) + (PI / 6.0)  # Start with point up
		var x = center_pos.x + radius * cos(angle)
		var y = center_pos.y + radius * sin(angle)
		vertices.append(Vector2(x, y))
	
	# Draw the 6 edges of the hexagon
	for i in range(6):
		var start = vertices[i]
		var end = vertices[(i + 1) % 6]
		draw_line(start, end, color, 4)  # Thicker line
	
	# Draw domain name and power directly as part of domain rendering
	_draw_domain_text(center_index, center_pos, color)

## Draw domain text directly on screen (FRONT END)
func _draw_domain_text(center_index: int, center_pos: Vector2, color: Color) -> void:
	# Domain text rendering
	# Get current power values
	var current_unit1_power = unit1_domain_power
	var current_unit2_power = unit2_domain_power
	if PowerSystem and PowerSystem.has_method("get_player_power"):
		current_unit1_power = PowerSystem.get_player_power(1)
		current_unit2_power = PowerSystem.get_player_power(2)
		# Update local variables to stay in sync
		unit1_domain_power = current_unit1_power
		unit2_domain_power = current_unit2_power
	
	# Determine which domain this is and draw its name/power directly
	if center_index == unit1_domain_center:
		# Domain 1 - draw name and power directly on screen
		var text = "%s ⚡%d" % [unit1_domain_name, current_unit1_power]
		var text_pos = center_pos + Vector2(-30, 35)  # Below domain
		# Draw text background for readability
		draw_rect(Rect2(text_pos - Vector2(5, 15), Vector2(text.length() * 8, 20)), Color.WHITE)
		# Draw the actual text using Godot's built-in font
		var font = ThemeDB.fallback_font
		var font_size = 12
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.RED)
		print("🎨 FRONT END: Drawing Domain1 text '%s' at %s" % [text, text_pos])
	
	elif center_index == unit2_domain_center:
		# Domain 2 - draw name and power directly on screen
		var text = "%s ⚡%d" % [unit2_domain_name, current_unit2_power]
		var text_pos = center_pos + Vector2(-30, 35)  # Below domain
		# Draw text background for readability
		draw_rect(Rect2(text_pos - Vector2(5, 15), Vector2(text.length() * 8, 20)), Color.WHITE)
		# Draw the actual text using Godot's built-in font
		var font = ThemeDB.fallback_font
		var font_size = 12
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.5, 0.0, 0.8))
		print("🎨 FRONT END: Drawing Domain2 text '%s' at %s" % [text, text_pos])

## Get real length of an edge
func _get_edge_length(point_index: int) -> float:
	# Find an adjacent point and calculate distance
	var point_coord = hex_coords[point_index]
	for dir in range(6):
		var neighbor_coord = point_coord + _hex_direction(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1:
			# Calculate distance between points
			var distance = points[point_index].distance_to(points[neighbor_index])
			return distance
	
	# Fallback to hex_size if no neighbor found
	return hex_size

## Check if domain is visible to current player (ENHANCED)
func _is_domain_visible(domain_center: int) -> bool:
	print("🔧 FIXED: Checking domain visibility for center=%d, current_player=%d" % [domain_center, current_player])
	
	# Domain always visible if it belongs to current player
	if (current_player == 1 and domain_center == unit1_domain_center) or \
	   (current_player == 2 and domain_center == unit2_domain_center):
		print("🔧 FIXED: Domain belongs to current player - VISIBLE")
		return true
	
	# Enemy domain visible if center or any adjacent point is visible
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	print("🔧 FIXED: Checking enemy domain visibility from unit pos=%d" % current_unit_pos)
	
	# Check if domain center is visible
	if _is_point_visible_to_unit(domain_center, current_unit_pos):
		print("🔧 FIXED: Domain center is visible - VISIBLE")
		return true
	
	# Check if any point adjacent to domain center is visible
	var domain_coord = hex_coords[domain_center]
	for dir in range(6):
		var neighbor_coord = domain_coord + _hex_direction(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1 and _is_point_visible_to_unit(neighbor_index, current_unit_pos):
			print("🔧 FIXED: Adjacent point %d is visible - VISIBLE" % neighbor_index)
			return true
	
	# ENHANCED: Check if current unit is within 2 hexes of domain center
	var distance = _hex_distance(hex_coords[current_unit_pos], hex_coords[domain_center])
	if distance <= 2:
		print("🔧 FIXED: Domain within 2 hexes (distance=%d) - VISIBLE" % distance)
		return true
	
	print("🔧 FIXED: Domain not visible - HIDDEN")
	return false

## Detect the six map corners (points with only 3 edges) - WITH DEBUG
func _get_map_corners() -> Array[int]:
	var corners: Array[int] = []
	print("🔍 DEBUG: Detecting corners from %d points..." % points.size())
	
	# Count paths connected to each point
	for i in range(points.size()):
		var path_count = 0
		
		# Count how many paths connect to this point
		for path in paths:
			var path_points = path.points
			if path_points[0] == i or path_points[1] == i:
				path_count += 1
		
		# Debug: print all points with their path counts
		if path_count <= 4:  # Only show points with low connectivity
			print("🔍 DEBUG: Point %d at %s has %d paths" % [i, hex_coords[i], path_count])
		
		# Hexagon corners have only 3 paths
		if path_count == 3:
			corners.append(i)
			print("🔴 DEBUG: Found corner %d at %s" % [i, hex_coords[i]])
	
	print("🔍 DEBUG: Total corners found: %d" % corners.size())
	return corners

## Mark map corners (paint magenta)
func _mark_map_corners() -> void:
	var corners = _get_map_corners()
	
	print("🔍 Corners detected: %d points with 3 paths" % corners.size())
	for corner_index in corners:
		print("  Corner %d: coordinate %s" % [corner_index, hex_coords[corner_index]])

## Create user interface
func _create_ui() -> void:
	# Skip Turn button
	skip_turn_button = Button.new()
	skip_turn_button.text = "Skip Turn"
	skip_turn_button.size = Vector2(100, 40)
	skip_turn_button.position = Vector2(680, 20)  # Top right corner
	skip_turn_button.pressed.connect(_on_skip_turn_pressed)
	add_child(skip_turn_button)
	
	# Action label
	action_label = Label.new()
	action_label.text = "Player 1 (Red)\nActions: 1"
	action_label.position = Vector2(580, 70)
	action_label.add_theme_font_size_override("font_size", 14)
	add_child(action_label)

## Skip Turn button callback - ULTRA SIMPLE VERSION
func _on_skip_turn_pressed() -> void:
	print("🔥 FIXED: Player %d clicked Skip Turn" % current_player)
	
	# Use UnitSystem if available
	if UnitSystem:
		# Update UnitSystem and PowerSystem state
		_update_unit_system_state()
		_update_power_system_state()
		
		# Switch player through UnitSystem
		UnitSystem.switch_player()
		
		# Generate power for new current player through PowerSystem
		if PowerSystem:
			PowerSystem.generate_power_for_current_player()
		else:
			# Fallback to UnitSystem
			UnitSystem.generate_power_for_current_player()
		
		# Sync local state from UnitSystem
		_sync_from_unit_system()
	else:
		# Fallback to FallbackSystem or local logic
		if FallbackSystem:
			_update_fallback_system_state()
			var result = FallbackSystem.handle_skip_turn_fallback()
			# Sync state back
			current_player = result.new_player
			unit1_actions = result.unit1_actions
			unit2_actions = result.unit2_actions
			unit1_domain_power = result.unit1_domain_power
			unit2_domain_power = result.unit2_domain_power
			unit1_force_revealed = result.unit1_force_revealed
			unit2_force_revealed = result.unit2_force_revealed
		else:
			_handle_skip_turn_fallback()
	
	if UISystem:
		_update_ui_system_state()
		UISystem.update_ui()
	else:
		_update_action_display()
	queue_redraw()

## Update action display
func _update_action_display() -> void:
	if action_label:
		var player_name = "Player 1 (Red)" if current_player == 1 else "Player 2 (Violet)"
		var actions = unit1_actions if current_player == 1 else unit2_actions
		action_label.text = "%s\nActions: %d" % [player_name, actions]

## Update position and visibility of units
func _update_units_visibility_and_position():
	if unit1_label:
		var unit1_pos = points[unit1_position]
		unit1_label.position = unit1_pos + Vector2(-12, -35)  # Center emoji above point
		
		# Unit 1 always visible to player 1, visible to player 2 only if on visible point
		if not fog_of_war:
			# Without fog: always visible
			unit1_label.visible = true
		elif current_player == 1:
			unit1_label.visible = true
		elif unit1_force_revealed:
			# Unit 1 was forcefully revealed (forest mechanics)
			unit1_label.visible = true
		else:
			unit1_label.visible = (VisibilitySystem.is_point_visible_to_current_unit(unit1_position) if VisibilitySystem else _is_point_visible_to_current_unit(unit1_position))
	
	if unit2_label:
		var unit2_pos = points[unit2_position]
		unit2_label.position = unit2_pos + Vector2(-12, -35)  # Center emoji above point
		
		# Unit 2 always visible to player 2, visible to player 1 only if on visible point
		if not fog_of_war:
			# Without fog: always visible
			unit2_label.visible = true
		elif current_player == 2:
			unit2_label.visible = true
		elif unit2_force_revealed:
			# Unit 2 was forcefully revealed (forest mechanics)
			unit2_label.visible = true
		else:
			unit2_label.visible = (VisibilitySystem.is_point_visible_to_current_unit(unit2_position) if VisibilitySystem else _is_point_visible_to_current_unit(unit2_position))
	
	# REMOVED: Name positioning - now drawn directly as part of rendering

## Draw unit names directly on screen (FRONT END)
func _draw_unit_names() -> void:
	# Draw unit names based on visibility
	# Draw unit 1 name ONLY if unit is visible
	if unit1_label and unit1_label.visible:
		var unit1_pos = points[unit1_position]
		var text_pos = unit1_pos + Vector2(-15, 15)  # Below unit
		# Draw text background for readability
		draw_rect(Rect2(text_pos - Vector2(5, 5), Vector2(unit1_name.length() * 6, 15)), Color.WHITE)
		# Draw the actual text using Godot's built-in font
		var font = ThemeDB.fallback_font
		var font_size = 10
		draw_string(font, text_pos, unit1_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.RED)
		print("🎨 FRONT END: Drawing Unit1 name '%s' at %s" % [unit1_name, text_pos])
	
	# Draw unit 2 name ONLY if unit is visible
	if unit2_label and unit2_label.visible:
		var unit2_pos = points[unit2_position]
		var text_pos = unit2_pos + Vector2(-15, 15)  # Below unit
		# Draw text background for readability
		draw_rect(Rect2(text_pos - Vector2(5, 5), Vector2(unit2_name.length() * 6, 15)), Color.WHITE)
		# Draw the actual text using Godot's built-in font
		var font = ThemeDB.fallback_font
		var font_size = 10
		draw_string(font, text_pos, unit2_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.5, 0.0, 0.8))
		print("🎨 FRONT END: Drawing Unit2 name '%s' at %s" % [unit2_name, text_pos])

# REMOVED: _update_name_positions() - Names now drawn directly as part of rendering

## Check and reset forced revelations
func _check_and_reset_forced_revelations() -> void:
	# Reset unit1_force_revealed if it's not naturally visible
	if unit1_force_revealed and current_player == 2:
		if not _is_point_visible_to_current_unit(unit1_position):
			unit1_force_revealed = false
			print("🔍 Unit 1 is no longer visible - resetting forced revelation")
	
	# Reset unit2_force_revealed if it's not naturally visible
		if not _is_point_visible_to_current_unit(unit2_position):
			unit2_force_revealed = false
			print("🔍 Unit 2 is no longer visible - resetting forced revelation")

## Performance Monitoring Functions (Step 17)
func _initialize_performance_monitoring() -> void:
	performance_monitor.start_time = Time.get_ticks_msec()
	performance_monitor.last_fps_update = performance_monitor.start_time
	
	# Create FPS display label
	fps_label = Label.new()
	fps_label.text = "FPS: --"
	fps_label.position = Vector2(10, 10)
	fps_label.add_theme_font_size_override("font_size", 12)
	fps_label.add_theme_color_override("font_color", Color.GREEN)
	add_child(fps_label)

func _update_performance_stats() -> void:
	var current_time = Time.get_ticks_msec()
	
	# Update FPS every 500ms
	if current_time - performance_monitor.last_fps_update > 500:
		var time_diff = current_time - performance_monitor.last_fps_update
		var frame_diff = performance_monitor.frame_count
		
		if frame_diff > 0:
			performance_monitor.current_fps = (frame_diff * 1000.0) / time_diff
			
			# Update FPS display
			if fps_label:
				fps_label.text = "FPS: %.1f | Draw: %.1fms | Process: %.1fms" % [
					performance_monitor.current_fps,
					performance_monitor.draw_time,
					performance_monitor.process_time
				]
				
				# Color code based on performance
				if performance_monitor.current_fps >= 55:
					fps_label.add_theme_color_override("font_color", Color.GREEN)
				elif performance_monitor.current_fps >= 30:
					fps_label.add_theme_color_override("font_color", Color.YELLOW)
				else:
					fps_label.add_theme_color_override("font_color", Color.RED)
		
		# Reset counters
		performance_monitor.last_fps_update = current_time
		performance_monitor.frame_count = 0

func _get_performance_report() -> Dictionary:
	return {
		"fps": performance_monitor.current_fps,
		"draw_time_ms": performance_monitor.draw_time,
		"process_time_ms": performance_monitor.process_time,
		"total_frame_time_ms": performance_monitor.draw_time + performance_monitor.process_time,
		"target_frame_time_ms": 16.67,  # 60 FPS target
		"performance_ratio": (performance_monitor.draw_time + performance_monitor.process_time) / 16.67
	}

func toggle_performance_monitoring() -> void:
	profiling_enabled = not profiling_enabled
	if fps_label:
		fps_label.visible = profiling_enabled

## Caching System Functions (Step 18)

# Initialize coordinate cache with pre-calculated values
func _initialize_coordinate_cache() -> void:
	if coordinate_cache.initialized:
		return
	
	print("⚡ Initializing coordinate cache...")
	var start_time = Time.get_ticks_msec()
	
	# Pre-calculate distances between all points
	for i in range(points.size()):
		for j in range(points.size()):
			var key = "%d_%d" % [i, j]
			coordinate_cache.distances[key] = _hex_distance(hex_coords[i], hex_coords[j])
	
	# Pre-calculate neighbors for each point
	for i in range(points.size()):
		coordinate_cache.neighbors[i] = _calculate_neighbors(i)
	
	# Pre-calculate pixel positions (already done, but cache the mapping)
	for i in range(points.size()):
		coordinate_cache.pixels[i] = points[i]
	
	coordinate_cache.initialized = true
	var end_time = Time.get_ticks_msec()
	print("⚡ Coordinate cache initialized in %dms" % (end_time - start_time))

# Get cached distance between two points
func _get_cached_distance(point1: int, point2: int) -> int:
	var key = "%d_%d" % [point1, point2]
	if coordinate_cache.distances.has(key):
		return coordinate_cache.distances[key]
	# Fallback to calculation if not cached
	return _hex_distance(hex_coords[point1], hex_coords[point2])

# Calculate neighbors for a point
func _calculate_neighbors(point_index: int) -> Array:
	var neighbors = []
	for path in paths:
		var path_points = path.points
		if path_points[0] == point_index:
			neighbors.append(path_points[1])
		elif path_points[1] == point_index:
			neighbors.append(path_points[0])
	return neighbors

# Get cached neighbors for a point
func _get_cached_neighbors(point_index: int) -> Array:
	if coordinate_cache.neighbors.has(point_index):
		return coordinate_cache.neighbors[point_index]
	# Fallback to calculation if not cached
	return _calculate_neighbors(point_index)

# Initialize movement cache
func _initialize_movement_cache() -> void:
	print("⚡ Initializing movement cache...")
	var start_time = Time.get_ticks_msec()
	
	# Pre-calculate path types between connected points
	for path in paths:
		var p1 = path.points[0]
		var p2 = path.points[1]
		var key = "%d_%d" % [min(p1, p2), max(p1, p2)]
		movement_cache.path_types[key] = path.type
	
	var end_time = Time.get_ticks_msec()
	print("⚡ Movement cache initialized in %dms" % (end_time - start_time))

# Get cached path type between two points
func _get_cached_path_type(point1: int, point2: int) -> EdgeType:
	var key = "%d_%d" % [min(point1, point2), max(point1, point2)]
	if movement_cache.path_types.has(key):
		return movement_cache.path_types[key]
	# Fallback to original function
	return _get_path_type_between_points(point1, point2)

# Get cached valid moves for a unit position
func _get_cached_valid_moves(unit_pos: int) -> Array:
	if not movement_cache.valid_moves.has(unit_pos):
		movement_cache.valid_moves[unit_pos] = _calculate_valid_moves_for_position(unit_pos)
	return movement_cache.valid_moves[unit_pos]

# Calculate valid moves for a position
func _calculate_valid_moves_for_position(unit_pos: int) -> Array:
	var valid_moves = []
	var neighbors = _get_cached_neighbors(unit_pos)
	
	for neighbor in neighbors:
		var path_type = _get_cached_path_type(unit_pos, neighbor)
		# Field and Forest allow movement
		var field_type = GameConstants.EdgeType.FIELD if GameConstants else EdgeType.FIELD
		var forest_type = GameConstants.EdgeType.FOREST if GameConstants else EdgeType.FOREST
		if path_type == field_type or path_type == forest_type:
			valid_moves.append(neighbor)
	
	return valid_moves

# Invalidate movement cache when needed
func _invalidate_movement_cache() -> void:
	movement_cache.valid_moves.clear()
	movement_cache.cache_valid = false

# Update visibility cache when units move
func _update_visibility_cache() -> void:
	# Check if cache needs updating
	if unit1_position == visibility_cache.last_unit1_pos and \
	   unit2_position == visibility_cache.last_unit2_pos and \
	   visibility_cache.cache_valid:
		return  # Cache is still valid
	
	print("⚡ Updating visibility cache...")
	var start_time = Time.get_ticks_msec()
	
	# Recalculate visibility for both players
	_recalculate_visibility_for_player(1)
	_recalculate_visibility_for_player(2)
	
	# Update cache state
	visibility_cache.last_unit1_pos = unit1_position
	visibility_cache.last_unit2_pos = unit2_position
	visibility_cache.cache_valid = true
	
	var end_time = Time.get_ticks_msec()
	print("⚡ Visibility cache updated in %dms" % (end_time - start_time))

# Recalculate visibility for a specific player
func _recalculate_visibility_for_player(player_id: int) -> void:
	var unit_pos = unit1_position if player_id == 1 else unit2_position
	var visible_points = []
	var visible_paths = []
	
	# Calculate visible points
	for i in range(points.size()):
		if _is_point_visible_to_unit(i, unit_pos):
			visible_points.append(i)
	
	# Calculate visible paths
	for i in range(paths.size()):
		var path = paths[i]
		if _is_path_visible_to_unit(path, unit_pos):
			visible_paths.append(i)
	
	# Store in cache
	if player_id == 1:
		visibility_cache.player1_visible_points = visible_points
		visibility_cache.player1_visible_paths = visible_paths
	else:
		visibility_cache.player2_visible_points = visible_points
		visibility_cache.player2_visible_paths = visible_paths

# Check if path is visible to unit
func _is_path_visible_to_unit(path: Dictionary, unit_pos: int) -> bool:
	var p1 = path.points[0]
	var p2 = path.points[1]
	return _is_point_visible_to_unit(p1, unit_pos) or _is_point_visible_to_unit(p2, unit_pos)

# Get cached visible points for current player
func _get_cached_visible_points() -> Array:
	_update_visibility_cache()
	if current_player == 1:
		return visibility_cache.player1_visible_points
	else:
		return visibility_cache.player2_visible_points

# Get cached visible paths for current player
func _get_cached_visible_paths() -> Array:
	_update_visibility_cache()
	if current_player == 1:
		return visibility_cache.player1_visible_paths
	else:
		return visibility_cache.player2_visible_paths

# Invalidate visibility cache when needed
func _invalidate_visibility_cache() -> void:
	visibility_cache.cache_valid = false