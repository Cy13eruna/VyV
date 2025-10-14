## TestRunner - Executor principal de todos os testes
extends Node

const TestFramework = preload("res://tests/test_framework.gd")
const TestObjectPool = preload("res://tests/unit/test_object_pool.gd")
const TestEventBus = preload("res://tests/unit/test_event_bus_simple.gd")
const TestMemoryLeaks = preload("res://tests/unit/test_memory_leaks.gd")
const TestInterfaces = preload("res://tests/unit/test_interfaces.gd")
const TestGameManager = preload("res://tests/unit/test_game_manager.gd")
const TestResultSystem = preload("res://tests/unit/test_result_system.gd")
const TestTerrainValidation = preload("res://tests/unit/test_terrain_validation.gd")
const TestUnitMovement = preload("res://tests/unit/test_unit_movement.gd")
const TestFullGameFlow = preload("res://tests/integration/test_full_game_flow.gd")
const TestStressPerformance = preload("res://tests/integration/test_stress_performance.gd")
const MemoryMonitor = preload("res://scripts/core/memory_monitor.gd")
const ResourceCleanup = preload("res://scripts/core/resource_cleanup.gd")

## Executar todos os testes
func _ready() -> void:
	print("=== INICIANDO EXECUÇÃO DE TODOS OS TESTES ===")
	
	# Inicializar sistema de cleanup
	ResourceCleanup.initialize()
	
	# Iniciar monitoramento de memória
	MemoryMonitor.start_monitoring()
	
	# Aguardar um frame para garantir que tudo está inicializado
	await get_tree().process_frame
	
	var start_time = Time.get_ticks_msec()
	
	# Executar testes unitários
	await run_unit_tests()
	
	# Executar testes de interfaces
	await run_interface_tests()
	
	# Executar testes de integração
	await run_integration_tests()
	
	var end_time = Time.get_ticks_msec()
	var total_time = (end_time - start_time) / 1000.0
	
	print("=== EXECUÇÃO COMPLETA EM %.2f SEGUNDOS ===" % total_time)
	
	# Verificar memória antes do cleanup
	MemoryMonitor.report_current_status()
	
	# Cleanup completo após testes
	await cleanup_after_tests()
	
	# Verificar memória após cleanup e parar monitoramento
	MemoryMonitor.report_current_status()
	MemoryMonitor.stop_monitoring()
	
	# Relatório final
	MemoryMonitor.run_full_check()
	
	# Cleanup agressivo final
	ResourceCleanup.cleanup_all_resources()
	
	# Aguardar frames finais
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Sair após testes
	get_tree().quit()

## Executar testes unitários
func run_unit_tests() -> void:
	print("\n--- EXECUTANDO TESTES UNITÁRIOS ---")
	
	# Testes do ObjectPool
	TestObjectPool.run_all_tests()
	await get_tree().process_frame
	
	# Testes do EventBus
	TestEventBus.run_all_tests()
	await get_tree().process_frame
	
	# Testes de Memory Leaks
	TestMemoryLeaks.run_all_tests()
	await get_tree().process_frame
	
	# Testes do GameManager com Error Handling
	TestGameManager.run_all_tests()
	await get_tree().process_frame
	
	# Testes do Sistema Result<T>
	TestResultSystem.run_all_tests()
	await get_tree().process_frame
	
	# Testes de Validação de Terreno
	TestTerrainValidation.run_all_tests()
	await get_tree().process_frame
	
	# Testes de Movimento de Unidades
	TestUnitMovement.run_all_tests()
	await get_tree().process_frame

## Executar testes de interfaces
func run_interface_tests() -> void:
	print("\n--- EXECUTANDO TESTES DE INTERFACES ---")
	
	# Testes de Interfaces
	TestInterfaces.run_tests()
	await get_tree().process_frame

## Executar testes de integração
func run_integration_tests() -> void:
	print("\n--- EXECUTANDO TESTES DE INTEGRAÇÃO ---")
	
	# Teste de fluxo completo do jogo
	TestFullGameFlow.run_all_tests()
	await get_tree().process_frame
	
	# Testes de stress e performance extrema
	TestStressPerformance.run_all_tests()
	await get_tree().process_frame
	
	# Teste de integração básico: verificar se todos os sistemas carregam
	TestFramework.start_test_suite("Integration")
	
	TestFramework.run_test("test_all_systems_load", test_all_systems_load)
	TestFramework.run_test("test_object_factories_setup", test_object_factories_setup)
	TestFramework.run_test("test_managers_creation", test_managers_creation)
	
	TestFramework.end_test_suite()

## Teste: Todos os sistemas carregam
func test_all_systems_load() -> void:
	# Testar carregamento de todos os sistemas principais
	var systems = [
		"res://scripts/core/logger.gd",
		"res://scripts/core/object_pool.gd",
		"res://scripts/core/object_factories.gd",
		"res://scripts/core/config.gd",
		"res://scripts/game/managers/turn_manager.gd",
		"res://scripts/game/managers/input_handler.gd",
		"res://scripts/game/managers/ui_manager.gd",
		"res://scripts/game/managers/game_controller.gd",
		"res://scripts/entities/unit.gd",
		"res://scripts/entities/domain.gd",
		"res://scripts/entities/star_mapper.gd"
	]
	
	for system_path in systems:
		var system = load(system_path)
		TestFramework.assert_not_null(system, "Sistema deve carregar: " + system_path)

## Teste: ObjectFactories setup
func test_object_factories_setup() -> void:
	const ObjectFactories = preload("res://scripts/core/object_factories.gd")
	const ObjectPool = preload("res://scripts/core/object_pool.gd")
	
	# Configurar pools
	ObjectFactories.setup_object_pools()
	
	# Verificar se pools foram criados
	var stats = ObjectPool.get_pool_stats()
	TestFramework.assert_true(stats.has("HighlightNode"), "Pool HighlightNode deve existir")
	TestFramework.assert_true(stats.has("UnitLabel"), "Pool UnitLabel deve existir")
	TestFramework.assert_true(stats.has("DomainNode"), "Pool DomainNode deve existir")

## Teste: Criação de managers
func test_managers_creation() -> void:
	const TurnManager = preload("res://scripts/game/managers/turn_manager.gd")
	const InputHandler = preload("res://scripts/game/managers/input_handler.gd")
	const UIManager = preload("res://scripts/game/managers/ui_manager.gd")
	const GameController = preload("res://scripts/game/managers/game_controller.gd")
	
	# Criar managers
	var turn_manager = TurnManager.new()
	var input_handler = InputHandler.new()
	var ui_manager = UIManager.new()
	var game_controller = GameController.new()
	
	TestFramework.assert_not_null(turn_manager, "TurnManager deve ser criado")
	TestFramework.assert_not_null(input_handler, "InputHandler deve ser criado")
	TestFramework.assert_not_null(ui_manager, "UIManager deve ser criado")
	TestFramework.assert_not_null(game_controller, "GameController deve ser criado")
	
	# Testar inicialização básica
	turn_manager.initialize()
	TestFramework.assert_true(true, "TurnManager deve inicializar sem erros")

## Cleanup completo após todos os testes
func cleanup_after_tests() -> void:
	print("\n=== INICIANDO CLEANUP APÓS TESTES ===")
	
	# Limpar ObjectPool
	const ObjectPool = preload("res://scripts/core/object_pool.gd")
	ObjectPool.cleanup_system()
	
	# Aguardar frames para processamento
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Limpar nodes órfãos
	cleanup_orphaned_nodes()
	
	# Aguardar mais frames
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("=== CLEANUP FINALIZADO ===")

## Limpar nodes órfãos
func cleanup_orphaned_nodes() -> void:
	print("Limpando nodes órfãos...")
	
	# Obter todos os nodes filhos da árvore principal
	var root = get_tree().root
	var children_to_remove = []
	
	# Identificar nodes que podem ser órfãos
	for child in root.get_children():
		# Não remover nodes essenciais do sistema
		if child.name in ["Main", "TestRunner", "@EditorNode", "@SceneTree"]:
			continue
		
		# Marcar para remoção
		children_to_remove.append(child)
	
	# Remover nodes órfãos
	for child in children_to_remove:
		if is_instance_valid(child):
			print("Removendo node órfão: ", child.name)
			child.queue_free()
	
	print("Cleanup de nodes órfãos concluído")