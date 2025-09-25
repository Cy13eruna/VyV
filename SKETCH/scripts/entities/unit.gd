## Unit - Entidade de Unidade do Jogo V&V
## Representa uma unidade no tabuleiro hexagonal
## Implementa interfaces IGameEntity, IMovable, ICombatable, IOwnable

class_name Unit
extends RefCounted

# Importar sistema de logging e interfaces
const Logger = preload("res://scripts/core/logger.gd")
const ObjectPool = preload("res://scripts/core/object_pool.gd")
const ObjectFactories = preload("res://scripts/core/object_factories.gd")
const Interfaces = preload("res://scripts/core/interfaces.gd")
const NameGenerator = preload("res://scripts/core/name_generator.gd")

## Sinais da unidade
signal unit_moved(from_star_id: int, to_star_id: int)
signal unit_positioned(star_id: int)

## Estados possíveis da unidade
const BEM = 0
const MAL = 1

## Implementação das interfaces
# IGameEntity
var entity_id: String = ""
var entity_type: String = "unit"
var is_active: bool = true
var world_position: Vector2 = Vector2.ZERO
var metadata: Dictionary = {}

# IMovable
var movement_speed: float = 1.0
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false

# ICombatable
var health: int = 100
var max_health: int = 100
var can_attack: bool = true
var can_be_attacked: bool = true
var attack_damage: int = 25

# IOwnable
var owner_id: String = ""
var owner_color: Color = Color.WHITE

## Propriedades específicas da unidade
var unit_id: int = -1
var current_star_id: int = -1
var state: int = BEM
var actions_remaining: int = 1
var max_actions: int = 1

## Sistema de nomes
var unit_name: String = ""
var origin_domain_id: int = -1
var name_generator_ref = null

## Referências visuais
var visual_node: Label = null
var name_label: Label = null
var emoji_text: String = "🚶🏻‍♀️"
var font_size: int = 14
var name_font_size: int = 8

## Referências do sistema
var hex_grid_ref = null
var star_mapper_ref = null

## Inicializar unidade
func _init(id: int = -1):
	unit_id = id if id >= 0 else randi()
	entity_id = "unit_" + str(unit_id)
	entity_type = "unit"
	is_active = true
	
	# Configurar propriedades de combate baseadas no estado
	health = 100
	max_health = 100
	attack_damage = 25
	
	Logger.debug("Unidade %s inicializada" % entity_id, "Unit")

## Configurar referências do sistema
func setup_references(hex_grid, star_mapper, name_generator = null) -> bool:
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper
	name_generator_ref = name_generator
	return true

## Criar representação visual da unidade
func create_visual(parent_node: Node) -> bool:
	if visual_node:
		return true  # Já criada
	
	# Criar visual da unidade usando ObjectPool
	visual_node = ObjectPool.get_object("UnitLabel", ObjectFactories.create_unit_label)
	visual_node.text = emoji_text
	visual_node.add_theme_font_size_override("font_size", font_size)
	visual_node.z_index = 100  # Acima de tudo
	visual_node.visible = false
	
	parent_node.add_child(visual_node)
	
	# Criar label do nome
	_create_name_label(parent_node)
	
	Logger.debug("Unidade %d: visual criado" % unit_id, "Unit")
	return true

## Posicionar unidade em uma estrela
func position_at_star(star_id: int) -> bool:
	if not _validate_star_id(star_id):
		return false
	
	var star_position = star_mapper_ref.get_star_position(star_id)
	var global_position = hex_grid_ref.to_global(star_position)
	
	# Atualizar posição visual - CENTRALIZAÇÃO PRECISA
	if visual_node:
		visual_node.global_position = global_position
		# Posicionamento da unidade: centralizada horizontalmente, ainda mais para cima
		visual_node.global_position.x -= font_size * 0.5  # Centralização horizontal
		visual_node.global_position.y -= font_size * 1.1  # Ainda mais para cima no eixo Y
		visual_node.visible = true
	
	# Posicionar label do nome
	_position_name_label(global_position)
	
	# Atualizar estado
	var old_star_id = current_star_id
	current_star_id = star_id
	
	# Emitir sinais apropriados
	if old_star_id == -1:
		unit_positioned.emit(star_id)
		Logger.debug("Unidade %d posicionada na estrela %d" % [unit_id, star_id], "Unit")
	else:
		unit_moved.emit(old_star_id, star_id)
		Logger.debug("Unidade %d movida da estrela %d para %d" % [unit_id, old_star_id, star_id], "Unit")
	
	return true

## Mover unidade para uma estrela
func move_to_star(target_star_id: int) -> bool:
	if current_star_id == -1:
		Logger.warning("Unidade %d não está posicionada" % unit_id, "Unit")
		return false
	
	if actions_remaining <= 0:
		Logger.warning("Unidade %d não tem ações restantes" % unit_id, "Unit")
		return false
	
	# Verificar se domínio de origem tem poder
	if not _check_and_consume_power():
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
	actions_remaining = max_actions
	Logger.debug("Unidade %d (%s): ações resetadas (%d/%d)" % [unit_id, unit_name, actions_remaining, max_actions], "Unit")

## Alterar estado da unidade
func set_state(new_state: int) -> void:
	if state != new_state:
		var old_state = state
		state = new_state
		_update_visual_for_state()
		Logger.debug("Unidade %d (%s): estado alterado de %s para %s" % [unit_id, unit_name, _state_to_string(old_state), _state_to_string(new_state)], "Unit")

## Definir cor da unidade
func set_color(new_color: Color) -> void:
	owner_color = new_color
	if visual_node:
		visual_node.modulate = new_color
	# Atualizar cor do nome
	_update_name_label_color()
	Logger.debug("Unidade %d (%s): cor alterada para %s" % [unit_id, unit_name, new_color], "Unit")

## Obter informações da unidade
func get_info() -> Dictionary:
	return {
		"unit_id": unit_id,
		"unit_name": unit_name,
		"origin_domain_id": origin_domain_id,
		"current_star_id": current_star_id,
		"state": state,
		"actions_remaining": actions_remaining,
		"max_actions": max_actions,
		"is_positioned": is_positioned(),
		"can_act": can_act()
	}

## Limpar recursos
func cleanup() -> void:
	if visual_node and is_instance_valid(visual_node):
		# Remover do parent
		if visual_node.get_parent():
			visual_node.get_parent().remove_child(visual_node)
		
		# Retornar ao pool
		ObjectPool.return_object("UnitLabel", visual_node)
		visual_node = null
	
	# Limpar label do nome
	if name_label and is_instance_valid(name_label):
		if name_label.get_parent():
			name_label.get_parent().remove_child(name_label)
		ObjectPool.return_object("UnitLabel", name_label)
		name_label = null
	
	Logger.debug("Unidade %d: recursos limpos e retornados ao ObjectPool" % unit_id, "Unit")

## Validar ID de estrela
func _validate_star_id(star_id: int) -> bool:
	if not star_mapper_ref:
		Logger.error("Unidade %d: referência do star_mapper não configurada" % unit_id, "Unit")
		return false
	
	if star_id < 0 or star_id >= star_mapper_ref.get_star_count():
		Logger.error("Unidade %d: ID de estrela inválido: %d" % [unit_id, star_id], "Unit")
		return false
	
	return true

## Atualizar visual baseado no estado
func _update_visual_for_state() -> void:
	if not visual_node:
		return
	
	match state:
		BEM:
			visual_node.modulate = Color.WHITE
		MAL:
			visual_node.modulate = Color.RED

## Converter estado para string
func _state_to_string(unit_state: int) -> String:
	match unit_state:
		BEM:
			return "BEM"
		MAL:
			return "MAL"
		_:
			return "UNKNOWN"

# ================================================================
# IMPLEMENTAÇÃO DAS INTERFACES
# ================================================================

## IGameEntity - Inicializar entidade com dados básicos
func initialize(id: String, type: String, position: Vector2) -> bool:
	entity_id = id
	entity_type = type
	world_position = position
	is_active = true
	Logger.debug("Entidade %s (%s) inicializada em %s" % [id, type, position], "Unit")
	return true

## IGameEntity - Atualizar entidade
func update(delta: float) -> void:
	if not is_active:
		return
	
	# Atualizar movimento se necessário
	update_movement(delta)
	
	# Atualizar posição mundial baseada na estrela atual
	if current_star_id >= 0 and star_mapper_ref:
		var star_pos = star_mapper_ref.get_star_position(current_star_id)
		world_position = hex_grid_ref.to_global(star_pos)

## IGameEntity - Validar estado da entidade
func validate() -> bool:
	if entity_id.is_empty():
		Logger.error("Unidade sem ID válido", "Unit")
		return false
	if entity_type.is_empty():
		Logger.error("Unidade sem tipo válido", "Unit")
		return false
	return true

## IGameEntity - Serializar entidade
func serialize() -> Dictionary:
	return {
		"entity_id": entity_id,
		"entity_type": entity_type,
		"is_active": is_active,
		"world_position": world_position,
		"metadata": metadata,
		"unit_id": unit_id,
		"unit_name": unit_name,
		"origin_domain_id": origin_domain_id,
		"current_star_id": current_star_id,
		"state": state,
		"actions_remaining": actions_remaining,
		"health": health,
		"owner_id": owner_id,
		"owner_color": var_to_str(owner_color)
	}

## IGameEntity - Deserializar entidade
func deserialize(data: Dictionary) -> bool:
	if not data.has("entity_id") or not data.has("entity_type"):
		Logger.error("Dados de deserialização inválidos", "Unit")
		return false
	
	entity_id = data.get("entity_id", "")
	entity_type = data.get("entity_type", "")
	is_active = data.get("is_active", true)
	world_position = data.get("world_position", Vector2.ZERO)
	metadata = data.get("metadata", {})
	unit_id = data.get("unit_id", -1)
	unit_name = data.get("unit_name", "")
	origin_domain_id = data.get("origin_domain_id", -1)
	current_star_id = data.get("current_star_id", -1)
	state = data.get("state", BEM)
	actions_remaining = data.get("actions_remaining", 1)
	health = data.get("health", 100)
	owner_id = data.get("owner_id", "")
	
	if data.has("owner_color"):
		owner_color = str_to_var(data.get("owner_color"))
	
	return validate()

## IMovable - Mover para posição específica
func move_to(position: Vector2) -> bool:
	if not is_active:
		return false
	
	target_position = position
	is_moving = true
	Logger.debug("Unidade %s movendo para %s" % [entity_id, position], "Unit")
	return true

## IMovable - Parar movimento
func stop_movement() -> void:
	is_moving = false
	target_position = world_position
	Logger.debug("Unidade %s parou movimento" % entity_id, "Unit")

## IMovable - Verificar se pode mover para posição
func can_move_to(position: Vector2) -> bool:
	return is_active and actions_remaining > 0

## IMovable - Atualizar movimento
func update_movement(delta: float) -> void:
	if not is_moving:
		return
	
	var distance = world_position.distance_to(target_position)
	if distance < 1.0:  # Chegou ao destino
		world_position = target_position
		stop_movement()
		return
	
	# Mover em direção ao alvo
	var direction = (target_position - world_position).normalized()
	world_position += direction * movement_speed * delta

## ICombatable - Receber dano
func take_damage(damage: int, attacker_id: String = "") -> bool:
	if not can_be_attacked or not is_active:
		return false
	
	health = max(0, health - damage)
	Logger.debug("Unidade %s recebeu %d de dano de %s (HP: %d/%d)" % [entity_id, damage, attacker_id, health, max_health], "Unit")
	
	if health <= 0:
		_on_death()
	
	return true

## ICombatable - Atacar outra entidade
func attack(target) -> bool:
	if not can_attack or not is_active:
		return false
	
	if not target or not target.has_method("take_damage"):
		return false
	
	Logger.debug("Unidade %s atacando %s" % [entity_id, target.entity_id], "Unit")
	return target.take_damage(attack_damage, entity_id)

## ICombatable - Curar entidade
func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	Logger.debug("Unidade %s curada em %d (HP: %d/%d)" % [entity_id, amount, health, max_health], "Unit")

## ICombatable - Verificar se está viva
func is_alive() -> bool:
	return health > 0 and is_active

## ICombatable - Callback quando morre
func _on_death() -> void:
	is_active = false
	state = MAL  # Unidade morta fica em estado MAL
	_update_visual_for_state()
	Logger.info("Unidade %s morreu" % entity_id, "Unit")

## IOwnable - Definir proprietário
func set_owner(player_id: String, color: Color = Color.WHITE) -> void:
	owner_id = player_id
	owner_color = color
	set_color(color)  # Atualizar cor visual (inclui nome)
	Logger.debug("Unidade %s agora pertence ao jogador %s" % [entity_id, player_id], "Unit")

## IOwnable - Verificar se pertence a um jogador
func belongs_to(player_id: String) -> bool:
	return owner_id == player_id

## IOwnable - Verificar se tem proprietário
func has_owner() -> bool:
	return not owner_id.is_empty()

# ================================================================
# SISTEMA DE NOMES
# ================================================================

## Definir domínio de origem e gerar nome
func set_origin_domain(domain_id: int) -> void:
	origin_domain_id = domain_id
	
	# Gerar nome automaticamente se name_generator disponível
	if name_generator_ref and unit_name.is_empty():
		_generate_unit_name()
	
	Logger.info("Unidade %d vinculada ao domínio %d" % [unit_id, domain_id], "Unit")

## Gerar nome para a unidade baseado no domínio de origem
func _generate_unit_name() -> void:
	if not name_generator_ref:
		Logger.warning("NameGenerator não disponível para unidade %d" % unit_id, "Unit")
		return
	
	if origin_domain_id == -1:
		Logger.warning("Unidade %d não tem domínio de origem definido" % unit_id, "Unit")
		return
	
	var name_data = name_generator_ref.generate_unit_name(unit_id, origin_domain_id)
	unit_name = name_data.name
	
	# Atualizar label se já existe
	_update_name_label_text()
	
	Logger.info("Unidade %d nomeada: %s (inicial %s)" % [unit_id, unit_name, name_data.domain_initial], "Unit")

## Obter nome da unidade
func get_unit_name() -> String:
	return unit_name

## Obter domínio de origem
func get_origin_domain_id() -> int:
	return origin_domain_id

## Verificar se unidade tem nome
func has_name() -> bool:
	return not unit_name.is_empty()

## Definir nome manualmente (para casos especiais)
func set_unit_name(name: String) -> void:
	unit_name = name
	# Atualizar label se já existe
	_update_name_label_text()
	Logger.info("Unidade %d nome definido manualmente: %s" % [unit_id, unit_name], "Unit")

## Obter inicial da unidade (baseada no domínio)
func get_unit_initial() -> String:
	if not name_generator_ref or origin_domain_id == -1:
		return "?"
	
	return name_generator_ref.get_unit_initial(unit_id)

## Validar relacionamento com domínio
func validate_domain_relationship() -> bool:
	if not name_generator_ref or origin_domain_id == -1:
		return false
	
	return name_generator_ref.validate_unit_domain_relationship(unit_id, origin_domain_id)

## Verificar e consumir poder do domínio de origem
func _check_and_consume_power() -> bool:
	if origin_domain_id == -1:
		Logger.warning("Unidade %d não tem domínio de origem definido" % unit_id, "Unit")
		return false
	
	# Encontrar domínio de origem (precisamos de referência ao GameManager)
	# Por enquanto, vamos assumir que o sistema de poder será verificado externamente
	# Esta função será chamada pelo GameManager que tem acesso aos domínios
	return true

## Verificar se pode agir (tem ações e domínio tem poder)
func can_act() -> bool:
	return actions_remaining > 0 and origin_domain_id != -1

## Obter ID do domínio de origem para verificação externa de poder
func get_origin_domain_for_power_check() -> int:
	return origin_domain_id

# ================================================================
# SISTEMA DE RENDERIZAÇÃO DE NOMES
# ================================================================

## Criar label do nome da unidade
func _create_name_label(parent_node: Node) -> void:
	if not unit_name.is_empty():
		# Criar label usando ObjectPool
		name_label = ObjectPool.get_object("UnitLabel", ObjectFactories.create_unit_label)
		name_label.text = unit_name
		name_label.add_theme_font_size_override("font_size", name_font_size)
		name_label.z_index = 110  # Acima da unidade
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.visible = false  # Inicialmente invisível
		
		# Melhorar qualidade da renderização
		name_label.clip_contents = false
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		
		# Aplicar cor do team
		_update_name_label_color()
		
		parent_node.add_child(name_label)
		Logger.debug("Label do nome criado para unidade %s" % unit_name, "Unit")

## Posicionar label do nome
func _position_name_label(star_global_position: Vector2) -> void:
	if not name_label:
		return
	
	# Posicionar na parte inferior da unidade
	name_label.global_position = star_global_position
	name_label.global_position.x -= name_label.size.x * 0.5  # Centralizar horizontalmente
	name_label.global_position.y += 8  # Bem próximo da unidade
	name_label.visible = true

## Atualizar cor do label do nome
func _update_name_label_color() -> void:
	if name_label:
		name_label.modulate = owner_color

## Atualizar nome no label
func _update_name_label_text() -> void:
	if name_label and not unit_name.is_empty():
		name_label.text = unit_name
		# Reposicionar se a unidade já está posicionada
		if current_star_id >= 0 and star_mapper_ref and hex_grid_ref:
			var star_position = star_mapper_ref.get_star_position(current_star_id)
			var global_position = hex_grid_ref.to_global(star_position)
			_position_name_label(global_position)