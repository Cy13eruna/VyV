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
	print("Generating expanded hexagonal grid...")
	
	# Generate hexagonal grid
	_generate_hex_grid()
	
	# Set initial unit positions
	_set_initial_unit_positions()
	
	# Generate random terrain automatically using TerrainSystem
	TerrainSystem.generate_random_terrain(paths)
	
	print("Hexagonal grid created: %d points, %d paths" % [points.size(), paths.size()])
	
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
	
	# Mark map corners
	_mark_map_corners()
	
	# Position labels at initial points
	_update_units_visibility_and_position()
	
	# Create UI
	_create_ui()

func _process(_delta):
	var mouse_pos = get_global_mouse_position()
	
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
	
	queue_redraw()

func _draw():
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
			var color = _get_path_color(path.type)
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
	
	# Update unit positions
	_update_units_visibility_and_position()

## Input handling for unit movement and terrain generation
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		# Check click on points
		for i in range(points.size()):
			if mouse_pos.distance_to(points[i]) < 20:
				# If clicked on point that current unit can move to, check actions
				if _can_current_unit_move_to_point(i):
					var current_actions = unit1_actions if current_player == 1 else unit2_actions
					if current_actions > 0:
						# Check if domain has enough power
						if not _has_domain_power_for_action():
							print("⚡ No power! Domain doesn't have power to perform action.")
							return
						
						# Check if there's a hidden unit at destination
						var movement_result = _attempt_movement(i)
						
						if movement_result.success:
							var old_pos = unit1_position if current_player == 1 else unit2_position
							print("🚶🏻‍♀️ Unit %d moving from point %d to point %d (Actions: %d → %d)" % [current_player, old_pos, i, current_actions, current_actions - 1])
							
							# Consume domain power
							_consume_domain_power()
							
							if current_player == 1:
								unit1_position = i
								unit1_actions -= 1
							else:
								unit2_position = i
								unit2_actions -= 1
						else:
							# Movement failed due to hidden unit
							print("⚠️ Movement blocked! %s" % movement_result.message)
							# Consume power and lose action anyway
							_consume_domain_power()
							if current_player == 1:
								unit1_actions -= 1
							else:
								unit2_actions -= 1
						
						_update_units_visibility_and_position()
						_update_action_display()
						queue_redraw()
						get_viewport().set_input_as_handled()
						return
					else:
						print("❌ No actions remaining! Use 'Skip Turn' to restore.")
				else:
					print("❌ Unit %d cannot move to point %d" % [current_player, i])
	
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Toggle fog of war
			fog_of_war = not fog_of_war
			var fog_status = "ENABLED" if fog_of_war else "DISABLED"
			print("🌫️ Fog of War %s" % fog_status)
			queue_redraw()
			get_viewport().set_input_as_handled()

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

## Check if path is adjacent to any unit (for hover)
func _is_path_adjacent_to_unit(path: Dictionary) -> bool:
	# Path is adjacent if one of the points has any unit
	var path_points = path.points
	return path_points[0] == unit1_position or path_points[1] == unit1_position or \
		   path_points[0] == unit2_position or path_points[1] == unit2_position

## Check if point is visible to current player
func _is_point_visible_to_current_unit(point_index: int) -> bool:
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	return _is_point_visible_to_unit(point_index, current_unit_pos)

## Check if point is visible to any unit (for hover)
func _is_point_visible_to_any_unit(point_index: int) -> bool:
	return _is_point_visible_to_unit(point_index, unit1_position) or _is_point_visible_to_unit(point_index, unit2_position)

## Check if point is visible to a specific unit
func _is_point_visible_to_unit(point_index: int, unit_pos: int) -> bool:
	# Check if there's a path that allows visibility
	for path in paths:
		var path_points = path.points
		if (path_points[0] == unit_pos and path_points[1] == point_index) or \
		   (path_points[1] == unit_pos and path_points[0] == point_index):
			# Field and Water allow seeing
			if path.type == EdgeType.FIELD or path.type == EdgeType.WATER:
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
		
		if path_type == EdgeType.FOREST and not enemy_was_visible:
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
	return EdgeType.MOUNTAIN

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

## Generate power for domains (once per round)
func _generate_domain_power() -> void:
	print("🔄 New round - Generating power for domains")
	
	# Domain 1: generate power if not occupied
	if unit2_position != unit1_domain_center:
		unit1_domain_power += 1
		print("⚡ Domain 1 (%s) generated 1 power (Total: %d)" % [unit1_domain_name, unit1_domain_power])
	else:
		print("⚡ Domain 1 (%s) occupied - didn't generate power" % unit1_domain_name)
	
	# Domain 2: generate power if not occupied
	if unit1_position != unit2_domain_center:
		unit2_domain_power += 1
		print("⚡ Domain 2 (%s) generated 1 power (Total: %d)" % [unit2_domain_name, unit2_domain_power])
	else:
		print("⚡ Domain 2 (%s) occupied - didn't generate power" % unit2_domain_name)

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

## Check if point is within any domain
func _is_point_in_domain(point_index: int) -> bool:
	# Check if point is within unit 1's domain
	if _is_point_in_specific_domain(point_index, unit1_domain_center):
		return true
	
	# Check if point is within unit 2's domain
	if _is_point_in_specific_domain(point_index, unit2_domain_center):
		return true
	
	return false

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

## Check if path is within any domain
func _is_path_in_domain(path: Dictionary) -> bool:
	# Path is in domain if both points are in the domain
	var point1 = path.points[0]
	var point2 = path.points[1]
	
	# Check unit 1's domain
	if _is_point_in_specific_domain(point1, unit1_domain_center) and _is_point_in_specific_domain(point2, unit1_domain_center):
		return true
	
	# Check unit 2's domain
	if _is_point_in_specific_domain(point1, unit2_domain_center) and _is_point_in_specific_domain(point2, unit2_domain_center):
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
			if path.type == EdgeType.FIELD or path.type == EdgeType.FOREST:
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
	print("Press SPACE again to regenerate.")

## Get outer points (radius 3)
func _get_outer_points() -> Array[int]:
	var outer_points: Array[int] = []
	for i in range(hex_coords.size()):
		var coord = hex_coords[i]
		var distance = max(abs(coord.x), abs(coord.y), abs(-coord.x - coord.y))
		if distance == 3:
			outer_points.append(i)
	return outer_points

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
					paths.append({"points": [i, neighbor_index], "type": EdgeType.FIELD})
					path_set[path_id] = true

## Find hexagonal coordinate index
func _find_hex_coord_index(coord: Vector2) -> int:
	for i in range(hex_coords.size()):
		if hex_coords[i].is_equal_approx(coord):
			return i
	return -1

## Set initial unit positions (official spawn)
func _set_initial_unit_positions() -> void:
	# Get the 6 map corners
	var corners = _get_map_corners()
	
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
		
		print("Units positioned at official spawn:")
		print("Unit1 (Red) '%s' at point %d: %s (Domain: %s)" % [unit1_name, unit1_position, hex_coords[unit1_position], unit1_domain_name])
		print("Unit2 (Violet) '%s' at point %d: %s (Domain: %s)" % [unit2_name, unit2_position, hex_coords[unit2_position], unit2_domain_name])
		print("Domains created at spawn points")
	else:
		print("Error: Could not find enough corners")

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

## Find adjacent point with 6 edges
func _find_adjacent_six_edge_point(corner_index: int) -> int:
	var corner_coord = hex_coords[corner_index]
	
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
			
			# If it has 6 paths, it's a valid point
			if path_count == 6:
				return neighbor_index
	
	# If no neighbor with 6 paths found, return the corner itself
	return corner_index

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

## Check if domain is visible to current player
func _is_domain_visible(domain_center: int) -> bool:
	# Domain always visible if it belongs to current player
	if (current_player == 1 and domain_center == unit1_domain_center) or \
	   (current_player == 2 and domain_center == unit2_domain_center):
		return true
	
	# Enemy domain visible if center or any adjacent point is visible
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	
	# Check if domain center is visible
	if _is_point_visible_to_unit(domain_center, current_unit_pos):
		return true
	
	# Check if any point adjacent to domain center is visible
	var domain_coord = hex_coords[domain_center]
	for dir in range(6):
		var neighbor_coord = domain_coord + _hex_direction(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1 and _is_point_visible_to_unit(neighbor_index, current_unit_pos):
			return true
	
	return false

## Detect the six map corners (points with only 3 edges)
func _get_map_corners() -> Array[int]:
	var corners: Array[int] = []
	
	# Count paths connected to each point
	for i in range(points.size()):
		var path_count = 0
		
		# Count how many paths connect to this point
		for path in paths:
			var path_points = path.points
			if path_points[0] == i or path_points[1] == i:
				path_count += 1
		
		# Hexagon corners have only 3 paths
		if path_count == 3:
			corners.append(i)
	
	return corners

## Mark map corners (paint magenta)
func _mark_map_corners() -> void:
	var corners = _get_map_corners()
	
	print("🔍 Corners detected: %d points with 3 paths" % corners.size())
	for corner_index in corners:
		print("  Corner %d: coordinate %s" % [corner_index, hex_coords[corner_index]])
	
	# Store corner indices to paint magenta
	for corner_index in corners:
		# Corners will be painted magenta in _draw() function
		pass

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

## Skip Turn button callback
func _on_skip_turn_pressed() -> void:
	print("⏭️ Player %d skipping turn - Switching to player %d" % [current_player, 3 - current_player])
	
	# Switch player
	current_player = 3 - current_player  # 1 -> 2, 2 -> 1
	
	# Generate power for domains at start of round (when returning to player 1)
	if current_player == 1:
		_generate_domain_power()
	
	# Restore actions for new player
	if current_player == 1:
		unit1_actions = 1
	else:
		unit2_actions = 1
	
	# Reset forced revelations if units are no longer visible
	_check_and_reset_forced_revelations()
	
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
	
	# Position domain names and update power
	if unit1_domain_label:
		var domain1_pos = points[unit1_domain_center]
		unit1_domain_label.position = domain1_pos + Vector2(-30, 35)  # Below domain
		unit1_domain_label.text = "%s ⚡%d" % [unit1_domain_name, unit1_domain_power]
		unit1_domain_label.visible = _is_domain_visible(unit1_domain_center) or not fog_of_war
	
	if unit2_domain_label:
		var domain2_pos = points[unit2_domain_center]
		unit2_domain_label.position = domain2_pos + Vector2(-30, 35)  # Below domain
		unit2_domain_label.text = "%s ⚡%d" % [unit2_domain_name, unit2_domain_power]
		unit2_domain_label.visible = _is_domain_visible(unit2_domain_center) or not fog_of_war

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