# 🚶 UNIT RENDERER (CLEAN)
# Purpose: Professional unit rendering with animations and effects
# Layer: Infrastructure/Rendering
# Dependencies: Clean entities

extends RefCounted

# Rendering configuration
const UNIT_RADIUS = 18.0
const SELECTION_RADIUS = 25.0
const HOVER_RADIUS = 22.0
const ACTION_INDICATOR_SIZE = 8.0

const COLOR_SELECTION = Color.YELLOW
const COLOR_HOVER = Color(1, 1, 1, 0.5)  # White with transparency
const COLOR_NO_ACTIONS = Color(0.5, 0.5, 0.5, 0.8)  # Gray overlay

# Render all units
static func render_units(canvas: CanvasItem, units_data: Dictionary, selected_unit_id: int = -1, hover_state: Dictionary = {}, font = null) -> void:
	if units_data.is_empty():
		return
	
	# Render units in order (selected unit last for proper layering)
	var units_to_render = []
	var selected_unit = null
	
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if unit_id == selected_unit_id:
			selected_unit = unit
		else:
			units_to_render.append(unit)
	
	# Render non-selected units first
	for unit in units_to_render:
		_render_single_unit(canvas, unit, false, hover_state, font)
	
	# Render selected unit last (on top)
	if selected_unit:
		_render_single_unit(canvas, selected_unit, true, hover_state, font)

# Render single unit with all effects
static func _render_single_unit(canvas: CanvasItem, unit, is_selected: bool, hover_state: Dictionary, font) -> void:
	var position = unit.position.pixel_pos
	var color = unit.get_color()
	
	# Draw selection highlight
	if is_selected:
		canvas.draw_circle(position, SELECTION_RADIUS, COLOR_SELECTION)
	
	# Draw hover effect
	if "hovered_unit_id" in hover_state and hover_state.hovered_unit_id == unit.id:
		canvas.draw_circle(position, HOVER_RADIUS, COLOR_HOVER)
	
	# Draw unit base
	canvas.draw_circle(position, UNIT_RADIUS, color)
	
	# Draw unit outline
	canvas.draw_arc(position, UNIT_RADIUS + 1, 0, TAU, 32, Color.WHITE, 2.0)
	
	# Draw no actions overlay
	if not unit.can_move():
		canvas.draw_circle(position, UNIT_RADIUS, COLOR_NO_ACTIONS)
	
	# Draw unit emoji
	if font:
		var emoji = unit.get_emoji()
		var text_size = font.get_string_size(emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
		canvas.draw_string(font, position - text_size/2, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.WHITE)
	
	# Draw action indicators
	_render_action_indicators(canvas, unit, position)
	
	# Draw unit info
	if font:
		_render_unit_info(canvas, unit, position, font, is_selected)

# Render action indicators (dots showing remaining actions)
static func _render_action_indicators(canvas: CanvasItem, unit, center_position: Vector2) -> void:
	var max_actions = 1  # Current max actions per turn
	var current_actions = unit.actions_remaining
	
	# Position indicators below the unit
	var indicator_y = center_position.y + UNIT_RADIUS + 15
	var total_width = max_actions * ACTION_INDICATOR_SIZE + (max_actions - 1) * 2
	var start_x = center_position.x - total_width / 2
	
	for i in range(max_actions):
		var indicator_x = start_x + i * (ACTION_INDICATOR_SIZE + 2)
		var indicator_pos = Vector2(indicator_x, indicator_y)
		
		var color = Color.GREEN if i < current_actions else Color.DARK_GRAY
		canvas.draw_circle(indicator_pos, ACTION_INDICATOR_SIZE / 2, color)

# Render unit information text
static func _render_unit_info(canvas: CanvasItem, unit, center_position: Vector2, font, is_selected: bool) -> void:
	if not is_selected:
		return  # Only show info for selected unit
	
	var info_lines = [
		unit.name,
		"Actions: %d" % unit.actions_remaining,
		"Owner: Player %d" % unit.owner_id
	]
	
	var info_position = center_position + Vector2(-30, 35)
	
	for i in range(info_lines.size()):
		var line = info_lines[i]
		var y_offset = i * 14
		var color = Color.WHITE if i == 0 else Color.LIGHT_GRAY
		
		# Draw text background for better readability
		var text_size = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		var bg_rect = Rect2(info_position + Vector2(-2, y_offset - 10), text_size + Vector2(4, 2))
		canvas.draw_rect(bg_rect, Color(0, 0, 0, 0.7))
		
		canvas.draw_string(font, info_position + Vector2(0, y_offset), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)

# Render movement targets
static func render_movement_targets(canvas: CanvasItem, targets: Array, font = null) -> void:
	if targets.is_empty():
		return
	
	for i in range(targets.size()):
		var target = targets[i]
		var position = target.pixel_pos
		
		# Draw target indicator
		canvas.draw_circle(position, 12.0, Color.MAGENTA)
		canvas.draw_arc(position, 12.0, 0, TAU, 32, Color.WHITE, 2.0)
		
		# Draw target number
		if font:
			var number = str(i + 1)
			var text_size = font.get_string_size(number, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
			canvas.draw_string(font, position - text_size/2, number, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)

# Render units with fog of war
static func render_units_with_fog(canvas: CanvasItem, units_data: Dictionary, visible_units: Array, selected_unit_id: int = -1, hover_state: Dictionary = {}, font = null) -> void:
	# Only render visible units
	var visible_units_data = {}
	
	for unit_id in visible_units:
		if unit_id in units_data:
			visible_units_data[unit_id] = units_data[unit_id]
	
	render_units(canvas, visible_units_data, selected_unit_id, hover_state, font)

# Render unit path (for future pathfinding visualization)
static func render_unit_path(canvas: CanvasItem, path: Array, color: Color = Color.CYAN) -> void:
	if path.size() < 2:
		return
	
	for i in range(path.size() - 1):
		var from_pos = path[i].pixel_pos
		var to_pos = path[i + 1].pixel_pos
		
		# Draw path line
		canvas.draw_line(from_pos, to_pos, color, 3.0)
		
		# Draw direction arrow
		var direction = (to_pos - from_pos).normalized()
		var arrow_size = 8.0
		var arrow_angle = PI / 6  # 30 degrees
		
		var arrow_left = to_pos - direction.rotated(arrow_angle) * arrow_size
		var arrow_right = to_pos - direction.rotated(-arrow_angle) * arrow_size
		
		canvas.draw_line(to_pos, arrow_left, color, 2.0)
		canvas.draw_line(to_pos, arrow_right, color, 2.0)

# Get unit rendering bounds (for culling)
static func get_unit_bounds(unit) -> Rect2:
	var position = unit.position.pixel_pos
	var size = SELECTION_RADIUS * 2
	return Rect2(position - Vector2(size/2, size/2), Vector2(size, size))