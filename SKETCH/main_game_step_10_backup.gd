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
var unit1_domain_label: Label # Label for domain 1 name
var unit2_domain_label: Label # Label for domain 2 name
var unit1_name_label: Label   # Label for unit 1 name
var unit2_name_label: Label   # Label for unit 2 name

# Forced revelation (for forest mechanics)
var unit1_force_revealed = false  # Unit 1 was forcefully revealed
var unit2_force_revealed = false  # Unit 2 was forcefully revealed

# Power System
var unit1_domain_power = 1  # Accumulated power of domain 1 (starts with 1)
var unit2_domain_power = 1  # Accumulated power of domain 2 (starts with 1)

# UI
var skip_turn_button: Button
var action_label: Label

func _ready():
	print("🔥 STEP 9 - PowerSystem integration...")
	print("⚡ Testing power with 9 systems: GameConstants, TerrainSystem, HexGridSystem, GameManager, InputSystem, RenderSystem, UISystem, UnitSystem, PowerSystem")
	print("🔥 Player 1 (RED) starts with 1 power")
	print("🔥 Player 2 (VIOLET) starts with 1 power")
	
	# Generate hexagonal grid using HexGridSystem
	if HexGridSystem:
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
		print("🎮 InputSystem connected and ready")
	
	# Initialize RenderSystem
	if RenderSystem:
		RenderSystem.initialize(points, hex_coords, paths)
		print("🎨 RenderSystem initialized and ready")
	
	# Initialize UISystem
	if UISystem:
		UISystem.initialize(self, points)
		UISystem.skip_turn_requested.connect(_on_ui_skip_turn)
		print("💻 UISystem initialized and ready")
	
	# Initialize UnitSystem
	if UnitSystem:
		UnitSystem.initialize(points, hex_coords, paths)
		UnitSystem.unit_moved.connect(_on_unit_moved)
		UnitSystem.movement_blocked.connect(_on_movement_blocked)
		print("🚶‍♀️ UnitSystem initialized and ready")
	
	# Initialize PowerSystem
	if PowerSystem:
		PowerSystem.initialize()
		PowerSystem.power_generated.connect(_on_power_generated)
		PowerSystem.power_consumed.connect(_on_power_consumed)
		PowerSystem.domain_occupied.connect(_on_domain_occupied)
		print("⚡ PowerSystem initialized and ready")
	
	print("Hexagonal grid created: %d points, %d paths" % [points.size(), paths.size()])
	
	# Create UI elements using UISystem or fallback
	if UISystem:
		# Set names first
		UISystem.set_names(unit1_name, unit2_name, unit1_domain_name, unit2_domain_name)
		# Create all UI elements
		UISystem.create_ui_elements()
		# Get references to UI elements
		var ui_elements = UISystem.get_ui_elements()
		unit1_label = ui_elements.unit1_label
		unit2_label = ui_elements.unit2_label
		unit1_name_label = ui_elements.unit1_name_label
		unit2_name_label = ui_elements.unit2_name_label
		unit1_domain_label = ui_elements.unit1_domain_label
		unit2_domain_label = ui_elements.unit2_domain_label
		skip_turn_button = ui_elements.skip_turn_button
		action_label = ui_elements.action_label
	else:
		# Fallback to local UI creation
		_create_ui_fallback()
	
	# Mark map corners
	_mark_map_corners()
	
	# Update UI positions and visibility
	if UISystem:
		_update_ui_system_state()
		UISystem.update_ui()
	else:
		_update_units_visibility_and_position()
		_create_ui()
	
	print("🔥 FIXED VERSION - Game ready! Current player: %d" % current_player)

func _process(_delta):
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
		# Fallback to local hover detection
		_process_hover_fallback(mouse_pos)
		queue_redraw()

func _draw():
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
			"unit2_domain_center": unit2_domain_center
		}
		RenderSystem.update_state(render_state)
		
		# Render using RenderSystem
		RenderSystem.render_game(self)
	else:
		# Fallback to local rendering
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
		# Fallback to local input handling
		_handle_input_fallback(event)

## InputSystem signal callbacks
func _on_input_point_clicked(point_index: int) -> void:
	print("🎮 InputSystem: Processing point %d click" % point_index)
	
	# Use UnitSystem if available
	if UnitSystem:
		# Update UnitSystem and PowerSystem state
		_update_unit_system_state()
		_update_power_system_state()
		
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
	print("🎮 InputSystem: Processing fog toggle")
	
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
	var corners = HexGridSystem.get_map_corners(paths, points.size()) if HexGridSystem else _get_map_corners()
	
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
			if _point_near_line(mouse_pos, p1, p2, 10):
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

## Fallback movement handling
func _handle_movement_fallback(point_index: int) -> void:
	# If clicked on point that current unit can move to, check actions
	if _can_current_unit_move_to_point(point_index):
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
			var movement_result = _attempt_movement(point_index)
			
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
			should_render = _is_path_adjacent_to_current_unit(path) or hovered_edge == i or _is_path_in_current_player_domain(path)
		else:
			# Without fog: all paths
			should_render = true
		
		if should_render:
			var path_points = path.points
			var p1 = points[path_points[0]]
			var p2 = points[path_points[1]]
			var color = TerrainSystem.get_path_color(path.type) if TerrainSystem else _get_path_color(path.type)
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
			elif i == enemy_unit_pos and _is_point_visible_to_current_unit(i):
				should_render = true
			# Render points visible to current player
			elif _is_point_visible_to_current_unit(i):
				should_render = true
			# Render points on hover
			elif hovered_point == i:
				should_render = true
			# Render points within current player's domain
			elif _is_point_in_current_player_domain(i):
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
			elif _can_current_unit_move_to_point(i):
				color = Color.MAGENTA
			
			draw_circle(points[i], 8, color)
	
	# Draw domains
	_draw_domains()

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
	_create_name_labels()
	
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
		var path_type = _get_path_type_between_points(current_unit_pos, target_point)
		
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
			var neighbor_index = _find_hex_coord_index(neighbor_coord)
			
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
	var corners = HexGridSystem.get_map_corners(paths, points.size()) if HexGridSystem else _get_map_corners()
	
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
	var corners = HexGridSystem.get_map_corners(paths, points.size()) if HexGridSystem else _get_map_corners()
	
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
	
	# Create labels for names
	_create_name_labels()

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

## Create labels for names
func _create_name_labels() -> void:
	# Domain 1 label
	unit1_domain_label = Label.new()
	unit1_domain_label.text = unit1_domain_name
	unit1_domain_label.add_theme_font_size_override("font_size", 12)
	unit1_domain_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	add_child(unit1_domain_label)
	
	# Domain 2 label
	unit2_domain_label = Label.new()
	unit2_domain_label.text = unit2_domain_name
	unit2_domain_label.add_theme_font_size_override("font_size", 12)
	unit2_domain_label.add_theme_color_override("font_color", Color(0.5, 0.0, 0.8))
	add_child(unit2_domain_label)
	
	# Unit 1 label
	unit1_name_label = Label.new()
	unit1_name_label.text = unit1_name
	unit1_name_label.add_theme_font_size_override("font_size", 10)
	unit1_name_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	add_child(unit1_name_label)
	
	# Unit 2 label
	unit2_name_label = Label.new()
	unit2_name_label.text = unit2_name
	unit2_name_label.add_theme_font_size_override("font_size", 10)
	unit2_name_label.add_theme_color_override("font_color", Color(0.5, 0.0, 0.8))
	add_child(unit2_name_label)

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
		var neighbor_coord = corner_coord + _hex_direction(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		
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
		var distance = _hex_distance(corner_coord, point_coord)
		
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
	print("🔍 GRID ANALYSIS - Analyzing %d points:" % points.size())
	
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
	
	# Print connectivity summary
	print("📊 Connectivity Summary:")
	for connections in connectivity_count.keys():
		print("  %d connections: %d points" % [connections, connectivity_count[connections]])
	
	# Print corners (3 connections)
	print("🔴 Corners (3 connections):")
	for point_data in point_connectivity:
		if point_data.connections == 3:
			print("  Point %d: %s" % [point_data.index, point_data.coord])
	
	# Print good domain spots (4+ connections)
	print("🟢 Good domain spots (4+ connections):")
	for point_data in point_connectivity:
		if point_data.connections >= 4:
			print("  Point %d: %d connections at %s" % [point_data.index, point_data.connections, point_data.coord])
	
	# Print best domain spots (6 connections)
	print("🌟 Best domain spots (6 connections):")
	for point_data in point_connectivity:
		if point_data.connections == 6:
			print("  Point %d: 6 connections at %s" % [point_data.index, point_data.coord])

## Find best domain positions - INTELLIGENT APPROACH
func _find_best_domain_positions() -> Array:
	print("🏰 INTELLIGENT DOMAIN POSITIONING - Finding best spots...")
	
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
				var distance = _hex_distance(hex_coords[i], hex_coords[corner])
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
			var distance = _hex_distance(candidate.coord, hex_coords[selected])
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
	# Check if domain should be visible (fog of war)
	if fog_of_war and not _is_domain_visible(center_index):
		return
	
	var center_pos = points[center_index]
	# Calculate radius based on real distance between adjacent points
	var radius = _get_edge_length(center_index)
	
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
		# Fallback to local logic
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
			unit1_label.visible = _is_point_visible_to_current_unit(unit1_position)
	
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
			unit2_label.visible = _is_point_visible_to_current_unit(unit2_position)
	
	# Update name positions
	_update_name_positions()

## Update name positions
func _update_name_positions() -> void:
	# Position unit names
	if unit1_name_label:
		var unit1_pos = points[unit1_position]
		unit1_name_label.position = unit1_pos + Vector2(-15, 15)  # Below unit
		unit1_name_label.visible = unit1_label.visible  # Same visibility as unit
	
	if unit2_name_label:
		var unit2_pos = points[unit2_position]
		unit2_name_label.position = unit2_pos + Vector2(-15, 15)  # Below unit
		unit2_name_label.visible = unit2_label.visible  # Same visibility as unit
	
	# Get current power values from PowerSystem (FIXED)
	var current_unit1_power = unit1_domain_power
	var current_unit2_power = unit2_domain_power
	if PowerSystem and PowerSystem.has_method("get_player_power"):
		current_unit1_power = PowerSystem.get_player_power(1)
		current_unit2_power = PowerSystem.get_player_power(2)
		# Update local variables to stay in sync
		unit1_domain_power = current_unit1_power
		unit2_domain_power = current_unit2_power
		print("🔧 FIXED: Power from PowerSystem - P1=%d, P2=%d" % [current_unit1_power, current_unit2_power])
	else:
		print("🔧 FIXED: Using local power values - P1=%d, P2=%d" % [current_unit1_power, current_unit2_power])
	
	# Position domain names and update power
	if unit1_domain_label:
		var domain1_pos = points[unit1_domain_center]
		unit1_domain_label.position = domain1_pos + Vector2(-30, 35)  # Below domain
		unit1_domain_label.text = "%s ⚡%d" % [unit1_domain_name, current_unit1_power]
		var domain1_visible = _is_domain_visible(unit1_domain_center) or not fog_of_war
		unit1_domain_label.visible = domain1_visible
		print("🔧 FIXED: Domain1 (%s) visible=%s, power=%d" % [unit1_domain_name, domain1_visible, current_unit1_power])
	
	if unit2_domain_label:
		var domain2_pos = points[unit2_domain_center]
		unit2_domain_label.position = domain2_pos + Vector2(-30, 35)  # Below domain
		unit2_domain_label.text = "%s ⚡%d" % [unit2_domain_name, current_unit2_power]
		var domain2_visible = _is_domain_visible(unit2_domain_center) or not fog_of_war
		unit2_domain_label.visible = domain2_visible
		print("🔧 FIXED: Domain2 (%s) visible=%s, power=%d" % [unit2_domain_name, domain2_visible, current_unit2_power])

## Check and reset forced revelations
func _check_and_reset_forced_revelations() -> void:
	# Reset unit1_force_revealed if it's not naturally visible
	if unit1_force_revealed and current_player == 2:
		if not _is_point_visible_to_current_unit(unit1_position):
			unit1_force_revealed = false
			print("🔍 Unit 1 is no longer visible - resetting forced revelation")
	
	# Reset unit2_force_revealed if it's not naturally visible
	if unit2_force_revealed and current_player == 1:
		if not _is_point_visible_to_current_unit(unit2_position):
			unit2_force_revealed = false
			print("🔍 Unit 2 is no longer visible - resetting forced revelation")