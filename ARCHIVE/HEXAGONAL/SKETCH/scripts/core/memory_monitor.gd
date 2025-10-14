## MemoryMonitor - Sistema de monitoramento de memory leaks
## Detecta e reporta vazamentos de memória em tempo real

class_name MemoryMonitor
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Estatísticas de memória
static var initial_memory: Dictionary = {}
static var current_memory: Dictionary = {}
static var monitoring_active: bool = false

## Iniciar monitoramento
static func start_monitoring() -> void:
	if monitoring_active:
		Logger.warning("Memory monitoring já está ativo", "MemoryMonitor")
		return
	
	monitoring_active = true
	initial_memory = _get_memory_stats()
	current_memory = initial_memory.duplicate()
	
	Logger.info("Memory monitoring iniciado", "MemoryMonitor")
	Logger.debug("Memória inicial: %s" % _format_memory_stats(initial_memory), "MemoryMonitor")

## Parar monitoramento
static func stop_monitoring() -> void:
	if not monitoring_active:
		return
	
	monitoring_active = false
	var final_memory = _get_memory_stats()
	
	Logger.info("Memory monitoring finalizado", "MemoryMonitor")
	_report_memory_changes(initial_memory, final_memory)

## Verificar memória atual
static func check_memory() -> Dictionary:
	if not monitoring_active:
		Logger.warning("Memory monitoring não está ativo", "MemoryMonitor")
		return {}
	
	current_memory = _get_memory_stats()
	return current_memory

## Reportar status atual
static func report_current_status() -> void:
	if not monitoring_active:
		Logger.warning("Memory monitoring não está ativo", "MemoryMonitor")
		return
	
	var current = _get_memory_stats()
	Logger.info("Status atual da memória:", "MemoryMonitor")
	Logger.info(_format_memory_stats(current), "MemoryMonitor")
	
	# Comparar com inicial
	_report_memory_changes(initial_memory, current)

## Detectar leaks potenciais
static func detect_potential_leaks() -> Array:
	if not monitoring_active:
		return []
	
	var current = _get_memory_stats()
	var potential_leaks = []
	
	# Verificar aumento significativo de memória
	var static_increase = current.static_memory - initial_memory.static_memory
	var dynamic_increase = current.dynamic_memory - initial_memory.dynamic_memory
	
	if static_increase > 1024 * 1024:  # 1MB
		potential_leaks.append({
			"type": "static_memory",
			"increase": static_increase,
			"description": "Aumento significativo na memória estática"
		})
	
	if dynamic_increase > 1024 * 1024:  # 1MB
		potential_leaks.append({
			"type": "dynamic_memory", 
			"increase": dynamic_increase,
			"description": "Aumento significativo na memória dinâmica"
		})
	
	# Verificar se há muitos objetos órfãos
	var orphan_count = _count_orphaned_objects()
	if orphan_count > 100:
		potential_leaks.append({
			"type": "orphaned_objects",
			"count": orphan_count,
			"description": "Muitos objetos órfãos detectados"
		})
	
	return potential_leaks

## Obter estatísticas de memória
static func _get_memory_stats() -> Dictionary:
	return {
		"static_memory": OS.get_static_memory_usage(),
		"dynamic_memory": OS.get_static_memory_peak_usage(),
		"timestamp": Time.get_ticks_msec()
	}

## Formatar estatísticas para exibição
static func _format_memory_stats(stats: Dictionary) -> String:
	var static_mb = stats.static_memory / (1024.0 * 1024.0)
	var dynamic_mb = stats.dynamic_memory / (1024.0 * 1024.0)
	
	return "Static: %.2f MB | Dynamic: %.2f MB" % [static_mb, dynamic_mb]

## Reportar mudanças na memória
static func _report_memory_changes(initial: Dictionary, final: Dictionary) -> void:
	var static_diff = final.static_memory - initial.static_memory
	var dynamic_diff = final.dynamic_memory - initial.dynamic_memory
	
	Logger.info("Mudanças na memória:", "MemoryMonitor")
	Logger.info("Static: %+d bytes (%.2f MB)" % [static_diff, static_diff / (1024.0 * 1024.0)], "MemoryMonitor")
	Logger.info("Dynamic: %+d bytes (%.2f MB)" % [dynamic_diff, dynamic_diff / (1024.0 * 1024.0)], "MemoryMonitor")
	
	# Alertas para aumentos significativos
	if static_diff > 1024 * 1024:  # 1MB
		Logger.warning("⚠️ Aumento significativo na memória estática: %.2f MB" % (static_diff / (1024.0 * 1024.0)), "MemoryMonitor")
	
	if dynamic_diff > 1024 * 1024:  # 1MB
		Logger.warning("⚠️ Aumento significativo na memória dinâmica: %.2f MB" % (dynamic_diff / (1024.0 * 1024.0)), "MemoryMonitor")

## Contar objetos órfãos (estimativa)
static func _count_orphaned_objects() -> int:
	# Esta é uma estimativa básica
	# Em um sistema real, seria mais complexo
	var count = 0
	
	# Verificar se há muitos nodes na árvore principal
	if Engine.get_main_loop() and Engine.get_main_loop().has_method("get_root"):
		var root = Engine.get_main_loop().get_root()
		if root:
			count = _count_nodes_recursive(root)
	
	return count

## Contar nodes recursivamente
static func _count_nodes_recursive(node: Node) -> int:
	var count = 1  # Contar o próprio node
	
	for child in node.get_children():
		count += _count_nodes_recursive(child)
	
	return count

## Executar verificação completa
static func run_full_check() -> Dictionary:
	var report = {
		"timestamp": Time.get_ticks_msec(),
		"memory_stats": _get_memory_stats(),
		"potential_leaks": detect_potential_leaks(),
		"orphaned_objects": _count_orphaned_objects()
	}
	
	Logger.info("=== RELATÓRIO COMPLETO DE MEMÓRIA ===", "MemoryMonitor")
	Logger.info("Memória: %s" % _format_memory_stats(report.memory_stats), "MemoryMonitor")
	Logger.info("Objetos órfãos: %d" % report.orphaned_objects, "MemoryMonitor")
	
	if report.potential_leaks.size() > 0:
		Logger.warning("⚠️ Potential leaks detectados:", "MemoryMonitor")
		for leak in report.potential_leaks:
			Logger.warning("- %s: %s" % [leak.type, leak.description], "MemoryMonitor")
	else:
		Logger.info("✅ Nenhum leak potencial detectado", "MemoryMonitor")
	
	return report