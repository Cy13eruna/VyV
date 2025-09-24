## GameController - Controlador Principal do Jogo
## Extraído do main_game.gd para seguir princípios SOLID
## Responsabilidade única: Orquestrar todos os sistemas do jogo

class_name GameController
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")
const ObjectPool = preload("res://scripts/core/object_pool.gd")
const ObjectFactories = preload("res://scripts/core/object_factories.gd")

# Importar managers
const TurnManager = preload("res://scripts/game/managers/turn_manager.gd")
const InputHandler = preload("res://scripts/game/managers/input_handler.gd")
const UIManager = preload("res://scripts/game/managers/ui_manager.gd")

## Sinais do controlador
signal game_initialized()
signal game_started()
signal game_ended()
signal system_error(error_message: String)

## Managers do sistema
var turn_manager: TurnManager
var input_handler: InputHandler
var ui_manager: UIManager

## Referências dos sistemas principais
var hex_grid_ref: Node2D
var star_mapper_ref
var game_manager_ref
var parent_node_ref: Node2D

## Estado do controlador
var is_initialized: bool = false
var is_game_active: bool = false

## Sistema de movimentação de unidades
var selected_unit = null
var movement_mode_active: bool = false
var highlighted_stars: Array = []
var valid_movement_stars: Array = []

## Inicializar controlador
func initialize(parent_node: Node2D, hex_grid: Node2D, star_mapper, game_manager) -> void:
	parent_node_ref = parent_node
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper
	game_manager_ref = game_manager
	
	# Criar managers
	turn_manager = TurnManager.new()
	input_handler = InputHandler.new()
	ui_manager = UIManager.new()
	
	# Inicializar managers
	turn_manager.initialize()
	input_handler.initialize(hex_grid, game_manager, star_mapper, parent_node.get_viewport())
	ui_manager.initialize(parent_node)
	
	# Conectar sinais dos managers
	_connect_manager_signals()
	
	is_initialized = true
	game_initialized.emit()
	Logger.info("GameController inicializado", "GameController")

## Conectar sinais dos managers
func _connect_manager_signals() -> void:
	# Sinais do TurnManager
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.turn_ended.connect(_on_turn_ended)
	turn_manager.team_changed.connect(_on_team_changed)
	turn_manager.game_started.connect(_on_game_started)
	turn_manager.game_ended.connect(_on_game_ended)
	
	# Conectar ao EventBus para comunicação global
	EventBus.game_state_changed.connect(_on_global_game_state_changed)
	EventBus.system_error.connect(_on_system_error)
	
	# Sinais do InputHandler
	input_handler.left_click_processed.connect(_on_left_click_processed)
	input_handler.unit_clicked.connect(_on_unit_clicked)
	input_handler.star_clicked.connect(_on_star_clicked)
	input_handler.empty_space_clicked.connect(_on_empty_space_clicked)
	input_handler.zoom_in_requested.connect(_on_zoom_in_requested)
	input_handler.zoom_out_requested.connect(_on_zoom_out_requested)
	
	# Sinais do UIManager
	ui_manager.next_turn_requested.connect(_on_next_turn_requested)
	
	Logger.debug("Sinais dos managers conectados", "GameController")

## Configurar sistema de turnos
func setup_turn_system(all_units: Array, all_domains: Array) -> void:
	if not is_initialized:
		Logger.error("Tentativa de configurar turnos sem inicialização", "GameController")
		return
	
	turn_manager.setup_teams(all_units, all_domains)
	Logger.info("Sistema de turnos configurado", "GameController")

## Iniciar jogo
func start_game() -> void:
	if not is_initialized:
		Logger.error("Tentativa de iniciar jogo sem inicialização", "GameController")
		return
	
	turn_manager.start_game()
	is_game_active = true
	game_started.emit()
	Logger.info("Jogo iniciado pelo GameController", "GameController")

## Processar input
func process_input(event: InputEvent) -> bool:
	if not is_initialized or not input_handler:
		return false
	
	return input_handler.process_input_event(event)

## Callbacks dos managers

## Callbacks do TurnManager
func _on_turn_started(team_index: int, turn_number: int) -> void:
	var team_info = turn_manager.get_current_team()
	ui_manager.update_turn_button(team_info)
	_deactivate_movement_mode()
	
	# Emitir evento global via EventBus
	EventBus.emit_turn_started(team_index)
	EventBus.emit_game_state_changed("turn_started")
	
	Logger.debug("Turno iniciado: Team %d, Turno %d" % [team_index, turn_number], "GameController")

func _on_turn_ended(team_index: int, turn_number: int) -> void:
	_deactivate_movement_mode()
	
	# Emitir evento global via EventBus
	EventBus.emit_turn_ended(team_index)
	
	Logger.debug("Turno finalizado: Team %d, Turno %d" % [team_index, turn_number], "GameController")

func _on_team_changed(old_team_index: int, new_team_index: int) -> void:
	Logger.debug("Team mudou: %d -> %d" % [old_team_index, new_team_index], "GameController")

func _on_game_started() -> void:
	# Emitir evento global via EventBus
	EventBus.emit_game_state_changed("game_started")
	
	Logger.info("Jogo iniciado (sinal do TurnManager)", "GameController")

func _on_game_ended() -> void:
	is_game_active = false
	game_ended.emit()
	
	# Emitir evento global via EventBus
	EventBus.emit_game_state_changed("game_ended")
	
	Logger.info("Jogo finalizado", "GameController")

## Callbacks do InputHandler
func _on_left_click_processed(world_position: Vector2, hex_grid_position: Vector2) -> void:
	Logger.debug("Clique esquerdo processado", "GameController")

func _on_unit_clicked(unit, world_position: Vector2) -> void:
	# Verificar se unidade pertence ao team atual
	if not turn_manager.is_unit_from_current_team(unit):
		Logger.warning("Unidade não pertence ao team atual", "GameController")
		return
	
	# Emitir evento via EventBus
	EventBus.emit_unit_selected(unit.get_info().unit_id)
	
	_handle_unit_click(unit)

func _on_star_clicked(star_id: int, world_position: Vector2) -> void:
	# Emitir evento via EventBus
	EventBus.emit_star_clicked(star_id, MOUSE_BUTTON_LEFT)
	
	if movement_mode_active and selected_unit and star_id in valid_movement_stars:
		# Verificar se unidade pode agir
		if not turn_manager.can_unit_act(selected_unit):
			Logger.warning("Unidade já usou sua ação neste turno", "GameController")
			return
		
		# Verificar se estrela está ocupada
		var occupying_unit = game_manager_ref.get_unit_at_star(star_id)
		if occupying_unit and occupying_unit != selected_unit:
			return
		
		# Executar movimento
		_move_selected_unit_to_star(star_id)
	else:
		_deactivate_movement_mode()

func _on_empty_space_clicked(world_position: Vector2) -> void:
	if movement_mode_active:
		_deactivate_movement_mode()

func _on_zoom_in_requested(world_position: Vector2) -> void:
	_handle_zoom(true, world_position)

func _on_zoom_out_requested(world_position: Vector2) -> void:
	_handle_zoom(false, world_position)

## Callbacks do UIManager
func _on_next_turn_requested() -> void:
	if is_game_active:
		turn_manager.next_turn()

## Callbacks do EventBus
func _on_global_game_state_changed(new_state: String) -> void:
	Logger.debug("Estado global do jogo mudou: %s" % new_state, "GameController")

func _on_system_error(error_message: String) -> void:
	Logger.error("Erro do sistema via EventBus: %s" % error_message, "GameController")
	system_error.emit(error_message)

## Sistema de movimentação de unidades

## Processar clique em unidade
func _handle_unit_click(unit) -> void:
	if selected_unit == unit:
		_deactivate_movement_mode()
	else:
		_activate_movement_mode(unit)

## Ativar modo de movimento
func _activate_movement_mode(unit) -> void:
	# Verificar se unidade pode agir
	if not turn_manager.can_unit_act(unit):
		Logger.warning("Unidade não pode agir neste turno", "GameController")
		return
	
	# Desativar modo anterior se ativo
	if movement_mode_active:
		_deactivate_movement_mode()
	
	selected_unit = unit
	movement_mode_active = true
	
	# Emitir evento de seleção via EventBus
	EventBus.emit_unit_selected(unit.get_info().unit_id)
	
	# Obter estrelas válidas para movimento
	var adjacent_stars = game_manager_ref.get_valid_adjacent_stars(unit)
	
	# Filtrar estrelas ocupadas
	valid_movement_stars = []
	for star_id in adjacent_stars:
		var occupying_unit = game_manager_ref.get_unit_at_star(star_id)
		if not occupying_unit or occupying_unit == unit:
			valid_movement_stars.append(star_id)
	
	# Destacar estrelas válidas
	_highlight_movement_stars(unit.visual_node.modulate)
	
	Logger.debug("Modo de movimento ativado para unidade", "GameController")

## Desativar modo de movimento
func _deactivate_movement_mode() -> void:
	# Emitir evento de desseleção via EventBus se havia unidade selecionada
	if selected_unit:
		EventBus.emit_unit_deselected(selected_unit.get_info().unit_id)
	
	selected_unit = null
	movement_mode_active = false
	valid_movement_stars.clear()
	_clear_star_highlights()
	Logger.debug("Modo de movimento desativado", "GameController")

## Mover unidade selecionada
func _move_selected_unit_to_star(target_star_id: int) -> void:
	if not selected_unit:
		return
	
	# Verificar se unidade pode agir
	if not turn_manager.can_unit_act(selected_unit):
		return
	
	# Tentar movimento
	var old_star_id = selected_unit.current_star_id
	if game_manager_ref.move_unit_to_star(selected_unit, target_star_id):
		# Emitir evento de movimento via EventBus
		EventBus.emit_unit_moved(selected_unit.get_info().unit_id, old_star_id, target_star_id)
		
		Logger.debug("Unidade movida! Ações restantes: %d" % selected_unit.actions_remaining, "GameController")
		
		# Remover highlights se não tem mais ações
		if selected_unit.actions_remaining <= 0:
			_deactivate_movement_mode()
		else:
			# Atualizar highlights se ainda tem ações
			var adjacent_stars = game_manager_ref.get_valid_adjacent_stars(selected_unit)
			valid_movement_stars = []
			for star_id in adjacent_stars:
				var occupying_unit = game_manager_ref.get_unit_at_star(star_id)
				if not occupying_unit or occupying_unit == selected_unit:
					valid_movement_stars.append(star_id)
			_highlight_movement_stars(selected_unit.visual_node.modulate)

## Sistema de highlights usando ObjectPool
func _highlight_movement_stars(unit_color: Color) -> void:
	_clear_star_highlights()
	
	var dot_positions = hex_grid_ref.get_dot_positions()
	
	for star_id in valid_movement_stars:
		if star_id < dot_positions.size():
			var star_pos = dot_positions[star_id]
			_create_colored_star_highlight(star_pos, unit_color)
	
	Logger.debug("Highlights de movimento atualizados com ObjectPool", "GameController")

## Criar highlight usando ObjectPool
func _create_colored_star_highlight(position: Vector2, color: Color) -> void:
	var highlight_node = ObjectPool.get_object("HighlightNode", ObjectFactories.create_highlight_node)
	highlight_node.position = position
	highlight_node.modulate = color
	
	# Conectar função de desenho
	highlight_node.draw.connect(_draw_colored_star.bind(highlight_node, color))
	
	hex_grid_ref.add_child(highlight_node)
	highlighted_stars.append(highlight_node)
	
	highlight_node.queue_redraw()

## Desenhar estrela colorida
func _draw_colored_star(canvas_item: CanvasItem, color: Color) -> void:
	var outer_radius = 6.0
	var inner_radius = 3.0
	var points = PackedVector2Array()
	
	for i in range(12):
		var angle_deg = 30.0 * i
		var angle_rad = deg_to_rad(angle_deg)
		var radius = outer_radius if i % 2 == 0 else inner_radius
		var point = Vector2(cos(angle_rad), sin(angle_rad)) * radius
		points.append(point)
	
	canvas_item.draw_colored_polygon(points, color)

func _clear_star_highlights() -> void:
	for highlight in highlighted_stars:
		if is_instance_valid(highlight):
			# Desconectar sinais antes de retornar ao pool
			if highlight.draw.is_connected(_draw_colored_star):
				highlight.draw.disconnect(_draw_colored_star)
			
			# Remover do parent
			if highlight.get_parent():
				highlight.get_parent().remove_child(highlight)
			
			# Retornar ao pool
			ObjectPool.return_object("HighlightNode", highlight)
	
	highlighted_stars.clear()
	Logger.debug("Highlights limpos e retornados ao ObjectPool", "GameController")

## Sistema de zoom (placeholder)
func _handle_zoom(zoom_in: bool, world_position: Vector2) -> void:
	# TODO: Implementar sistema de zoom otimizado
	Logger.debug("Zoom %s solicitado" % ("in" if zoom_in else "out"), "GameController")

## Obter informações do estado atual
func get_game_state() -> Dictionary:
	return {
		"initialized": is_initialized,
		"game_active": is_game_active,
		"turn_info": turn_manager.get_turn_info() if turn_manager else {},
		"movement_mode": movement_mode_active,
		"selected_unit": selected_unit != null,
		"valid_movement_stars": valid_movement_stars.size()
	}

## Limpeza de recursos
func cleanup() -> void:
	if ui_manager:
		ui_manager.cleanup()
	
	_clear_star_highlights()
	
	turn_manager = null
	input_handler = null
	ui_manager = null
	
	is_initialized = false
	is_game_active = false
	
	Logger.info("GameController limpo", "GameController")