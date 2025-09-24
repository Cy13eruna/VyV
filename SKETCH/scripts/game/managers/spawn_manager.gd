## SpawnManager - Gerenciador de spawn de domínios e unidades
## Responsabilidade: Centralizar toda a lógica de spawn do jogo
##
## ✅ REFATORAÇÃO: Lógica extraída do main_game.gd
## 🎯 Objetivo: Simplificar main_game.gd e centralizar spawn logic

class_name SpawnManager
extends RefCounted

const Logger = preload("res://scripts/core/logger.gd")
const GameConfig = preload("res://scripts/core/game_config.gd")

## Referências necessárias
var hex_grid_ref
var star_mapper_ref
var game_manager_ref

## Inicializar SpawnManager com referências
func initialize(hex_grid, star_mapper, game_manager) -> void:
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper
	game_manager_ref = game_manager
	Logger.debug("SpawnManager inicializado", "SpawnManager")

## Executar spawn de domínios baseado no número solicitado
func spawn_domains(domain_count: int) -> int:
	if not _validate_references():
		Logger.error("Referências não configuradas para spawn", "SpawnManager")
		return 0
	
	# Limpar domínios e unidades existentes
	game_manager_ref.clear_all_units()
	game_manager_ref.clear_all_domains()
	
	# Encontrar vértices disponíveis para spawn
	var available_vertices = _find_spawn_vertices()
	if available_vertices.size() == 0:
		Logger.warning("Nenhum vértice disponível para spawn", "SpawnManager")
		return 0
	
	# Selecionar vértices aleatórios
	var selected_vertices = _select_random_vertices(available_vertices, domain_count)
	
	# Spawnar domínios com cores
	return _spawn_colored_domains(selected_vertices)

## Validar se todas as referências estão configuradas
func _validate_references() -> bool:
	return hex_grid_ref != null and star_mapper_ref != null and game_manager_ref != null

## Encontrar vértices válidos para spawn de domínios
func _find_spawn_vertices() -> Array:
	if not hex_grid_ref or not star_mapper_ref:
		return []
	
	var dot_positions = hex_grid_ref.get_dot_positions()
	var total_stars = star_mapper_ref.get_star_count()
	var domain_centers = []
	
	# Calcular centro do mapa
	var center = Vector2.ZERO
	for pos in dot_positions:
		center += pos
	center /= dot_positions.size()
	
	# Calcular distâncias das estrelas ao centro
	var star_distances = []
	for i in range(dot_positions.size()):
		var pos = dot_positions[i]
		var distance = center.distance_to(pos)
		star_distances.append({"id": i, "distance": distance, "pos": pos})
	
	# Ordenar por distância (mais distantes primeiro)
	star_distances.sort_custom(func(a, b): return a.distance > b.distance)
	var twelve_farthest = star_distances.slice(0, min(12, star_distances.size()))
	
	# Encontrar pares de estrelas distantes
	var pairs = []
	var used_stars = []
	
	for star_a in twelve_farthest:
		if star_a.id in used_stars or pairs.size() >= 6:
			continue
		
		var closest_star = null
		var closest_distance = 999999.0
		
		for star_b in twelve_farthest:
			if star_b.id == star_a.id or star_b.id in used_stars:
				continue
			
			var distance = star_a.pos.distance_to(star_b.pos)
			if distance < closest_distance:
				closest_distance = distance
				closest_star = star_b
		
		if closest_star:
			pairs.append([star_a, closest_star])
			used_stars.append_array([star_a.id, closest_star.id])
	
	# Encontrar centros comuns para cada par
	for pair in pairs:
		var center_star = _find_common_adjacent_star(pair[0].id, pair[1].id, dot_positions)
		if center_star >= 0 and center_star < total_stars:
			domain_centers.append(center_star)
	
	Logger.debug("Encontrados %d vértices para spawn" % domain_centers.size(), "SpawnManager")
	return domain_centers

## Encontrar estrela adjacente comum entre duas estrelas
func _find_common_adjacent_star(star_a_id: int, star_b_id: int, dot_positions: Array) -> int:
	var max_adjacent_distance = GameConfig.MAX_ADJACENT_DISTANCE
	
	# Encontrar estrelas adjacentes à estrela A
	var adjacent_to_a = []
	var star_a_pos = dot_positions[star_a_id]
	for i in range(dot_positions.size()):
		if i != star_a_id and star_a_pos.distance_to(dot_positions[i]) <= max_adjacent_distance:
			adjacent_to_a.append(i)
	
	# Encontrar estrelas adjacentes à estrela B
	var adjacent_to_b = []
	var star_b_pos = dot_positions[star_b_id]
	for i in range(dot_positions.size()):
		if i != star_b_id and star_b_pos.distance_to(dot_positions[i]) <= max_adjacent_distance:
			adjacent_to_b.append(i)
	
	# Encontrar estrela comum
	for star_id in adjacent_to_a:
		if star_id in adjacent_to_b:
			return star_id
	
	return -1

## Selecionar vértices aleatórios da lista disponível
func _select_random_vertices(available_vertices: Array, count: int) -> Array:
	if available_vertices.size() == 0:
		return []
	
	var max_count = min(count, available_vertices.size())
	var vertices_copy = available_vertices.duplicate()
	var selected = []
	
	for i in range(max_count):
		var random_index = randi() % vertices_copy.size()
		selected.append(vertices_copy[random_index])
		vertices_copy.remove_at(random_index)
	
	Logger.debug("Selecionados %d vértices de %d disponíveis" % [selected.size(), available_vertices.size()], "SpawnManager")
	return selected

## Spawnar domínios coloridos nos vértices selecionados
func _spawn_colored_domains(selected_vertices: Array) -> int:
	var spawned_count = 0
	
	for i in range(selected_vertices.size()):
		var vertex_star_id = selected_vertices[i]
		var domain_color = GameConfig.get_team_color(i)
		
		var spawn_result = game_manager_ref.spawn_domain_with_unit_colored(vertex_star_id, domain_color)
		
		if spawn_result:
			spawned_count += 1
			Logger.debug("Domínio %d spawnado na estrela %d" % [i, vertex_star_id], "SpawnManager")
		else:
			Logger.warning("Falha ao spawnar domínio %d na estrela %d" % [i, vertex_star_id], "SpawnManager")
	
	Logger.info("Spawn concluído: %d/%d domínios criados" % [spawned_count, selected_vertices.size()], "SpawnManager")
	return spawned_count

## Obter estatísticas do último spawn
func get_spawn_stats() -> Dictionary:
	if not game_manager_ref:
		return {}
	
	return {
		"domains_spawned": game_manager_ref.get_all_domains().size(),
		"units_spawned": game_manager_ref.get_all_units().size(),
		"spawn_manager_ready": _validate_references()
	}