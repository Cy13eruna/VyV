# res://src/systems/movement/UnitMover.gd
extends RefCounted

static func move_unit(unit: Node2D, target_grid_pos: Vector2, grid_manager: Node2D) -> void:
	if not is_instance_valid(unit) or not is_instance_valid(grid_manager): 
		return
	
	# 1. SINCRONIZAÇÃO LÓGICA IMEDIATA
	# Arredondamos para 0.1 para garantir que o DomainManager e o Pathfinder 
	# reconheçam esta posição exatamente no próximo frame.
	var clean_grid_pos = target_grid_pos.snapped(Vector2(0.1, 0.1))
	unit.grid_pos = clean_grid_pos
	
	# 2. CONVERSÃO DE COORDENADAS (Espaço de Tela/Mundo)
	# O segredo aqui é converter a posição do GRID para a posição LOCAL do pai da unidade.
	var target_world = grid_manager.to_global(clean_grid_pos)
	var final_pos = unit.get_parent().to_local(target_world) if unit.get_parent() else target_world

	# 3. MOVIMENTO VISUAL (Tween)
	# Cancelamos qualquer movimento anterior para evitar "tremedeira"
	var tween = unit.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(unit, "position", final_pos, 0.25)
	
	# 4. NOTIFICAÇÃO DE CONCLUSÃO
	# Importante: se a unidade atualizar sua própria visão/nevoa, deve ser APÓS o snap.
	if unit.has_method("_on_move_completed"):
		tween.finished.connect(unit._on_move_completed)