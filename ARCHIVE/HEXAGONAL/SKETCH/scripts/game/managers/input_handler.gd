## InputHandler - Sistema de Gerenciamento de Input
## Extraído do main_game.gd para seguir princípios SOLID
## Responsabilidade única: Processar e distribuir eventos de input

class_name InputHandler
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Sinais de input
signal left_click_processed(world_position: Vector2, hex_grid_position: Vector2)
signal right_click_processed(world_position: Vector2, hex_grid_position: Vector2)
signal zoom_in_requested(world_position: Vector2)
signal zoom_out_requested(world_position: Vector2)
signal unit_clicked(unit, world_position: Vector2)
signal star_clicked(star_id: int, world_position: Vector2)
signal empty_space_clicked(world_position: Vector2)

## Referências necessárias
var hex_grid_ref: Node2D
var game_manager_ref
var star_mapper_ref
var viewport_ref: Viewport

## Estado do input
var map_initialized: bool = false
var input_cooldown: float = 0.1  # Cooldown entre inputs
var last_input_time: float = 0.0

## Configurações de input
var click_tolerance: float = 30.0
var click_width: float = 24.0
var click_height: float = 54.0

## Inicializar handler
func initialize(hex_grid: Node2D, game_manager, star_mapper, viewport: Viewport) -> void:
	hex_grid_ref = hex_grid
	game_manager_ref = game_manager
	star_mapper_ref = star_mapper
	viewport_ref = viewport
	map_initialized = true
	Logger.info("InputHandler inicializado", "InputHandler")

## Processar evento de input
func process_input_event(event: InputEvent) -> bool:
	# Input apenas se mapa estiver inicializado
	if not map_initialized:
		return false
	
	# Verificar cooldown
	if not _can_process_input():
		return false
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed:
			return _handle_mouse_button(mouse_event)
	
	return false

## Processar clique do mouse
func _handle_mouse_button(mouse_event: InputEventMouseButton) -> bool:
	var world_pos = _convert_screen_to_world(mouse_event.global_position)
	var hex_grid_pos = hex_grid_ref.to_local(world_pos)
	
	match mouse_event.button_index:
		MOUSE_BUTTON_LEFT:
			return _handle_left_click(world_pos, hex_grid_pos)
		MOUSE_BUTTON_RIGHT:
			return _handle_right_click(world_pos, hex_grid_pos)
		MOUSE_BUTTON_WHEEL_UP:
			return _handle_zoom_in(world_pos)
		MOUSE_BUTTON_WHEEL_DOWN:
			return _handle_zoom_out(world_pos)
	
	return false

## Processar clique esquerdo
func _handle_left_click(world_pos: Vector2, hex_grid_pos: Vector2) -> bool:
	Logger.debug("Clique esquerdo processado: %s" % hex_grid_pos, "InputHandler")
	
	# Verificar se clicou em uma unidade
	var clicked_unit = _get_unit_at_position(hex_grid_pos)
	if clicked_unit:
		unit_clicked.emit(clicked_unit, world_pos)
		return true
	
	# Verificar se clicou em uma estrela
	var clicked_star_id = _get_star_at_position(hex_grid_pos)
	if clicked_star_id >= 0:
		star_clicked.emit(clicked_star_id, world_pos)
		return true
	
	# Clique em espaço vazio
	empty_space_clicked.emit(world_pos)
	left_click_processed.emit(world_pos, hex_grid_pos)
	return true

## Processar clique direito
func _handle_right_click(world_pos: Vector2, hex_grid_pos: Vector2) -> bool:
	Logger.debug("Clique direito processado: %s" % hex_grid_pos, "InputHandler")
	right_click_processed.emit(world_pos, hex_grid_pos)
	return true

## Processar zoom in
func _handle_zoom_in(world_pos: Vector2) -> bool:
	Logger.debug("Zoom in solicitado: %s" % world_pos, "InputHandler")
	zoom_in_requested.emit(world_pos)
	return true

## Processar zoom out
func _handle_zoom_out(world_pos: Vector2) -> bool:
	Logger.debug("Zoom out solicitado: %s" % world_pos, "InputHandler")
	zoom_out_requested.emit(world_pos)
	return true

## Converter posição da tela para mundo
func _convert_screen_to_world(screen_pos: Vector2) -> Vector2:
	var camera = viewport_ref.get_camera_2d()
	var zoom_factor = camera.zoom.x if camera else 1.0
	var camera_pos = camera.global_position if camera else Vector2.ZERO
	
	var viewport_size = viewport_ref.get_visible_rect().size
	var screen_center = viewport_size / 2.0
	var mouse_offset = screen_pos - screen_center
	var world_offset = mouse_offset / zoom_factor
	var world_pos = camera_pos + world_offset
	
	return world_pos

## Encontrar unidade na posição
func _get_unit_at_position(position: Vector2):
	if not game_manager_ref:
		return null
	
	for unit in game_manager_ref.get_all_units():
		if unit.is_positioned():
			var unit_world_pos = unit.get_world_position()
			var unit_local_pos = hex_grid_ref.to_local(unit_world_pos)
			
			var dx = abs(position.x - unit_local_pos.x)
			var dy = abs(position.y - unit_local_pos.y)
			
			var within_bounds = (dx <= click_width / 2.0) and (dy <= click_height / 2.0)
			
			if within_bounds:
				return unit
	
	return null

## Encontrar estrela na posição
func _get_star_at_position(position: Vector2) -> int:
	if not hex_grid_ref or not star_mapper_ref:
		return -1
	
	var dot_positions = hex_grid_ref.get_dot_positions()
	var closest_star = -1
	var closest_distance = 999999.0
	
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = position.distance_to(star_pos)
		
		if distance <= click_tolerance and distance < closest_distance:
			closest_distance = distance
			closest_star = i
	
	return closest_star

## Verificar se pode processar input (cooldown)
func _can_process_input() -> bool:
	var current_time = Time.get_unix_time_from_system()
	
	# Verificar cooldown
	if current_time - last_input_time < input_cooldown:
		Logger.debug("Input ignorado (cooldown ativo)", "InputHandler")
		return false
	
	last_input_time = current_time
	return true

## Configurar tolerâncias de clique
func set_click_tolerances(tolerance: float, width: float, height: float) -> void:
	click_tolerance = tolerance
	click_width = width
	click_height = height
	Logger.debug("Tolerâncias de clique atualizadas", "InputHandler")

## Configurar cooldown de input
func set_input_cooldown(cooldown: float) -> void:
	input_cooldown = cooldown
	Logger.debug("Cooldown de input atualizado: %.3f" % cooldown, "InputHandler")

## Verificar se está inicializado
func is_initialized() -> bool:
	return map_initialized and hex_grid_ref != null and game_manager_ref != null