## GameManager - Gerenciador Central Refatorado do Jogo V&V
## Versão limpa com separação de responsabilidades e sistemas especializados

class_name GameManagerRefactored
extends RefCounted

# Preload classes refatoradas
const UnitRefactored = preload("res://scripts/unit_refactored.gd")
const DomainRefactored = preload("res://scripts/domain_refactored.gd")

## Coleções de entidades organizadas
var entities: Dictionary = {
	"units": {},
	"domains": {}
}

## Sistemas especializados
var terrain_system: TerrainSystem
var input_manager: InputManager
var config: GameConfig

## Referências do sistema (injetadas)
var hex_grid_ref = null
var star_mapper_ref = null
var parent_node_ref = null
var camera_ref = null

## Estado do jogo
var current_player_id: int = 1
var game_state: String = "playing"

## Inicializar GameManager
func _init(game_config: GameConfig = null):
	config = game_config if game_config else GameConfig.get_instance()
	
	# Inicializar sistemas especializados
	terrain_system = TerrainSystem.new(config)
	input_manager = InputManager.new(config)
	
	# Conectar aos eventos do EventBus
	_connect_to_event_bus()

## Configurar referências do sistema (Dependency Injection)
func setup_references(hex_grid, star_mapper, parent_node, camera = null) -> void:
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper
	parent_node_ref = parent_node
	camera_ref = camera
	
	# Configurar sistemas especializados
	terrain_system.setup_references(hex_grid, hex_grid.cache if hex_grid else null)
	input_manager.setup_references(hex_grid, camera)
	
	EventBus.emit_info("GameManager: references configured")

## Criar nova unidade
func create_unit(star_id: int = -1, owner_id: int = -1) -> UnitRefactored:
	var unit = UnitRefactored.new(-1, config)
	unit.setup_references(hex_grid_ref, star_mapper_ref)
	unit.create_visual(parent_node_ref)
	
	# Definir proprietário
	if owner_id >= 0:
		unit.set_owner(owner_id)
	else:
		unit.set_owner(current_player_id)
	
	# Conectar sinais da entidade
	unit.entity_created.connect(_on_entity_created)
	unit.entity_destroyed.connect(_on_entity_destroyed)
	
	# Armazenar na coleção
	entities.units[unit.get_entity_id()] = unit
	
	# Posicionar se estrela especificada
	if star_id >= 0:
		unit.position_at_star(star_id)
	
	EventBus.emit_info("GameManager: unit %d created" % unit.get_entity_id())
	return unit

## Criar novo domínio
func create_domain(center_star_id: int, owner_id: int = -1) -> DomainRefactored:
	# Verificar se já existe domínio na estrela
	for domain in entities.domains.values():
		if domain.is_at_star(center_star_id):
			EventBus.emit_warning("GameManager: domain already exists at star %d" % center_star_id)
			return null
	
	var domain = DomainRefactored.new(-1, config)
	domain.setup_references(hex_grid_ref, star_mapper_ref)
	
	# Criar domínio primeiro
	if not domain.create_at_star(center_star_id, parent_node_ref):
		EventBus.emit_error("GameManager: failed to create domain at star %d" % center_star_id)
		domain.cleanup()
		return null
	
	# Verificar se compartilharia lados APÓS criação
	var existing_domains = entities.domains.values()
	if domain.would_share_sides_with_domains(existing_domains):
		EventBus.emit_warning("GameManager: domain would share sides with existing domain")
		domain.cleanup()
		return null
	
	# Conectar sinais da entidade
	domain.entity_created.connect(_on_entity_created)
	domain.entity_destroyed.connect(_on_entity_destroyed)
	
	# Definir proprietário
	if owner_id >= 0:
		domain.set_owner(owner_id)
	else:
		domain.set_owner(current_player_id)
	
	# Armazenar na coleção
	entities.domains[domain.get_entity_id()] = domain
	
	EventBus.emit_info("GameManager: domain %d created at star %d" % [domain.get_entity_id(), center_star_id])
	return domain

## Criar domínio com unidade no centro (sistema de spawn colorido)
func spawn_domain_with_unit_colored(center_star_id: int, color: Color, owner_id: int = -1) -> Dictionary:
	# Criar domínio primeiro
	var domain = create_domain(center_star_id, owner_id)
	if not domain:
		return {"success": false, "reason": "domain_creation_failed"}
	
	# Aplicar cor ao domínio
	domain.set_color(color)
	
	# Criar unidade no centro do domínio
	var unit = create_unit(center_star_id, owner_id)
	if not unit:
		EventBus.emit_warning("GameManager: failed to create unit at domain center %d" % domain.get_entity_id())
		return {"success": true, "domain": domain, "unit": null}
	
	# Aplicar cor à unidade
	unit.set_color(color)
	
	EventBus.emit_info("GameManager: colored spawn complete - domain %d with unit %d at star %d (color: %s)" % [domain.get_entity_id(), unit.get_entity_id(), center_star_id, color])
	return {"success": true, "domain": domain, "unit": unit}

## Mover unidade para estrela
func move_unit_to_star(unit: UnitRefactored, target_star_id: int) -> bool:
	if not unit or not entities.units.has(unit.get_entity_id()):
		EventBus.emit_error("GameManager: unit not found")
		return false
	
	# Verificar se movimento é válido (não bloqueado por terreno)
	if unit.is_positioned():
		var from_star_id = unit.get_current_star_id()
		if terrain_system.is_movement_blocked(from_star_id, target_star_id):
			EventBus.emit_warning("GameManager: movement blocked by terrain")
			return false
	
	return unit.move_to_star(target_star_id)

## Obter unidade na estrela
func get_unit_at_star(star_id: int) -> UnitRefactored:
	for unit in entities.units.values():
		if unit.get_current_star_id() == star_id:
			return unit
	return null

## Obter domínio na estrela
func get_domain_at_star(star_id: int) -> DomainRefactored:
	for domain in entities.domains.values():
		if domain.is_at_star(star_id):
			return domain
	return null

## Obter estrelas adjacentes válidas para unidade
func get_valid_adjacent_stars(unit: UnitRefactored) -> Array:
	if not unit.is_positioned():
		return []
	
	var from_star_id = unit.get_current_star_id()
	var dot_positions = hex_grid_ref.get_dot_positions()
	var unit_position = dot_positions[from_star_id]
	var valid_stars = []
	
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = unit_position.distance_to(star_pos)
		
		# Verificar se está dentro da distância e não é a própria estrela
		if distance > 5.0 and distance <= config.max_adjacent_distance:
			# Verificar se movimento não é bloqueado por terreno
			if not terrain_system.is_movement_blocked(from_star_id, i):
				valid_stars.append(i)
	
	return valid_stars

## Processar input do mouse
func process_mouse_input(global_pos: Vector2, button: int) -> Dictionary:
	return input_manager.process_mouse_click(global_pos, button)

## Obter todas as unidades
func get_all_units() -> Array:
	return entities.units.values()

## Obter todos os domínios
func get_all_domains() -> Array:
	return entities.domains.values()

## Obter entidade por ID
func get_entity_by_id(entity_id: int) -> IGameEntity:
	if entities.units.has(entity_id):
		return entities.units[entity_id]
	elif entities.domains.has(entity_id):
		return entities.domains[entity_id]
	return null

## Obter estatísticas do jogo
func get_game_stats() -> Dictionary:
	return {
		"total_units": entities.units.size(),
		"total_domains": entities.domains.size(),
		"current_player": current_player_id,
		"game_state": game_state,
		"terrain_system": terrain_system != null,
		"input_manager": input_manager != null
	}

## Limpar todas as entidades
func clear_all_entities() -> void:
	# Limpar unidades
	for unit in entities.units.values():
		unit.cleanup()
	entities.units.clear()
	
	# Limpar domínios
	for domain in entities.domains.values():
		domain.cleanup()
	entities.domains.clear()
	
	EventBus.emit_info("GameManager: all entities cleared")

## Conectar aos eventos do EventBus
func _connect_to_event_bus() -> void:
	if not EventBus.instance:
		return
	
	# Conectar aos eventos de sistema
	EventBus.instance.system_error.connect(_on_system_error)
	EventBus.instance.system_warning.connect(_on_system_warning)
	EventBus.instance.game_state_changed.connect(_on_game_state_changed)

## Callbacks de entidades
func _on_entity_created(entity_id: int) -> void:
	EventBus.emit_info("GameManager: entity %d created" % entity_id)

func _on_entity_destroyed(entity_id: int) -> void:
	# Remover da coleção apropriada
	if entities.units.has(entity_id):
		entities.units.erase(entity_id)
	elif entities.domains.has(entity_id):
		entities.domains.erase(entity_id)
	
	EventBus.emit_info("GameManager: entity %d destroyed and removed" % entity_id)

## Callbacks do EventBus
func _on_system_error(error_message: String) -> void:
	# Implementar lógica de tratamento de erros
	pass

func _on_system_warning(warning_message: String) -> void:
	# Implementar lógica de tratamento de avisos
	pass

func _on_game_state_changed(new_state: String) -> void:
	game_state = new_state
	EventBus.emit_info("GameManager: game state changed to %s" % new_state)