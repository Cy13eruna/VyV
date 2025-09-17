## Demo de Spawn de Domínios - Sistema de Spawn nos VÉRTICES (ATUALIZADO)
## VERSÃO: Vértices do hexágono (pontas agudas) - NÃO lados
extends Node2D

const StarMapper = preload("res://scripts/star_mapper.gd")
const Unit = preload("res://scripts/unit.gd")
const Domain = preload("res://scripts/domain.gd")
const GameManager = preload("res://scripts/game_manager.gd")

@onready var hex_grid = $HexGrid
var star_mapper = null
var game_manager = null
var current_unit = null
var magenta_stars = []  # Visualização de estrelas adjacentes
var adjacent_stars = []  # IDs das estrelas adjacentes
var domains = []  # Lista de domínios (compatibilidade)
var domain_nodes = []  # Nodes visuais dos domínios
var unit_current_star_id: int = -1  # ID da estrela atual da unidade
var domain_count_selected: int = 6  # Quantidade de domínios selecionada
var waiting_for_input: bool = false  # Flag para aguardar input

# Cores disponíveis para domínios
var domain_colors = [
	Color(0, 0, 1),      # Azul RGB
	Color(1, 0.5, 0),    # Laranja
	Color(1, 0, 0),      # Vermelho RGB
	Color(0.5, 0, 1),    # Roxo
	Color(1, 1, 0),      # Amarelo
	Color(0, 1, 1)       # Ciano
]
var available_colors = []  # Cores disponíveis para randomização

func _ready() -> void:
	print("StarClickDemo: Inicializando sistema refatorado...")
	
	# Inicializar componentes
	star_mapper = StarMapper.new()
	game_manager = GameManager.new()
	
	if hex_grid.is_initialized:
		_setup_system()
	else:
		hex_grid.grid_initialized.connect(_setup_system)
	
	# Input removido - sistema agora é automático
	# set_process_unhandled_input(true)

func _setup_system() -> void:
	if not hex_grid or not hex_grid.is_grid_ready():
		return
	
	# Configurar star mapper
	var dot_positions = hex_grid.get_dot_positions()
	star_mapper.map_stars(dot_positions)
	
	# Configurar game manager
	game_manager.setup_references(hex_grid, star_mapper, self)
	
	# Conectar sinais
	game_manager.unit_created.connect(_on_unit_created)
	game_manager.domain_created.connect(_on_domain_created)
	
	# Inicializar sistema de spawn
	_initialize_spawn_system()
	
	print("StarClickDemo: Sistema de spawn pronto!")
	print("  - Domínios spawnam automaticamente nos 6 cantos")
	print("  - Cada domínio spawn com uma unidade no centro")

## Inicializar sistema de spawn nos cantos
func _initialize_spawn_system() -> void:
	print("🚀 INICIANDO SISTEMA DE SPAWN...")
	
	# Verificar se game_manager está configurado
	if not game_manager:
		print("❌ GameManager não está configurado!")
		return
	
	# Pedir quantidade de domínios ao usuário
	var num_domains = _ask_for_domain_count()
	print("📊 Quantidade de domínios solicitada: " + str(num_domains))
	
	# Encontrar os vértices disponíveis
	print("🔍 Procurando vértices disponíveis...")
	var available_vertices = _find_corner_stars_improved()
	print("📍 Vértices disponíveis: " + str(available_vertices.size()))
	
	if available_vertices.size() == 0:
		print("❌ Nenhum vértice encontrado!")
		return
	
	# Selecionar vértices aleatórios
	var selected_vertices = _select_random_vertices(available_vertices, num_domains)
	print("🎲 Vértices selecionados aleatoriamente: " + str(selected_vertices))
	
	# Preparar cores aleatórias
	_prepare_random_colors(num_domains)
	
	# Spawnar domínios com unidades nos vértices selecionados
	print("🎯 Iniciando spawns...")
	for i in range(selected_vertices.size()):
		var vertex_star_id = selected_vertices[i]
		var domain_color = available_colors[i] if i < available_colors.size() else Color.WHITE
		print("🎯 Spawn " + str(i + 1) + ": tentando na estrela " + str(vertex_star_id) + " com cor " + str(domain_color))
		
		var spawn_result = game_manager.spawn_domain_with_unit_colored(vertex_star_id, domain_color)
		
		if spawn_result:
			print("✅ Spawn " + str(i + 1) + ": Domínio e unidade criados (estrela " + str(vertex_star_id) + ")")
		else:
			print("❌ Falha no spawn " + str(i + 1) + " (estrela " + str(vertex_star_id) + ")")
	
	print("🎮 Sistema de spawn concluído: " + str(selected_vertices.size()) + " spawns realizados")

## Algoritmo correto: 12 estrelas -> 6 duplas -> 6 centros
func _find_corner_stars_improved() -> Array:
	if not hex_grid or not star_mapper:
		return []
	
	var dot_positions = hex_grid.get_dot_positions()
	var domain_centers = []
	
	# 1. Encontrar centro do tabuleiro
	var center = Vector2.ZERO
	for pos in dot_positions:
		center += pos
	center /= dot_positions.size()
	print("Centro: " + str(center.x) + ", " + str(center.y))
	
	# 2. Encontrar as 12 estrelas mais distantes do centro
	var star_distances = []
	for i in range(dot_positions.size()):
		var pos = dot_positions[i]
		var distance = center.distance_to(pos)
		star_distances.append({"id": i, "distance": distance, "pos": pos})
	
	star_distances.sort_custom(func(a, b): return a.distance > b.distance)
	var twelve_farthest = []
	for i in range(min(12, star_distances.size())):
		twelve_farthest.append(star_distances[i])
		print("Estrela distante " + str(i + 1) + ": ID " + str(star_distances[i].id))
	
	# 3. Agrupar em 6 duplas por proximidade
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
			used_stars.append(star_a.id)
			used_stars.append(closest_star.id)
			print("Dupla " + str(pairs.size()) + ": estrelas " + str(star_a.id) + " e " + str(closest_star.id))
	
	# 4. Para cada dupla, encontrar estrela adjacente comum (centro do domínio)
	for i in range(pairs.size()):
		var pair = pairs[i]
		var star_a_id = pair[0].id
		var star_b_id = pair[1].id
		
		# Encontrar estrela adjacente a ambas
		var common_adjacent = _find_common_adjacent_star(star_a_id, star_b_id, dot_positions)
		if common_adjacent >= 0:
			domain_centers.append(common_adjacent)
			print("Centro do dominio " + str(i + 1) + ": estrela " + str(common_adjacent))
		else:
			print("Nenhuma estrela adjacente comum encontrada para dupla " + str(i + 1))
	
	return domain_centers

func _unhandled_input_old(event: InputEvent) -> void:
	# Sistema de cliques removido - agora usa spawn automático
	pass

## Encontrar estrela adjacente comum a duas estrelas
func _find_common_adjacent_star(star_a_id: int, star_b_id: int, dot_positions: Array) -> int:
	var max_adjacent_distance = 38.0  # Distância máxima para considerar adjacente
	
	# Encontrar estrelas adjacentes à estrela A
	var adjacent_to_a = []
	var star_a_pos = dot_positions[star_a_id]
	
	for i in range(dot_positions.size()):
		if i == star_a_id:
			continue
		var distance = star_a_pos.distance_to(dot_positions[i])
		if distance <= max_adjacent_distance:
			adjacent_to_a.append(i)
	
	# Encontrar estrelas adjacentes à estrela B
	var adjacent_to_b = []
	var star_b_pos = dot_positions[star_b_id]
	
	for i in range(dot_positions.size()):
		if i == star_b_id:
			continue
		var distance = star_b_pos.distance_to(dot_positions[i])
		if distance <= max_adjacent_distance:
			adjacent_to_b.append(i)
	
	# Encontrar estrela comum (adjacente a ambas)
	for star_id in adjacent_to_a:
		if star_id in adjacent_to_b:
			print("Estrela comum encontrada: " + str(star_id) + " (adjacente a " + str(star_a_id) + " e " + str(star_b_id) + ")")
			return star_id
	
	return -1  # Nenhuma estrela comum encontrada

## Obter quantidade de domínios dos argumentos da linha de comando
func _ask_for_domain_count() -> int:
	var args = OS.get_cmdline_args()
	var domain_count = 6  # Padrão
	
	# Procurar pelo parâmetro --domain-count
	for i in range(args.size()):
		if args[i].begins_with("--domain-count="):
			var count_str = args[i].split("=")[1]
			domain_count = int(count_str)
			break
	
	# Validar entrada
	if domain_count < 1:
		domain_count = 1
	elif domain_count > 6:
		domain_count = 6
	
	print("")
	print("=== CONFIGURAÇÃO DE SPAWN ===")
	print("Quantidade de domínios selecionada: " + str(domain_count))
	print("")
	
	return domain_count

## Selecionar vértices aleatórios
func _select_random_vertices(available_vertices: Array, count: int) -> Array:
	if available_vertices.size() == 0:
		return []
	
	# Limitar count ao número disponível
	var max_count = min(count, available_vertices.size())
	
	# Criar cópia para não modificar o original
	var vertices_copy = available_vertices.duplicate()
	var selected = []
	
	# Selecionar aleatoriamente
	for i in range(max_count):
		var random_index = randi() % vertices_copy.size()
		selected.append(vertices_copy[random_index])
		vertices_copy.remove_at(random_index)
	
	return selected

## Preparar cores aleatórias para os domínios
func _prepare_random_colors(count: int) -> void:
	available_colors.clear()
	
	# Criar cópia das cores para randomização
	var colors_copy = domain_colors.duplicate()
	
	# Selecionar cores aleatórias sem repetição
	for i in range(min(count, colors_copy.size())):
		var random_index = randi() % colors_copy.size()
		available_colors.append(colors_copy[random_index])
		colors_copy.remove_at(random_index)
	
	print("🎨 Cores preparadas para " + str(count) + " domínios")

## Aguardar input numérico do usuário
func _wait_for_number_input():
	# Aguardar até o usuário pressionar uma tecla
	while waiting_for_input:
		await get_tree().process_frame

func _unhandled_input(event: InputEvent) -> void:
	print("DEBUG: Input recebido, waiting_for_input = " + str(waiting_for_input))
	
	if not waiting_for_input:
		return
	
	if event is InputEventKey and event.pressed:
		var key_code = event.keycode
		print("DEBUG: Tecla pressionada: " + str(key_code))
		
		# Verificar teclas numéricas 1-6
		if key_code >= KEY_1 and key_code <= KEY_6:
			domain_count_selected = key_code - KEY_0
			print("Quantidade selecionada: " + str(domain_count_selected))
			print("")
			waiting_for_input = false
		
		# Verificar tecla ESPAÇO (usar padrão)
		elif key_code == KEY_SPACE:
			domain_count_selected = 6
			print("Quantidade selecionada: 6 (padrão)")
			print("")
			waiting_for_input = false
		
		# Qualquer outra tecla para debug
		else:
			print("DEBUG: Tecla não reconhecida: " + str(key_code))

## Algoritmo para encontrar os 6 vértices de um hexágono central
func _find_hexagon_vertices() -> Array:
	if not hex_grid or not star_mapper:
		return []
	
	var dot_positions = hex_grid.get_dot_positions()
	var vertices = []
	
	# Encontrar centro do tabuleiro
	var center = Vector2.ZERO
	for pos in dot_positions:
		center += pos
	center /= dot_positions.size()
	print("📍 Centro do tabuleiro: (%.3f, %.3f)" % [center.x, center.y])
	
	# Encontrar o raio real do tabuleiro (distância máxima do centro)
	var max_distance = 0.0
	for pos in dot_positions:
		var distance = center.distance_to(pos)
		if distance > max_distance:
			max_distance = distance
	
	# Usar 85% da distância máxima para encontrar os vértices do tabuleiro
	var hex_radius = max_distance * 0.85
	print("Distancia maxima do centro: " + str(max_distance) + " pixels")
	print("Usando raio hexagonal: " + str(hex_radius) + " pixels")
	
	# Calcular posições dos 6 vértices do hexágono
	var vertex_angles = [0.0, PI/3.0, 2*PI/3.0, PI, 4*PI/3.0, 5*PI/3.0]  # 0°, 60°, 120°, 180°, 240°, 300°
	
	for i in range(vertex_angles.size()):
		var angle = vertex_angles[i]
		# Calcular posição teórica do vértice
		var target_pos = center + Vector2(cos(angle), sin(angle)) * hex_radius
		print("Procurando vertice %d: posicao teorica (%.1f, %.1f) (angulo %.0f graus)" % [i + 1, target_pos.x, target_pos.y, rad_to_deg(angle)])
		
		# Encontrar a estrela mais próxima dessa posição
		var best_star_id = -1
		var best_distance = 999999.0  # Valor grande mas não infinito
		
		for j in range(dot_positions.size()):
			var star_pos = dot_positions[j]
			var distance_to_target = star_pos.distance_to(target_pos)
			
			if distance_to_target < best_distance:
				best_distance = distance_to_target
				best_star_id = j
		
		if best_star_id >= 0:
			vertices.append(best_star_id)
			var actual_pos = dot_positions[best_star_id]
			var distance_from_center = actual_pos.distance_to(center)
			print("Vertice " + str(i + 1) + ": estrela " + str(best_star_id) + " encontrada")
		else:
			print("Vertice " + str(i + 1) + ": nenhuma estrela encontrada")
	
	return vertices

## Algoritmo para encontrar os 6 vértices nas pontas de um hexágono intermediário
func _find_hexagon_vertices_at_tips() -> Array:
	if not hex_grid or not star_mapper:
		return []
	
	var dot_positions = hex_grid.get_dot_positions()
	var vertices = []
	
	# Encontrar centro do tabuleiro
	var center = Vector2.ZERO
	for pos in dot_positions:
		center += pos
	center /= dot_positions.size()
	print("Centro do tabuleiro: " + str(center.x) + ", " + str(center.y))
	
	# Usar um raio fixo para hexágono intermediário (nas pontas, não nos cantos extremos)
	var hex_radius = 200.0  # Raio intermediário para as pontas
	print("Usando raio para pontas: " + str(hex_radius) + " pixels")
	
	# Calcular posições exatas dos 6 vértices do hexágono
	var vertex_angles = [0.0, PI/3.0, 2*PI/3.0, PI, 4*PI/3.0, 5*PI/3.0]  # 0°, 60°, 120°, 180°, 240°, 300°
	
	for i in range(vertex_angles.size()):
		var angle = vertex_angles[i]
		# Calcular posição exata do vértice (ponta)
		var target_pos = center + Vector2(cos(angle), sin(angle)) * hex_radius
		print("Procurando ponta " + str(i + 1) + " em posicao: " + str(target_pos.x) + ", " + str(target_pos.y))
		
		# Encontrar a estrela mais próxima dessa posição
		var best_star_id = -1
		var best_distance = 999999.0
		
		for j in range(dot_positions.size()):
			var star_pos = dot_positions[j]
			var distance_to_target = star_pos.distance_to(target_pos)
			
			if distance_to_target < best_distance:
				best_distance = distance_to_target
				best_star_id = j
		
		if best_star_id >= 0:
			vertices.append(best_star_id)
			print("Ponta " + str(i + 1) + ": estrela " + str(best_star_id) + " encontrada")
		else:
			print("Ponta " + str(i + 1) + ": nenhuma estrela encontrada")
	
	return vertices

# Função removida - conflito resolvido

# Funções de clique removidas - sistema agora usa spawn automático

# Função removida - agora gerenciada pela classe Unit

# Função removida - agora gerenciada pelo GameManager

# Função removida - agora gerenciada por _update_adjacent_stars_display()

func _clear_adjacent_highlights() -> void:
	# Remover estrelas magenta customizadas
	for magenta_star in magenta_stars:
		if is_instance_valid(magenta_star):
			magenta_star.queue_free()
	
	magenta_stars.clear()
	adjacent_stars.clear()

func _create_magenta_star(star_position: Vector2) -> void:
	# Criar uma estrela magenta customizada
	var magenta_star = Node2D.new()
	magenta_star.z_index = 60  # Acima do grid, abaixo do emoji
	
	# Adicionar ao HexGrid para usar coordenadas locais
	hex_grid.add_child(magenta_star)
	magenta_star.position = star_position
	
	# Conectar o evento de desenho
	magenta_star.draw.connect(_draw_magenta_star.bind(magenta_star))
	magenta_star.queue_redraw()
	
	# Armazenar referência
	magenta_stars.append(magenta_star)

func _draw_magenta_star(node: Node2D) -> void:
	# Desenhar estrela magenta simples
	var star_size = 3.0
	var points = []
	
	# Criar pontos da estrela (6 pontas)
	for i in range(6):
		var angle = i * PI / 3.0
		var outer_point = Vector2(cos(angle), sin(angle)) * star_size
		var inner_angle = angle + PI / 6.0
		var inner_point = Vector2(cos(inner_angle), sin(inner_angle)) * (star_size * 0.5)
		
		points.append(outer_point)
		points.append(inner_point)
	
	# Desenhar a estrela magenta
	node.draw_colored_polygon(PackedVector2Array(points), Color.MAGENTA)

func _is_movement_blocked_by_terrain(from_star_id: int, to_star_id: int) -> bool:
	# Verificar se o movimento entre duas estrelas é bloqueado pelo terreno
	var terrain_color = _get_terrain_between_stars(from_star_id, to_star_id)
	
	# Cores de terreno bloqueado: azul (água) e cinza (montanha)
	var water_color = Color(0.0, 1.0, 1.0, 1.0)  # Cyan
	var mountain_color = Color(0.4, 0.4, 0.4, 1.0)  # Gray
	
	return terrain_color == water_color or terrain_color == mountain_color

func _get_terrain_between_stars(from_star_id: int, to_star_id: int) -> Color:
	# Obter a cor do terreno (diamante) que conecta duas estrelas
	if not hex_grid or not hex_grid.cache:
		return Color.WHITE  # Padrão se não conseguir acessar
	
	var diamond_colors = hex_grid.cache.get_diamond_colors()
	var connections = hex_grid.cache.get_connections()
	
	# Procurar pela conexão específica entre essas duas estrelas
	for i in range(connections.size()):
		var connection = connections[i]
		# Verificar se esta conexão liga exatamente essas duas estrelas
		if (connection.index_a == from_star_id and connection.index_b == to_star_id) or \
		   (connection.index_a == to_star_id and connection.index_b == from_star_id):
			# Encontrou a conexão, retornar a cor do diamante correspondente
			if i < diamond_colors.size():
				return diamond_colors[i]
	
	# Se não encontrou conexão direta, assumir terreno livre (verde)
	return Color(0.0, 1.0, 0.0, 1.0)  # Light green

func _count_blocked_adjacent_stars(unit_star_position: Vector2) -> int:
	# Contar quantas estrelas adjacentes estão bloqueadas por terreno
	var dot_positions = hex_grid.get_dot_positions()
	var max_adjacent_distance = 38.0
	var blocked_count = 0
	
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = unit_star_position.distance_to(star_pos)
		
		if distance > 5.0 and distance <= max_adjacent_distance:
			if current_unit and current_unit.is_positioned() and _is_movement_blocked_by_terrain(current_unit.get_current_star_id(), i):
				blocked_count += 1
	
	return blocked_count

# Função de criação de domínio por clique removida - agora usa spawn automático

# Função removida - agora gerenciada pelo GameManager

# Função removida - agora gerenciada pela classe Domain

# Função removida - agora gerenciada pela classe Domain

# Função removida - agora gerenciada pela classe Domain

# Função removida - agora gerenciada pela classe Domain

# Função removida - agora gerenciada pela classe Domain

## Obter ID da estrela a partir da posição do mouse
func _get_star_id_from_mouse_position(global_pos: Vector2) -> int:
	# Obter câmera e calcular coordenadas corretas considerando zoom
	var camera = get_viewport().get_camera_2d()
	var zoom_factor = 1.0
	var camera_pos = Vector2.ZERO
	
	if camera:
		zoom_factor = camera.zoom.x
		camera_pos = camera.global_position
	
	# Converter coordenadas do mouse considerando zoom e posição da câmera
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2.0
	var mouse_offset = global_pos - screen_center
	var world_offset = mouse_offset / zoom_factor
	var world_pos = camera_pos + world_offset
	
	# Converter para coordenadas locais do HexGrid
	var hex_grid_pos = hex_grid.to_local(world_pos)
	var star_id = star_mapper.get_nearest_star_id(hex_grid_pos)
	
	if star_id >= 0:
		var star_pos = star_mapper.get_star_position(star_id)
		var distance = hex_grid_pos.distance_to(star_pos)
		var click_tolerance = 30.0
		
		if distance <= click_tolerance:
			return star_id
	
	return -1

## Atualizar visualização das estrelas adjacentes
func _update_adjacent_stars_display() -> void:
	# Limpar estrelas magenta anteriores
	_clear_adjacent_highlights()
	
	if not current_unit or not current_unit.is_positioned():
		return
	
	# Obter estrelas válidas e criar visualização
	var valid_stars = game_manager.get_valid_adjacent_stars(current_unit)
	var dot_positions = hex_grid.get_dot_positions()
	
	for star_id in valid_stars:
		if star_id < dot_positions.size():
			var star_pos = dot_positions[star_id]
			_create_magenta_star(star_pos)
	
	print("🔮 %d estrelas adjacentes em magenta" % valid_stars.size())

## Callbacks do GameManager
func _on_unit_created(unit) -> void:
	print("🎆 Unidade criada: %d" % unit.get_info().unit_id)

func _on_domain_created(domain) -> void:
	print("🏠 Domínio criado: %d" % domain.get_domain_id())

func _are_sides_identical(side1_start: Vector2, side1_end: Vector2, side2_start: Vector2, side2_end: Vector2) -> bool:
	# Verificar se dois lados são idênticos (mesmo par de vértices, independente da ordem)
	var tolerance = 5.0  # Tolerância para comparação de posições
	
	# Verificar se side1 == side2 (mesma direção)
	if side1_start.distance_to(side2_start) <= tolerance and side1_end.distance_to(side2_end) <= tolerance:
		return true
	
	# Verificar se side1 == side2 (direção oposta)
	if side1_start.distance_to(side2_end) <= tolerance and side1_end.distance_to(side2_start) <= tolerance:
		return true
	
	return false