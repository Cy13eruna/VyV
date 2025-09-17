## Unit - Entidade de Unidade do Jogo
##
## Representa uma unidade no tabuleiro hexagonal.
## Responsável por posicionamento, movimento e estado da unidade.
##
## @author: V&V Game Studio
## @version: 1.0

class_name Unit
extends RefCounted

## Sinais da unidade
signal unit_moved(from_star_id: int, to_star_id: int)
signal unit_positioned(star_id: int)

## Estados possíveis da unidade
const BEM = 0
const MAL = 1

## Propriedades da unidade
var unit_id: int = -1
var current_star_id: int = -1
var state: int = BEM
var actions_remaining: int = 1
var max_actions: int = 1

## Referências visuais
var visual_node: Label = null
var emoji_text: String = "🚶🏻‍♀️"
var font_size: int = 18

## Referências do sistema
var hex_grid_ref = null
var star_mapper_ref = null

## Inicializar unidade
func _init(id: int = -1):
	unit_id = id if id >= 0 else randi()

## Configurar referências do sistema
func setup_references(hex_grid, star_mapper) -> void:
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper

## Criar representação visual da unidade
func create_visual(parent_node: Node) -> void:
	if visual_node:
		return  # Já criada
	
	visual_node = Label.new()
	visual_node.text = emoji_text
	visual_node.add_theme_font_size_override("font_size", font_size)
	visual_node.z_index = 100  # Acima de tudo
	visual_node.visible = false
	
	parent_node.add_child(visual_node)
	print("🚶🏻‍♀️ Unidade %d: visual criado" % unit_id)

## Posicionar unidade em uma estrela
func position_at_star(star_id: int) -> bool:
	if not _validate_star_id(star_id):
		return false
	
	var star_position = star_mapper_ref.get_star_position(star_id)
	var global_position = hex_grid_ref.to_global(star_position)
	
	# Atualizar posição visual
	if visual_node:
		visual_node.global_position = global_position
		visual_node.global_position.x -= font_size / 2
		visual_node.global_position.y -= font_size / 2
		visual_node.visible = true
	
	# Atualizar estado
	var old_star_id = current_star_id
	current_star_id = star_id
	
	# Emitir sinais apropriados
	if old_star_id == -1:
		unit_positioned.emit(star_id)
		print("🎆 Unidade %d posicionada na estrela %d" % [unit_id, star_id])
	else:
		unit_moved.emit(old_star_id, star_id)
		print("➡️ Unidade %d movida da estrela %d para %d" % [unit_id, old_star_id, star_id])
	
	return true

## Mover unidade para uma estrela
func move_to_star(target_star_id: int) -> bool:
	if current_star_id == -1:
		print("❌ Unidade %d não está posicionada" % unit_id)
		return false
	
	if actions_remaining <= 0:
		print("❌ Unidade %d não tem ações restantes" % unit_id)
		return false
	
	if not _validate_star_id(target_star_id):
		return false
	
	# Executar movimento
	if position_at_star(target_star_id):
		actions_remaining -= 1
		return true
	
	return false

## Verificar se unidade está posicionada
func is_positioned() -> bool:
	return current_star_id >= 0

## Obter posição atual
func get_current_star_id() -> int:
	return current_star_id

## Obter posição mundial atual
func get_world_position() -> Vector2:
	if not is_positioned() or not star_mapper_ref:
		return Vector2.ZERO
	
	var star_position = star_mapper_ref.get_star_position(current_star_id)
	return hex_grid_ref.to_global(star_position)

## Resetar ações da unidade
func reset_actions() -> void:
	actions_remaining = max_actions
	print("🔄 Unidade %d: ações resetadas (%d/%d)" % [unit_id, actions_remaining, max_actions])

## Alterar estado da unidade
func set_state(new_state: int) -> void:
	if state != new_state:
		var old_state = state
		state = new_state
		_update_visual_for_state()
		print("🔄 Unidade %d: estado alterado de %s para %s" % [unit_id, _state_to_string(old_state), _state_to_string(new_state)])

## Definir cor da unidade
func set_color(new_color: Color) -> void:
	if visual_node:
		visual_node.modulate = new_color
	print("🎨 Unidade %d: cor alterada para %s" % [unit_id, new_color])

## Obter informações da unidade
func get_info() -> Dictionary:
	return {
		"unit_id": unit_id,
		"current_star_id": current_star_id,
		"state": state,
		"actions_remaining": actions_remaining,
		"max_actions": max_actions,
		"is_positioned": is_positioned()
	}

## Limpar recursos da unidade
func cleanup() -> void:
	if visual_node and is_instance_valid(visual_node):
		visual_node.queue_free()
		visual_node = null
	
	print("🧹 Unidade %d: recursos limpos" % unit_id)

## Validar ID de estrela
func _validate_star_id(star_id: int) -> bool:
	if not star_mapper_ref:
		print("❌ Unidade %d: referência do star_mapper não configurada" % unit_id)
		return false
	
	if star_id < 0 or star_id >= star_mapper_ref.get_star_count():
		print("❌ Unidade %d: ID de estrela inválido: %d" % [unit_id, star_id])
		return false
	
	return true

## Atualizar visual baseado no estado
func _update_visual_for_state() -> void:
	if not visual_node:
		return
	
	match state:
		BEM:
			visual_node.modulate = Color.WHITE
		MAL:
			visual_node.modulate = Color.RED

## Converter estado para string
func _state_to_string(unit_state: int) -> String:
	match unit_state:
		BEM:
			return "BEM"
		MAL:
			return "MAL"
		_:
			return "UNKNOWN"