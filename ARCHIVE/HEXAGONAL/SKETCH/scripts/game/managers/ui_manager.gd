## UIManager - Sistema de Gerenciamento de Interface
## Extraído do main_game.gd para seguir princípios SOLID
## Responsabilidade única: Gerenciar interface do usuário

class_name UIManager
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")
const ObjectPool = preload("res://scripts/core/object_pool.gd")
const ObjectFactories = preload("res://scripts/core/object_factories.gd")

## Sinais da interface
signal next_turn_requested()
signal ui_element_created(element_name: String, element: Control)
signal ui_element_destroyed(element_name: String)

## Elementos da interface
var next_turn_button: Button
var button_canvas_layer: CanvasLayer
var parent_node_ref: Node

## Estado da interface
var ui_initialized: bool = false
var current_team_info: Dictionary = {}

## Configurações da interface
var button_size: Vector2 = Vector2(120, 40)
var button_margin: int = 10

## Inicializar interface
func initialize(parent_node: Node) -> void:
	parent_node_ref = parent_node
	_setup_turn_interface()
	ui_initialized = true
	Logger.info("UIManager inicializado", "UIManager")

## Configurar interface de turnos
func _setup_turn_interface() -> void:
	# Criar CanvasLayer para UI usando ObjectPool
	button_canvas_layer = ObjectPool.get_object("CanvasLayer", ObjectFactories.create_canvas_layer)
	button_canvas_layer.layer = 100  # Sempre no topo
	parent_node_ref.add_child(button_canvas_layer)
	
	# Criar botão NEXT TURN usando ObjectPool
	next_turn_button = ObjectPool.get_object("Button", ObjectFactories.create_button)
	next_turn_button.text = "NEXT TURN"
	next_turn_button.size = button_size
	
	# Posicionar no canto superior direito
	next_turn_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	next_turn_button.position = Vector2(-button_size.x - button_margin, button_margin)
	
	# Conectar sinal
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	
	# Adicionar ao CanvasLayer
	button_canvas_layer.add_child(next_turn_button)
	
	# Emitir sinal de criação
	ui_element_created.emit("next_turn_button", next_turn_button)
	
	Logger.debug("Interface de turnos configurada", "UIManager")

## Atualizar aparência do botão baseado no team atual
func update_turn_button(team_info: Dictionary) -> void:
	if not next_turn_button or team_info.is_empty():
		return
	
	current_team_info = team_info
	
	# Definir cor do botão baseado no team atual
	if team_info.has("color"):
		next_turn_button.modulate = team_info.color
	
	# Atualizar texto do botão
	if team_info.has("name"):
		next_turn_button.text = "TURNO: " + team_info.name
	
	Logger.debug("Botão atualizado: %s (cor: %s)" % [team_info.get("name", ""), team_info.get("color", "")], "UIManager")

## Callback do botão NEXT TURN
func _on_next_turn_pressed() -> void:
	Logger.debug("Botão NEXT TURN pressionado", "UIManager")
	next_turn_requested.emit()

## Mostrar/ocultar interface
func set_ui_visible(visible: bool) -> void:
	if button_canvas_layer:
		button_canvas_layer.visible = visible
		Logger.debug("Interface %s" % ("mostrada" if visible else "ocultada"), "UIManager")

## Habilitar/desabilitar botão de turno
func set_turn_button_enabled(enabled: bool) -> void:
	if next_turn_button:
		next_turn_button.disabled = not enabled
		Logger.debug("Botão de turno %s" % ("habilitado" if enabled else "desabilitado"), "UIManager")

## Criar elemento de UI personalizado
func create_ui_element(element_name: String, element_type: String, properties: Dictionary = {}) -> Control:
	var element: Control
	
	match element_type:
		"Button":
			element = ObjectPool.get_object("Button", ObjectFactories.create_button)
		"Label":
			element = ObjectPool.get_object("UnitLabel", ObjectFactories.create_unit_label)
		"Panel":
			element = ObjectPool.get_object("Panel", ObjectFactories.create_panel)
		_:
			Logger.error("Tipo de elemento UI não suportado: %s" % element_type, "UIManager")
			return null
	
	# Aplicar propriedades
	for property in properties.keys():
		if element.has_method("set_" + property):
			element.call("set_" + property, properties[property])
		elif property in element:
			element.set(property, properties[property])
	
	# Adicionar ao canvas layer
	if button_canvas_layer:
		button_canvas_layer.add_child(element)
	
	ui_element_created.emit(element_name, element)
	Logger.debug("Elemento UI criado: %s (%s)" % [element_name, element_type], "UIManager")
	
	return element

## Remover elemento de UI
func remove_ui_element(element_name: String, element: Control, element_type: String = "") -> void:
	if element and is_instance_valid(element):
		# Remover do parent
		if element.get_parent():
			element.get_parent().remove_child(element)
		
		# Retornar ao pool se tipo especificado
		if element_type != "":
			ObjectPool.return_object(element_type, element)
		else:
			# Fallback para queue_free se tipo não especificado
			element.queue_free()
		
		ui_element_destroyed.emit(element_name)
		Logger.debug("Elemento UI removido: %s" % element_name, "UIManager")

## Obter informações da interface
func get_ui_info() -> Dictionary:
	return {
		"initialized": ui_initialized,
		"button_visible": next_turn_button.visible if next_turn_button else false,
		"button_enabled": not next_turn_button.disabled if next_turn_button else false,
		"current_team": current_team_info,
		"canvas_layer_children": button_canvas_layer.get_child_count() if button_canvas_layer else 0
	}

## Configurar tamanho e posição do botão
func configure_button(size: Vector2, margin: int) -> void:
	button_size = size
	button_margin = margin
	
	if next_turn_button:
		next_turn_button.size = button_size
		next_turn_button.position = Vector2(-button_size.x - button_margin, button_margin)
	
	Logger.debug("Configuração do botão atualizada", "UIManager")

## Limpeza de recursos
func cleanup() -> void:
	# Retornar botão ao pool
	if next_turn_button and is_instance_valid(next_turn_button):
		if next_turn_button.get_parent():
			next_turn_button.get_parent().remove_child(next_turn_button)
		ObjectPool.return_object("Button", next_turn_button)
		next_turn_button = null
	
	# Retornar canvas layer ao pool
	if button_canvas_layer and is_instance_valid(button_canvas_layer):
		if button_canvas_layer.get_parent():
			button_canvas_layer.get_parent().remove_child(button_canvas_layer)
		ObjectPool.return_object("CanvasLayer", button_canvas_layer)
		button_canvas_layer = null
	
	ui_initialized = false
	
	Logger.debug("Recursos da UI limpos e retornados ao ObjectPool", "UIManager")

## Verificar se está inicializado
func is_initialized() -> bool:
	return ui_initialized and next_turn_button != null and button_canvas_layer != null