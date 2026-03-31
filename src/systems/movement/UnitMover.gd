# res://src/systems/movement/UnitMover.gd
extends RefCounted

static func move_unit(unit: Node2D, target_grid_pos: Vector2, grid_manager: Node2D, occupied_nodes: Array = []) -> void:
	if not is_instance_valid(unit) or not is_instance_valid(grid_manager): 
		return
	
	# 0. VERIFICAÇÃO DE OCUPAÇÃO (SEGURANÇA FINAL)
	var snap_val = Vector2(0.1, 0.1)
	var clean_target = target_grid_pos.snapped(snap_val)
	
	# Se o destino já estiver ocupado por OUTRA unidade, cancelamos o movimento.
	for occ_pos in occupied_nodes:
		if occ_pos.snapped(snap_val) == clean_target:
			# Se a posição ocupada não for a posição ATUAL da própria unidade, bloqueia.
			if unit.grid_pos.snapped(snap_val) != clean_target:
				push_warning("UnitMover: Movimento cancelado. Alvo ocupado por outra unidade.")
				return

	# 1. SINCRONIZAÇÃO LÓGICA IMEDIATA
	# Atualizamos o grid_pos antes da animação para que o Pathfinder/Visibility 
	# já considerem a unidade no novo lugar.
	unit.grid_pos = clean_target
	
	# 2. CONVERSÃO DE COORDENADAS
	var target_world = grid_manager.to_global(clean_target)
	var final_pos = unit.get_parent().to_local(target_world) if unit.get_parent() else target_world

	# 3. MOVIMENTO VISUAL (Tween)
	# Usamos kill() para garantir que movimentos rápidos não se sobreponham
	var tween = unit.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(unit, "position", final_pos, 0.25)
	
	# 4. NOTIFICAÇÃO DE CONCLUSÃO
	if unit.has_method("_on_move_completed"):
		tween.finished.connect(unit._on_move_completed)