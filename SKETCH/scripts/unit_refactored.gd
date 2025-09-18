## Unit - Entidade de Unidade Refatorada do Jogo V&V
## Versão limpa com separação de responsabilidades

class_name UnitRefactored
extends IGameEntity

## Estados possíveis da unidade
enum UnitState {
	BEM = 0,
	MAL = 1
}

## Propriedades da unidade
var current_star_id: int = -1
var state: UnitState = UnitState.BEM
var actions_remaining: int = 1
var max_actions: int = 1
var owner_id: int = -1

## Componentes
var visual_component: UnitVisualComponent
var config: GameConfig

## Referências do sistema (injetadas via dependency injection)
var hex_grid_ref = null
var star_mapper_ref = null

## Inicializar unidade
func _init(id: int = -1, game_config: GameConfig = null):
	entity_id = id if id >= 0 else randi()
	entity_type = "Unit"
	config = game_config if game_config else GameConfig.get_instance()
	
	# Criar componente visual
	visual_component = UnitVisualComponent.new(config)
	
	# Conectar sinais do componente
	visual_component.visual_created.connect(_on_visual_created)
	visual_component.visual_destroyed.connect(_on_visual_destroyed)

## Configurar referências do sistema (Dependency Injection)
func setup_references(hex_grid, star_mapper) -> void:
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper

## Criar representação visual da unidade
func create_visual(parent_node: Node) -> bool:
	var success = visual_component.create_visual(parent_node)
	if success:
		EventBus.emit_unit_created(get_info())
	return success

## Posicionar unidade em uma estrela
func position_at_star(star_id: int) -> bool:
	if not _validate_star_id(star_id):
		return false
	
	var star_position = star_mapper_ref.get_star_position(star_id)
	var global_position = hex_grid_ref.to_global(star_position)
	
	# Atualizar posição visual através do componente
	visual_component.update_position(global_position)
	
	# Atualizar estado
	var old_star_id = current_star_id
	current_star_id = star_id
	
	# Emitir eventos através do EventBus
	if old_star_id == -1:
		EventBus.instance.unit_positioned.emit(star_id)
		EventBus.emit_info("Unit %d positioned at star %d" % [entity_id, star_id])
	else:
		EventBus.emit_unit_moved(entity_id, old_star_id, star_id)
		EventBus.emit_info("Unit %d moved from star %d to %d" % [entity_id, old_star_id, star_id])
	
	return true

## Mover unidade para uma estrela
func move_to_star(target_star_id: int) -> bool:
	if current_star_id == -1:
		EventBus.emit_warning("Unit %d is not positioned" % entity_id)
		return false
	
	if actions_remaining <= 0:
		EventBus.emit_warning("Unit %d has no actions remaining" % entity_id)
		return false
	
	if not _validate_star_id(target_star_id):
		return false
	
	# Executar movimento
	if position_at_star(target_star_id):
		actions_remaining -= 1
		return true
	
	return false

## Verificar se unidade está posicionada
func is_positioned() -> bool:
	return current_star_id >= 0

## Obter posição atual
func get_current_star_id() -> int:
	return current_star_id

## Obter posição mundial atual
func get_world_position() -> Vector2:
	if not is_positioned() or not star_mapper_ref:
		return Vector2.ZERO
	
	var star_position = star_mapper_ref.get_star_position(current_star_id)
	return hex_grid_ref.to_global(star_position)

## Resetar ações da unidade
func reset_actions() -> void:
	actions_remaining = config.max_actions_per_turn
	EventBus.emit_info("Unit %d actions reset (%d/%d)" % [entity_id, actions_remaining, config.max_actions_per_turn])

## Alterar estado da unidade
func set_state(new_state: UnitState) -> void:
	if state != new_state:
		var old_state = state
		state = new_state
		_update_visual_for_state()
		EventBus.instance.unit_state_changed.emit(entity_id, new_state)
		EventBus.emit_info("Unit %d state changed from %s to %s" % [entity_id, _state_to_string(old_state), _state_to_string(new_state)])

## Definir proprietário da unidade
func set_owner(new_owner_id: int) -> void:
	owner_id = new_owner_id

## Definir cor da unidade
func set_color(new_color: Color) -> void:
	visual_component.update_color(new_color)
	EventBus.emit_info("Unit %d color changed to %s" % [entity_id, new_color])

## Implementação da interface IGameEntity
func get_info() -> Dictionary:
	return {
		"entity_id": entity_id,
		"entity_type": entity_type,
		"current_star_id": current_star_id,
		"state": state,
		"actions_remaining": actions_remaining,
		"max_actions": config.max_actions_per_turn,
		"owner_id": owner_id,
		"is_positioned": is_positioned(),
		"visual_info": visual_component.get_visual_info() if visual_component else {}
	}

func cleanup() -> void:
	if visual_component:
		visual_component.cleanup()
		visual_component = null
	
	entity_destroyed.emit(entity_id)
	EventBus.emit_info("Unit %d resources cleaned up" % entity_id)

func validate() -> bool:
	return entity_id >= 0 and config != null and visual_component != null

## Validar ID de estrela
func _validate_star_id(star_id: int) -> bool:
	if not star_mapper_ref:
		EventBus.emit_error("Unit %d: star_mapper reference not configured" % entity_id)
		return false
	
	if star_id < 0 or star_id >= star_mapper_ref.get_star_count():
		EventBus.emit_error("Unit %d: invalid star ID: %d" % [entity_id, star_id])
		return false
	
	return true

## Atualizar visual baseado no estado
func _update_visual_for_state() -> void:
	if not visual_component:
		return
	
	match state:
		UnitState.BEM:
			visual_component.update_color(Color.WHITE)
		UnitState.MAL:
			visual_component.update_color(Color.RED)

## Converter estado para string
func _state_to_string(unit_state: UnitState) -> String:
	match unit_state:
		UnitState.BEM: return "BEM"
		UnitState.MAL: return "MAL"
		_: return "UNKNOWN"

## Callbacks dos componentes
func _on_visual_created(node: Node) -> void:
	EventBus.emit_info("Unit %d visual component created" % entity_id)

func _on_visual_destroyed() -> void:
	EventBus.emit_info("Unit %d visual component destroyed" % entity_id)