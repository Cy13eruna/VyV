# 🎮 UNIT BASIC RENDERER
# Purpose: Handle basic unit rendering and settler technology validation
# Layer: Presentation - Unit Rendering

extends RefCounted
class_name UnitBasicRenderer

# Import dependencies
const FogOfWarService = preload("res://application/services/fog_of_war_service.gd")
const MovementService = preload("res://application/services/movement_service.gd")
const TurnService = preload("res://application/services/turn_service_clean.gd")

# References
var main_node: Node2D
var camera_manager
var visual_effects

# Initialize with references
func initialize(main_node_ref: Node2D, camera_manager_ref, visual_effects_ref):
	main_node = main_node_ref
	camera_manager = camera_manager_ref
	visual_effects = visual_effects_ref

# Render units with fog of war
func render_units_with_fog(game_state: Dictionary, fog_settings: Dictionary, hover_state: Dictionary, selected_unit_id: int, font: Font, technology_manager = null):
	if not font:
		return
	
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		# Skip dead units - they should not be rendered
		if unit.is_dead():
			continue
		
		var is_visible = true
		if fog_settings.fog_enabled:
			is_visible = FogOfWarService.is_visible_to_player("unit", unit, fog_settings.player_id, game_state)
		
		if is_visible:
			var pos = camera_manager.apply_full_transform(unit.position.pixel_pos)
			var is_selected = unit_id == selected_unit_id
			var is_hovered = unit_id in hover_state and hover_state[unit_id]
			
			var unit_color = game_state.players[unit.owner_id].color
			var has_actions = unit.can_move()
			
			var unit_emoji = "🚶🏻‍♀️"
			# Draw team color glow behind unit if Settler is ready for second click
			if technology_manager and can_unit_use_settler(unit, game_state, technology_manager) and is_selected:
				visual_effects.draw_settler_ready_glow(pos, unit_color)
			
			var unit_emoji_size = int(32 * camera_manager.zoom_level)
			var unit_emoji_offset = Vector2(-12, 0) * camera_manager.zoom_level
			
			var should_flip = visual_effects.should_flip_unit_emoji(unit_id)
			var enhanced_team_color = visual_effects.get_enhanced_team_color(unit_color, has_actions)
			
			# Draw unit emoji with team color tinting
			if should_flip:
				visual_effects.draw_flipped_tinted_emoji(font, pos + unit_emoji_offset, unit_emoji, unit_emoji_size, enhanced_team_color)
			else:
				visual_effects.draw_tinted_emoji(font, pos + unit_emoji_offset, unit_emoji, unit_emoji_size, enhanced_team_color)
			
			var unit_name_pos = pos + Vector2(0, 15 * camera_manager.zoom_level)
			visual_effects.draw_bold_italic_text(font, unit_name_pos, unit.name, 12, unit_color)
			
			# Check if unit can use Settler technology
			if technology_manager and can_unit_use_settler(unit, game_state, technology_manager):
				visual_effects.draw_settler_flag(pos)
			
			if is_hovered:
				visual_effects.draw_hover_effect(pos)
	
	# Render skull emojis for dead units
	render_skull_emojis(game_state, font)

# Render movement targets with terrain
func render_movement_targets_with_terrain(game_state: Dictionary, selected_unit_id: int, valid_movement_targets: Array, font: Font):
	if not font or selected_unit_id == -1:
		return
	
	var unit = game_state.units[selected_unit_id]
	
	for target_pos in valid_movement_targets:
		var pos = target_pos.pixel_pos
		var terrain_cost = MovementService.get_terrain_movement_cost(unit, target_pos, game_state.grid, game_state)
		var rotated_pos = camera_manager.apply_full_transform(pos)
		var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
		var team_color = current_player.color if current_player else Color.WHITE
		visual_effects.draw_team_color_glow_around_star(rotated_pos, terrain_cost, team_color)
		
		visual_effects.draw_terrain_cost_indicator(rotated_pos, terrain_cost, font)

# Render skull emojis for positions where units died
func render_skull_emojis(game_state: Dictionary, font: Font):
	if not font or not ("skull_emojis" in game_state):
		return
	
	# Get current turn for expiration check
	var current_turn = 0
	if "turn_data" in game_state and "turn_number" in game_state.turn_data:
		current_turn = game_state.turn_data.turn_number
	
	# Render each skull emoji that hasn't expired
	for skull_data in game_state.skull_emojis:
		# Check if skull has expired
		if current_turn >= skull_data.get("expires_turn", 0):
			continue  # Skip expired skulls
		
		var pos = camera_manager.apply_full_transform(skull_data.position.pixel_pos)
		var skull_emoji = skull_data.get("emoji", "💀")
		var skull_size = int(20 * camera_manager.zoom_level)  # Reduced from 32 to 20
		var skull_offset = Vector2(-8, 0) * camera_manager.zoom_level  # Adjusted offset
		
		# Draw skull emoji with slight transparency to indicate it's temporary
		var skull_color = Color(1.0, 1.0, 1.0, 0.8)  # Slightly transparent white
		main_node.draw_string(font, pos + skull_offset, skull_emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, skull_size, skull_color)

# Check if unit can use Settler technology (SYNCHRONIZED WITH ACTION_DIALOG_MANAGER)
func can_unit_use_settler(unit, game_state: Dictionary, technology_manager) -> bool:
	# Must have actions remaining to establish domain
	if not unit.can_move():
		return false
	
	# Must have Settler technology
	if not technology_manager.has_technology(unit.owner_id, "settler"):
		return false
	
	# Must have at least 1 power in natal domain to establish domain
	var natal_power = get_unit_natal_power(unit, game_state)
	if natal_power < 1:
		return false
	
	# Must not share paths with existing domains (can share at most one star)
	if not can_domain_be_placed_without_sharing_paths(unit, game_state):
		return false
	
	# Must not be on the border of the map
	return is_unit_away_from_border(unit, game_state)

# Check if unit is at least 3 stars away from domain nuclei
func is_unit_far_from_domains(unit, game_state: Dictionary) -> bool:
	if not ("domains" in game_state):
		return false
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		var distance = calculate_hex_distance(unit.position, domain.center_position)
		if distance < 3:
			return false
	
	return true

# Check if unit is away from map border (not on edge or corner)
func is_unit_away_from_border(unit, game_state: Dictionary) -> bool:
	if not ("grid" in game_state):
		return false
	
	# Find the point at unit's position
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(unit.position):
			# Check if point is a corner (3 connections) or edge (less than 6 connections)
			var connections = point.get("connected_edges", [])
			if connections.size() < 6:
				return false  # Point is on border or corner
			return true  # Point has 6 connections (interior)
	
	return false  # Position not found on grid

# Calculate hex distance between two positions
func calculate_hex_distance(pos1, pos2) -> int:
	# Use the built-in distance calculation from Position class
	return pos1.distance_to(pos2)

# Get power from unit's natal domain only
func get_unit_natal_power(unit, game_state: Dictionary) -> int:
	var natal_domain = find_natal_domain(unit, game_state)
	if natal_domain:
		return natal_domain.get("power", 0)
	return 0

# Find unit's natal domain (domain with same initial as unit name)
func find_natal_domain(unit, game_state: Dictionary):
	if not ("domains" in game_state):
		return null
	
	var unit_initial = unit.get_name_initial()
	if unit_initial == "":
		return null
	
	# Find domain with matching initial for this player
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == unit.owner_id and domain.get("initial", "") == unit_initial:
			return domain
	
	return null

# Check if domain can be placed without sharing paths with existing domains
func can_domain_be_placed_without_sharing_paths(unit, game_state: Dictionary) -> bool:
	if not ("domains" in game_state):
		return true  # No existing domains, can place anywhere
	
	# Get the grid point where unit is located
	var unit_point = null
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(unit.position):
			unit_point = point
			break
	
	if not unit_point:
		return false  # Unit position not found on grid
	
	# Get the "influence area" of the new domain (center + neighbors)
	var new_domain_positions = []
	# Add center position
	new_domain_positions.append(unit.position)
	var unit_neighbors = get_point_neighbors(unit_point, game_state)
	for neighbor in unit_neighbors:
		# Add neighbor positions
		new_domain_positions.append(neighbor.position)
	
	# Check each existing domain
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		# Get the domain's center point
		var domain_point = null
		for point_id in game_state.grid.points:
			var point = game_state.grid.points[point_id]
			if point.position.equals(domain.center_position):
				domain_point = point
				break
		
		if not domain_point:
			continue  # Domain position not found, skip
		
		# Get the "influence area" of the existing domain (center + neighbors)
		var existing_domain_positions = []
		# Add center position
		existing_domain_positions.append(domain.center_position)
		var domain_neighbors = get_point_neighbors(domain_point, game_state)
		for neighbor in domain_neighbors:
			# Add neighbor positions
			existing_domain_positions.append(neighbor.position)
		
		# Count shared positions between the two influence areas
		var shared_count = 0
		for new_pos in new_domain_positions:
			for existing_pos in existing_domain_positions:
				if new_pos.equals(existing_pos):  # Use Position.equals() method
					shared_count += 1
					break  # Avoid double counting same position
		
		# If sharing more than one position, domains would share paths (not allowed)
		if shared_count > 1:
			return false
	
	return true

# Get neighbors of a grid point
func get_point_neighbors(point, game_state: Dictionary) -> Array:
	var neighbors = []
	if not point or not ("connected_edges" in point):
		return neighbors
	
	# Get all connected edges and find their other endpoints
	for edge_id in point.connected_edges:
		if edge_id in game_state.grid.edges:
			var edge = game_state.grid.edges[edge_id]
			# Find the other point of this edge
			var other_point_id = -1
			if "point_a_id" in edge and "point_b_id" in edge:
				other_point_id = edge.point_a_id if edge.point_b_id == point.id else edge.point_b_id
			elif "point1_id" in edge and "point2_id" in edge:
				other_point_id = edge.point1_id if edge.point2_id == point.id else edge.point2_id
			elif "point1" in edge and "point2" in edge:
				other_point_id = edge.point1 if edge.point2 == point.id else edge.point2
			else:
				continue  # Skip malformed edge
			
			if other_point_id != -1 and other_point_id in game_state.grid.points:
				neighbors.append(game_state.grid.points[other_point_id])
	
	return neighbors

# Cleanup method
func cleanup():
	main_node = null
	camera_manager = null
	visual_effects = null