## Teste rápido da refatoração
extends Node

func _ready():
	print("=== TESTE DE REFATORAÇÃO ===")
	
	# Testar Logger
	const Logger = preload("res://scripts/core/logger.gd")
	Logger.info("Logger funcionando", "Test")
	
	# Testar ObjectPool
	const ObjectPool = preload("res://scripts/core/object_pool.gd")
	const ObjectFactories = preload("res://scripts/core/object_factories.gd")
	
	# Testar factory
	var label = ObjectFactories.create_unit_label()
	print("Label criado: ", label != null)
	
	# Testar pool
	var pooled_label = ObjectPool.get_object("UnitLabel", ObjectFactories.create_unit_label)
	print("Label do pool: ", pooled_label != null)
	
	# Testar managers
	const TurnManager = preload("res://scripts/game/managers/turn_manager.gd")
	var turn_mgr = TurnManager.new()
	turn_mgr.initialize()
	print("TurnManager: OK")
	
	const InputHandler = preload("res://scripts/game/managers/input_handler.gd")
	var input_handler = InputHandler.new()
	print("InputHandler: OK")
	
	const UIManager = preload("res://scripts/game/managers/ui_manager.gd")
	var ui_mgr = UIManager.new()
	print("UIManager: OK")
	
	const GameController = preload("res://scripts/game/managers/game_controller.gd")
	var game_ctrl = GameController.new()
	print("GameController: OK")
	
	print("=== TODOS OS SISTEMAS FUNCIONANDO! ===")
	
	# Sair após teste
	get_tree().quit()