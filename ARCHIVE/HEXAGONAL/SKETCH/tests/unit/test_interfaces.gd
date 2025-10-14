## Testes para o sistema de interfaces
## Valida implementação das interfaces nas entidades

extends RefCounted

const TestFramework = preload("res://tests/test_framework.gd")
const Interfaces = preload("res://scripts/core/interfaces.gd")
const Unit = preload("res://scripts/entities/unit.gd")
const Domain = preload("res://scripts/entities/domain.gd")
const Logger = preload("res://scripts/core/logger.gd")

## Executar todos os testes de interfaces
static func run_tests() -> Dictionary:
	var framework = TestFramework.new()
	
	# Testes de validação de interfaces
	framework.add_test("test_interface_validator", test_interface_validator)
	framework.add_test("test_unit_implements_interfaces", test_unit_implements_interfaces)
	framework.add_test("test_domain_implements_interfaces", test_domain_implements_interfaces)
	
	# Testes de funcionalidade das interfaces
	framework.add_test("test_unit_game_entity_interface", test_unit_game_entity_interface)
	framework.add_test("test_unit_movable_interface", test_unit_movable_interface)
	framework.add_test("test_unit_combatable_interface", test_unit_combatable_interface)
	framework.add_test("test_unit_ownable_interface", test_unit_ownable_interface)
	
	framework.add_test("test_domain_game_entity_interface", test_domain_game_entity_interface)
	framework.add_test("test_domain_resource_producer_interface", test_domain_resource_producer_interface)
	framework.add_test("test_domain_ownable_interface", test_domain_ownable_interface)
	
	# Testes de serialização
	framework.add_test("test_unit_serialization", test_unit_serialization)
	framework.add_test("test_domain_serialization", test_domain_serialization)
	
	return framework.run_all_tests()

## Testar validador de interfaces
static func test_interface_validator() -> bool:
	var unit = Unit.new(1)
	
	# Testar validação de IGameEntity
	var is_valid = Interfaces.InterfaceValidator.validate_interface(unit, "IGameEntity")
	if not is_valid:
		Logger.error("Unit não passou na validação de IGameEntity", "TestInterfaces")
		return false
	
	# Testar validação de IMovable
	is_valid = Interfaces.InterfaceValidator.validate_interface(unit, "IMovable")
	if not is_valid:
		Logger.error("Unit não passou na validação de IMovable", "TestInterfaces")
		return false
	
	# Testar validação de ICombatable
	is_valid = Interfaces.InterfaceValidator.validate_interface(unit, "ICombatable")
	if not is_valid:
		Logger.error("Unit não passou na validação de ICombatable", "TestInterfaces")
		return false
	
	# Testar validação de IOwnable
	is_valid = Interfaces.InterfaceValidator.validate_interface(unit, "IOwnable")
	if not is_valid:
		Logger.error("Unit não passou na validação de IOwnable", "TestInterfaces")
		return false
	
	Logger.debug("Validador de interfaces funcionando corretamente", "TestInterfaces")
	return true

## Testar se Unit implementa todas as interfaces
static func test_unit_implements_interfaces() -> bool:
	var unit = Unit.new(1)
	
	# Verificar propriedades de IGameEntity
	if not unit.has_method("initialize") or not unit.has_method("update") or not unit.has_method("validate"):
		Logger.error("Unit não implementa métodos de IGameEntity", "TestInterfaces")
		return false
	
	# Verificar propriedades de IMovable
	if not unit.has_method("move_to") or not unit.has_method("stop_movement"):
		Logger.error("Unit não implementa métodos de IMovable", "TestInterfaces")
		return false
	
	# Verificar propriedades de ICombatable
	if not unit.has_method("take_damage") or not unit.has_method("attack") or not unit.has_method("heal"):
		Logger.error("Unit não implementa métodos de ICombatable", "TestInterfaces")
		return false
	
	# Verificar propriedades de IOwnable
	if not unit.has_method("set_owner") or not unit.has_method("belongs_to"):
		Logger.error("Unit não implementa métodos de IOwnable", "TestInterfaces")
		return false
	
	Logger.debug("Unit implementa todas as interfaces corretamente", "TestInterfaces")
	return true

## Testar se Domain implementa todas as interfaces
static func test_domain_implements_interfaces() -> bool:
	var domain = Domain.new(1)
	
	# Verificar propriedades de IGameEntity
	if not domain.has_method("initialize") or not domain.has_method("update") or not domain.has_method("validate"):
		Logger.error("Domain não implementa métodos de IGameEntity", "TestInterfaces")
		return false
	
	# Verificar propriedades de IResourceProducer
	if not domain.has_method("produce_resources") or not domain.has_method("collect_resources"):
		Logger.error("Domain não implementa métodos de IResourceProducer", "TestInterfaces")
		return false
	
	# Verificar propriedades de IOwnable
	if not domain.has_method("set_owner") or not domain.has_method("belongs_to"):
		Logger.error("Domain não implementa métodos de IOwnable", "TestInterfaces")
		return false
	
	Logger.debug("Domain implementa todas as interfaces corretamente", "TestInterfaces")
	return true

## Testar interface IGameEntity na Unit
static func test_unit_game_entity_interface() -> bool:
	var unit = Unit.new(1)
	
	# Testar inicialização
	var init_result = unit.initialize("test_unit", "unit", Vector2(100, 200))
	if not init_result:
		Logger.error("Falha na inicialização da Unit", "TestInterfaces")
		return false
	
	# Verificar propriedades
	if unit.entity_id != "test_unit" or unit.entity_type != "unit":
		Logger.error("Propriedades de entidade não configuradas corretamente", "TestInterfaces")
		return false
	
	# Testar validação
	if not unit.validate():
		Logger.error("Validação da Unit falhou", "TestInterfaces")
		return false
	
	# Testar serialização
	var serialized = unit.serialize()
	if not serialized.has("entity_id") or serialized.entity_id != "test_unit":
		Logger.error("Serialização da Unit falhou", "TestInterfaces")
		return false
	
	Logger.debug("Interface IGameEntity da Unit funcionando corretamente", "TestInterfaces")
	return true

## Testar interface IMovable na Unit
static func test_unit_movable_interface() -> bool:
	var unit = Unit.new(1)
	
	# Testar movimento
	var move_result = unit.move_to(Vector2(300, 400))
	if not move_result:
		Logger.error("Falha no movimento da Unit", "TestInterfaces")
		return false
	
	# Verificar estado de movimento
	if not unit.is_moving or unit.target_position != Vector2(300, 400):
		Logger.error("Estado de movimento não configurado corretamente", "TestInterfaces")
		return false
	
	# Testar parada de movimento
	unit.stop_movement()
	if unit.is_moving:
		Logger.error("Movimento não foi parado corretamente", "TestInterfaces")
		return false
	
	Logger.debug("Interface IMovable da Unit funcionando corretamente", "TestInterfaces")
	return true

## Testar interface ICombatable na Unit
static func test_unit_combatable_interface() -> bool:
	var unit1 = Unit.new(1)
	var unit2 = Unit.new(2)
	
	# Testar dano
	var initial_health = unit1.health
	var damage_result = unit1.take_damage(25, "test_attacker")
	if not damage_result or unit1.health != initial_health - 25:
		Logger.error("Sistema de dano não funcionando corretamente", "TestInterfaces")
		return false
	
	# Testar cura
	unit1.heal(10)
	if unit1.health != initial_health - 15:
		Logger.error("Sistema de cura não funcionando corretamente", "TestInterfaces")
		return false
	
	# Testar ataque
	var attack_result = unit1.attack(unit2)
	if not attack_result:
		Logger.error("Sistema de ataque não funcionando corretamente", "TestInterfaces")
		return false
	
	# Testar se está viva
	if not unit1.is_alive():
		Logger.error("Unit deveria estar viva", "TestInterfaces")
		return false
	
	Logger.debug("Interface ICombatable da Unit funcionando corretamente", "TestInterfaces")
	return true

## Testar interface IOwnable na Unit
static func test_unit_ownable_interface() -> bool:
	var unit = Unit.new(1)
	
	# Testar definição de proprietário
	unit.set_owner("player1", Color.BLUE)
	if unit.owner_id != "player1" or unit.owner_color != Color.BLUE:
		Logger.error("Proprietário não definido corretamente", "TestInterfaces")
		return false
	
	# Testar verificação de pertencimento
	if not unit.belongs_to("player1"):
		Logger.error("Verificação de pertencimento falhou", "TestInterfaces")
		return false
	
	if unit.belongs_to("player2"):
		Logger.error("Verificação de pertencimento retornou falso positivo", "TestInterfaces")
		return false
	
	# Testar verificação de ter proprietário
	if not unit.has_owner():
		Logger.error("Unit deveria ter proprietário", "TestInterfaces")
		return false
	
	Logger.debug("Interface IOwnable da Unit funcionando corretamente", "TestInterfaces")
	return true

## Testar interface IGameEntity no Domain
static func test_domain_game_entity_interface() -> bool:
	var domain = Domain.new(1)
	
	# Testar inicialização
	var init_result = domain.initialize("test_domain", "domain", Vector2(500, 600))
	if not init_result:
		Logger.error("Falha na inicialização do Domain", "TestInterfaces")
		return false
	
	# Verificar propriedades
	if domain.entity_id != "test_domain" or domain.entity_type != "domain":
		Logger.error("Propriedades de entidade do Domain não configuradas corretamente", "TestInterfaces")
		return false
	
	# Testar validação
	if not domain.validate():
		Logger.error("Validação do Domain falhou", "TestInterfaces")
		return false
	
	Logger.debug("Interface IGameEntity do Domain funcionando corretamente", "TestInterfaces")
	return true

## Testar interface IResourceProducer no Domain
static func test_domain_resource_producer_interface() -> bool:
	var domain = Domain.new(1)
	
	# Testar produção de recursos
	var initial_stored = domain.stored_resources
	var produced = domain.produce_resources()
	if produced != domain.production_rate or domain.stored_resources != initial_stored + produced:
		Logger.error("Produção de recursos não funcionando corretamente", "TestInterfaces")
		return false
	
	# Testar coleta de recursos
	var collected = domain.collect_resources()
	if collected != initial_stored + produced or domain.stored_resources != 0:
		Logger.error("Coleta de recursos não funcionando corretamente", "TestInterfaces")
		return false
	
	# Testar verificação de capacidade de produção
	if not domain.can_produce():
		Logger.error("Domain deveria poder produzir recursos", "TestInterfaces")
		return false
	
	Logger.debug("Interface IResourceProducer do Domain funcionando corretamente", "TestInterfaces")
	return true

## Testar interface IOwnable no Domain
static func test_domain_ownable_interface() -> bool:
	var domain = Domain.new(1)
	
	# Testar definição de proprietário
	domain.set_owner("player2", Color.RED)
	if domain.owner_id != "player2" or domain.owner_color != Color.RED:
		Logger.error("Proprietário do Domain não definido corretamente", "TestInterfaces")
		return false
	
	# Testar verificação de pertencimento
	if not domain.belongs_to("player2"):
		Logger.error("Verificação de pertencimento do Domain falhou", "TestInterfaces")
		return false
	
	# Testar verificação de ter proprietário
	if not domain.has_owner():
		Logger.error("Domain deveria ter proprietário", "TestInterfaces")
		return false
	
	Logger.debug("Interface IOwnable do Domain funcionando corretamente", "TestInterfaces")
	return true

## Testar serialização da Unit
static func test_unit_serialization() -> bool:
	var unit = Unit.new(1)
	unit.initialize("test_unit", "unit", Vector2(100, 200))
	unit.set_owner("player1", Color.BLUE)
	unit.health = 75
	
	# Serializar
	var serialized = unit.serialize()
	
	# Criar nova unit e deserializar
	var new_unit = Unit.new(2)
	var deserialize_result = new_unit.deserialize(serialized)
	
	if not deserialize_result:
		Logger.error("Falha na deserialização da Unit", "TestInterfaces")
		return false
	
	# Verificar dados
	if new_unit.entity_id != "test_unit" or new_unit.health != 75 or new_unit.owner_id != "player1":
		Logger.error("Dados da Unit não foram deserializados corretamente", "TestInterfaces")
		return false
	
	Logger.debug("Serialização da Unit funcionando corretamente", "TestInterfaces")
	return true

## Testar serialização do Domain
static func test_domain_serialization() -> bool:
	var domain = Domain.new(1)
	domain.initialize("test_domain", "domain", Vector2(500, 600))
	domain.set_owner("player2", Color.RED)
	domain.stored_resources = 5
	
	# Serializar
	var serialized = domain.serialize()
	
	# Criar novo domain e deserializar
	var new_domain = Domain.new(2)
	var deserialize_result = new_domain.deserialize(serialized)
	
	if not deserialize_result:
		Logger.error("Falha na deserialização do Domain", "TestInterfaces")
		return false
	
	# Verificar dados
	if new_domain.entity_id != "test_domain" or new_domain.stored_resources != 5 or new_domain.owner_id != "player2":
		Logger.error("Dados do Domain não foram deserializados corretamente", "TestInterfaces")
		return false
	
	Logger.debug("Serialização do Domain funcionando corretamente", "TestInterfaces")
	return true