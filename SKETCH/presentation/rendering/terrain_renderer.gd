# 🎮 V&V TERRAIN RENDERER
# Purpose: Handle terrain rendering, emojis, and textures
# Layer: Presentation Rendering

class_name TerrainRenderer
extends RefCounted

# Preload services
const FogOfWarService = preload("res://application/services/fog_of_war_service.gd")

# References
var main_node: Node2D
var camera_controller: CameraController

# Texture system for terrain
var terrain_textures: Dictionary = {}
var textures_loaded: bool = false

func set_references(main_node_ref: Node2D, camera_ref: CameraController):
	main_node = main_node_ref
	camera_controller = camera_ref
	load_terrain_textures()

# Load terrain textures from files
func load_terrain_textures():
	# Load each texture
	for terrain_name in GameConstants.TEXTURE_PATHS:
		var texture_path = GameConstants.TEXTURE_PATHS[terrain_name]
		var texture_path_tres = GameConstants.TEXTURE_PATHS_TRES[terrain_name]
		
		# Try PNG first
		if FileAccess.file_exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				terrain_textures[terrain_name] = texture
			else:
				pass
		# Try TRES as fallback
		elif FileAccess.file_exists(texture_path_tres):
			var texture = load(texture_path_tres) as Texture2D
			if texture:
				terrain_textures[terrain_name] = texture
			else:
				pass
		else:
			pass
	
	textures_loaded = true

# Render only grid edges
func render_grid_edges(game_state: Dictionary, hover_state: Dictionary):
	if not ("grid" in game_state):
		return
	
	var current_player = game_state.get("current_player")
	var current_player_id = current_player.id if current_player else 1
	
	# Draw edges with restored colors and thickness (with fog of war and remembered terrain)
	for edge_id in game_state.grid.edges:
		var edge = game_state.grid.edges[edge_id]
		
		# Check if edge is currently visible or remembered
		var is_visible = true
		var is_remembered = false
		
		if game_state.get("fog_of_war_enabled", false):
			is_visible = FogOfWarService.is_edge_visible_to_player(edge, current_player_id, game_state)
			if not is_visible:
				is_remembered = FogOfWarService.is_remembered_by_player("edge", edge_id, current_player_id, game_state)
		
		if is_visible or is_remembered:
			var point_a = game_state.grid.points[edge.point_a_id]
			var point_b = game_state.grid.points[edge.point_b_id]
			
			# Get terrain color from restored palette (no paleness for remembered)
			var terrain_color = GameConstants.get_terrain_color(edge.get("terrain_type", 0), false)
			
			# Draw diamond-shaped path with emojis (pass remembered state)
			draw_diamond_path(
				camera_controller.apply_full_transform(point_a.position.pixel_pos),
				camera_controller.apply_full_transform(point_b.position.pixel_pos),
				terrain_color,
				GameConstants.PATH_THICKNESS,
				edge.get("terrain_type", 0),
				is_remembered and not is_visible  # Pass remembered state
			)

# Render only grid points (stars) - called after domains to overlay them
func render_grid_points(game_state: Dictionary, hover_state: Dictionary):
	if not ("grid" in game_state):
		return
	
	var current_player = game_state.get("current_player")
	var current_player_id = current_player.id if current_player else 1
	
	# Draw points (with fog of war and remembered terrain)
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		
		# Check if point is currently visible or remembered
		var is_visible = true
		var is_remembered = false
		var is_hidden = false
		
		if game_state.get("fog_of_war_enabled", false):
			is_visible = FogOfWarService._is_position_visible_to_player(point.position, current_player_id, game_state)
			if not is_visible:
				is_remembered = FogOfWarService.is_remembered_by_player("point", point_id, current_player_id, game_state)
				if not is_remembered:
					is_hidden = true
		
		# Draw star based on visibility state
		var star_color: Color
		var star_pos = camera_controller.apply_full_transform(point.position.pixel_pos)
		
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
		
		# Draw star (reduced size) - with zoom support
		var zoomed_star_radius = 12.0 * camera_controller.zoom_level
		draw_six_pointed_star(star_pos, zoomed_star_radius, star_color)

# Draw diamond-shaped path between two points with emoji support
func draw_diamond_path(start_pos: Vector2, end_pos: Vector2, color: Color, thickness: float, terrain_type: int = 0, is_remembered: bool = false) -> void:
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
	main_node.draw_colored_polygon(diamond_points, color)
	
	# Depois desenhar os emojis DIRETAMENTE por cima
	draw_emoji_on_diamond(diamond_points, terrain_type, is_remembered)

# NOVA FUNÇÃO: Desenhar emojis diretamente no diamante
func draw_emoji_on_diamond(diamond_points: PackedVector2Array, terrain_type: int, is_remembered: bool = false) -> void:
	# Calcular centro do diamante
	var center = Vector2.ZERO
	for point in diamond_points:
		center += point
	center /= diamond_points.size()
	
	# Obter emoji e cor para o tipo de terreno
	var emoji_text = GameConstants.get_terrain_emoji(terrain_type)
	var emoji_color = GameConstants.get_terrain_emoji_color(terrain_type)
	
	# Desenhar múltiplos emojis espalhados no diamante
	var font = ThemeDB.fallback_font
	if font and emoji_text != "":
		# Aplicar zoom aos tamanhos dos emojis e offsets
		var base_size = int(12 * camera_controller.zoom_level)
		var small_size = int(10 * camera_controller.zoom_level)
		var smaller_size = int(8 * camera_controller.zoom_level)
		var smallest_size = int(7 * camera_controller.zoom_level)
		
		# Desenhar emoji no centro (sem blur - removido conforme solicitado)
		main_node.draw_string(font, center + Vector2(-6, 3) * camera_controller.zoom_level, emoji_text, HORIZONTAL_ALIGNMENT_CENTER, -1, base_size, emoji_color)
		
		# Desenhar emojis adicionais espalhados (sem blur) - com zoom aplicado aos offsets
		if terrain_type == 0:  # FIELD - semicolons espalhados
			main_node.draw_string(font, center + Vector2(-15, -8) * camera_controller.zoom_level, "؛", HORIZONTAL_ALIGNMENT_CENTER, -1, small_size, emoji_color)
			main_node.draw_string(font, center + Vector2(10, -5) * camera_controller.zoom_level, "؛", HORIZONTAL_ALIGNMENT_CENTER, -1, small_size, emoji_color)
			main_node.draw_string(font, center + Vector2(-8, 12) * camera_controller.zoom_level, "؛", HORIZONTAL_ALIGNMENT_CENTER, -1, small_size, emoji_color)
			main_node.draw_string(font, center + Vector2(15, 8) * camera_controller.zoom_level, "؛", HORIZONTAL_ALIGNMENT_CENTER, -1, small_size, emoji_color)
		elif terrain_type == 1:  # FOREST - árvores espalhadas
			main_node.draw_string(font, center + Vector2(-12, -6) * camera_controller.zoom_level, "🌳", HORIZONTAL_ALIGNMENT_CENTER, -1, small_size, emoji_color)
			main_node.draw_string(font, center + Vector2(8, -3) * camera_controller.zoom_level, "🌳", HORIZONTAL_ALIGNMENT_CENTER, -1, smaller_size, emoji_color)
			main_node.draw_string(font, center + Vector2(-5, 10) * camera_controller.zoom_level, "🌳", HORIZONTAL_ALIGNMENT_CENTER, -1, int(9 * camera_controller.zoom_level), emoji_color)
		elif terrain_type == 2:  # MOUNTAIN - montanhas espalhadas
			main_node.draw_string(font, center + Vector2(-10, -4) * camera_controller.zoom_level, "⛰", HORIZONTAL_ALIGNMENT_CENTER, -1, int(9 * camera_controller.zoom_level), emoji_color)
			main_node.draw_string(font, center + Vector2(12, -2) * camera_controller.zoom_level, "⛰", HORIZONTAL_ALIGNMENT_CENTER, -1, smaller_size, emoji_color)
			main_node.draw_string(font, center + Vector2(-3, 8) * camera_controller.zoom_level, "⛰", HORIZONTAL_ALIGNMENT_CENTER, -1, smallest_size, emoji_color)
		elif terrain_type == 3:  # WATER - ondas espalhadas
			main_node.draw_string(font, center + Vector2(-14, -6) * camera_controller.zoom_level, "〰", HORIZONTAL_ALIGNMENT_CENTER, -1, small_size, emoji_color)
			main_node.draw_string(font, center + Vector2(6, -2) * camera_controller.zoom_level, "〰", HORIZONTAL_ALIGNMENT_CENTER, -1, int(9 * camera_controller.zoom_level), emoji_color)
			main_node.draw_string(font, center + Vector2(-8, 8) * camera_controller.zoom_level, "〰", HORIZONTAL_ALIGNMENT_CENTER, -1, smaller_size, emoji_color)
			main_node.draw_string(font, center + Vector2(12, 6) * camera_controller.zoom_level, "〰", HORIZONTAL_ALIGNMENT_CENTER, -1, smallest_size, emoji_color)

# Draw 6-pointed star (Star of David) rotated 30 degrees
func draw_six_pointed_star(center: Vector2, radius: float, color: Color) -> void:
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
	main_node.draw_colored_polygon(triangle1_points, color)
	main_node.draw_colored_polygon(triangle2_points, color)

# Get terrain texture by type
func get_terrain_texture(terrain_type: int) -> Texture2D:
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