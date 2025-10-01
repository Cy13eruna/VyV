# 🔄 OBJECT POOL
# Purpose: Efficient object reuse to reduce garbage collection
# Layer: Infrastructure/Performance

extends RefCounted

class_name ObjectPool

# Pool configuration
var pool_type: String
var max_pool_size: int
var create_function: Callable
var reset_function: Callable

# Pool storage
var available_objects: Array = []
var active_objects: Dictionary = {}
var total_created: int = 0

# Initialize object pool
func _init(type_name: String, max_size: int, creator: Callable, resetter: Callable = Callable()):
	pool_type = type_name
	max_pool_size = max_size
	create_function = creator
	reset_function = resetter

# Get object from pool
func get_object():
	var obj
	
	if available_objects.size() > 0:
		obj = available_objects.pop_back()
	else:
		obj = create_function.call()
		total_created += 1
	
	var obj_id = obj.get_instance_id()
	active_objects[obj_id] = obj
	
	return obj

# Return object to pool
func return_object(obj) -> void:
	var obj_id = obj.get_instance_id()
	
	if obj_id in active_objects:
		active_objects.erase(obj_id)
		
		# Reset object if reset function provided
		if reset_function.is_valid():
			reset_function.call(obj)
		
		# Add to available pool if not at max capacity
		if available_objects.size() < max_pool_size:
			available_objects.append(obj)
		else:
			# Pool is full, let object be garbage collected
			pass

# Clear all objects
func clear() -> void:
	available_objects.clear()
	active_objects.clear()

# Get pool statistics
func get_stats() -> Dictionary:
	return {
		"type": pool_type,
		"available": available_objects.size(),
		"active": active_objects.size(),
		"total_created": total_created,
		"max_size": max_pool_size,
		"efficiency": float(total_created - available_objects.size()) / max(1, total_created)
	}

# Preload pool with objects
func preload_pool(count: int) -> void:
	for i in range(count):
		if available_objects.size() < max_pool_size:
			var obj = create_function.call()
			available_objects.append(obj)
			total_created += 1