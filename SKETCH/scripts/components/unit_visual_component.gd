## UnitVisualComponent - Componente visual específico para unidades
## Gerencia toda a lógica visual das unidades

class_name UnitVisualComponent
extends VisualComponent

## Propriedades específicas da unidade
var emoji_text: String = "🚶🏻‍♀️"
var current_color: Color = Color.WHITE

## Criar visual da unidade
func create_visual(parent: Node) -> bool:
	if visual_node:
		return true  # Já criada
	
	parent_node = parent
	visual_node = Label.new()
	visual_node.text = emoji_text
	visual_node.add_theme_font_size_override("font_size", config.unit_font_size)
	visual_node.z_index = 100  # Acima de tudo
	visual_node.visible = false
	visual_node.modulate = current_color
	
	parent_node.add_child(visual_node)
	visual_created.emit(visual_node)
	
	EventBus.emit_info("Unit visual created with font size: %d" % config.unit_font_size)
	return true

## Atualizar posição com offset configurável
func update_position(new_position: Vector2) -> void:
	if not visual_node:
		return
	
	visual_node.global_position = new_position
	# Aplicar offsets configuráveis
	visual_node.global_position.x -= config.unit_font_size * config.unit_offset_x
	visual_node.global_position.y -= config.unit_font_size * config.unit_offset_y
	visual_node.visible = true
	
	visual_updated.emit()

## Atualizar cor da unidade
func update_color(new_color: Color) -> void:
	current_color = new_color
	if visual_node:
		visual_node.modulate = new_color

## Definir emoji da unidade
func set_emoji(new_emoji: String) -> void:
	emoji_text = new_emoji
	if visual_node:
		visual_node.text = emoji_text

## Obter informações visuais
func get_visual_info() -> Dictionary:
	return {
		"emoji": emoji_text,
		"color": current_color,
		"font_size": config.unit_font_size,
		"is_visible": is_visible,
		"position": visual_node.global_position if visual_node else Vector2.ZERO
	}