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
	
	# Delegamos a lógica de seleção e movimento para o GridManager
	if main_ref.grid_manager:
		main_ref.grid_manager.handle_click(
			world_pos, 
			main_ref.vagabond_manager.active_vagabonds, 
			main_ref.turn_manager.current_player_index
		)
		
		# Após qualquer interação que mude o estado, pedimos ao Main para atualizar a visão
		main_ref._update_game_visibility.call_deferred(false)

func _handle_right_click() -> void:
	# Exemplo: Deselecionar unidade atual
	if main_ref.grid_manager:
		main_ref.grid_manager._deselect_all()
		main_ref._update_game_visibility.call_deferred(false)