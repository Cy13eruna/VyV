# 🏰 DOMAIN RENDERER
# Purpose: Render player domains
# Layer: Infrastructure/Rendering
# Dependencies: Core entities, VisibilityService

class_name DomainRenderer
extends RefCounted

static func render_domains(canvas: CanvasItem, game_state: Dictionary, current_player_id: int) -> void:
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		if VisibilityService.is_domain_visible_to_player(
			domain, current_player_id, game_state.grid,
			game_state.units, game_state.domains, game_state.fog_of_war_enabled
		):
			_render_domain(canvas, domain)

static func _render_domain(canvas: CanvasItem, domain: Domain) -> void:
	var center_pos = domain.center_position.pixel_pos
	var color = domain.get_color()
	var outline_color = domain.get_outline_color()
	
	# Calculate domain radius based on influence
	var radius = GameConstants.HEX_SIZE * domain.influence_radius
	
	# Draw domain area (transparent fill)
	canvas.draw_circle(center_pos, radius, Color(color.r, color.g, color.b, 0.2))
	
	# Draw domain outline
	canvas.draw_arc(
		center_pos,
		radius,
		0,
		TAU,
		32,
		outline_color,
		GameConstants.DOMAIN_OUTLINE_WIDTH
	)
	
	# Draw domain name and power
	var font = ThemeDB.fallback_font
	var text = "%s\nPower: %d" % [domain.name, domain.power]
	var font_size = 14
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	
	var text_pos = center_pos - text_size / 2 + Vector2(0, -radius - 20)
	canvas.draw_string(
		font,
		text_pos,
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		font_size,
		color
	)
	
	# Draw occupation indicator if occupied
	if domain.is_occupied:
		var occupied_text = "OCCUPIED"
		var occupied_size = font.get_string_size(occupied_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		var occupied_pos = center_pos - occupied_size / 2 + Vector2(0, radius + 10)
		canvas.draw_string(
			font,
			occupied_pos,
			occupied_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			12,
			Color.RED
		)