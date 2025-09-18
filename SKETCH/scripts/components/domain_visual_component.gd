## DomainVisualComponent - Componente visual específico para domínios
## Gerencia toda a lógica visual dos domínios

class_name DomainVisualComponent
extends VisualComponent

## Propriedades específicas do domínio
var vertices: Array = []
var line_color: Color = Color.MAGENTA
var hex_grid_ref = null

## Criar visual do domínio
func create_visual(parent: Node) -> bool:
	if visual_node:
		return true  # Já criada
	
	parent_node = parent
	visual_node = Node2D.new()
	visual_node.z_index = 40
	
	# Adicionar ao hex_grid para usar coordenadas locais
	if hex_grid_ref:
		hex_grid_ref.add_child(visual_node)
	else:
		parent_node.add_child(visual_node)
	
	visual_node.draw.connect(_draw_domain_hexagon)
	visual_created.emit(visual_node)
	
	return true

## Configurar referência do hex_grid
func set_hex_grid_reference(hex_grid) -> void:
	hex_grid_ref = hex_grid

## Atualizar vértices do domínio
func update_vertices(new_vertices: Array) -> void:
	vertices = new_vertices.duplicate()
	if visual_node:
		visual_node.queue_redraw()
	visual_updated.emit()

## Atualizar cor do domínio
func update_color(new_color: Color) -> void:
	line_color = new_color
	if visual_node:
		visual_node.queue_redraw()

## Desenhar hexágono do domínio
func _draw_domain_hexagon() -> void:
	if not visual_node or vertices.size() < 3:
		return
	
	# Desenhar hexágono tracejado entre vértices
	for i in range(vertices.size()):
		var start_pos = vertices[i]
		var end_pos = vertices[(i + 1) % vertices.size()]
		_draw_dashed_line(start_pos, end_pos)

## Desenhar linha tracejada
func _draw_dashed_line(start: Vector2, end: Vector2) -> void:
	if not visual_node:
		return
	
	var direction = (end - start).normalized()
	var total_length = start.distance_to(end)
	var current_pos = start
	var distance_covered = 0.0
	var drawing_dash = true
	
	while distance_covered < total_length:
		var segment_length = config.domain_dash_length if drawing_dash else config.domain_gap_length
		var remaining_length = total_length - distance_covered
		var actual_length = min(segment_length, remaining_length)
		
		var next_pos = current_pos + direction * actual_length
		
		if drawing_dash:
			visual_node.draw_line(current_pos, next_pos, line_color, config.domain_line_width)
		
		current_pos = next_pos
		distance_covered += actual_length
		drawing_dash = not drawing_dash

## Obter informações visuais
func get_visual_info() -> Dictionary:
	return {
		"vertices_count": vertices.size(),
		"line_color": line_color,
		"line_width": config.domain_line_width,
		"is_visible": is_visible
	}