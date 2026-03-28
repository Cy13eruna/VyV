# res://src/systems/input/InputHandler.gd
extends RefCounted

var main_ref: Node

func _init(p_main: Node) -> void:
    main_ref = p_main

## Processa cliques e gestos do mouse/touch
func handle_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        match event.button_index:
            MOUSE_BUTTON_LEFT:
                _handle_left_click()
            MOUSE_BUTTON_RIGHT:
                _handle_right_click()

func _handle_left_click() -> void:
    var world_pos = main_ref.world.get_global_mouse_position()
    
    if main_ref.grid_manager:
        # 1. Filtramos os vagabonds para enviar apenas aqueles que podem agir.
        # Isso impede que o GridManager selecione unidades exauridas.
        var eligible_vagabonds = []
        for v in main_ref.vagabond_manager.active_vagabonds:
            # Só enviamos para o processamento de clique se tiver AP > 0
            if is_instance_valid(v) and v.has_method("has_ap") and v.has_ap():
                eligible_vagabonds.append(v)
        
        # 2. Passamos apenas a lista filtrada
        main_ref.grid_manager.handle_click(
            world_pos, 
            eligible_vagabonds, 
            main_ref.turn_manager.current_player_index
        )
        
        # Após qualquer interação que mude o estado, pedimos ao Main para atualizar a visão
        main_ref._update_game_visibility.call_deferred(false)

func _handle_right_click() -> void:
    # Exemplo: Deselecionar unidade atual
    if main_ref.grid_manager:
        main_ref.grid_manager._deselect_all()
        main_ref._update_game_visibility.call_deferred(false)