## ResourceCleanup - Sistema agressivo de limpeza de recursos
## Resolve memory leaks críticos de RIDs e ObjectDB instances

class_name ResourceCleanup
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")
const ObjectPool = preload("res://scripts/core/object_pool.gd")

## Singleton para cleanup global
static var instance

## Listas de recursos para cleanup
static var tracked_nodes: Array = []
static var tracked_textures: Array = []
static var tracked_fonts: Array = []
static var tracked_canvas_items: Array = []

## Inicializar sistema de cleanup
static func initialize() -> void:
	if not instance:
		instance = RefCounted.new()
		Logger.info("ResourceCleanup inicializado", "ResourceCleanup")

## Registrar node para cleanup automático
static func track_node(node: Node) -> void:
	if node and is_instance_valid(node):
		tracked_nodes.append(node)

## Registrar texture para cleanup
static func track_texture(texture: Texture2D) -> void:
	if texture and is_instance_valid(texture):
		tracked_textures.append(texture)

## Registrar font para cleanup
static func track_font(font: Font) -> void:
	if font and is_instance_valid(font):
		tracked_fonts.append(font)

## Cleanup completo de todos os recursos
static func cleanup_all_resources() -> void:
	Logger.info("Iniciando cleanup agressivo de todos os recursos...", "ResourceCleanup")
	
	# 1. Limpar ObjectPool primeiro
	ObjectPool.cleanup_system()
	
	# 2. Limpar nodes rastreados
	_cleanup_tracked_nodes()
	
	# 3. Limpar texturas rastreadas
	_cleanup_tracked_textures()
	
	# 4. Limpar fontes rastreadas
	_cleanup_tracked_fonts()
	
	# 5. Limpar nodes órfãos da árvore principal
	_cleanup_orphaned_nodes()
	
	# 6. Limpar CanvasItems órfãos
	_cleanup_canvas_items()
	
	# 7. Forçar limpeza de recursos do sistema
	_force_system_cleanup()
	
	Logger.info("Cleanup agressivo finalizado", "ResourceCleanup")

## Limpar nodes rastreados
static func _cleanup_tracked_nodes() -> void:
	Logger.debug("Limpando %d nodes rastreados..." % tracked_nodes.size(), "ResourceCleanup")
	
	for node in tracked_nodes:
		if node and is_instance_valid(node):
			# Remover do parent se tiver
			if node.get_parent():
				node.get_parent().remove_child(node)
			# Queue free para limpeza adequada
			node.queue_free()
	
	tracked_nodes.clear()
	Logger.debug("Nodes rastreados limpos", "ResourceCleanup")

## Limpar texturas rastreadas
static func _cleanup_tracked_textures() -> void:
	Logger.debug("Limpando %d texturas rastreadas..." % tracked_textures.size(), "ResourceCleanup")
	
	for texture in tracked_textures:
		if texture and is_instance_valid(texture):
			# Limpar referência
			texture = null
	
	tracked_textures.clear()
	Logger.debug("Texturas rastreadas limpas", "ResourceCleanup")

## Limpar fontes rastreadas
static func _cleanup_tracked_fonts() -> void:
	Logger.debug("Limpando %d fontes rastreadas..." % tracked_fonts.size(), "ResourceCleanup")
	
	for font in tracked_fonts:
		if font and is_instance_valid(font):
			# Limpar referência
			font = null
	
	tracked_fonts.clear()
	Logger.debug("Fontes rastreadas limpas", "ResourceCleanup")

## Limpar nodes órfãos da árvore principal
static func _cleanup_orphaned_nodes() -> void:
	Logger.debug("Limpando nodes órfãos da árvore principal...", "ResourceCleanup")
	
	var main_loop = Engine.get_main_loop()
	if not main_loop or not main_loop.has_method("get_root"):
		return
	
	var root = main_loop.get_root()
	if not root:
		return
	
	var children_to_remove = []
	
	# Identificar nodes que podem ser órfãos
	for child in root.get_children():
		# Não remover nodes essenciais do sistema
		if child.name in ["Main", "TestRunner", "@EditorNode", "@SceneTree", "MainGame"]:
			continue
		
		# Marcar para remoção
		children_to_remove.append(child)
	
	# Remover nodes órfãos
	for child in children_to_remove:
		if is_instance_valid(child):
			Logger.debug("Removendo node órfão: %s" % child.name, "ResourceCleanup")
			child.queue_free()
	
	Logger.debug("Cleanup de nodes órfãos concluído", "ResourceCleanup")

## Limpar CanvasItems órfãos
static func _cleanup_canvas_items() -> void:
	Logger.debug("Forçando limpeza de CanvasItems...", "ResourceCleanup")
	
	# Aguardar frames para limpeza de CanvasItems
	if Engine.get_main_loop():
		var main_loop = Engine.get_main_loop()
		if main_loop.has_method("process_frame"):
			await main_loop.process_frame

## Forçar limpeza de recursos do sistema
static func _force_system_cleanup() -> void:
	Logger.debug("Forçando limpeza de recursos do sistema...", "ResourceCleanup")
	
	# Aguardar frames para processamento
	if Engine.get_main_loop():
		var main_loop = Engine.get_main_loop()
		if main_loop.has_method("process_frame"):
			# Processar múltiplos frames para garantir limpeza
			for i in range(5):
				await main_loop.process_frame
	
	# Garbage collection é automático em Godot
	# Não há função manual disponível
	
	Logger.debug("Limpeza de sistema finalizada", "ResourceCleanup")

## Cleanup de emergência para exit
static func emergency_cleanup() -> void:
	Logger.warning("Executando cleanup de emergência...", "ResourceCleanup")
	
	# Limpar ObjectPool imediatamente
	ObjectPool.clear_all_pools()
	
	# Limpar todas as listas rastreadas
	tracked_nodes.clear()
	tracked_textures.clear()
	tracked_fonts.clear()
	tracked_canvas_items.clear()
	
	Logger.warning("Cleanup de emergência finalizado", "ResourceCleanup")

## Obter estatísticas de recursos rastreados
static func get_resource_stats() -> Dictionary:
	return {
		"tracked_nodes": tracked_nodes.size(),
		"tracked_textures": tracked_textures.size(),
		"tracked_fonts": tracked_fonts.size(),
		"tracked_canvas_items": tracked_canvas_items.size()
	}

## Reportar estatísticas
static func report_stats() -> void:
	var stats = get_resource_stats()
	Logger.info("Recursos rastreados:", "ResourceCleanup")
	Logger.info("- Nodes: %d" % stats.tracked_nodes, "ResourceCleanup")
	Logger.info("- Texturas: %d" % stats.tracked_textures, "ResourceCleanup")
	Logger.info("- Fontes: %d" % stats.tracked_fonts, "ResourceCleanup")
	Logger.info("- CanvasItems: %d" % stats.tracked_canvas_items, "ResourceCleanup")