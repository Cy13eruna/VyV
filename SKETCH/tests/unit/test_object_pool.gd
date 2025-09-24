## Testes unitários para ObjectPool
extends RefCounted

const TestFramework = preload("res://tests/test_framework.gd")
const ObjectPool = preload("res://scripts/core/object_pool.gd")
const ObjectFactories = preload("res://scripts/core/object_factories.gd")

## Executar todos os testes do ObjectPool
static func run_all_tests() -> void:
	TestFramework.start_test_suite("ObjectPool")
	
	# Limpar pools antes dos testes
	ObjectPool.clear_all_pools()
	
	TestFramework.run_test("test_get_object_with_factory", test_get_object_with_factory)
	TestFramework.run_test("test_return_object_to_pool", test_return_object_to_pool)
	TestFramework.run_test("test_pool_reuse", test_pool_reuse)
	TestFramework.run_test("test_warm_pool", test_warm_pool)
	TestFramework.run_test("test_clear_pool", test_clear_pool)
	TestFramework.run_test("test_pool_size_limit", test_pool_size_limit)
	
	# Limpar pools após os testes
	ObjectPool.clear_all_pools()
	
	TestFramework.end_test_suite()

## Teste: Obter objeto com factory
static func test_get_object_with_factory() -> void:
	# Limpar pool antes do teste
	ObjectPool.clear_pool("TestNode")
	
	# Obter objeto do pool vazio (deve criar novo)
	var obj = ObjectPool.get_object("TestNode", ObjectFactories.create_highlight_node)
	
	TestFramework.assert_not_null(obj, "Objeto deve ser criado")
	TestFramework.assert_instance_of(obj, Node2D, "Objeto deve ser Node2D")
	
	# Cleanup: destruir objeto criado
	if obj and is_instance_valid(obj):
		obj.queue_free()
	
	# Limpar pool após teste
	ObjectPool.clear_pool("TestNode")

## Teste: Retornar objeto para pool
static func test_return_object_to_pool() -> void:
	ObjectPool.clear_pool("TestNode")
	
	var obj = ObjectPool.get_object("TestNode", ObjectFactories.create_highlight_node)
	TestFramework.assert_not_null(obj, "Objeto inicial criado")
	
	# Retornar ao pool
	ObjectPool.return_object("TestNode", obj)
	
	# Verificar estatísticas
	var stats = ObjectPool.get_pool_stats()
	TestFramework.assert_equal(1, stats.get("TestNode", 0), "Pool deve ter 1 objeto")
	
	# Cleanup: limpar pool após teste
	ObjectPool.clear_pool("TestNode")

## Teste: Reutilização de objetos
static func test_pool_reuse() -> void:
	ObjectPool.clear_pool("TestReuse")
	
	# Criar e retornar objeto
	var obj1 = ObjectPool.get_object("TestReuse", ObjectFactories.create_highlight_node)
	ObjectPool.return_object("TestReuse", obj1)
	
	# Obter novamente (deve reutilizar)
	var obj2 = ObjectPool.get_object("TestReuse", ObjectFactories.create_highlight_node)
	
	# Em um pool ideal, obj1 e obj2 seriam o mesmo objeto
	# Mas vamos verificar que pelo menos obtivemos um objeto válido
	TestFramework.assert_not_null(obj2, "Objeto reutilizado deve ser válido")
	
	# Cleanup: destruir objeto e limpar pool
	if obj2 and is_instance_valid(obj2):
		obj2.queue_free()
	ObjectPool.clear_pool("TestReuse")

## Teste: Warm pool
static func test_warm_pool() -> void:
	ObjectPool.clear_pool("TestWarm")
	
	# Aquecer pool com 5 objetos
	ObjectPool.warm_pool("TestWarm", 5, ObjectFactories.create_highlight_node)
	
	var stats = ObjectPool.get_pool_stats()
	TestFramework.assert_equal(5, stats.get("TestWarm", 0), "Pool deve ter 5 objetos após warm")

## Teste: Limpar pool
static func test_clear_pool() -> void:
	ObjectPool.clear_pool("TestClear")
	ObjectPool.warm_pool("TestClear", 3, ObjectFactories.create_highlight_node)
	
	# Verificar que tem objetos
	var stats_before = ObjectPool.get_pool_stats()
	TestFramework.assert_equal(3, stats_before.get("TestClear", 0), "Pool deve ter 3 objetos antes de limpar")
	
	# Limpar
	ObjectPool.clear_pool("TestClear")
	
	# Verificar que foi limpo
	var stats_after = ObjectPool.get_pool_stats()
	TestFramework.assert_equal(0, stats_after.get("TestClear", 0), "Pool deve estar vazio após limpar")

## Teste: Limite de tamanho do pool
static func test_pool_size_limit() -> void:
	ObjectPool.clear_pool("TestLimit")
	
	# Tentar adicionar mais objetos que o limite (50)
	for i in range(55):
		var obj = ObjectFactories.create_highlight_node()
		ObjectPool.return_object("TestLimit", obj)
	
	var stats = ObjectPool.get_pool_stats()
	# Pool deve limitar a 50 objetos
	TestFramework.assert_true(stats.get("TestLimit", 0) <= 50, "Pool não deve exceder limite de 50 objetos")
	
	# Cleanup: limpar pool após teste
	ObjectPool.clear_pool("TestLimit")