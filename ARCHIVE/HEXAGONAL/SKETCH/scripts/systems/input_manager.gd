## InputManager - Gerenciador de input centralizado
## Separa lógica de input da lógica de jogo

class_name InputManager
extends RefCounted

## Configuração
var config: GameConfig
var hex_grid_ref
var camera_ref

## Estado do input
var is_processing_input: bool = true
var last_click_time: float = 0.0
var click_cooldown: float = 0.1

## Inicializar
func _init(game_config: GameConfig = null):
	config = game_config if game_config else GameConfig.get_instance()

## Configurar referências
func setup_references(hex_grid, camera) -> void:
	hex_grid_ref = hex_grid
	camera_ref = camera

## Processar clique do mouse
func process_mouse_click(global_pos: Vector2, button: int) -> Dictionary:
	if not _can_process_input():
		return {"valid": false, "reason": "cooldown"}
	
	var world_pos = _convert_screen_to_world(global_pos)
	var hex_grid_pos = hex_grid_ref.to_local(world_pos)
	var star_id = _get_star_at_position(hex_grid_pos)
	
	var result = {
		"valid": star_id >= 0,
		"star_id": star_id,
		"world_pos": world_pos,
		"hex_grid_pos": hex_grid_pos,
		"button": button
	}
	
	if result.valid:
		EventBus.emit_info("Star clicked: %d" % star_id)
		EventBus.instance.star_clicked.emit(star_id, button)
	
	last_click_time = Time.get_time_dict_from_system().unix
	return result

## Verificar se pode processar input
func _can_process_input() -> bool:
	if not is_processing_input:
		return false
	
	var current_time = Time.get_time_dict_from_system().unix
	return (current_time - last_click_time) >= click_cooldown

## Converter coordenadas de tela para mundo
func _convert_screen_to_world(screen_pos: Vector2) -> Vector2:
	var zoom_factor = camera_ref.zoom.x if camera_ref else 1.0
	var camera_pos = camera_ref.global_position if camera_ref else Vector2.ZERO
	
	var viewport_size = hex_grid_ref.get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2.0
	var mouse_offset = screen_pos - screen_center
	var world_offset = mouse_offset / zoom_factor
	
	return camera_pos + world_offset

## Encontrar estrela na posição
func _get_star_at_position(position: Vector2) -> int:
	var dot_positions = hex_grid_ref.get_dot_positions()
	var closest_star = -1
	var closest_distance = 999999.0
	
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = position.distance_to(star_pos)
		
		if distance <= config.click_tolerance and distance < closest_distance:
			closest_distance = distance
			closest_star = i
	
	return closest_star

## Habilitar/desabilitar processamento de input
func set_input_processing(enabled: bool) -> void:
	is_processing_input = enabled