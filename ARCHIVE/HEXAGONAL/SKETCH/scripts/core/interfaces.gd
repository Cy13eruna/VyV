## Interfaces - Sistema de contratos para entidades do jogo
## Define contratos que todas as entidades devem implementar
## Garante consistência e permite polimorfismo

class_name Interfaces
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Interface base para todas as entidades do jogo
class IGameEntity:
	## ID único da entidade
	var entity_id: String
	
	## Tipo da entidade (unit, domain, structure, etc.)
	var entity_type: String
	
	## Estado ativo/inativo
	var is_active: bool = true
	
	## Posição no mundo do jogo
	var world_position: Vector2
	
	## Metadados da entidade
	var metadata: Dictionary = {}
	
	## Inicializar entidade com dados básicos
	func initialize(id: String, type: String, position: Vector2) -> bool:
		entity_id = id
		entity_type = type
		world_position = position
		is_active = true
		Logger.debug("Entidade %s (%s) inicializada em %s" % [id, type, position], "IGameEntity")
		return true
	
	## Atualizar entidade (chamado a cada frame se necessário)
	func update(delta: float) -> void:
		# Override em classes filhas
		pass
	
	## Cleanup da entidade
	func cleanup() -> void:
		is_active = false
		metadata.clear()
		Logger.debug("Entidade %s limpa" % entity_id, "IGameEntity")
	
	## Obter informações da entidade
	func get_info() -> Dictionary:
		return {
			"entity_id": entity_id,
			"entity_type": entity_type,
			"is_active": is_active,
			"world_position": world_position,
			"metadata": metadata
		}
	
	## Validar estado da entidade
	func validate() -> bool:
		if entity_id.is_empty():
			Logger.error("Entidade sem ID válido", "IGameEntity")
			return false
		if entity_type.is_empty():
			Logger.error("Entidade sem tipo válido", "IGameEntity")
			return false
		return true
	
	## Serializar entidade para save/load
	func serialize() -> Dictionary:
		return get_info()
	
	## Deserializar entidade de save/load
	func deserialize(data: Dictionary) -> bool:
		if not data.has("entity_id") or not data.has("entity_type"):
			Logger.error("Dados de deserialização inválidos", "IGameEntity")
			return false
		
		entity_id = data.get("entity_id", "")
		entity_type = data.get("entity_type", "")
		is_active = data.get("is_active", true)
		world_position = data.get("world_position", Vector2.ZERO)
		metadata = data.get("metadata", {})
		
		return validate()

## Interface para entidades que podem se mover
class IMovable extends IGameEntity:
	## Velocidade de movimento
	var movement_speed: float = 1.0
	
	## Destino atual do movimento
	var target_position: Vector2
	
	## Se está em movimento
	var is_moving: bool = false
	
	## Mover para posição específica
	func move_to(position: Vector2) -> bool:
		if not is_active:
			return false
		
		target_position = position
		is_moving = true
		Logger.debug("Entidade %s movendo para %s" % [entity_id, position], "IMovable")
		return true
	
	## Parar movimento
	func stop_movement() -> void:
		is_moving = false
		target_position = world_position
		Logger.debug("Entidade %s parou movimento" % entity_id, "IMovable")
	
	## Verificar se pode mover para posição
	func can_move_to(position: Vector2) -> bool:
		# Override em classes filhas para validações específicas
		return is_active
	
	## Atualizar movimento
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

## Interface para entidades que podem ser atacadas
class ICombatable extends IGameEntity:
	## Pontos de vida/saúde
	var health: int = 100
	
	## Saúde máxima
	var max_health: int = 100
	
	## Se pode atacar outras entidades
	var can_attack: bool = true
	
	## Se pode ser atacada
	var can_be_attacked: bool = true
	
	## Dano que causa
	var attack_damage: int = 10
	
	## Receber dano
	func take_damage(damage: int, attacker_id: String = "") -> bool:
		if not can_be_attacked or not is_active:
			return false
		
		health = max(0, health - damage)
		Logger.debug("Entidade %s recebeu %d de dano de %s (HP: %d/%d)" % [entity_id, damage, attacker_id, health, max_health], "ICombatable")
		
		if health <= 0:
			_on_death()
		
		return true
	
	## Atacar outra entidade
	func attack(target: ICombatable) -> bool:
		if not can_attack or not is_active:
			return false
		
		if not target or not target.can_be_attacked:
			return false
		
		Logger.debug("Entidade %s atacando %s" % [entity_id, target.entity_id], "ICombatable")
		return target.take_damage(attack_damage, entity_id)
	
	## Curar entidade
	func heal(amount: int) -> void:
		health = min(max_health, health + amount)
		Logger.debug("Entidade %s curada em %d (HP: %d/%d)" % [entity_id, amount, health, max_health], "ICombatable")
	
	## Verificar se está viva
	func is_alive() -> bool:
		return health > 0 and is_active
	
	## Callback quando morre
	func _on_death() -> void:
		is_active = false
		Logger.info("Entidade %s morreu" % entity_id, "ICombatable")

## Interface para entidades que produzem recursos
class IResourceProducer extends IGameEntity:
	## Tipo de recurso produzido
	var resource_type: String = "power"
	
	## Quantidade produzida por turno
	var production_rate: int = 1
	
	## Recursos acumulados
	var stored_resources: int = 0
	
	## Capacidade máxima de armazenamento
	var storage_capacity: int = 10
	
	## Produzir recursos
	func produce_resources() -> int:
		if not is_active:
			return 0
		
		var produced = production_rate
		stored_resources = min(storage_capacity, stored_resources + produced)
		
		Logger.debug("Entidade %s produziu %d %s (total: %d/%d)" % [entity_id, produced, resource_type, stored_resources, storage_capacity], "IResourceProducer")
		return produced
	
	## Coletar recursos armazenados
	func collect_resources() -> int:
		var collected = stored_resources
		stored_resources = 0
		Logger.debug("Entidade %s coletou %d %s" % [entity_id, collected, resource_type], "IResourceProducer")
		return collected
	
	## Verificar se pode produzir
	func can_produce() -> bool:
		return is_active and stored_resources < storage_capacity

## Interface para entidades que têm proprietário
class IOwnable extends IGameEntity:
	## ID do jogador proprietário
	var owner_id: String = ""
	
	## Cor do proprietário
	var owner_color: Color = Color.WHITE
	
	## Definir proprietário
	func set_owner(player_id: String, color: Color = Color.WHITE) -> void:
		owner_id = player_id
		owner_color = color
		Logger.debug("Entidade %s agora pertence ao jogador %s" % [entity_id, player_id], "IOwnable")
	
	## Verificar se pertence a um jogador
	func belongs_to(player_id: String) -> bool:
		return owner_id == player_id
	
	## Verificar se tem proprietário
	func has_owner() -> bool:
		return not owner_id.is_empty()

## Validador de interfaces
class InterfaceValidator:
	## Validar se objeto implementa interface corretamente
	static func validate_interface(obj: Object, interface_name: String) -> bool:
		match interface_name:
			"IGameEntity":
				return _validate_game_entity(obj)
			"IMovable":
				return _validate_movable(obj)
			"ICombatable":
				return _validate_combatable(obj)
			"IResourceProducer":
				return _validate_resource_producer(obj)
			"IOwnable":
				return _validate_ownable(obj)
			_:
				Logger.error("Interface desconhecida: %s" % interface_name, "InterfaceValidator")
				return false
	
	static func _validate_game_entity(obj: Object) -> bool:
		var required_methods = ["initialize", "update", "cleanup", "get_info", "validate", "serialize", "deserialize"]
		var required_properties = ["entity_id", "entity_type", "is_active", "world_position", "metadata"]
		
		for method in required_methods:
			if not obj.has_method(method):
				Logger.error("Objeto não implementa método %s da interface IGameEntity" % method, "InterfaceValidator")
				return false
		
		for prop in required_properties:
			if not obj.has_method("get") or not obj.get(prop) != null:
				Logger.warning("Objeto pode não ter propriedade %s da interface IGameEntity" % prop, "InterfaceValidator")
		
		return true
	
	static func _validate_movable(obj: Object) -> bool:
		if not _validate_game_entity(obj):
			return false
		
		var required_methods = ["move_to", "stop_movement", "can_move_to", "update_movement"]
		for method in required_methods:
			if not obj.has_method(method):
				Logger.error("Objeto não implementa método %s da interface IMovable" % method, "InterfaceValidator")
				return false
		
		return true
	
	static func _validate_combatable(obj: Object) -> bool:
		if not _validate_game_entity(obj):
			return false
		
		var required_methods = ["take_damage", "attack", "heal", "is_alive"]
		for method in required_methods:
			if not obj.has_method(method):
				Logger.error("Objeto não implementa método %s da interface ICombatable" % method, "InterfaceValidator")
				return false
		
		return true
	
	static func _validate_resource_producer(obj: Object) -> bool:
		if not _validate_game_entity(obj):
			return false
		
		var required_methods = ["produce_resources", "collect_resources", "can_produce"]
		for method in required_methods:
			if not obj.has_method(method):
				Logger.error("Objeto não implementa método %s da interface IResourceProducer" % method, "InterfaceValidator")
				return false
		
		return true
	
	static func _validate_ownable(obj: Object) -> bool:
		if not _validate_game_entity(obj):
			return false
		
		var required_methods = ["set_owner", "belongs_to", "has_owner"]
		for method in required_methods:
			if not obj.has_method(method):
				Logger.error("Objeto não implementa método %s da interface IOwnable" % method, "InterfaceValidator")
				return false
		
		return true