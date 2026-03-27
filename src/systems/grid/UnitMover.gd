# res://src/systems/grid/UnitMover.gd
extends RefCounted

static func move_unit(unit: Node2D, target_grid_pos: Vector2, grid_manager: Node2D) -> void:
	if not is_instance_valid(unit): return
	
	unit.grid_pos = target_grid_pos
	
	# Converte a posição do grid (local ao GridManager) para a posição local do pai da unidade
	var target_global = grid_manager.to_global(target_grid_pos)
	var target_local = unit.get_parent().to_local(target_global)
	
	var tween = unit.create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(unit, "position", target_local, 0.3)