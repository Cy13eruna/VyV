## ObjectPool - Sistema de Pool de Objetos para Performance
## Reutiliza objetos em vez de criar/destruir constantemente

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
			Logger.debug("Object reused from pool", "ObjectPool")
			return obj
	
	# Criar novo objeto se pool vazio
	if factory_callable.is_valid():
		var new_obj = factory_callable.call()
		Logger.debug("New object created", "ObjectPool")
		return new_obj
	
	Logger.warning("No factory provided for type: " + type, "ObjectPool")
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
		if obj.has_method("cleanup"):
			obj.cleanup()
		Logger.debug("Pool full, object destroyed", "ObjectPool")
		return
	
	if obj.has_method("cleanup"):
		obj.cleanup()
	
	pool.append(obj)
	Logger.debug("Object returned to pool", "ObjectPool")

## Limpar pool específico
static func clear_pool(type: String) -> void:
	if pools.has(type):
		var pool = pools[type]
		for obj in pool:
			if obj and is_instance_valid(obj) and obj.has_method("cleanup"):
				obj.cleanup()
		pool.clear()
		Logger.debug("Pool cleared: " + type, "ObjectPool")

## Limpar todos os pools
static func clear_all_pools() -> void:
	for type in pools.keys():
		clear_pool(type)
	pools.clear()
	Logger.debug("All pools cleared", "ObjectPool")

## Obter estatísticas dos pools
static func get_pool_stats() -> Dictionary:
	var stats = {}
	for type in pools.keys():
		stats[type] = pools[type].size()
	return stats

## Pré-aquecer pool com objetos
static func warm_pool(type: String, count: int, factory_callable: Callable) -> void:
	if not factory_callable.is_valid():
		Logger.warning("Invalid factory for warming pool: " + type, "ObjectPool")
		return
	
	if not pools.has(type):
		pools[type] = []
	
	var pool = pools[type]
	for i in range(count):
		var obj = factory_callable.call()
		if obj:
			if obj.has_method("cleanup"):
				obj.cleanup()
			pool.append(obj)
	
	Logger.debug("Pool warmed: %s with %d objects" % [type, count], "ObjectPool")