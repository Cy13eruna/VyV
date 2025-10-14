# 🌟 GRID OVERLAY RENDERER
# Purpose: Render grid overlays, effects, and special structures
# Layer: Presentation Manager - Rendering

extends RefCounted
class_name GridOverlayRenderer

# Import dependencies
const GameConstants = preload("res://presentation/config/game_constants.gd")
const TurnService = preload("res://application/services/turn_service_clean.gd")
const FogOfWarService = preload("res://application/services/fog_of_war_service.gd")

# References
var main_node: Node2D
var camera_manager
var domain_renderer

# Texture system for terrain
var terrain_textures: Dictionary = {}
var textures_loaded: bool = false

# Initialize with required references
func initialize(main_node_ref: Node2D, camera_manager_ref, domain_renderer_ref):
	main_node = main_node_ref
	camera_manager = camera_manager_ref
	domain_renderer = domain_renderer_ref

# Load terrain textures from files
func load_terrain_textures():
	for terrain_name in GameConstants.TEXTURE_PATHS:
		var texture_path = GameConstants.TEXTURE_PATHS[terrain_name]
		var texture_path_tres = GameConstants.TEXTURE_PATHS_TRES[terrain_name]
		
		if FileAccess.file_exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				terrain_textures[terrain_name] = texture
		elif FileAccess.file_exists(texture_path_tres):
			var texture = load(texture_path_tres) as Texture2D
			if texture:
				terrain_textures[terrain_name] = texture
	
	textures_loaded = true

# Render grid edges with terrain
func render_grid_edges(game_state: Dictionary, hover_state: Dictionary):
	if not ("grid" in game_state):
		return
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	var current_player_id = current_player.id if current_player else 1
	
	for edge_id in game_state.grid.edges:
		var edge = game_state.grid.edges[edge_id]
		
		var is_visible = true
		var is_remembered = false
		
		if game_state.get("fog_of_war_enabled", false):
			is_visible = FogOfWarService.is_edge_visible_to_player(edge, current_player_id, game_state)
			if not is_visible:
				is_remembered = FogOfWarService.is_remembered_by_player("edge", edge_id, current_player_id, game_state)
		
		if is_visible or is_remembered:
			var point_a = game_state.grid.points[edge.point_a_id]
			var point_b = game_state.grid.points[edge.point_b_id]
			
			var terrain_color = GameConstants.get_terrain_color(edge.get("terrain_type", 0), false)
			
			draw_diamond_path(
				camera_manager.apply_full_transform(point_a.position.pixel_pos),
				camera_manager.apply_full_transform(point_b.position.pixel_pos),
				terrain_color,
				GameConstants.PATH_THICKNESS,
				edge.get("terrain_type", 0),
				is_remembered and not is_visible,
				edge.get("structures", [])
			)

# Draw diamond-shaped path between two points with emoji support
func draw_diamond_path(start_pos: Vector2, end_pos: Vector2, color: Color, thickness: float, terrain_type: int = 0, is_remembered: bool = false, structures: Array = []) -> void:
	var direction = (end_pos - start_pos).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	var path_length = start_pos.distance_to(end_pos)
	var diamond_width = path_length * 0.6
	var center = (start_pos + end_pos) / 2
	
	var tip_start = start_pos
	var tip_end = end_pos
	var side_top = center + perpendicular * (diamond_width / 2)
	var side_bottom = center - perpendicular * (diamond_width / 2)
	
	var diamond_points = PackedVector2Array([
		tip_start, side_top, tip_end, side_bottom
	])
	
	main_node.draw_colored_polygon(diamond_points, color)
	draw_emoji_on_diamond(diamond_points, terrain_type, is_remembered, structures)

# Draw emojis on diamond
func draw_emoji_on_diamond(diamond_points: PackedVector2Array, terrain_type: int, is_remembered: bool = false, structures: Array = []) -> void:
	var center = Vector2.ZERO
	for point in diamond_points:
		center += point
	center /= diamond_points.size()
	
	var emoji_text = GameConstants.get_terrain_emoji(terrain_type)
	var emoji_color = GameConstants.get_terrain_emoji_color(terrain_type)
	
	var font = ThemeDB.fallback_font
	if font and emoji_text != "":
		var base_size = int(12 * camera_manager.zoom_level)
		var small_size = int(10 * camera_manager.zoom_level)
		var smaller_size = int(8 * camera_manager.zoom_level)
		var smallest_size = int(7 * camera_manager.zoom_level)
		
		main_node.draw_string(font, center + Vector2(-6, 3) * camera_manager.zoom_level, emoji_text, HORIZONTAL_ALIGNMENT_CENTER, -1, base_size, emoji_color)
		
		if terrain_type == 0:  # FIELD
			main_node.draw_string(font, center + Vector2(-15, -8) * camera_manager.zoom_level, "؛", HORIZONTAL_ALIGNMENT_CENTER, -1, small_size, emoji_color)
			main_node.draw_string(font, center + Vector2(10, -5) * camera_manager.zoom_level, "؛", HORIZONTAL_ALIGNMENT_CENTER, -1, small_size, emoji_color)
			main_node.draw_string(font, center + Vector2(-8, 12) * camera_manager.zoom_level, "؛", HORIZONTAL_ALIGNMENT_CENTER, -1, small_size, emoji_color)
			main_node.draw_string(font, center + Vector2(15, 8) * camera_manager.zoom_level, "؛", HORIZONTAL_ALIGNMENT_CENTER, -1, small_size, emoji_color)
		elif terrain_type == 1:  # FOREST
			main_node.draw_string(font, center + Vector2(-12, -6) * camera_manager.zoom_level, "🌳", HORIZONTAL_ALIGNMENT_CENTER, -1, small_size, emoji_color)
			main_node.draw_string(font, center + Vector2(8, -3) * camera_manager.zoom_level, "🌳", HORIZONTAL_ALIGNMENT_CENTER, -1, smaller_size, emoji_color)
			main_node.draw_string(font, center + Vector2(-5, 10) * camera_manager.zoom_level, "🌳", HORIZONTAL_ALIGNMENT_CENTER, -1, int(9 * camera_manager.zoom_level), emoji_color)
		elif terrain_type == 2:  # MOUNTAIN
			main_node.draw_string(font, center + Vector2(-10, -4) * camera_manager.zoom_level, "⛰", HORIZONTAL_ALIGNMENT_CENTER, -1, int(9 * camera_manager.zoom_level), emoji_color)
			main_node.draw_string(font, center + Vector2(12, -2) * camera_manager.zoom_level, "⛰", HORIZONTAL_ALIGNMENT_CENTER, -1, smaller_size, emoji_color)
			main_node.draw_string(font, center + Vector2(-3, 8) * camera_manager.zoom_level, "⛰", HORIZONTAL_ALIGNMENT_CENTER, -1, smallest_size, emoji_color)
		elif terrain_type == 3:  # WATER
			main_node.draw_string(font, center + Vector2(-14, -6) * camera_manager.zoom_level, "〰", HORIZONTAL_ALIGNMENT_CENTER, -1, small_size, emoji_color)
			main_node.draw_string(font, center + Vector2(6, -2) * camera_manager.zoom_level, "〰", HORIZONTAL_ALIGNMENT_CENTER, -1, int(9 * camera_manager.zoom_level), emoji_color)
			main_node.draw_string(font, center + Vector2(-8, 8) * camera_manager.zoom_level, "〰", HORIZONTAL_ALIGNMENT_CENTER, -1, smaller_size, emoji_color)
			main_node.draw_string(font, center + Vector2(12, 6) * camera_manager.zoom_level, "〰", HORIZONTAL_ALIGNMENT_CENTER, -1, smallest_size, emoji_color)

# Render grid points (stars)
func render_grid_points(game_state: Dictionary, hover_state: Dictionary, fog_settings: Dictionary = {}):
	if not ("grid" in game_state):
		return
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	var current_player_id = current_player.id if current_player else 1
	
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		
		var is_visible = true
		var is_remembered = false
		var is_hidden = false
		
		if game_state.get("fog_of_war_enabled", false):
			is_visible = FogOfWarService._is_position_visible_to_player(point.position, current_player_id, game_state)
			if not is_visible:
				is_remembered = FogOfWarService.is_remembered_by_player("point", point_id, current_player_id, game_state)
				if not is_remembered:
					is_hidden = true
		
		var star_color: Color
		
		# Check if this point is a domain center with power >= level
		var domain_color = domain_renderer.get_domain_nuclear_star_color(point.position, game_state, fog_settings)
		if domain_color != Color.TRANSPARENT:
			star_color = domain_color
		elif is_visible:
			star_color = Color.WHITE
		elif is_remembered:
			star_color = Color.BLACK
		else:
			star_color = Color.BLACK
		
		var star_pos = camera_manager.apply_full_transform(point.position.pixel_pos)
		var zoomed_star_radius = 12.0 * camera_manager.zoom_level
		
		# Draw white gradient glow behind nuclear star if it has team color
		if domain_color != Color.TRANSPARENT:
			draw_nuclear_star_glow(star_pos, zoomed_star_radius)
		
		draw_six_pointed_star(star_pos, zoomed_star_radius, star_color)

# Draw gradient glow for nuclear star
func draw_nuclear_star_glow(position: Vector2, star_radius: float) -> void:
	# Create gradient glow effect with multiple circles
	var glow_layers = [
		{"radius": star_radius * 2.5, "alpha": 0.1},
		{"radius": star_radius * 2.0, "alpha": 0.15},
		{"radius": star_radius * 1.6, "alpha": 0.25},
		{"radius": star_radius * 1.3, "alpha": 0.35},
		{"radius": star_radius * 1.1, "alpha": 0.45}
	]
	
	# Use white color for nuclear star glow
	var glow_color = Color.WHITE
	
	# Draw gradient glow layers
	for layer in glow_layers:
		var layer_color = Color(glow_color.r, glow_color.g, glow_color.b, layer.alpha)
		main_node.draw_circle(position, layer.radius, layer_color)

# Draw 6-pointed star
func draw_six_pointed_star(center: Vector2, radius: float, color: Color) -> void:
	var rotation_offset = PI / 6.0
	
	var triangle1_points = PackedVector2Array()
	for i in range(3):
		var angle = i * (2 * PI / 3) - PI / 2 + rotation_offset
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		triangle1_points.append(point)
	
	var triangle2_points = PackedVector2Array()
	for i in range(3):
		var angle = i * (2 * PI / 3) + PI / 2 + rotation_offset
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		triangle2_points.append(point)
	
	main_node.draw_colored_polygon(triangle1_points, color)
	main_node.draw_colored_polygon(triangle2_points, color)

# Render all structures on top of everything (harvest, hamlet, etc.)
func render_harvest_structures(game_state: Dictionary, fog_settings: Dictionary):
	if not ("grid" in game_state):
		return
	
	var current_player_id = fog_settings.get("player_id", 1)
	
	for edge_id in game_state.grid.edges:
		var edge = game_state.grid.edges[edge_id]
		
		# Check if edge is visible
		var is_visible = true
		if game_state.get("fog_of_war_enabled", false):
			is_visible = FogOfWarService.is_edge_visible_to_player(edge, current_player_id, game_state)
		
		if is_visible:
			var structures = edge.get("structures", [])
			
			# Check if this edge has any structures (harvest, hamlet, etc.)
			for structure in structures:
				var structure_type = structure.get("type", "")
				if structure_type in ["harvest", "hamlet"]:
					# Get edge center position
					var point_a = game_state.grid.points[edge.point_a_id]
					var point_b = game_state.grid.points[edge.point_b_id]
					var edge_center = (point_a.position.pixel_pos + point_b.position.pixel_pos) / 2
					
					# Transform to screen coordinates
					var screen_pos = camera_manager.apply_full_transform(edge_center)
					
					# Draw structure emoji on top
					var font = ThemeDB.fallback_font
					if font:
						var structure_emoji = structure.get("emoji", "")
						var structure_size = int(20 * camera_manager.zoom_level)  # Even larger for top layer
						
						# Add a subtle shadow for better visibility
						var shadow_offset = Vector2(2, 2) * camera_manager.zoom_level
						main_node.draw_string(font, screen_pos + shadow_offset, structure_emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, structure_size, Color(0, 0, 0, 0.5))
						
						# Draw the main emoji
						main_node.draw_string(font, screen_pos, structure_emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, structure_size, Color.WHITE)
	
	# Render fish emojis separately based on current bonus
	render_fish_emojis(game_state, fog_settings)

# Render fish emojis based on current turn bonus
func render_fish_emojis(game_state: Dictionary, fog_settings: Dictionary):
	if not ("grid" in game_state and "domains" in game_state):
		return
	
	var current_player_id = fog_settings.get("player_id", 1)
	
	# For each domain with fish upgrade
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.get("has_fish_upgrade", false):
			var current_fish_bonus = domain.get("current_fish_bonus", 0)
			if current_fish_bonus > 0:
				render_fish_emojis_for_domain(domain, game_state, current_fish_bonus, current_player_id)

# Render fish emojis for a specific domain
func render_fish_emojis_for_domain(domain, game_state: Dictionary, fish_bonus: int, current_player_id: int):
	# Get all water edges for this domain
	var water_edges = get_domain_water_edges_for_rendering(domain, game_state)
	
	if water_edges.size() == 0:
		return
	
	# Use fixed positions stored in domain to avoid random changes
	var productive_edges = []
	var emoji_positions = domain.get("fish_emoji_positions", [])
	
	# Select edges based on stored fixed positions
	for position_index in emoji_positions:
		if position_index < water_edges.size():
			var edge_id = water_edges[position_index]
			productive_edges.append(edge_id)
	
	# Render fish emoji on selected edges
	for edge_id in productive_edges:
		var edge = game_state.grid.edges[edge_id]
		
		# Check if edge is visible
		var is_visible = true
		if game_state.get("fog_of_war_enabled", false):
			is_visible = FogOfWarService.is_edge_visible_to_player(edge, current_player_id, game_state)
		
		if is_visible:
			# Get edge center position
			var point_a = game_state.grid.points[edge.point_a_id]
			var point_b = game_state.grid.points[edge.point_b_id]
			var edge_center = (point_a.position.pixel_pos + point_b.position.pixel_pos) / 2
			
			# Transform to screen coordinates
			var screen_pos = camera_manager.apply_full_transform(edge_center)
			
			# Draw fish emoji
			var font = ThemeDB.fallback_font
			if font:
				var fish_emoji = "🎣"
				var fish_size = int(20 * camera_manager.zoom_level)
				
				# Add a subtle shadow for better visibility
				var shadow_offset = Vector2(2, 2) * camera_manager.zoom_level
				main_node.draw_string(font, screen_pos + shadow_offset, fish_emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, fish_size, Color(0, 0, 0, 0.5))
				
				# Draw the main emoji
				main_node.draw_string(font, screen_pos, fish_emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, fish_size, Color.WHITE)

# Get water edges for a domain (for rendering)
func get_domain_water_edges_for_rendering(domain, game_state: Dictionary) -> Array:
	var water_edges = []
	
	if not ("grid" in game_state):
		return water_edges
	
	# Find the domain center point
	var domain_center_point = null
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(domain.center_position):
			domain_center_point = point
			break
	
	if not domain_center_point:
		return water_edges
	
	# Get neighbor points
	var neighbor_points = []
	for edge_id in domain_center_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		var other_point_id = edge.point_b_id if edge.point_a_id == domain_center_point.id else edge.point_a_id
		if other_point_id in game_state.grid.points:
			neighbor_points.append(game_state.grid.points[other_point_id])
	
	# 1. Radial water edges
	for edge_id in domain_center_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		if edge.get("terrain_type", 0) == 3:  # 3 = WATER
			water_edges.append(edge_id)
	
	# 2. Perimeter water edges
	var checked_perimeter_edges = []
	for i in range(neighbor_points.size()):
		var neighbor = neighbor_points[i]
		for edge_id in neighbor.connected_edges:
			if edge_id in checked_perimeter_edges or edge_id in domain_center_point.connected_edges:
				continue
			
			var edge = game_state.grid.edges[edge_id]
			var other_point_id = edge.point_b_id if edge.point_a_id == neighbor.id else edge.point_a_id
			
			# Check if connects to another neighbor
			for j in range(neighbor_points.size()):
				if neighbor_points[j].id == other_point_id:
					checked_perimeter_edges.append(edge_id)
					if edge.get("terrain_type", 0) == 3:  # 3 = WATER
						water_edges.append(edge_id)
					break
	
	return water_edges

# Cleanup method
func cleanup():
	main_node = null
	camera_manager = null
	domain_renderer = null
	terrain_textures.clear()
	textures_loaded = false