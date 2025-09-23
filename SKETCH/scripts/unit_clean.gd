## Unit - Versão Ultra-Limpa
## Sistema de unidades sem logs desnecessários

class_name UnitClean
extends RefCounted

signal unit_moved(from_star_id: int, to_star_id: int)
signal unit_positioned(star_id: int)

var unit_id: int
var current_star_id: int = -1
var team_id: int = -1
var team_color: Color = Color.WHITE
var actions_remaining: int = 1
var max_actions: int = 1
var visual_node: Node2D = null

var hex_grid_ref = null
var star_mapper_ref = null

func _init():
	unit_id = randi()

func setup_references(hex_grid, star_mapper):
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper

func create_visual(parent_node: Node):
	if not parent_node:
		return false
	
	visual_node = Node2D.new()
	visual_node.z_index = 50
	visual_node.draw.connect(_draw_unit)
	parent_node.add_child(visual_node)
	
	return true

func position_at_star(star_id: int) -> bool:
	if not _is_valid_star_id(star_id):
		return false
	
	var old_star_id = current_star_id
	current_star_id = star_id
	_update_visual_position()
	
	if old_star_id >= 0:
		unit_moved.emit(old_star_id, star_id)
	else:
		unit_positioned.emit(star_id)
	
	return true

func move_to_star(target_star_id: int) -> bool:
	if not is_positioned():
		return false
	
	if actions_remaining <= 0:
		return false
	
	if not _is_valid_star_id(target_star_id):
		return false
	
	var old_star_id = current_star_id
	current_star_id = target_star_id
	actions_remaining -= 1
	
	_update_visual_position()
	unit_moved.emit(old_star_id, target_star_id)
	
	return true

func reset_actions():
	actions_remaining = max_actions

func set_state(new_state: int):
	pass

func set_color(new_color: Color):
	team_color = new_color
	if visual_node:
		visual_node.queue_redraw()

func set_team(new_team_id: int, color: Color):
	team_id = new_team_id
	team_color = color
	if visual_node:
		visual_node.queue_redraw()

func get_info() -> Dictionary:
	return {
		"unit_id": unit_id,
		"current_star_id": current_star_id,
		"team_id": team_id,
		"team_color": team_color,
		"actions_remaining": actions_remaining,
		"max_actions": max_actions
	}

func get_unit_id() -> int:
	return unit_id

func get_current_star_id() -> int:
	return current_star_id

func get_team_id() -> int:
	return team_id

func is_positioned() -> bool:
	return current_star_id >= 0

func has_actions_remaining() -> bool:
	return actions_remaining > 0

func get_actions_remaining() -> int:
	return actions_remaining

func get_world_position() -> Vector2:
	if not is_positioned() or not star_mapper_ref:
		return Vector2.ZERO
	
	var star_pos = star_mapper_ref.get_star_position(current_star_id)
	if hex_grid_ref:
		return hex_grid_ref.to_global(star_pos)
	return star_pos

func set_visual_visibility(visible: bool):
	if visual_node:
		visual_node.visible = visible

func cleanup():
	if visual_node and is_instance_valid(visual_node):
		if visual_node.get_parent():
			visual_node.get_parent().remove_child(visual_node)
		visual_node.queue_free()
		visual_node = null
	
	hex_grid_ref = null
	star_mapper_ref = null

func _is_valid_star_id(star_id: int) -> bool:
	if not star_mapper_ref:
		return false
	
	if star_id < 0 or star_id >= star_mapper_ref.get_star_count():
		return false
	
	return true

func _update_visual_position():
	if not visual_node or not is_positioned():
		return
	
	var world_pos = get_world_position()
	if hex_grid_ref:
		visual_node.position = hex_grid_ref.to_local(world_pos)
	else:
		visual_node.position = world_pos
	
	visual_node.queue_redraw()

func _draw_unit():
	if not visual_node:
		return
	
	# Desenhar emoji de unidade (círculo simples)
	visual_node.draw_circle(Vector2.ZERO, 8.0, team_color)
	visual_node.draw_circle(Vector2.ZERO, 8.0, Color.BLACK, false, 2.0)