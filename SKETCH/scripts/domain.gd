## Domain - Entidade de Domínio do Jogo V&V
## Representa um domínio hexagonal no tabuleiro

class_name Domain
extends RefCounted

## Sinais do domínio
signal domain_created(domain_id: int, center_star_id: int)
signal domain_destroyed(domain_id: int)

## Propriedades do domínio
var domain_id: int = -1
var center_star_id: int = -1
var center_position: Vector2 = Vector2.ZERO
var vertices = []
var owner_id: int = -1  # ID do jogador proprietário

## Propriedades visuais
var visual_node: Node2D = null
var line_color: Color = Color.MAGENTA
var line_width: float = 2.0
var dash_length: float = 8.0
var gap_length: float = 4.0
var z_index: int = 40

## Referências do sistema
var hex_grid_ref = null
var star_mapper_ref = null

## Configurações de adjacência
var max_adjacent_distance: float = 38.0
var position_tolerance: float = 10.0  # Aumentada para melhor detecção de lados compartilhados

## Inicializar domínio
func _init(id: int = -1):
	domain_id = id if id >= 0 else randi()

## Configurar referências do sistema
func setup_references(hex_grid, star_mapper) -> void:
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper

## Criar domínio em uma estrela
func create_at_star(star_id: int, parent_node: Node) -> bool:
	if not _validate_star_id(star_id):
		return false
	
	# Configurar propriedades básicas
	center_star_id = star_id
	center_position = star_mapper_ref.get_star_position(star_id)
	
	# Encontrar vértices do hexágono
	vertices = _find_domain_vertices()
	
	if vertices.size() < 6:
		print("⚠️ Domínio %d: não foi possível encontrar 6 vértices adjacentes (apenas %d)" % [domain_id, vertices.size()])
		# Temporariamente permitir domínios com menos vértices para debug
		# return false
	
	# Criar visualização
	if not _create_visual(parent_node):
		print("❌ Domínio %d: falha ao criar visualização" % domain_id)
		return false
	
	domain_created.emit(domain_id, center_star_id)
	print("🏠 Domínio %d criado na estrela %d com %d vértices" % [domain_id, center_star_id, vertices.size()])
	return true

## Verificar se domínio compartilharia lados com outros domínios
func would_share_sides_with_domains(existing_domains: Array) -> bool:
	if vertices.is_empty():
		vertices = _find_domain_vertices()
	
	print("🔍 Verificando compartilhamento de ARESTAS para domínio %d com %d domínios existentes" % [domain_id, existing_domains.size()])
	
	for existing_domain in existing_domains:
		if existing_domain == self:
			continue
		
		var existing_vertices = existing_domain.get_vertices()
		print("🔍 Comparando com domínio %d (centro: %d)" % [existing_domain.get_domain_id(), existing_domain.get_center_star_id()])
		
		# Verificar cada ARESTA do novo domínio
		for i in range(vertices.size()):
			var new_side_start = vertices[i]
			var new_side_end = vertices[(i + 1) % vertices.size()]
			
			# Verificar contra cada ARESTA do domínio existente
			for j in range(existing_vertices.size()):
				var existing_side_start = existing_vertices[j]
				var existing_side_end = existing_vertices[(j + 1) % existing_vertices.size()]
				
				if _are_sides_identical(new_side_start, new_side_end, existing_side_start, existing_side_end):
					print("🔴 Domínio %d: ARESTA compartilhada detectada com domínio %d" % [domain_id, existing_domain.get_domain_id()])
					print("🔴 Aresta: %s -> %s" % [new_side_start, new_side_end])
					return true
	
	print("✅ Nenhuma ARESTA compartilhada detectada para domínio %d (vértices podem ser compartilhados)" % domain_id)
	return false

## Verificar se domínio está na estrela especificada
func is_at_star(star_id: int) -> bool:
	return center_star_id == star_id

## Obter ID do domínio
func get_domain_id() -> int:
	return domain_id

## Obter ID da estrela central
func get_center_star_id() -> int:
	return center_star_id

## Obter posição central
func get_center_position() -> Vector2:
	return center_position

## Obter vértices do domínio
func get_vertices():
	return vertices.duplicate()

## Obter proprietário do domínio
func get_owner_id() -> int:
	return owner_id

## Definir proprietário do domínio
func set_owner(new_owner_id: int) -> void:
	if owner_id != new_owner_id:
		var old_owner = owner_id
		owner_id = new_owner_id
		_update_visual_for_owner()
		print("👑 Domínio %d: proprietário alterado de %d para %d" % [domain_id, old_owner, new_owner_id])

## Definir cor do domínio
func set_color(new_color: Color) -> void:
	line_color = new_color
	if visual_node:
		visual_node.queue_redraw()
	print("🎨 Domínio %d: cor alterada para %s" % [domain_id, new_color])

## Obter informações do domínio
func get_info() -> Dictionary:
	return {
		"domain_id": domain_id,
		"center_star_id": center_star_id,
		"center_position": center_position,
		"vertices_count": vertices.size(),
		"owner_id": owner_id
	}

## Destruir domínio
func destroy() -> void:
	if visual_node and is_instance_valid(visual_node):
		visual_node.queue_free()
		visual_node = null
	
	domain_destroyed.emit(domain_id)
	print("💥 Domínio %d destruído" % domain_id)

## Limpar recursos do domínio
func cleanup() -> void:
	destroy()

## Encontrar vértices do domínio
func _find_domain_vertices():
	if not star_mapper_ref:
		return []
	
	var dot_positions = hex_grid_ref.get_dot_positions()
	var domain_vertices = []
	
	# Encontrar estrelas adjacentes
	var adjacent_positions = []
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = center_position.distance_to(star_pos)
		
		if distance > 5.0 and distance <= max_adjacent_distance:
			adjacent_positions.append(star_pos)
	
	# Ordenar por ângulo para formar hexágono correto
	adjacent_positions.sort_custom(func(a, b): 
		var angle_a = center_position.angle_to_point(a)
		var angle_b = center_position.angle_to_point(b)
		return angle_a < angle_b
	)
	
	# Pegar até 6 vértices
	for i in range(min(6, adjacent_positions.size())):
		domain_vertices.append(adjacent_positions[i])
	
	return domain_vertices

## Criar visualização do domínio
func _create_visual(parent_node: Node) -> bool:
	if visual_node:
		return true  # Já criada
	
	visual_node = Node2D.new()
	visual_node.z_index = z_index
	
	# Adicionar ao hex_grid em vez do parent_node para usar coordenadas locais
	hex_grid_ref.add_child(visual_node)
	visual_node.draw.connect(_draw_domain_hexagon)
	visual_node.queue_redraw()
	
	return true

## Desenhar hexágono do domínio
func _draw_domain_hexagon() -> void:
	# Desenhar hexágono tracejado entre vértices
	if vertices.size() >= 3:
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
		var segment_length = dash_length if drawing_dash else gap_length
		var remaining_length = total_length - distance_covered
		var actual_length = min(segment_length, remaining_length)
		
		var next_pos = current_pos + direction * actual_length
		
		if drawing_dash:
			visual_node.draw_line(current_pos, next_pos, line_color, line_width)
		
		current_pos = next_pos
		distance_covered += actual_length
		drawing_dash = not drawing_dash

## Validar ID de estrela
func _validate_star_id(star_id: int) -> bool:
	if not star_mapper_ref:
		print("❌ Domínio %d: referência do star_mapper não configurada" % domain_id)
		return false
	
	if star_id < 0 or star_id >= star_mapper_ref.get_star_count():
		print("❌ Domínio %d: ID de estrela inválido: %d" % [domain_id, star_id])
		return false
	
	return true

## Verificar se dois lados são idênticos
func _are_sides_identical(side1_start: Vector2, side1_end: Vector2, side2_start: Vector2, side2_end: Vector2) -> bool:
	# Verificar se side1 == side2 (mesma direção)
	if side1_start.distance_to(side2_start) <= position_tolerance and side1_end.distance_to(side2_end) <= position_tolerance:
		return true
	
	# Verificar se side1 == side2 (direção oposta)
	if side1_start.distance_to(side2_end) <= position_tolerance and side1_end.distance_to(side2_start) <= position_tolerance:
		return true
	
	return false

## Atualizar visual baseado no proprietário
func _update_visual_for_owner() -> void:
	if not visual_node:
		return
	
	# Aqui pode ser implementada lógica para cores diferentes por proprietário
	# Por enquanto mantém a cor padrão
	visual_node.queue_redraw()