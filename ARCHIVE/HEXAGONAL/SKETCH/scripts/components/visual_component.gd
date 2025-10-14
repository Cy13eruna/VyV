## VisualComponent - Componente visual reutilizável
## Separa lógica visual da lógica de negócio

class_name VisualComponent
extends RefCounted

## Sinais
signal visual_created(node: Node)
signal visual_destroyed()
signal visual_updated()

## Propriedades
var visual_node: Node = null
var parent_node: Node = null
var is_visible: bool = true
var z_index: int = 0

## Configuração
var config: GameConfig

## Inicializar componente
func _init(game_config: GameConfig = null):
	config = game_config if game_config else GameConfig.get_instance()

## Criar visual (método abstrato)
func create_visual(parent: Node) -> bool:
	push_error("create_visual() must be implemented by subclass")
	return false

## Atualizar posição
func update_position(new_position: Vector2) -> void:
	if visual_node:
		visual_node.global_position = new_position

## Atualizar cor
func update_color(new_color: Color) -> void:
	if visual_node and visual_node.has_method("set_modulate"):
		visual_node.modulate = new_color

## Mostrar/esconder
func set_visible(visible: bool) -> void:
	is_visible = visible
	if visual_node:
		visual_node.visible = visible

## Limpar recursos
func cleanup() -> void:
	if visual_node and is_instance_valid(visual_node):
		visual_node.queue_free()
		visual_node = null
	visual_destroyed.emit()