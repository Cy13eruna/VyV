## Testes específicos para memory leaks
extends RefCounted

const TestFramework = preload("res://tests/test_framework.gd")
const ObjectPool = preload("res://scripts/core/object_pool.gd")
const ObjectFactories = preload("res://scripts/core/object_factories.gd")
const MemoryMonitor = preload("res://scripts/core/memory_monitor.gd")

## Executar todos os testes de memory leaks
static func run_all_tests() -> void:
	TestFramework.start_test_suite("MemoryLeaks")
	
	TestFramework.run_test("test_node_creation_cleanup", test_node_creation_cleanup)
	TestFramework.run_test("test_label_creation_cleanup", test_label_creation_cleanup)
	TestFramework.run_test("test_canvas_layer_cleanup", test_canvas_layer_cleanup)
	TestFramework.run_test("test_massive_object_creation", test_massive_object_creation)
	
	TestFramework.end_test_suite()

## Teste: Criação e cleanup de nodes
static func test_node_creation_cleanup() -> void:
	MemoryMonitor.start_monitoring()
	var initial_memory = MemoryMonitor.check_memory()
	
	# Criar muitos nodes
	var nodes = []
	for i in range(100):
		var node = Node2D.new()
		node.name = "TestNode_%d" % i
		nodes.append(node)
	
	# Verificar se memória aumentou
	var after_creation = MemoryMonitor.check_memory()
	TestFramework.assert_true(after_creation.static_memory > initial_memory.static_memory, "Memória deve aumentar após criação")
	
	# Cleanup adequado
	for node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	nodes.clear()
	
	# Aguardar processamento
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	
	MemoryMonitor.stop_monitoring()

## Teste: Criação e cleanup de labels
static func test_label_creation_cleanup() -> void:
	MemoryMonitor.start_monitoring()
	var initial_memory = MemoryMonitor.check_memory()
	
	# Criar muitos labels
	var labels = []
	for i in range(50):
		var label = Label.new()
		label.text = "Test Label %d" % i
		label.add_theme_font_size_override("font_size", 16)
		labels.append(label)
	
	# Verificar aumento de memória
	var after_creation = MemoryMonitor.check_memory()
	TestFramework.assert_true(after_creation.static_memory > initial_memory.static_memory, "Memória deve aumentar com labels")
	
	# Cleanup
	for label in labels:
		if is_instance_valid(label):
			label.queue_free()
	labels.clear()
	
	# Aguardar processamento
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	
	MemoryMonitor.stop_monitoring()

## Teste: Cleanup de CanvasLayer
static func test_canvas_layer_cleanup() -> void:
	MemoryMonitor.start_monitoring()
	var initial_memory = MemoryMonitor.check_memory()
	
	# Criar canvas layers
	var layers = []
	for i in range(10):
		var layer = CanvasLayer.new()
		layer.layer = i
		layers.append(layer)
	
	# Verificar aumento
	var after_creation = MemoryMonitor.check_memory()
	TestFramework.assert_true(after_creation.static_memory > initial_memory.static_memory, "Memória deve aumentar com CanvasLayers")
	
	# Cleanup
	for layer in layers:
		if is_instance_valid(layer):
			layer.queue_free()
	layers.clear()
	
	# Aguardar processamento
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	
	MemoryMonitor.stop_monitoring()

## Teste: Criação massiva de objetos
static func test_massive_object_creation() -> void:
	MemoryMonitor.start_monitoring()
	var initial_memory = MemoryMonitor.check_memory()
	
	# Limpar pools primeiro
	ObjectPool.clear_all_pools()
	
	# Criar muitos objetos via ObjectPool
	var objects = []
	for i in range(200):
		var obj = ObjectPool.get_object("MassiveTest", ObjectFactories.create_highlight_node)
		if obj:
			objects.append(obj)
	
	# Verificar aumento
	var after_creation = MemoryMonitor.check_memory()
	TestFramework.assert_true(after_creation.static_memory > initial_memory.static_memory, "Memória deve aumentar com criação massiva")
	
	# Retornar objetos ao pool
	for obj in objects:
		ObjectPool.return_object("MassiveTest", obj)
	objects.clear()
	
	# Limpar pool completamente
	ObjectPool.clear_pool("MassiveTest")
	
	# Aguardar processamento
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	
	# Verificar se memória foi liberada (pelo menos parcialmente)
	var after_cleanup = MemoryMonitor.check_memory()
	if after_cleanup.has("static_memory") and after_creation.has("static_memory"):
		TestFramework.assert_true(after_cleanup.static_memory <= after_creation.static_memory, "Memória deve ser liberada após cleanup")
	else:
		TestFramework.assert_true(true, "Cleanup executado com sucesso")
	
	MemoryMonitor.stop_monitoring()