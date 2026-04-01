# res://src/systems/movement/UnitMover.gd
extends RefCounted

static func move_unit(unit: Node2D, target_grid_pos: Vector2, grid_manager: Node2D, occupied_nodes: Array = []) -> void:
	if not is_instance_valid(unit) or not is_instance_valid(grid_manager): 
		return
	
	var snap_val = Vector2(0.1, 0.1)
	var clean_target = target_grid_pos.snapped(snap_val)
	
	for occ_pos in occupied_nodes:
		if occ_pos.snapped(snap_val) == clean_target:
			if unit.grid_pos.snapped(snap_val) != clean_target:
				push_warning("UnitMover: Movimento cancelado. Alvo ocupado por outra unidade.")
				return

	var target_world = grid_manager.to_global(clean_target)
	var final_pos = unit.get_parent().to_local(target_world) if unit.get_parent() else target_world

	# --- CÁLCULO DE DIREÇÃO DO FLIP (ANTES DE ATUALIZAR GRID_POS) ---
	if unit.has_method("set_facing_direction"):
		# Usar as coordenadas lógicas do Grid é muito mais seguro que as visuais
		if not is_equal_approx(unit.grid_pos.x, clean_target.x):
			var moves_right = clean_target.x > unit.grid_pos.x
			unit.set_facing_direction(moves_right)

	# Atualiza a posição lógica
	unit.grid_pos = clean_target

	# 3. MOVIMENTO VISUAL (Tween)
	var tween = unit.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(unit, "position", final_pos, 0.25)
	
	if unit.has_method("_on_move_completed"):
		tween.finished.connect(unit._on_move_completed)