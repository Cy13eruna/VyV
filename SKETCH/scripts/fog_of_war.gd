## FogOfWar - Sistema de Visibilidade por Time
## Gerencia a visibilidade de estrelas e losangos para cada time
## Baseado em domínios e unidades de cada jogador

class_name FogOfWar
extends RefCounted

## Sinais do sistema
signal visibility_changed(team_id: int)
signal fog_updated()

## Referências do sistema
var hex_grid_ref = null
var game_manager_ref = null

## Dados de visibilidade por time
var team_visible_stars: Dictionary = {}  # team_id -> Array[int] (star IDs)
var team_visible_diamonds: Dictionary = {}  # team_id -> Array[int] (diamond IDs)

## Cache de visibilidade
var visibility_cache_valid: bool = false
var last_update_time: float = 0.0

## Configurações
var fog_enabled: bool = true
var debug_mode: bool = false

## Configurar referências do sistema
func setup_references(hex_grid, game_manager) -> void:
	hex_grid_ref = hex_grid
	game_manager_ref = game_manager
	print("🌫️ FogOfWar: referências configuradas")

## Ativar/desativar fog of war
func set_fog_enabled(enabled: bool) -> void:
	fog_enabled = enabled
	if enabled and game_manager_ref:
		# Obter domínios e unidades do game manager
		var domains = game_manager_ref.get_all_domains()
		var units = game_manager_ref.get_all_units()
		update_all_team_visibility(domains, units)
	else:
		_clear_all_fog()
	fog_updated.emit()
	print("🌫️ FogOfWar: %s" % ("ativado" if enabled else "desativado"))

## Atualizar visibilidade de todos os times
func update_all_team_visibility(domains: Array, units: Array) -> void:
	if debug_mode:
		print("🌫️ FogOfWar: atualizando visibilidade de todos os times...")
	
	for team_id in range(1, 7):  # Times 1-6
		_update_team_visibility(team_id, domains, units)
	
	last_update_time = Time.get_unix_time_from_system()
	visibility_cache_valid = true
	
	if debug_mode:
		print("🌫️ FogOfWar: visibilidade atualizada para todos os times")

## Atualizar visibilidade IMEDIATAMENTE quando unidade se move
func update_visibility_immediately(domains: Array, units: Array) -> void:
	if debug_mode:
		print("🌫️ FogOfWar: atualização IMEDIATA de visibilidade...")
	
	# Forçar atualização imediata
	visibility_cache_valid = false
	update_all_team_visibility(domains, units)
	
	if debug_mode:
		print("🌫️ FogOfWar: visibilidade atualizada IMEDIATAMENTE")

## Atualizar visibilidade de um time específico
func _update_team_visibility(team_id: int, domains: Array, units: Array) -> void:
	var visible_stars: Array[int] = []
	var visible_diamonds: Array[int] = []
	
	# Processar domínios do time
	for domain in domains:
		if domain.get_owner_id() == team_id:
			var domain_visibility = _calculate_domain_visibility(domain)
			# Verificar se o resultado tem as chaves esperadas
			if domain_visibility.has("stars") and domain_visibility.has("diamonds"):
				visible_stars.append_array(domain_visibility.stars)
				visible_diamonds.append_array(domain_visibility.diamonds)
			else:
				print("⚠️ FogOfWar: domain_visibility inválido para domínio do time %d" % team_id)
	
	# Processar unidades do time
	for unit in units:
		if unit.get_team_id() == team_id and unit.is_positioned():
			var unit_visibility = _calculate_unit_visibility(unit)
			# Verificar se o resultado tem as chaves esperadas
			if unit_visibility.has("stars") and unit_visibility.has("diamonds"):
				visible_stars.append_array(unit_visibility.stars)
				visible_diamonds.append_array(unit_visibility.diamonds)
			else:
				print("⚠️ FogOfWar: unit_visibility inválido para unidade do time %d" % team_id)
	
	# Remover duplicatas
	visible_stars = _remove_duplicates_int(visible_stars)
	visible_diamonds = _remove_duplicates_int(visible_diamonds)
	
	# Armazenar visibilidade do time
	team_visible_stars[team_id] = visible_stars
	team_visible_diamonds[team_id] = visible_diamonds
	
	visibility_changed.emit(team_id)
	
	if debug_mode:
		print("🌫️ Time %d: %d estrelas visíveis, %d losangos visíveis" % [team_id, visible_stars.size(), visible_diamonds.size()])

## Calcular visibilidade de um domínio
## Regra SIMPLIFICADA: APENAS 6 estrelas + 12 losangos que compõem o domínio
func _calculate_domain_visibility(domain) -> Dictionary:
	var visible_stars: Array[int] = []
	var visible_diamonds: Array[int] = []
	
	var center_star_id = domain.get_center_star_id()
	var domain_vertices = domain.get_vertices()
	
	if domain_vertices.size() != 6:
		print("⚠️ FogOfWar: domínio com %d vértices (esperado: 6)" % domain_vertices.size())
		return {"stars": visible_stars, "diamonds": visible_diamonds}
	
	# 1. Estrela central do domínio
	visible_stars.append(center_star_id)
	
	# 2. As 6 estrelas dos vértices do domínio
	var dot_positions = hex_grid_ref.get_dot_positions()
	for vertex_pos in domain_vertices:
		var vertex_star_id = _find_star_at_position(vertex_pos, dot_positions)
		if vertex_star_id >= 0:
			visible_stars.append(vertex_star_id)
	
	# 3. APENAS os 12 losangos que compõem o domínio (SEM adjacentes extras)
	# Converter Array para Array[Vector2] para compatibilidade
	var vertices_typed: Array[Vector2] = []
	for vertex in domain_vertices:
		vertices_typed.append(vertex)
	var domain_diamonds = _find_diamonds_in_domain(center_star_id, vertices_typed)
	visible_diamonds.append_array(domain_diamonds)
	
	# REMOVIDO: Losangos adjacentes às estrelas externas (conforme preferência)
	
	return {"stars": visible_stars, "diamonds": visible_diamonds}

## Calcular visibilidade de uma unidade
## Regra: 6 estrelas adjacentes + 6 losangos que a cercam
func _calculate_unit_visibility(unit) -> Dictionary:
	var visible_stars: Array[int] = []
	var visible_diamonds: Array[int] = []
	
	var unit_star_id = unit.get_current_star_id()
	var dot_positions = hex_grid_ref.get_dot_positions()
	
	if unit_star_id < 0 or unit_star_id >= dot_positions.size():
		return {"stars": visible_stars, "diamonds": visible_diamonds}
	
	# 1. Estrela onde a unidade está
	visible_stars.append(unit_star_id)
	
	# 2. As 6 estrelas adjacentes à unidade
	var adjacent_stars = _find_adjacent_stars(unit_star_id, dot_positions)
	visible_stars.append_array(adjacent_stars)
	
	# 3. Os 6 losangos que cercam a unidade
	var surrounding_diamonds = _find_diamonds_around_star(unit_star_id)
	visible_diamonds.append_array(surrounding_diamonds)
	
	return {"stars": visible_stars, "diamonds": visible_diamonds}

## Verificar se estrela está visível para um time
func is_star_visible(star_id: int, team_id: int) -> bool:
	if not fog_enabled:
		return true
	
	if not team_visible_stars.has(team_id):
		return false
	
	return star_id in team_visible_stars[team_id]

## Verificar se domínio adversário está visível para um time
func is_enemy_domain_visible(domain, viewing_team_id: int) -> bool:
	if not fog_enabled:
		return true
	
	# Domínios próprios sempre visíveis
	if domain.get_owner_id() == viewing_team_id:
		return true
	
	# Domínio adversário só visível se sua estrela central estiver revelada
	var center_star_id = domain.get_center_star_id()
	return is_star_visible(center_star_id, viewing_team_id)

## Verificar se unidade adversária está visível para um time
func is_enemy_unit_visible(unit, viewing_team_id: int) -> bool:
	if not fog_enabled:
		return true
	
	# Unidades próprias sempre visíveis
	if unit.get_team_id() == viewing_team_id:
		return true
	
	# Unidade adversária só visível se estiver em estrela revelada
	if not unit.is_positioned():
		return false
	
	var unit_star_id = unit.get_current_star_id()
	return is_star_visible(unit_star_id, viewing_team_id)

## Verificar se um losango é visível para um time
func is_diamond_visible(diamond_id: int, team_id: int) -> bool:
	if not fog_enabled:
		return true
	
	if not team_visible_diamonds.has(team_id):
		return false
	
	return diamond_id in team_visible_diamonds[team_id]

## Obter todas as estrelas visíveis para um time
func get_visible_stars(team_id: int) -> Array[int]:
	if not fog_enabled:
		return _get_all_star_ids()
	
	if not team_visible_stars.has(team_id):
		return []
	
	return team_visible_stars[team_id].duplicate()

## Obter todos os losangos visíveis para um time
func get_visible_diamonds(team_id: int) -> Array[int]:
	if not fog_enabled:
		return _get_all_diamond_ids()
	
	if not team_visible_diamonds.has(team_id):
		return []
	
	return team_visible_diamonds[team_id].duplicate()

## Encontrar estrela na posição especificada
func _find_star_at_position(position: Vector2, dot_positions: Array[Vector2]) -> int:
	var tolerance = 10.0  # Tolerância para encontrar estrela
	
	for i in range(dot_positions.size()):
		if position.distance_to(dot_positions[i]) <= tolerance:
			return i
	
	return -1

## Encontrar estrelas adjacentes a uma estrela
func _find_adjacent_stars(star_id: int, dot_positions: Array[Vector2]) -> Array[int]:
	var adjacent: Array[int] = []
	var max_distance = 38.0  # Distância máxima para adjacência
	
	if star_id < 0 or star_id >= dot_positions.size():
		return adjacent
	
	var star_pos = dot_positions[star_id]
	
	for i in range(dot_positions.size()):
		if i == star_id:
			continue
		
		var distance = star_pos.distance_to(dot_positions[i])
		if distance > 5.0 and distance <= max_distance:
			adjacent.append(i)
	
	return adjacent

## Encontrar losangos que compõem um domínio
func _find_diamonds_in_domain(center_star_id: int, vertices: Array) -> Array[int]:
	var diamonds: Array[int] = []
	var connections = hex_grid_ref.cache.get_connections()
	var dot_positions = hex_grid_ref.get_dot_positions()
	
	# Encontrar IDs das estrelas dos vértices
	var vertex_star_ids: Array[int] = []
	for vertex_pos in vertices:
		var vertex_id = _find_star_at_position(vertex_pos, dot_positions)
		if vertex_id >= 0:
			vertex_star_ids.append(vertex_id)
	
	# Encontrar conexões que envolvem o centro ou os vértices do domínio
	for i in range(connections.size()):
		var connection = connections[i]
		var star_a = connection.index_a
		var star_b = connection.index_b
		
		# Verificar se a conexão envolve o centro ou vértices do domínio
		var involves_center = (star_a == center_star_id or star_b == center_star_id)
		var involves_vertex = (star_a in vertex_star_ids or star_b in vertex_star_ids)
		
		if involves_center or involves_vertex:
			diamonds.append(i)
	
	return diamonds

## Encontrar losangos adjacentes a uma estrela
func _find_diamonds_adjacent_to_star(star_id: int) -> Array[int]:
	var diamonds: Array[int] = []
	var connections = hex_grid_ref.cache.get_connections()
	
	# Encontrar todas as conexões que envolvem esta estrela
	for i in range(connections.size()):
		var connection = connections[i]
		if connection.index_a == star_id or connection.index_b == star_id:
			diamonds.append(i)
	
	return diamonds

## Encontrar losangos ao redor de uma estrela (para unidades)
func _find_diamonds_around_star(star_id: int) -> Array[int]:
	# Para unidades, usar a mesma lógica de adjacência
	return _find_diamonds_adjacent_to_star(star_id)

## Obter todos os IDs de estrelas (para modo sem fog)
func _get_all_star_ids() -> Array[int]:
	var all_stars: Array[int] = []
	var dot_positions = hex_grid_ref.get_dot_positions()
	
	for i in range(dot_positions.size()):
		all_stars.append(i)
	
	return all_stars

## Obter todos os IDs de losangos (para modo sem fog)
func _get_all_diamond_ids() -> Array[int]:
	var all_diamonds: Array[int] = []
	var connections = hex_grid_ref.cache.get_connections()
	
	for i in range(connections.size()):
		all_diamonds.append(i)
	
	return all_diamonds

## Remover duplicatas de array de inteiros
func _remove_duplicates_int(array: Array[int]) -> Array[int]:
	var unique: Array[int] = []
	var seen: Dictionary = {}
	
	for item in array:
		if not seen.has(item):
			seen[item] = true
			unique.append(item)
	
	return unique

## Limpar toda a fog of war (mostrar tudo)
func _clear_all_fog() -> void:
	team_visible_stars.clear()
	team_visible_diamonds.clear()
	visibility_cache_valid = false

## Debug: imprimir informações de visibilidade
func _print_visibility_debug() -> void:
	print("🌫️ === DEBUG VISIBILIDADE ===")
	for team_id in team_visible_stars.keys():
		var stars = team_visible_stars[team_id].size()
		var diamonds = team_visible_diamonds.get(team_id, []).size()
		print("🌫️ Time %d: %d estrelas, %d losangos visíveis" % [team_id, stars, diamonds])
	print("🌫️ ========================")

## Ativar/desativar modo debug
func set_debug_mode(enabled: bool) -> void:
	debug_mode = enabled
	print("🌫️ FogOfWar: debug mode %s" % ("ativado" if enabled else "desativado"))

## Destructor para limpeza automática
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(self):
			cleanup()

## Invalidar cache de visibilidade (forçar recálculo)
func invalidate_visibility_cache() -> void:
	visibility_cache_valid = false
	print("🌫️ FogOfWar: cache de visibilidade invalidado")

## Verificar se o cache de visibilidade precisa ser atualizado
func needs_visibility_update() -> bool:
	if not visibility_cache_valid:
		return true
	
	# Atualizar a cada 1 segundo ou quando necessário
	var current_time = Time.get_unix_time_from_system()
	return (current_time - last_update_time) > 1.0

## Limpeza de recursos para evitar vazamentos de memória
func cleanup() -> void:
	# Verificar se ainda é válido
	if not is_instance_valid(self):
		return
	
	# Limpar dados de visibilidade
	if team_visible_stars:
		team_visible_stars.clear()
	if team_visible_diamonds:
		team_visible_diamonds.clear()
	
	# Invalidar cache
	visibility_cache_valid = false
	
	# Limpar referências
	hex_grid_ref = null
	game_manager_ref = null
	
	if debug_mode:
		print("🌫️ FogOfWar: recursos limpos")