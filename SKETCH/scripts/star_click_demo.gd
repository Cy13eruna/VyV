## Demo de Spawn de Domínios - Sistema de Spawn Colorido
## Sistema principal do jogo V&V
extends Node2D

const StarMapper = preload("res://scripts/star_mapper.gd")
const Unit = preload("res://scripts/unit.gd")
const Domain = preload("res://scripts/domain.gd")
const GameManager = preload("res://scripts/game_manager.gd")

@onready var hex_grid = $HexGrid
var star_mapper = null
var game_manager = null

# Cores disponíveis para domínios
var domain_colors = [
	Color(0, 0, 1),      # Azul RGB
	Color(1, 0.5, 0),    # Laranja
	Color(1, 0, 0),      # Vermelho RGB
	Color(0.5, 0, 1),    # Roxo
	Color(1, 1, 0),      # Amarelo
	Color(0, 1, 1)       # Ciano
]
var available_colors = []

func _ready() -> void:
	print("V&V: Inicializando sistema...")
	
	# Inicializar componentes
	star_mapper = StarMapper.new()
	game_manager = GameManager.new()
	
	if hex_grid.is_initialized:
		_setup_system()
	else:
		hex_grid.grid_initialized.connect(_setup_system)

func _setup_system() -> void:
	if not hex_grid or not hex_grid.is_grid_ready():
		return
	
	# Configurar componentes
	var dot_positions = hex_grid.get_dot_positions()
	star_mapper.map_stars(dot_positions)
	game_manager.setup_references(hex_grid, star_mapper, self)
	
	# Conectar sinais
	game_manager.unit_created.connect(_on_unit_created)
	game_manager.domain_created.connect(_on_domain_created)
	
	# Inicializar sistema de spawn
	_initialize_spawn_system()
	
	print("V&V: Sistema pronto!")

## Sistema principal de spawn
func _initialize_spawn_system() -> void:
	print("🚀 Iniciando sistema de spawn...")
	
	if not game_manager:
		print("❌ GameManager não configurado!")
		return
	
	# Obter quantidade de domínios
	var num_domains = _get_domain_count_from_args()
	print("📊 Domínios solicitados: " + str(num_domains))
	
	# Encontrar vértices disponíveis
	var available_vertices = _find_spawn_vertices()
	if available_vertices.size() == 0:
		print("❌ Nenhum vértice encontrado!")
		return
	
	# Selecionar vértices e cores aleatórias
	var selected_vertices = _select_random_vertices(available_vertices, num_domains)
	_prepare_random_colors(num_domains)
	
	# Spawnar domínios coloridos
	_spawn_colored_domains(selected_vertices)
	
	print("🎮 Sistema de spawn concluído!")

## Algoritmo de detecção de vértices: 12 estrelas -> 6 duplas -> 6 centros
func _find_spawn_vertices() -> Array:
	if not hex_grid or not star_mapper:
		return []
	
	var dot_positions = hex_grid.get_dot_positions()
	var domain_centers = []
	
	# 1. Encontrar centro do tabuleiro
	var center = Vector2.ZERO
	for pos in dot_positions:
		center += pos
	center /= dot_positions.size()
	
	# 2. Encontrar as 12 estrelas mais distantes
	var star_distances = []
	for i in range(dot_positions.size()):
		var pos = dot_positions[i]
		var distance = center.distance_to(pos)
		star_distances.append({"id": i, "distance": distance, "pos": pos})
	
	star_distances.sort_custom(func(a, b): return a.distance > b.distance)
	var twelve_farthest = star_distances.slice(0, 12)
	
	# 3. Agrupar em duplas por proximidade
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
	
	# 4. Encontrar centros das duplas
	for pair in pairs:
		var center_star = _find_common_adjacent_star(pair[0].id, pair[1].id, dot_positions)
		if center_star >= 0:
			domain_centers.append(center_star)
	
	return domain_centers

## Encontrar estrela adjacente comum a duas estrelas
func _find_common_adjacent_star(star_a_id: int, star_b_id: int, dot_positions: Array) -> int:
	var max_adjacent_distance = 38.0
	
	# Encontrar adjacentes de A
	var adjacent_to_a = []
	var star_a_pos = dot_positions[star_a_id]
	for i in range(dot_positions.size()):
		if i != star_a_id and star_a_pos.distance_to(dot_positions[i]) <= max_adjacent_distance:
			adjacent_to_a.append(i)
	
	# Encontrar adjacentes de B
	var adjacent_to_b = []
	var star_b_pos = dot_positions[star_b_id]
	for i in range(dot_positions.size()):
		if i != star_b_id and star_b_pos.distance_to(dot_positions[i]) <= max_adjacent_distance:
			adjacent_to_b.append(i)
	
	# Encontrar comum
	for star_id in adjacent_to_a:
		if star_id in adjacent_to_b:
			return star_id
	
	return -1

## Obter quantidade de domínios dos argumentos
func _get_domain_count_from_args() -> int:
	var args = OS.get_cmdline_args()
	var domain_count = 6  # Padrão
	
	for arg in args:
		if arg.begins_with("--domain-count="):
			domain_count = int(arg.split("=")[1])
			break
	
	# Validar
	domain_count = clamp(domain_count, 1, 6)
	
	print("=== CONFIGURAÇÃO DE SPAWN ===")
	print("Quantidade selecionada: " + str(domain_count))
	print("")
	
	return domain_count

## Selecionar vértices aleatórios
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
	
	return selected

## Preparar cores aleatórias
func _prepare_random_colors(count: int) -> void:
	available_colors.clear()
	var colors_copy = domain_colors.duplicate()
	
	for i in range(min(count, colors_copy.size())):
		var random_index = randi() % colors_copy.size()
		available_colors.append(colors_copy[random_index])
		colors_copy.remove_at(random_index)

## Spawnar domínios com cores
func _spawn_colored_domains(selected_vertices: Array) -> void:
	print("🎯 Spawnando domínios coloridos...")
	
	for i in range(selected_vertices.size()):
		var vertex_star_id = selected_vertices[i]
		var domain_color = available_colors[i] if i < available_colors.size() else Color.WHITE
		
		var spawn_result = game_manager.spawn_domain_with_unit_colored(vertex_star_id, domain_color)
		
		if spawn_result:
			print("✅ Domínio " + str(i + 1) + " criado na estrela " + str(vertex_star_id))
		else:
			print("❌ Falha no spawn " + str(i + 1))

## Callbacks
func _on_unit_created(unit) -> void:
	print("🎆 Unidade criada: " + str(unit.get_info().unit_id))

func _on_domain_created(domain) -> void:
	print("🏠 Domínio criado: " + str(domain.get_domain_id()))