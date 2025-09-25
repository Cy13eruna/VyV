## ObjectFactories - Factories para ObjectPool
## Centraliza criação de objetos comuns para reutilização

class_name ObjectFactories
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")
const ObjectPool = preload("res://scripts/core/object_pool.gd")
const ResourceCleanup = preload("res://scripts/core/resource_cleanup.gd")

## Factory para highlight nodes
static func create_highlight_node() -> Node2D:
	var node = Node2D.new()
	node.z_index = 60
	node.visible = true
	# Rastrear para cleanup
	ResourceCleanup.track_node(node)
	return node

## Criar label para unidades
static func create_unit_label() -> Label:
	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Melhorar qualidade da renderização de texto
	label.clip_contents = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	return label

## Factory para nodes de domínio
static func create_domain_node() -> Node2D:
	var node = Node2D.new()
	node.z_index = 50
	# Rastrear para cleanup
	ResourceCleanup.track_node(node)
	return node

## Factory para canvas layers
static func create_canvas_layer() -> CanvasLayer:
	var layer = CanvasLayer.new()
	layer.layer = 100
	# Rastrear para cleanup
	ResourceCleanup.track_node(layer)
	return layer

## Factory para botões
static func create_button() -> Button:
	var button = Button.new()
	button.size = Vector2(120, 40)
	# Rastrear para cleanup
	ResourceCleanup.track_node(button)
	return button

## Factory para panels
static func create_panel() -> Panel:
	var panel = Panel.new()
	# Rastrear para cleanup
	ResourceCleanup.track_node(panel)
	return panel

## Configurar pools com factories
static func setup_object_pools() -> void:
	# Warm pools com objetos comuns
	ObjectPool.warm_pool("HighlightNode", 20, create_highlight_node)
	ObjectPool.warm_pool("UnitLabel", 10, create_unit_label)
	ObjectPool.warm_pool("DomainNode", 10, create_domain_node)
	ObjectPool.warm_pool("Button", 5, create_button)
	ObjectPool.warm_pool("Panel", 5, create_panel)
	ObjectPool.warm_pool("CanvasLayer", 3, create_canvas_layer)
	
	Logger.info("Object pools configurados e aquecidos", "ObjectFactories")