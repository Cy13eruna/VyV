## PathMapper - Sistema de Mapeamento de Paths (Losangos)
## Mapeia todos os paths baseado no mapeamento de estrelas
## Path = área entre duas estrelas conectadas

class_name PathMapper
extends RefCounted

# Estrutura de dados dos paths
var paths: Dictionary = {}  # path_id -> path_data
var star_to_paths: Dictionary = {}  # star_id -> Array[path_ids]
var path_positions: Dictionary = {}  # path_id -> Vector2 (centro do path)

# Referências
var hex_grid_ref = null
var star_positions: Array[Vector2] = []

## Configurar referências
func setup_references(hex_grid) -> void:
	print("🔍 DEBUG: setup_references chamado com hex_grid: %s" % str(hex_grid))
	hex_grid_ref = hex_grid
	print("🔍 DEBUG: hex_grid_ref definido: %s" % str(hex_grid_ref))
	print("🛤️ PathMapper configurado")

## Mapear todos os paths baseado nas estrelas
func map_all_paths() -> void:
	print("🔍 DEBUG: map_all_paths() chamado")
	
	if not hex_grid_ref:
		print("❌ PathMapper: HexGrid não configurado")
		return
	
	# Limpar dados anteriores
	paths.clear()
	star_to_paths.clear()
	path_positions.clear()
	print("🔍 DEBUG: Dados anteriores limpos")
	
	# Obter posições das estrelas
	star_positions = hex_grid_ref.get_dot_positions()
	print("🔍 DEBUG: Obtidas %d posições de estrelas" % star_positions.size())
	
	if star_positions.is_empty():
		print("❌ PathMapper: Nenhuma estrela encontrada")
		return
	
	print("🛤️ MAPEANDO PATHS: %d estrelas disponíveis" % star_positions.size())
	
	var path_count = 0
	var max_distance = 100.0  # Distância máxima aumentada para detectar mais conexões
	print("🔍 DEBUG: Iniciando loop de mapeamento, max_distance = %.1f" % max_distance)
	
	# Debug: mostrar algumas posições de estrelas
	print("🔍 DEBUG: Primeiras 3 estrelas:")
	for i in range(min(3, star_positions.size())):
		print("🔍   Estrela %d: %s" % [i, str(star_positions[i])])
	
	# Mapear paths entre estrelas adjacentes
	for i in range(star_positions.size()):
		for j in range(i + 1, star_positions.size()):
			var star_a_pos = star_positions[i]
			var star_b_pos = star_positions[j]
			var distance = star_a_pos.distance_to(star_b_pos)
			
			# Debug: mostrar algumas distâncias
			if path_count < 5:
				print("🔍 DEBUG: Estrelas %d-%d, dist: %.1f" % [i, j, distance])
			
			# Se as estrelas estão próximas o suficiente, criar um path
			if distance <= max_distance:
				var path_id = _generate_path_id(i, j)
				var path_center = (star_a_pos + star_b_pos) / 2.0
				
				if path_count < 3:
					print("✅ DEBUG: Criando path %s entre estrelas %d-%d" % [path_id, i, j])
				
				# Criar dados do path
				var path_data = {
					"id": path_id,
					"star_a": i,
					"star_b": j,
					"star_a_pos": star_a_pos,
					"star_b_pos": star_b_pos,
					"center": path_center,
					"distance": distance
				}
				
				# Armazenar path
				paths[path_id] = path_data
				path_positions[path_id] = path_center
				
				# Mapear estrelas para paths
				if not star_to_paths.has(i):
					star_to_paths[i] = []
				if not star_to_paths.has(j):
					star_to_paths[j] = []
				
				star_to_paths[i].append(path_id)
				star_to_paths[j].append(path_id)
				
				path_count += 1
	
	print("🛤️ MAPEAMENTO CONCLUÍDO: %d paths criados" % path_count)
	print("🛤️ DEBUG: Primeiros 3 paths:")
	
	var count = 0
	for path_id in paths.keys():
		if count >= 3:
			break
		var path_data = paths[path_id]
		print("🛤️   Path %s: Estrelas %d-%d, Centro %s" % [path_id, path_data.star_a, path_data.star_b, str(path_data.center)])
		count += 1

## Gerar ID do path baseado nas duas estrelas
func _generate_path_id(star_a: int, star_b: int) -> String:
	# Garantir ordem consistente (menor primeiro)
	var min_star = min(star_a, star_b)
	var max_star = max(star_a, star_b)
	return "path_%d_%d" % [min_star, max_star]

## Encontrar path na posição especificada
func find_path_at_position(position: Vector2, tolerance: float = 25.0) -> Dictionary:
	print("🔍 PathMapper: Procurando path na posição %s" % str(position))
	print("🔍 PathMapper: Total de paths: %d" % path_positions.size())
	
	var closest_path_id = ""
	var closest_distance = INF
	
	for path_id in path_positions.keys():
		var path_center = path_positions[path_id]
		var distance = position.distance_to(path_center)
		
		if distance <= tolerance and distance < closest_distance:
			closest_distance = distance
			closest_path_id = path_id
			print("🔍 PathMapper: Path candidato %s, dist: %.1f" % [path_id, distance])
	
	if closest_path_id != "":
		print("✅ PathMapper: Path encontrado: %s" % closest_path_id)
		return {
			"found": true,
			"path_id": closest_path_id,
			"path_data": paths[closest_path_id],
			"distance": closest_distance
		}
	else:
		print("❌ PathMapper: Nenhum path encontrado")
		return {"found": false}

## Obter paths conectados a uma estrela
func get_paths_for_star(star_id: int) -> Array:
	if star_to_paths.has(star_id):
		return star_to_paths[star_id]
	else:
		return []

## Obter dados de um path específico
func get_path_data(path_id: String) -> Dictionary:
	if paths.has(path_id):
		return paths[path_id]
	else:
		return {}

## Obter todos os paths
func get_all_paths() -> Dictionary:
	return paths.duplicate()

## Obter estatísticas do mapeamento
func get_path_stats() -> Dictionary:
	return {
		"total_paths": paths.size(),
		"total_stars": star_positions.size(),
		"paths_per_star": float(paths.size() * 2) / float(star_positions.size()) if star_positions.size() > 0 else 0.0
	}

## Debug: Imprimir informações dos paths
func print_path_info(max_paths: int = 5) -> void:
	print("\n🛤️ === INFORMAÇÕES DOS PATHS ===")
	
	var stats = get_path_stats()
	print("📊 Estatísticas:")
	print("   • Total de paths: %d" % stats.total_paths)
	print("   • Total de estrelas: %d" % stats.total_stars)
	print("   • Média de paths por estrela: %.1f" % stats.paths_per_star)
	
	print("\n🛤️ Primeiros %d paths:" % max_paths)
	var count = 0
	for path_id in paths.keys():
		if count >= max_paths:
			break
		
		var path_data = paths[path_id]
		print("   • %s: Estrelas %d-%d (dist: %.1f)" % [
			path_id, 
			path_data.star_a, 
			path_data.star_b, 
			path_data.distance
		])
		count += 1
	
	print("=== FIM DAS INFORMAÇÕES ===\n")