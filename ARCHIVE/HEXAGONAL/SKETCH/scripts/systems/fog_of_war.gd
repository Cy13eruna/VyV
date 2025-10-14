## FogOfWar - Sistema de Névoa de Guerra
## Implementa visibilidade por team com ocultação de elementos adversários
## Cada team tem sua própria instância de fog of war

class_name FogOfWar
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Sinais do sistema
signal visibility_changed(team_id: String, visible_positions: Array)
signal enemy_revealed(team_id: String, enemy_type: String, enemy_id: int)
signal enemy_hidden(team_id: String, enemy_type: String, enemy_id: int)

## Estado da fog of war
var team_id: String = ""
var visible_stars: Dictionary = {}  # star_id -> bool
var visible_hexes: Dictionary = {}  # hex_position -> bool
var revealed_enemies: Dictionary = {}  # enemy_id -> enemy_data

## Referências do sistema
var hex_grid_ref = null
var star_mapper_ref = null
var game_manager_ref = null

## Configurações de visibilidade
var unit_vision_range: int = 6  # 6 estrelas + 6 losangos
var domain_vision_range: int = 6  # 6 estrelas + 12 losangos
var terrain_blocks_vision: bool = true  # Para unidades

## Tipos de terreno que bloqueiam visão
var blocking_terrain_types: Array = ["mountain", "forest"]

## Inicializar fog of war para um team específico
func initialize(team_identifier: String, hex_grid, star_mapper, game_manager) -> void:
	team_id = team_identifier
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper
	game_manager_ref = game_manager
	
	visible_stars.clear()
	visible_hexes.clear()
	revealed_enemies.clear()
	
	Logger.info("FogOfWar inicializada para team %s" % team_id, "FogOfWar")

## Atualizar visibilidade baseada nas unidades e domínios do team
func update_visibility(team_units: Array, team_domains: Array) -> void:
	# Limpar visibilidade anterior
	visible_stars.clear()
	visible_hexes.clear()
	
	# Calcular visibilidade das unidades
	for unit in team_units:
		if unit.is_positioned():
			_add_unit_vision(unit)
	
	# Calcular visibilidade dos domínios
	for domain in team_domains:
		_add_domain_vision(domain)
	
	# Atualizar inimigos revelados
	_update_revealed_enemies()
	
	# Emitir sinal de mudança
	var visible_positions = _get_all_visible_positions()
	visibility_changed.emit(team_id, visible_positions)
	
	Logger.debug("Visibilidade atualizada para team %s: %d estrelas, %d hexágonos" % [team_id, visible_stars.size(), visible_hexes.size()], "FogOfWar")

## Adicionar visão de uma unidade
func _add_unit_vision(unit) -> void:
	var unit_star_id = unit.get_current_star_id()
	if unit_star_id < 0:
		return
	
	var unit_position = star_mapper_ref.get_star_position(unit_star_id)
	
	# Revelar estrela da unidade
	visible_stars[unit_star_id] = true
	
	# Revelar estrelas adjacentes (com bloqueio de terreno)
	var adjacent_stars = _get_adjacent_stars(unit_star_id)
	for star_id in adjacent_stars:
		if _has_line_of_sight(unit_position, star_mapper_ref.get_star_position(star_id)):
			visible_stars[star_id] = true
	
	# Revelar hexágonos adjacentes
	var adjacent_hexes = _get_adjacent_hexes(unit_position)
	for hex_pos in adjacent_hexes:
		if _has_line_of_sight(unit_position, hex_pos):
			visible_hexes[_position_to_key(hex_pos)] = true

## Adicionar visão de um domínio
func _add_domain_vision(domain) -> void:
	var domain_center = domain.get_center_position()
	var domain_vertices = domain.get_vertices()
	
	# Revelar estrela central do domínio
	var center_star_id = domain.get_center_star_id()
	if center_star_id >= 0:
		visible_stars[center_star_id] = true
	
	# Revelar estrelas adjacentes (sem bloqueio de terreno)
	var adjacent_stars = _get_adjacent_stars(center_star_id)
	for star_id in adjacent_stars:
		visible_stars[star_id] = true
	
	# Revelar todos os vértices do domínio
	for vertex in domain_vertices:
		visible_hexes[_position_to_key(vertex)] = true
	
	# Revelar hexágonos adjacentes aos vértices
	for vertex in domain_vertices:
		var adjacent_hexes = _get_adjacent_hexes(vertex)
		for hex_pos in adjacent_hexes:
			visible_hexes[_position_to_key(hex_pos)] = true

## Obter estrelas adjacentes a uma estrela
func _get_adjacent_stars(star_id: int) -> Array:
	var adjacent = []
	if not star_mapper_ref or star_id < 0:
		return adjacent
	
	var star_position = star_mapper_ref.get_star_position(star_id)
	var all_positions = hex_grid_ref.get_dot_positions()
	
	for i in range(all_positions.size()):
		if i == star_id:
			continue
		
		var distance = star_position.distance_to(all_positions[i])
		if distance <= 40.0:  # Distância de adjacência
			adjacent.append(i)
	
	return adjacent

## Obter hexágonos adjacentes a uma posição
func _get_adjacent_hexes(center_position: Vector2) -> Array:
	var adjacent = []
	var hex_radius = 20.0  # Raio aproximado de um hexágono
	
	# Calcular posições hexagonais ao redor do centro
	for angle in range(0, 360, 60):  # 6 direções hexagonais
		var rad = deg_to_rad(angle)
		var hex_pos = center_position + Vector2(cos(rad), sin(rad)) * hex_radius
		adjacent.append(hex_pos)
	
	return adjacent

## Verificar linha de visão (para unidades com bloqueio de terreno)
func _has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	if not terrain_blocks_vision:
		return true
	
	# Implementação simplificada - assumir que não há bloqueio por enquanto
	# TODO: Implementar verificação real de terreno quando sistema de terreno estiver disponível
	return true

## Atualizar inimigos revelados
func _update_revealed_enemies() -> void:
	if not game_manager_ref:
		return
	
	var previous_revealed = revealed_enemies.duplicate()
	revealed_enemies.clear()
	
	# Verificar unidades inimigas
	var all_units = game_manager_ref.get_all_units()
	for unit in all_units:
		if _is_enemy_unit(unit) and _is_position_visible_for_unit(unit):
			var unit_id = unit.unit_id
			revealed_enemies[unit_id] = {
				"type": "unit",
				"id": unit_id,
				"object": unit
			}
			
			# Emitir sinal se recém revelado
			if not previous_revealed.has(unit_id):
				enemy_revealed.emit(team_id, "unit", unit_id)
	
	# Verificar domínios inimigos
	var all_domains = game_manager_ref.get_all_domains()
	for domain in all_domains:
		if _is_enemy_domain(domain) and _is_position_visible_for_domain(domain):
			var domain_id = domain.get_domain_id()
			revealed_enemies[domain_id] = {
				"type": "domain",
				"id": domain_id,
				"object": domain
			}
			
			# Emitir sinal se recém revelado
			if not previous_revealed.has(domain_id):
				enemy_revealed.emit(team_id, "domain", domain_id)
	
	# Emitir sinais para inimigos que foram ocultados
	for enemy_id in previous_revealed.keys():
		if not revealed_enemies.has(enemy_id):
			var enemy_data = previous_revealed[enemy_id]
			enemy_hidden.emit(team_id, enemy_data.type, enemy_id)

## Verificar se unidade é inimiga
func _is_enemy_unit(unit) -> bool:
	# TODO: Implementar verificação real de team quando sistema de teams estiver integrado
	# Por enquanto, assumir que unidades com cores diferentes são inimigas
	return true

## Verificar se domínio é inimigo
func _is_enemy_domain(domain) -> bool:
	# TODO: Implementar verificação real de team quando sistema de teams estiver integrado
	# Por enquanto, assumir que domínios com cores diferentes são inimigos
	return true

## Verificar se posição da unidade está visível
func _is_position_visible_for_unit(unit) -> bool:
	if not unit.is_positioned():
		return false
	
	var star_id = unit.get_current_star_id()
	return visible_stars.has(star_id) and visible_stars[star_id]

## Verificar se posição do domínio está visível
func _is_position_visible_for_domain(domain) -> bool:
	var center_star_id = domain.get_center_star_id()
	if center_star_id >= 0 and visible_stars.has(center_star_id) and visible_stars[center_star_id]:
		return true
	
	# Verificar se algum vértice está visível
	var vertices = domain.get_vertices()
	for vertex in vertices:
		var key = _position_to_key(vertex)
		if visible_hexes.has(key) and visible_hexes[key]:
			return true
	
	return false

## Verificar se uma estrela está visível para este team
func is_star_visible(star_id: int) -> bool:
	return visible_stars.has(star_id) and visible_stars[star_id]

## Verificar se uma posição hexagonal está visível para este team
func is_hex_visible(position: Vector2) -> bool:
	var key = _position_to_key(position)
	return visible_hexes.has(key) and visible_hexes[key]

## Verificar se um inimigo está revelado
func is_enemy_revealed(enemy_type: String, enemy_id: int) -> bool:
	return revealed_enemies.has(enemy_id)

## Obter todas as posições visíveis
func _get_all_visible_positions() -> Array:
	var positions = []
	
	# Adicionar estrelas visíveis
	for star_id in visible_stars.keys():
		if visible_stars[star_id]:
			positions.append({
				"type": "star",
				"id": star_id,
				"position": star_mapper_ref.get_star_position(star_id)
			})
	
	# Adicionar hexágonos visíveis
	for hex_key in visible_hexes.keys():
		if visible_hexes[hex_key]:
			positions.append({
				"type": "hex",
				"position": _key_to_position(hex_key)
			})
	
	return positions

## Converter posição para chave string
func _position_to_key(position: Vector2) -> String:
	return "%.1f_%.1f" % [position.x, position.y]

## Converter chave string para posição
func _key_to_position(key: String) -> Vector2:
	var parts = key.split("_")
	if parts.size() >= 2:
		return Vector2(float(parts[0]), float(parts[1]))
	return Vector2.ZERO

## Obter estatísticas da fog of war
func get_stats() -> Dictionary:
	return {
		"team_id": team_id,
		"visible_stars": visible_stars.size(),
		"visible_hexes": visible_hexes.size(),
		"revealed_enemies": revealed_enemies.size(),
		"enemy_units": _count_revealed_by_type("unit"),
		"enemy_domains": _count_revealed_by_type("domain")
	}

## Contar inimigos revelados por tipo
func _count_revealed_by_type(type: String) -> int:
	var count = 0
	for enemy_data in revealed_enemies.values():
		if enemy_data.type == type:
			count += 1
	return count

## Limpar fog of war
func clear() -> void:
	visible_stars.clear()
	visible_hexes.clear()
	revealed_enemies.clear()
	Logger.debug("FogOfWar limpa para team %s" % team_id, "FogOfWar")