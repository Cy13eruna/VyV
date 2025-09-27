## ObjectPool - Sistema de Pool de Objetos para Performance
## Reutiliza objetos em vez de criar/destruir constantemente
## NOTA: Não usa Logger para evitar dependência circular

class_name ObjectPool
extends RefCounted

## Pool de objetos por tipo
static var pools: Dictionary = {}

## Interface para objetos pooláveis
class PoolableObject:
	func reset() -> void:
		pass  # Override para resetar estado
	
	func cleanup() -> void:
		pass  # Override para limpeza

## Obter objeto do pool
static func get_object(type: String, factory_callable: Callable = Callable()) -> Variant:
	if not pools.has(type):
		pools[type] = []
	
	var pool = pools[type]
	
	if pool.size() > 0:
		var obj = pool.pop_back()
		if obj and is_instance_valid(obj):
			if obj.has_method("reset"):
				obj.reset()
			# Debug: Object reused from pool
			return obj
	
	# Criar novo objeto se pool vazio
	if factory_callable.is_valid():
		var new_obj = factory_callable.call()
		# Debug: New object created
		return new_obj
	
	# Warning: No factory provided for type
	print("ObjectPool WARNING: No factory provided for type: " + type)
	return null

## Retornar objeto para o pool
static func return_object(type: String, obj: Variant) -> void:
	if not obj or not is_instance_valid(obj):
		return
	
	if not pools.has(type):
		pools[type] = []
	
	var pool = pools[type]
	
	# Limitar tamanho do pool para evitar vazamentos
	if pool.size() >= 50:
		_destroy_object_safely(obj)
		# Debug: Pool full, object destroyed
		return
	
	# Resetar objeto antes de retornar ao pool
	if obj.has_method("reset"):
		obj.reset()
	
	pool.append(obj)
	# Debug: Object returned to pool

## Limpar pool específico
static func clear_pool(type: String) -> void:
	if pools.has(type):
		var pool = pools[type]
		for obj in pool:
			_destroy_object_safely(obj)
		pool.clear()
		# Debug: Pool cleared: + type

## Limpar todos os pools
static func clear_all_pools() -> void:
	for type in pools.keys():
		clear_pool(type)
	pools.clear()
	# Debug: All pools cleared

## Obter estatísticas dos pools
static func get_pool_stats() -> Dictionary:
	var stats = {}
	for type in pools.keys():
		stats[type] = pools[type].size()
	return stats

## Pré-aquecer pool com objetos
static func warm_pool(type: String, count: int, factory_callable: Callable) -> void:
	if not factory_callable.is_valid():
		print("ObjectPool WARNING: Invalid factory for warming pool: " + type)
		return
	
	if not pools.has(type):
		pools[type] = []
	
	var pool = pools[type]
	for i in range(count):
		var obj = factory_callable.call()
		if obj:
			# Resetar objeto antes de adicionar ao pool
			if obj.has_method("reset"):
				obj.reset()
			pool.append(obj)
	
	# Debug: Pool warmed with objects
	print("ObjectPool: Pool warmed - %s with %d objects" % [type, count])

## Destruir objeto de forma segura
static func _destroy_object_safely(obj: Variant) -> void:
	if not obj or not is_instance_valid(obj):
		return
	
	# Chamar cleanup se disponível
	if obj.has_method("cleanup"):
		obj.cleanup()
	
	# Se for um Node, usar queue_free para evitar memory leaks
	if obj is Node:
		# Remover do parent se tiver
		if obj.get_parent():
			obj.get_parent().remove_child(obj)
		obj.queue_free()
	else:
		# Para outros objetos, apenas limpar referências
		obj = null

## Cleanup completo do sistema
static func cleanup_system() -> void:
	print("ObjectPool: Iniciando cleanup completo do sistema...")
	
	# Limpar todos os pools
	clear_all_pools()
	
	# Forçar garbage collection (não disponível em GDScript)
	# Em Godot, o garbage collection é automático
	
	print("ObjectPool: Cleanup completo finalizado")