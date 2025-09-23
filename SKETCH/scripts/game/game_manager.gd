## GameManager - Gerenciador Central do Jogo V&V
## Coordena entidades (Units e Domains) e regras de negócio

class_name GameManager
extends RefCounted

# Preload classes
const Logger = preload("res://scripts/core/logger.gd")
const Unit = preload("res://scripts/entities/unit.gd")
const Domain = preload("res://scripts/entities/domain.gd")

## Sinais do gerenciador
signal unit_created(unit)
signal unit_destroyed(unit)
signal domain_created(domain)
signal domain_destroyed(domain)
signal game_state_changed(new_state: String)

## Coleções de entidades
var units = []
var domains = []

## Referências do sistema
var hex_grid_ref = null
var star_mapper_ref = null
var parent_node_ref = null

## Configurações do jogo
var max_units_per_player: int = 10
var max_domains_per_player: int = 5

## Estado do jogo
var current_player_id: int = 1
var game_state: String = "playing"

## Configurar referências do sistema
func setup_references(hex_grid, star_mapper, parent_node) -> void:
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper
	parent_node_ref = parent_node
	Logger.debug("Referências configuradas", "GameManager")

## Criar nova unidade
func create_unit(star_id: int = -1):
	var unit = Unit.new()
	unit.setup_references(hex_grid_ref, star_mapper_ref)
	unit.create_visual(parent_node_ref)
	
	# Conectar sinais
	unit.unit_moved.connect(_on_unit_moved)
	unit.unit_positioned.connect(_on_unit_positioned)
	
	units.append(unit)
	
	# Posicionar se estrela especificada
	if star_id >= 0:
		unit.position_at_star(star_id)
	
	unit_created.emit(unit)
	Logger.debug("Unidade %d criada" % unit.get_info().unit_id, "GameManager")
	return unit

## Criar novo domínio
func create_domain(center_star_id: int):
	# Verificar se referências estão configuradas
	if not hex_grid_ref or not star_mapper_ref:
		Logger.error("Referências não configuradas (hex_grid: %s, star_mapper: %s)" % [hex_grid_ref != null, star_mapper_ref != null], "GameManager")
		return null
	
	# Verificar se já existe domínio na estrela
	for domain in domains:
		if domain.is_at_star(center_star_id):
			Logger.warning("Domínio já existe na estrela %d" % center_star_id, "GameManager")
			return null
	
	var domain = Domain.new()
	Logger.debug("Configurando referências para domínio %d" % domain.get_domain_id(), "GameManager")
	domain.setup_references(hex_grid_ref, star_mapper_ref)
	
	# Criar domínio primeiro
	if not domain.create_at_star(center_star_id, parent_node_ref):
		print("❌ GameManager: falha ao criar domínio na estrela %d" % center_star_id)
		domain.cleanup()
		return null
	
	# Verificar se compartilharia lados APÓS criação
	if domain.would_share_sides_with_domains(domains):
		print("❌ GameManager: domínio compartilharia lados com domínio existente")
		domain.cleanup()
		return null
	
	# Conectar sinais
	domain.domain_created.connect(_on_domain_created)
	domain.domain_destroyed.connect(_on_domain_destroyed)
	
	# Definir proprietário
	domain.set_owner(current_player_id)
	
	domains.append(domain)
	domain_created.emit(domain)
	print("🎮 GameManager: domínio %d criado na estrela %d" % [domain.get_domain_id(), center_star_id])
	return domain

## Criar domínio com unidade no centro (sistema de spawn)
func spawn_domain_with_unit(center_star_id: int):
	# Criar domínio primeiro
	var domain = create_domain(center_star_id)
	if not domain:
		return null
	
	# Criar unidade no centro do domínio
	var unit = create_unit(center_star_id)
	if not unit:
		print("⚠️ GameManager: falha ao criar unidade no centro do domínio %d" % domain.get_domain_id())
		return domain
	
	print("🎯 GameManager: spawn completo - domínio %d com unidade %d na estrela %d" % [domain.get_domain_id(), unit.get_info().unit_id, center_star_id])
	return {"domain": domain, "unit": unit}

## Criar domínio com unidade no centro (sistema de spawn com cor)
func spawn_domain_with_unit_colored(center_star_id: int, color: Color):
	# Criar domínio primeiro
	var domain = create_domain(center_star_id)
	if not domain:
		return null
	
	# Aplicar cor ao domínio
	domain.set_color(color)
	
	# Criar unidade no centro do domínio
	var unit = create_unit(center_star_id)
	if not unit:
		print("⚠️ GameManager: falha ao criar unidade no centro do domínio %d" % domain.get_domain_id())
		return domain
	
	# Aplicar cor à unidade
	unit.set_color(color)
	
	print("🎯 GameManager: spawn colorido completo - domínio %d com unidade %d na estrela %d (cor: %s)" % [domain.get_domain_id(), unit.get_info().unit_id, center_star_id, color])
	return {"domain": domain, "unit": unit}

## Mover unidade para estrela
func move_unit_to_star(unit, target_star_id: int) -> bool:
	if not unit in units:
		print("❌ GameManager: unidade não encontrada")
		return false
	
	# Verificar se movimento é válido (não bloqueado por terreno)
	if unit.is_positioned():
		var from_star_id = unit.get_current_star_id()
		if _is_movement_blocked_by_terrain(from_star_id, target_star_id):
			print("❌ GameManager: movimento bloqueado por terreno")
			return false
	
	return unit.move_to_star(target_star_id)

## Posicionar unidade em estrela (primeiro posicionamento)
func position_unit_at_star(unit, star_id: int) -> bool:
	if not unit in units:
		print("❌ GameManager: unidade não encontrada")
		return false
	
	return unit.position_at_star(star_id)

## Obter unidade na estrela
func get_unit_at_star(star_id: int):
	for unit in units:
		if unit.get_current_star_id() == star_id:
			return unit
	return null

## Obter domínio na estrela
func get_domain_at_star(star_id: int):
	for domain in domains:
		if domain.is_at_star(star_id):
			return domain
	return null

## Obter estrelas adjacentes válidas para unidade
func get_valid_adjacent_stars(unit):
	if not unit.is_positioned():
		return []
	
	var from_star_id = unit.get_current_star_id()
	var dot_positions = hex_grid_ref.get_dot_positions()
	var unit_position = dot_positions[from_star_id]
	var max_distance = 38.0
	var valid_stars = []
	
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = unit_position.distance_to(star_pos)
		
		# Verificar se está dentro da distância e não é a própria estrela
		if distance > 5.0 and distance <= max_distance:
			# Verificar se movimento não é bloqueado por terreno
			if not _is_movement_blocked_by_terrain(from_star_id, i):
				valid_stars.append(i)
	
	return valid_stars

## Obter todas as unidades
func get_all_units():
	return units.duplicate()

## Obter todos os domínios
func get_all_domains():
	return domains.duplicate()

## Obter estatísticas do jogo
func get_game_stats() -> Dictionary:
	return {
		"total_units": units.size(),
		"total_domains": domains.size(),
		"current_player": current_player_id,
		"game_state": game_state
	}

## Limpar todas as entidades
func clear_all_entities() -> void:
	# Limpar unidades
	for unit in units:
		unit.cleanup()
	units.clear()
	
	# Limpar domínios
	for domain in domains:
		domain.cleanup()
	domains.clear()
	
	print("🧹 GameManager: todas as entidades limpas")

## Limpar apenas unidades
func clear_all_units() -> void:
	for unit in units:
		unit.cleanup()
	units.clear()
	print("🧹 GameManager: todas as unidades limpas")

## Limpar apenas domínios
func clear_all_domains() -> void:
	for domain in domains:
		domain.cleanup()
	domains.clear()
	print("🧹 GameManager: todos os domínios limpos")

# Função removida - algoritmo movido para star_click_demo.gd

## Verificar se movimento é bloqueado por terreno
func _is_movement_blocked_by_terrain(from_star_id: int, to_star_id: int) -> bool:
	if not hex_grid_ref or not hex_grid_ref.cache:
		return false
	
	var terrain_color = _get_terrain_between_stars(from_star_id, to_star_id)
	
	# Cores de terreno bloqueado: azul (água) e cinza (montanha)
	var water_color = Color(0.0, 1.0, 1.0, 1.0)  # Cyan
	var mountain_color = Color(0.4, 0.4, 0.4, 1.0)  # Gray
	
	return terrain_color == water_color or terrain_color == mountain_color

## Obter cor do terreno entre duas estrelas
func _get_terrain_between_stars(from_star_id: int, to_star_id: int) -> Color:
	if not hex_grid_ref or not hex_grid_ref.cache:
		return Color.WHITE
	
	var diamond_colors = hex_grid_ref.cache.get_diamond_colors()
	var connections = hex_grid_ref.cache.get_connections()
	
	# Procurar pela conexão específica entre essas duas estrelas
	for i in range(connections.size()):
		var connection = connections[i]
		if (connection.index_a == from_star_id and connection.index_b == to_star_id) or \
		   (connection.index_a == to_star_id and connection.index_b == from_star_id):
			if i < diamond_colors.size():
				return diamond_colors[i]
	
	# Se não encontrou conexão direta, assumir terreno livre (verde)
	return Color(0.0, 1.0, 0.0, 1.0)  # Light green

## Callback: unidade movida
func _on_unit_moved(from_star_id: int, to_star_id: int) -> void:
	print("🎮 GameManager: unidade movida de %d para %d" % [from_star_id, to_star_id])

## Callback: unidade posicionada
func _on_unit_positioned(star_id: int) -> void:
	print("🎮 GameManager: unidade posicionada na estrela %d" % star_id)

## Callback: domínio criado
func _on_domain_created(domain_id: int, center_star_id: int) -> void:
	print("🎮 GameManager: domínio %d criado na estrela %d" % [domain_id, center_star_id])

## Callback: domínio destruído
func _on_domain_destroyed(domain_id: int) -> void:
	print("🎮 GameManager: domínio %d destruído" % domain_id)