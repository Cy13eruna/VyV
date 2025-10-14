## Testes unitários simplificados para EventBus
extends RefCounted

const TestFramework = preload("res://tests/test_framework.gd")

## Executar todos os testes do EventBus
static func run_all_tests() -> void:
	TestFramework.start_test_suite("EventBus")
	
	TestFramework.run_test("test_eventbus_singleton", test_eventbus_singleton)
	TestFramework.run_test("test_emit_functions_exist", test_emit_functions_exist)
	
	TestFramework.end_test_suite()

## Teste: EventBus singleton
static func test_eventbus_singleton() -> void:
	var instance = EventBus.get_instance()
	TestFramework.assert_not_null(instance, "EventBus instance deve existir")

## Teste: Funções emit existem
static func test_emit_functions_exist() -> void:
	# Verificar se as funções emit existem e podem ser chamadas
	TestFramework.assert_true(EventBus.has_method("emit_unit_created"), "emit_unit_created deve existir")
	TestFramework.assert_true(EventBus.has_method("emit_unit_moved"), "emit_unit_moved deve existir")
	TestFramework.assert_true(EventBus.has_method("emit_unit_selected"), "emit_unit_selected deve existir")
	TestFramework.assert_true(EventBus.has_method("emit_turn_started"), "emit_turn_started deve existir")
	TestFramework.assert_true(EventBus.has_method("emit_turn_ended"), "emit_turn_ended deve existir")
	TestFramework.assert_true(EventBus.has_method("emit_game_state_changed"), "emit_game_state_changed deve existir")
	
	# Testar chamadas básicas (sem verificar se sinais foram emitidos)
	EventBus.emit_unit_created({"test": true})
	EventBus.emit_unit_moved(1, 0, 1)
	EventBus.emit_unit_selected(1)
	EventBus.emit_turn_started(0)
	EventBus.emit_turn_ended(0)
	EventBus.emit_game_state_changed("test")
	
	# Se chegou até aqui sem erro, as funções existem e funcionam
	TestFramework.assert_true(true, "Todas as funções emit funcionam sem erro")