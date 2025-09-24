## Domain - Entidade de Domínio do Jogo V&V
## Representa um domínio hexagonal no tabuleiro
## Implementa interfaces IGameEntity, IResourceProducer, IOwnable

class_name Domain
extends RefCounted

# Importar sistema de logging e interfaces
const Logger = preload("res://scripts/core/logger.gd")
const ObjectPool = preload("res://scripts/core/object_pool.gd")
const ObjectFactories = preload("res://scripts/core/object_factories.gd")
const Interfaces = preload("res://scripts/core/interfaces.gd")

## Sinais do domínio
signal domain_created(domain_id: int, center_star_id: int)
signal domain_destroyed(domain_id: int)

## Implementação das interfaces
# IGameEntity
var entity_id: String = ""
var entity_type: String = "domain"
var is_active: bool = true
var world_position: Vector2 = Vector2.ZERO
var metadata: Dictionary = {}

# IResourceProducer
var resource_type: String = "power"
var production_rate: int = 1
var stored_resources: int = 0
var storage_capacity: int = 10

# IOwnable
var owner_id: String = ""
var owner_color: Color = Color.MAGENTA

## Propriedades específicas do domínio
var domain_id: int = -1
var center_star_id: int = -1
var center_position: Vector2 = Vector2.ZERO
var vertices = []
var legacy_owner_id: int = -1  # Manter compatibilidade

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
	entity_id = "domain_" + str(domain_id)
	entity_type = "domain"
	is_active = true
	
	# Configurar produção de recursos
	resource_type = "power"
	production_rate = 1
	stored_resources = 0
	storage_capacity = 10
	
	Logger.debug("Domínio %s inicializado" % entity_id, "Domain")

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
		Logger.warning("Domínio %d: não foi possível encontrar 6 vértices adjacentes (apenas %d)" % [domain_id, vertices.size()], "Domain")
		# Temporariamente permitir domínios com menos vértices para debug
		# return false
	
	# Criar visualização
	if not _create_visual(parent_node):
		Logger.error("Domínio %d: falha ao criar visualização" % domain_id, "Domain")
		return false
	
	domain_created.emit(domain_id, center_star_id)
	Logger.info("Domínio %d criado na estrela %d com %d vértices" % [domain_id, center_star_id, vertices.size()], "Domain")
	return true

## Verificar se domínio compartilharia lados com outros domínios
func would_share_sides_with_domains(existing_domains: Array) -> bool:
	if vertices.is_empty():
		vertices = _find_domain_vertices()
	
	Logger.debug("Verificando compartilhamento de ARESTAS para domínio %d com %d domínios existentes" % [domain_id, existing_domains.size()], "Domain")
	
	for existing_domain in existing_domains:
		if existing_domain == self:
			continue
		
		var existing_vertices = existing_domain.get_vertices()
		Logger.debug("Comparando com domínio %d (centro: %d)" % [existing_domain.get_domain_id(), existing_domain.get_center_star_id()], "Domain")
		
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

## Obter proprietário do domínio (legacy)
func get_owner_id() -> int:
	return legacy_owner_id

## Definir proprietário do domínio (legacy)
func set_legacy_owner(new_owner_id: int) -> void:
	if legacy_owner_id != new_owner_id:
		var old_owner = legacy_owner_id
		legacy_owner_id = new_owner_id
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
		"owner_id": legacy_owner_id
	}

## Destruir domínio
func destroy() -> void:
	if visual_node and is_instance_valid(visual_node):
		visual_node.queue_free()
		visual_node = null
	
	domain_destroyed.emit(domain_id)
	print("💥 Domínio %d destruído" % domain_id)

## Limpar recursos
func cleanup() -> void:
	if visual_node and is_instance_valid(visual_node):
		# Desconectar sinais
		if visual_node.draw.is_connected(_draw_domain_hexagon):
			visual_node.draw.disconnect(_draw_domain_hexagon)
		
		# Remover do parent
		if visual_node.get_parent():
			visual_node.get_parent().remove_child(visual_node)
		
		# Retornar ao pool
		ObjectPool.return_object("DomainNode", visual_node)
		visual_node = null
	
	Logger.debug("Domínio %d: recursos limpos e retornados ao ObjectPool" % domain_id, "Domain")

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
	
	# Criar visual do domínio usando ObjectPool
	visual_node = ObjectPool.get_object("DomainNode", ObjectFactories.create_domain_node)
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

# ================================================================
# IMPLEMENTAÇÃO DAS INTERFACES
# ================================================================

## IGameEntity - Inicializar entidade com dados básicos
func initialize(id: String, type: String, position: Vector2) -> bool:
	entity_id = id
	entity_type = type
	world_position = position
	is_active = true
	Logger.debug("Entidade %s (%s) inicializada em %s" % [id, type, position], "Domain")
	return true

## IGameEntity - Atualizar entidade
func update(delta: float) -> void:
	if not is_active:
		return
	
	# Atualizar posição mundial baseada na posição central
	world_position = center_position
	
	# Produzir recursos automaticamente (pode ser controlado por turnos)
	if can_produce():
		produce_resources()

## IGameEntity - Validar estado da entidade
func validate() -> bool:
	if entity_id.is_empty():
		Logger.error("Domínio sem ID válido", "Domain")
		return false
	if entity_type.is_empty():
		Logger.error("Domínio sem tipo válido", "Domain")
		return false
	return true

## IGameEntity - Serializar entidade
func serialize() -> Dictionary:
	return {
		"entity_id": entity_id,
		"entity_type": entity_type,
		"is_active": is_active,
		"world_position": world_position,
		"metadata": metadata,
		"domain_id": domain_id,
		"center_star_id": center_star_id,
		"center_position": center_position,
		"vertices": vertices,
		"resource_type": resource_type,
		"production_rate": production_rate,
		"stored_resources": stored_resources,
		"storage_capacity": storage_capacity,
		"owner_id": owner_id,
		"owner_color": var_to_str(owner_color),
		"legacy_owner_id": legacy_owner_id
	}

## IGameEntity - Deserializar entidade
func deserialize(data: Dictionary) -> bool:
	if not data.has("entity_id") or not data.has("entity_type"):
		Logger.error("Dados de deserialização inválidos", "Domain")
		return false
	
	entity_id = data.get("entity_id", "")
	entity_type = data.get("entity_type", "")
	is_active = data.get("is_active", true)
	world_position = data.get("world_position", Vector2.ZERO)
	metadata = data.get("metadata", {})
	domain_id = data.get("domain_id", -1)
	center_star_id = data.get("center_star_id", -1)
	center_position = data.get("center_position", Vector2.ZERO)
	vertices = data.get("vertices", [])
	resource_type = data.get("resource_type", "power")
	production_rate = data.get("production_rate", 1)
	stored_resources = data.get("stored_resources", 0)
	storage_capacity = data.get("storage_capacity", 10)
	owner_id = data.get("owner_id", "")
	legacy_owner_id = data.get("legacy_owner_id", -1)
	
	if data.has("owner_color"):
		owner_color = str_to_var(data.get("owner_color"))
	
	return validate()

## IResourceProducer - Produzir recursos
func produce_resources() -> int:
	if not is_active:
		return 0
	
	var produced = production_rate
	stored_resources = min(storage_capacity, stored_resources + produced)
	
	Logger.debug("Domínio %s produziu %d %s (total: %d/%d)" % [entity_id, produced, resource_type, stored_resources, storage_capacity], "Domain")
	return produced

## IResourceProducer - Coletar recursos armazenados
func collect_resources() -> int:
	var collected = stored_resources
	stored_resources = 0
	Logger.debug("Domínio %s coletou %d %s" % [entity_id, collected, resource_type], "Domain")
	return collected

## IResourceProducer - Verificar se pode produzir
func can_produce() -> bool:
	return is_active and stored_resources < storage_capacity

## IOwnable - Definir proprietário
func set_owner(player_id: String, color: Color = Color.MAGENTA) -> void:
	owner_id = player_id
	owner_color = color
	line_color = color  # Atualizar cor visual
	# Manter compatibilidade com sistema legado
	legacy_owner_id = player_id.hash() if not player_id.is_empty() else -1
	if visual_node:
		visual_node.queue_redraw()
	Logger.debug("Domínio %s agora pertence ao jogador %s" % [entity_id, player_id], "Domain")

## IOwnable - Verificar se pertence a um jogador
func belongs_to(player_id: String) -> bool:
	return owner_id == player_id

## IOwnable - Verificar se tem proprietário
func has_owner() -> bool:
	return not owner_id.is_empty()