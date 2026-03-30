# res://src/systems/movement/UnitMover.gd
extends RefCounted

static func move_unit(unit: Node2D, target_grid_pos: Vector2, grid_manager: Node2D) -> void:
	if not is_instance_valid(unit): return
	
	# REGRA DE OURO: Salva a posição no grid com snap de 0.1
	var clean_pos = target_grid_pos.snapped(Vector2(0.1, 0.1))
	unit.grid_pos = clean_pos
	
	# Converte para global e depois para o local do pai (geralmente o YSort/EntityLayer)
	var target_global = grid_manager.to_global(clean_pos)
	
	# Se a unidade tiver um pai, converte para o espaço local dele
	var target_dest = target_global
	if unit.get_parent():
		target_dest = unit.get_parent().to_local(target_global)
	
	# Tween suave para a posição visual
	var tween = unit.create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(unit, "position", target_dest, 0.3)
	
	# Opcional: Se a unidade tiver lógica própria de atualização após mover
	if unit.has_method("_on_move_completed"):
		tween.finished.connect(unit._on_move_completed)