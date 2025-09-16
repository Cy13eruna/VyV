## Demo de Click em Estrelas
extends Node2D

const StarMapper = preload("res://scripts/star_mapper.gd")

@onready var hex_grid = $HexGrid
var star_mapper = null
var unit_emoji: Label = null
var adjacent_stars: Array[int] = []  # IDs das estrelas adjacentes
var magenta_stars: Array[Node2D] = []  # Estrelas magenta customizadas
var unit_current_star_id: int = -1  # ID da estrela onde a unidade está posicionada
var domains: Array[Dictionary] = []  # Lista de domínios criados
var domain_nodes: Array[Node2D] = []  # Nodes visuais dos domínios

func _ready() -> void:
	print("StarClickDemo: Inicializando...")
	
	star_mapper = StarMapper.new()
	_create_unit_emoji()
	
	if hex_grid.is_initialized:
		_setup_mapping()
	else:
		hex_grid.grid_initialized.connect(_setup_mapping)
	
	set_process_unhandled_input(true)

func _setup_mapping() -> void:
	if not hex_grid or not hex_grid.is_grid_ready():
		return
	
	var dot_positions = hex_grid.get_dot_positions()
	star_mapper.map_stars(dot_positions)
	print("StarClickDemo: Sistema pronto! Clique nas estrelas para ver o ID")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				_handle_star_click(mouse_event.global_position)
			elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
				_handle_domain_creation(mouse_event.global_position)

func _handle_star_click(global_pos: Vector2) -> void:
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
	
	# Calcular offset do mouse em relação ao centro da tela
	var mouse_offset = global_pos - screen_center
	
	# Aplicar zoom inverso ao offset
	var world_offset = mouse_offset / zoom_factor
	
	# Calcular posição mundial real
	var world_pos = camera_pos + world_offset
	
	# Converter para coordenadas locais do HexGrid
	var hex_grid_pos = hex_grid.to_local(world_pos)
	var star_id = star_mapper.get_nearest_star_id(hex_grid_pos)
	
	if star_id >= 0:
		var star_pos = star_mapper.get_star_position(star_id)
		var distance = hex_grid_pos.distance_to(star_pos)
		
		# Tolerância fixa agora que as coordenadas estão corretas
		var click_tolerance = 30.0
		
		# Debug
		print("Mouse: %s | World: %s | HexGrid: %s | Star %d at %s | Distance: %.1f (zoom: %.1fx)" % [global_pos, world_pos, hex_grid_pos, star_id, star_pos, distance, zoom_factor])
		
		if distance <= click_tolerance:
			print("✅ Estrela clicada: ID %d" % star_id)
			_handle_unit_movement(star_id, star_pos)
		else:
			print("❌ Clique fora das estrelas (dist: %.1f)" % distance)

func _create_unit_emoji() -> void:
	# Criar o Label para o emoji
	unit_emoji = Label.new()
	unit_emoji.text = "🚶🏻‍♀️"
	unit_emoji.add_theme_font_size_override("font_size", 18)  # Tamanho reduzido
	unit_emoji.z_index = 100  # Garantir que fique acima do grid
	unit_emoji.visible = false  # Inicialmente invisível
	
	# Adicionar ao node principal (não ao HexGrid) para coordenadas globais corretas
	add_child(unit_emoji)
	
	print("🚶🏻‍♀️ Emoji criado e pronto para posicionamento (tamanho 18)")

func _handle_unit_movement(target_star_id: int, target_star_position: Vector2) -> void:
	# Se é o primeiro posicionamento
	if unit_current_star_id == -1:
		_position_unit_on_star(target_star_id, target_star_position)
		print("🎆 Unidade posicionada inicialmente na estrela %d" % target_star_id)
		return
	
	# Verificar se o movimento é válido (estrela magenta)
	if target_star_id in adjacent_stars:
		_position_unit_on_star(target_star_id, target_star_position)
		print("➡️ Unidade movida para estrela %d" % target_star_id)
	else:
		print("❌ Movimento inválido! Clique apenas nas estrelas magenta")

func _position_unit_on_star(star_id: int, star_position: Vector2) -> void:
	if not unit_emoji:
		return
	
	# Atualizar posição atual da unidade
	unit_current_star_id = star_id
	
	# Converter posição da estrela (local do HexGrid) para posição global
	var global_star_pos = hex_grid.to_global(star_position)
	
	# Posicionar o emoji na posição global da estrela
	unit_emoji.global_position = global_star_pos
	# Centralizar o emoji na estrela (ajustar offset para tamanho menor)
	unit_emoji.global_position.x -= 9   # Metade da largura aproximada do emoji menor
	unit_emoji.global_position.y -= 9   # Metade da altura aproximada do emoji menor
	unit_emoji.visible = true
	
	# Atualizar estrelas adjacentes (caminhos possíveis)
	_highlight_adjacent_stars(star_position)
	
	print("🚶🏻‍♀️ Unidade na estrela %d | Posição: %s" % [star_id, star_position])

func _highlight_adjacent_stars(unit_star_position: Vector2) -> void:
	# Limpar destaques anteriores
	_clear_adjacent_highlights()
	
	# Obter todas as posições das estrelas
	var dot_positions = hex_grid.get_dot_positions()
	if dot_positions.is_empty():
		return
	
	# Encontrar estrelas adjacentes com raio máximo
	var max_adjacent_distance = 38.0  # Raio máximo para considerar adjacente (apenas primeiro anel)
	adjacent_stars.clear()
	
	# Calcular distâncias para todas as estrelas
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = unit_star_position.distance_to(star_pos)
		
		# Apenas estrelas dentro do raio máximo (evitando a própria estrela)
		if distance > 5.0 and distance <= max_adjacent_distance:
			# Verificar se o movimento não é bloqueado pelo terreno
			if not _is_movement_blocked_by_terrain(unit_current_star_id, i):
				adjacent_stars.append(i)
	
	# Mudar cor das estrelas para magenta
	_set_stars_color_magenta()
	
	var blocked_count = _count_blocked_adjacent_stars(unit_star_position)
	print("🔮 %d estrelas adjacentes em magenta | %d bloqueadas por terreno" % [adjacent_stars.size(), blocked_count])

func _set_stars_color_magenta() -> void:
	# Criar estrelas magenta customizadas nas posições adjacentes
	var dot_positions = hex_grid.get_dot_positions()
	
	for star_id in adjacent_stars:
		if star_id < dot_positions.size():
			var star_pos = dot_positions[star_id]
			_create_magenta_star(star_pos)

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
			if _is_movement_blocked_by_terrain(unit_current_star_id, i):
				blocked_count += 1
	
	return blocked_count

func _handle_domain_creation(global_pos: Vector2) -> void:
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
			print("🏠 Criando domínio na estrela %d" % star_id)
			_create_domain(star_id, star_pos)
		else:
			print("❌ Clique direito fora das estrelas (dist: %.1f)" % distance)

func _create_domain(center_star_id: int, center_star_pos: Vector2) -> void:
	# Verificar se já existe um domínio nesta estrela
	for domain in domains:
		if domain.center_star_id == center_star_id:
			print("⚠️ Domínio já existe na estrela %d" % center_star_id)
			return
	
	# Encontrar as 6 estrelas adjacentes para os vértices do hexágono
	var adjacent_vertices = _find_domain_vertices(center_star_id)
	
	if adjacent_vertices.size() < 6:
		print("⚠️ Não foi possível encontrar 6 estrelas adjacentes para o domínio")
		return
	
	# Verificar se o novo domínio compartilharia lados com domínios existentes
	if _would_share_sides_with_existing_domains(adjacent_vertices):
		print("❌ Domínio não pode ser criado: compartilharia lado com domínio existente")
		return
	
	# Criar dados do domínio
	var domain_data = {
		"center_star_id": center_star_id,
		"center_position": center_star_pos,
		"vertices": adjacent_vertices
	}
	
	# Adicionar à lista de domínios
	domains.append(domain_data)
	
	# Criar visualização do domínio
	_create_domain_visual(domain_data)
	
	print("🏠 Domínio criado na estrela %d com %d vértices" % [center_star_id, adjacent_vertices.size()])

func _find_domain_vertices(center_star_id: int) -> Array[Vector2]:
	# Encontrar as 6 estrelas adjacentes que formarão os vértices do hexágono
	var dot_positions = hex_grid.get_dot_positions()
	var center_pos = dot_positions[center_star_id]
	var max_adjacent_distance = 38.0
	var vertices: Array[Vector2] = []
	
	# Encontrar estrelas adjacentes
	var adjacent_positions = []
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = center_pos.distance_to(star_pos)
		
		if distance > 5.0 and distance <= max_adjacent_distance:
			adjacent_positions.append(star_pos)
	
	# Ordenar por ângulo para formar hexágono correto
	adjacent_positions.sort_custom(func(a, b): 
		var angle_a = center_pos.angle_to_point(a)
		var angle_b = center_pos.angle_to_point(b)
		return angle_a < angle_b
	)
	
	# Pegar até 6 vértices
	for i in range(min(6, adjacent_positions.size())):
		vertices.append(adjacent_positions[i])
	
	return vertices

func _create_domain_visual(domain_data: Dictionary) -> void:
	# Criar node visual para o domínio
	var domain_node = Node2D.new()
	domain_node.z_index = 40  # Abaixo das estrelas magenta, acima do grid
	
	# Adicionar ao HexGrid
	hex_grid.add_child(domain_node)
	
	# Conectar evento de desenho
	domain_node.draw.connect(_draw_domain_hexagon.bind(domain_node, domain_data))
	domain_node.queue_redraw()
	
	# Armazenar referência
	domain_nodes.append(domain_node)

func _draw_domain_hexagon(node: Node2D, domain_data: Dictionary) -> void:
	# Desenhar hexágono tracejado magenta
	var vertices = domain_data.vertices
	if vertices.size() < 3:
		return
	
	# Configurar estilo do contorno
	var color = Color.MAGENTA
	var line_width = 2.0
	var dash_length = 8.0
	var gap_length = 4.0
	
	# Desenhar linhas tracejadas entre vértices
	for i in range(vertices.size()):
		var start_pos = vertices[i]
		var end_pos = vertices[(i + 1) % vertices.size()]
		_draw_dashed_line(node, start_pos, end_pos, color, line_width, dash_length, gap_length)

func _draw_dashed_line(node: Node2D, start: Vector2, end: Vector2, color: Color, width: float, dash_length: float, gap_length: float) -> void:
	# Desenhar linha tracejada
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
			node.draw_line(current_pos, next_pos, color, width)
		
		current_pos = next_pos
		distance_covered += actual_length
		drawing_dash = not drawing_dash

func _would_share_sides_with_existing_domains(new_vertices: Array[Vector2]) -> bool:
	# Verificar se o novo domínio compartilharia lados com domínios existentes
	for existing_domain in domains:
		var existing_vertices = existing_domain.vertices
		
		# Verificar cada lado do novo domínio
		for i in range(new_vertices.size()):
			var new_side_start = new_vertices[i]
			var new_side_end = new_vertices[(i + 1) % new_vertices.size()]
			
			# Verificar contra cada lado do domínio existente
			for j in range(existing_vertices.size()):
				var existing_side_start = existing_vertices[j]
				var existing_side_end = existing_vertices[(j + 1) % existing_vertices.size()]
				
				# Verificar se os lados são idênticos (mesmo par de vértices)
				if _are_sides_identical(new_side_start, new_side_end, existing_side_start, existing_side_end):
					print("🔴 Lado compartilhado detectado entre domínios")
					return true
	
	return false

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