## DiamondMapper - Mapeamento de Losangos Baseado em Conexões de Estrelas
## Cada losango conecta duas estrelas e tem ID baseado nelas

class_name DiamondMapper
extends RefCounted

## Estrutura de dados dos losangos
var diamonds: Dictionary = {}  # diamond_id -> {star1_id, star2_id, position, center}
var star_to_diamonds: Dictionary = {}  # star_id -> Array[diamond_ids]
var diamond_positions: Array[Vector2] = []
var diamond_ids: Array[String] = []

## Referências do sistema
var hex_grid_ref = null
var cache_ref = null

## Configurações
var max_connection_distance: float = 50.0  # Distância máxima para conectar estrelas (reduzida para menos losangos)

## Inicializar mapeador
func _init():
	pass

## Configurar referências
func setup_references(hex_grid, cache) -> void:
	hex_grid_ref = hex_grid
	cache_ref = cache

## Mapear todos os losangos baseado nas conexões entre estrelas
func map_all_diamonds() -> void:
	if not cache_ref:
		print("❌ DiamondMapper: Referência cache não configurada")
		return
	
	# Limpar dados anteriores
	diamonds.clear()
	star_to_diamonds.clear()
	diamond_positions.clear()
	diamond_ids.clear()
	
	# CORREÇÃO: Usar apenas estrelas que serão renderizadas
	# O problema era que o cache tem todas as estrelas, mas o renderer só renderiza algumas
	var all_dot_positions = cache_ref.get_dot_positions()
	if all_dot_positions.is_empty():
		print("❌ DiamondMapper: Nenhuma estrela encontrada no cache")
		return
	
	# Filtrar apenas as estrelas que serão renderizadas (primeiras 133)
	var dot_positions: Array[Vector2] = []
	var max_rendered_stars = 133  # Baseado nos logs: "ESTRELAS RENDERIZADAS: 133"
	for i in range(min(max_rendered_stars, all_dot_positions.size())):
		dot_positions.append(all_dot_positions[i])
	
	print("🔷 MAPEAMENTO CORRIGIDO: Usando apenas %d estrelas renderizadas (de %d totais)" % [dot_positions.size(), all_dot_positions.size()])
	print("🔷 DEBUG: Primeiras 3 estrelas filtradas:")
	for i in range(min(3, dot_positions.size())):
		print("🔷   Estrela %d: %s" % [i, str(dot_positions[i])])
	
	var diamond_count = 0
	
	# Para cada par de estrelas, verificar se devem ser conectadas
	for i in range(dot_positions.size()):
		for j in range(i + 1, dot_positions.size()):
			var star1_pos = dot_positions[i]
			var star2_pos = dot_positions[j]
			var distance = star1_pos.distance_to(star2_pos)
			
			# Se estão próximas o suficiente, criar losango
			if distance <= max_connection_distance:
				var diamond_id = _create_diamond_id(i, j)
				var diamond_center = (star1_pos + star2_pos) / 2.0
				
				# Criar dados do losango
				var diamond_data = {
					"id": diamond_id,
					"star1_id": i,
					"star2_id": j,
					"star1_pos": star1_pos,
					"star2_pos": star2_pos,
					"center": diamond_center,
					"distance": distance
				}
				
				# Armazenar losango
				diamonds[diamond_id] = diamond_data
				diamond_positions.append(diamond_center)
				diamond_ids.append(diamond_id)
				
				# Mapear estrelas para losangos
				if not star_to_diamonds.has(i):
					star_to_diamonds[i] = []
				star_to_diamonds[i].append(diamond_id)
				
				if not star_to_diamonds.has(j):
					star_to_diamonds[j] = []
				star_to_diamonds[j].append(diamond_id)
				
				diamond_count += 1
	
	print("🔷 MAPEAMENTO CONCLUÍDO: %d losangos criados" % diamond_count)
	if diamond_ids.size() > 0:
		var first_diamond = diamonds[diamond_ids[0]]
		print("🔷 EXEMPLO: Losango '%s' conecta estrelas %d e %d" % [diamond_ids[0], first_diamond.star1_id, first_diamond.star2_id])
		print("🔷 CENTRO DO PRIMEIRO LOSANGO: %s" % str(first_diamond.center))
		print("🔷 DISTÂNCIA MÁXIMA PERMITIDA: %.1f" % max_connection_distance)
	else:
		print("❌ NENHUM LOSANGO FOI CRIADO!")
		print("❌ POSSÍVEIS CAUSAS: Estrelas muito distantes (> %.1f) ou cache vazio" % max_connection_distance)

## Criar ID único para losango baseado nas duas estrelas
func _create_diamond_id(star1_id: int, star2_id: int) -> String:
	# Garantir ordem consistente (menor ID primeiro)
	var min_id = min(star1_id, star2_id)
	var max_id = max(star1_id, star2_id)
	return "diamond_%d_%d" % [min_id, max_id]

## Encontrar losango mais próximo de uma posição
func find_diamond_at_position(position: Vector2, tolerance: float = 30.0) -> Dictionary:
	var closest_distance = INF
	var closest_diamond = {"found": false}
	
	# Buscar losango mais próximo sem logs excessivos
	for diamond_id in diamonds.keys():
		var diamond = diamonds[diamond_id]
		var distance = position.distance_to(diamond.center)
		
		if distance < closest_distance and distance <= tolerance:
			closest_distance = distance
			closest_diamond = {
				"found": true,
				"id": diamond_id,
				"diamond": diamond,
				"distance": distance
			}
	
	return closest_diamond

## Obter estrelas conectadas a um losango
func get_connected_stars(diamond_id: String) -> Array:
	if not diamonds.has(diamond_id):
		return []
	
	var diamond = diamonds[diamond_id]
	return [diamond.star1_id, diamond.star2_id]

## Obter losangos conectados a uma estrela
func get_diamonds_for_star(star_id: int) -> Array:
	if not star_to_diamonds.has(star_id):
		return []
	
	return star_to_diamonds[star_id]

## Obter todos os losangos
func get_all_diamonds() -> Dictionary:
	return diamonds

## Obter posições dos losangos (para compatibilidade)
func get_diamond_positions() -> Array[Vector2]:
	return diamond_positions

## Obter estatísticas
func get_stats() -> Dictionary:
	return {
		"total_diamonds": diamonds.size(),
		"total_stars": star_to_diamonds.size(),
		"avg_connections_per_star": float(diamonds.size() * 2) / max(1, star_to_diamonds.size()),
		"max_connection_distance": max_connection_distance
	}

## Debug: imprimir informações dos losangos
func print_diamond_info(limit: int = 5) -> void:
	print("🔷 === INFORMAÇÕES DOS LOSANGOS ===")
	
	var count = 0
	for diamond_id in diamonds.keys():
		if count >= limit:
			break
		
		var diamond = diamonds[diamond_id]
		print("🔷 %s:" % diamond_id)
		print("   Estrelas: %d ↔ %d" % [diamond.star1_id, diamond.star2_id])
		print("   Centro: %s" % str(diamond.center))
		print("   Distância: %.1f" % diamond.distance)
		count += 1
	
	if diamonds.size() > limit:
		print("🔷 ... e mais %d losangos" % (diamonds.size() - limit))
	
	var stats = get_stats()
	print("🔷 ESTATÍSTICAS:")
	print("   Total de losangos: %d" % stats.total_diamonds)
	print("   Estrelas com conexões: %d" % stats.total_stars)
	print("   Média de conexões por estrela: %.1f" % stats.avg_connections_per_star)
	print("=== FIM DAS INFORMAÇÕES ===")