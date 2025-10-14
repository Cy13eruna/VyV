# 🏰 DOMAIN RENDERER
# Purpose: Render domain shapes, labels, and power indicators
# Layer: Presentation Manager - Rendering

extends RefCounted
class_name DomainRenderer

# Import dependencies
const GameConstants = preload("res://presentation/config/game_constants.gd")
const FogOfWarService = preload("res://application/services/fog_of_war_service.gd")

# References
var main_node: Node2D
var camera_manager

# Initialize with required references
func initialize(main_node_ref: Node2D, camera_manager_ref):
	main_node = main_node_ref
	camera_manager = camera_manager_ref

# Render domain shapes (hexagons) - LAYER 1
func render_domain_shapes(game_state: Dictionary, fog_settings: Dictionary):
	if not ("domains" in game_state):
		return
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		var domain_visible = true
		if fog_settings.fog_enabled:
			domain_visible = FogOfWarService.is_visible_to_player("domain", domain, fog_settings.player_id, game_state)
		
		if domain_visible:
			var center_pos = camera_manager.apply_full_transform(domain.center_position.pixel_pos)
			var player = game_state.players[domain.owner_id]
			var color = player.color
			
			var zoomed_radius = GameConstants.DOMAIN_RADIUS * camera_manager.zoom_level
			var zoomed_width = 6.0 * camera_manager.zoom_level
			
			var glow_width = zoomed_width + (4.0 * camera_manager.zoom_level)
			var glow_color = Color(1.0, 1.0, 1.0, 0.6)
			
			draw_hexagon_solid_outline(center_pos, zoomed_radius, glow_color, glow_width)
			draw_hexagon_solid_outline(center_pos, zoomed_radius, color, zoomed_width)

# Render domain labels (titles) - LAYER 2
func render_domain_labels(game_state: Dictionary, fog_settings: Dictionary):
	if not ("domains" in game_state):
		return
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		var domain_visible = true
		if fog_settings.fog_enabled:
			domain_visible = FogOfWarService.is_visible_to_player("domain", domain, fog_settings.player_id, game_state)
		
		if domain_visible:
			var center_pos = camera_manager.apply_full_transform(domain.center_position.pixel_pos)
			var player = game_state.players[domain.owner_id]
			var color = player.color
			
			var font = ThemeDB.fallback_font
			if font:
				# Get domain level (default to 1 if not set)
				var domain_level = domain.get("level", 1)
				var level_roman = to_roman_numeral(domain_level)
				var domain_name_upper = domain.name.to_upper()
				var domain_info = "{%s} %s ⭐%d" % [level_roman, domain_name_upper, domain.power]
				var domain_pos = center_pos + Vector2(0, (GameConstants.DOMAIN_RADIUS + 25) * camera_manager.zoom_level)
				
				draw_bold_italic_text(font, domain_pos, domain_info, 14, color)

# Render market indicators (🤝🏻 for domains with market upgrade)
func render_market_indicators(game_state: Dictionary, fog_settings: Dictionary):
	if not ("domains" in game_state):
		return
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		# Only show indicator for domains with market upgrade
		if not domain.get("has_market_upgrade", false):
			continue
		
		var domain_visible = true
		if fog_settings.fog_enabled:
			domain_visible = FogOfWarService.is_visible_to_player("domain", domain, fog_settings.player_id, game_state)
		
		if domain_visible:
			var center_pos = camera_manager.apply_full_transform(domain.center_position.pixel_pos)
			
			# Draw market indicator emoji at domain center (nucleus)
			var font = ThemeDB.fallback_font
			if font:
				var emoji = "🤝🏻"  # Market emoji
				var size = int(24 * camera_manager.zoom_level)  # Larger size for nucleus
				
				# Center the emoji at the domain nucleus
				var emoji_pos = center_pos - Vector2(12, 12) * camera_manager.zoom_level
				
				# Add shadow for visibility
				var shadow_offset = Vector2(2, 2) * camera_manager.zoom_level
				main_node.draw_string(font, emoji_pos + shadow_offset, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color(0, 0, 0, 0.8))
				
				# Draw main emoji
				main_node.draw_string(font, emoji_pos, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color.WHITE)

# Legacy function for compatibility - calls both layers
func render_domains(game_state: Dictionary, fog_settings: Dictionary):
	render_domain_shapes(game_state, fog_settings)
	render_market_indicators(game_state, fog_settings)  # Render market indicators BEFORE labels
	render_domain_labels(game_state, fog_settings)      # Render labels AFTER market indicators

# Check if position is a domain center with power >= level (nuclear star)
func get_domain_nuclear_star_color(position, game_state: Dictionary, fog_settings: Dictionary) -> Color:
	if not ("domains" in game_state and "players" in game_state):
		return Color.TRANSPARENT
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		# Check if this position is the domain center
		if domain.center_position.equals(position):
			# Check if domain is visible (atrelado à visualização do domínio)
			var domain_visible = true
			if fog_settings.fog_enabled:
				domain_visible = FogOfWarService.is_visible_to_player("domain", domain, fog_settings.player_id, game_state)
			
			if domain_visible:
				# Check if power >= level
				var domain_power = domain.get("power", 1)
				var domain_level = domain.get("level", 1)
				
				if domain_power >= domain_level:
					# Only show nuclear star color if current player owns the domain
					if domain.owner_id == fog_settings.player_id:
						# Return team color
						var player = game_state.players[domain.owner_id]
						return player.color
	
	return Color.TRANSPARENT

# Draw hexagon with solid outline
func draw_hexagon_solid_outline(center: Vector2, radius: float, color: Color, width: float):
	var points = []
	var rotation_offset = PI / 6.0
	for i in range(6):
		var angle = i * PI / 3.0 + rotation_offset
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	for i in range(6):
		var start_point = points[i]
		var end_point = points[(i + 1) % 6]
		main_node.draw_line(start_point, end_point, color, width)

# Convert number to Roman numerals
func to_roman_numeral(number: int) -> String:
	var values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
	var numerals = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
	
	var result = ""
	for i in range(values.size()):
		while number >= values[i]:
			result += numerals[i]
			number -= values[i]
	
	return result

# Draw text with bold and italic effect
func draw_bold_italic_text(font: Font, position: Vector2, text: String, size: int, color: Color) -> void:
	var zoomed_size = int(size * camera_manager.zoom_level)
	
	# Ensure minimum font size
	if zoomed_size < 8:
		zoomed_size = 8
	
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, zoomed_size)
	var centered_pos = position - Vector2(text_size.x / 2, 0)
	
	var italic_offsets = [
		Vector2(0, 0),
		Vector2(1, -2) * camera_manager.zoom_level,
		Vector2(2, -4) * camera_manager.zoom_level,
		Vector2(-1, 2) * camera_manager.zoom_level,
		Vector2(-2, 4) * camera_manager.zoom_level
	]
	
	var bold_offsets = [
		Vector2(-1, -1) * camera_manager.zoom_level, Vector2(0, -1) * camera_manager.zoom_level, Vector2(1, -1) * camera_manager.zoom_level,
		Vector2(-1, 0) * camera_manager.zoom_level,                                Vector2(1, 0) * camera_manager.zoom_level,
		Vector2(-1, 1) * camera_manager.zoom_level,  Vector2(0, 1) * camera_manager.zoom_level,  Vector2(1, 1) * camera_manager.zoom_level
	]
	
	for italic_offset in italic_offsets:
		for bold_offset in bold_offsets:
			main_node.draw_string(font, centered_pos + italic_offset + bold_offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, zoomed_size, Color.BLACK)
	
	main_node.draw_string(font, centered_pos + Vector2(1, -1) * camera_manager.zoom_level, text, HORIZONTAL_ALIGNMENT_LEFT, -1, zoomed_size, color)

# Cleanup method
func cleanup():
	main_node = null
	camera_manager = null