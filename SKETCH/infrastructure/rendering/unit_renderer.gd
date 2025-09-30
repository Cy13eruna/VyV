# 🚶 UNIT RENDERER
# Purpose: Render game units
# Layer: Infrastructure/Rendering
# Dependencies: Core entities, VisibilityService

class_name UnitRenderer
extends RefCounted

static func render_units(canvas: CanvasItem, game_state: Dictionary, current_player_id: int) -> void:
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		if VisibilityService.is_unit_visible_to_player(
			unit, current_player_id, game_state.grid, 
			game_state.units, game_state.domains, game_state.fog_of_war_enabled
		):
			_render_unit(canvas, unit)

static func _render_unit(canvas: CanvasItem, unit: Unit) -> void:
	var position = unit.position.pixel_pos
	var color = unit.get_color()
	
	# Draw unit circle
	canvas.draw_circle(position, 15.0, color)
	
	# Draw unit emoji
	var font = ThemeDB.fallback_font
	var emoji = unit.get_emoji()
	var font_size = GameConstants.UNIT_FONT_SIZE
	var text_size = font.get_string_size(emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	
	canvas.draw_string(
		font,
		position - text_size / 2,
		emoji,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		font_size,
		Color.WHITE
	)
	
	# Draw unit name
	var name_pos = position + Vector2(0, 25)
	var name_size = font.get_string_size(unit.name, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
	canvas.draw_string(
		font,
		name_pos - name_size / 2,
		unit.name,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		12,
		color
	)

static func render_movement_targets(canvas: CanvasItem, valid_targets: Array[Position]) -> void:
	for target in valid_targets:
		canvas.draw_circle(
			target.pixel_pos,
			GameConstants.POINT_RADIUS + 2.0,
			GameConstants.HIGHLIGHT_COLOR
		)