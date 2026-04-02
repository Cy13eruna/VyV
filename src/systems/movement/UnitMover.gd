# res://src/systems/movement/UnitMover.gd
extends RefCounted

static func move_unit(unit: Node2D, target_grid_pos: Vector2, grid_manager: Node2D, occupied_nodes: Array = []) -> bool:
    if not is_instance_valid(unit) or not is_instance_valid(grid_manager): 
        return false
    
    var snap_val = Vector2(0.1, 0.1)
    var clean_target = target_grid_pos.snapped(snap_val)
    
    # 1. VERIFICAÇÃO DE OCUPAÇÃO
    for occ_pos in occupied_nodes:
        if occ_pos.snapped(snap_val) == clean_target:
            if unit.get("grid_pos").snapped(snap_val) != clean_target:
                return false # Falhou: Alvo ocupado

    # 2. CÁLCULO DE POSIÇÃO
    var target_world = grid_manager.to_global(clean_target)
    var final_pos = unit.get_parent().to_local(target_world) if unit.get_parent() else target_world

    # 3. DIREÇÃO (FLIP)
    if unit.has_method("set_facing_direction"):
        if not is_equal_approx(unit.grid_pos.x, clean_target.x):
            var moves_right = clean_target.x > unit.grid_pos.x
            unit.set_facing_direction(moves_right)

    # 4. ATUALIZAÇÃO LÓGICA E VISUAL
    unit.grid_pos = clean_target
    var tween = unit.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tween.tween_property(unit, "position", final_pos, 0.25)
    
    if unit.has_method("_on_move_completed"):
        tween.finished.connect(unit._on_move_completed)

    # --- A MUDANÇA CRUCIAL ---
    # Avisamos ao motor que este clique foi consumido pelo movimento
    unit.get_viewport().set_input_as_handled()
    return true