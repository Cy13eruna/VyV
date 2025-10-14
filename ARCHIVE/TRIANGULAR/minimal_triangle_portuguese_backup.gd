extends Node2D

# Malha hexagonal expandida (37 pontos: raio 3)
var points = []
var hex_coords = []  # Coordenadas axiais (q, r) para cada ponto
var hex_size = 40.0  # Tamanho do hexágono
var hex_center = Vector2(400, 300)  # Centro da malha

# Tipos de terreno (arestas)
enum EdgeType {
	FIELD,          # Verde: field (move + vê) - 6/12
	FOREST,         # Verde acizentado: forest (move mas não vê) - 2/12
	MOUNTAIN,       # Amarelo acizentado: mountain (não move nem vê) - 2/12
	WATER           # Ciano acizentado: water (vê mas não move) - 2/12
}

# Paths (caminhos) da malha hexagonal (geradas dinamicamente)
var paths = []

# Estado do hover
var hovered_point = -1
var hovered_edge = -1

# Units (unidades) - serão definidas após gerar a malha
var unit1_position = 0  # Índice do ponto onde está a unit 1
var unit2_position = 0  # Índice do ponto onde está a unit 2
var unit1_label: Label
var unit2_label: Label
var unit1_actions = 1   # Pontos de ação da unit 1
var unit2_actions = 1   # Pontos de ação da unit 2
var current_player = 1  # Jogador atual (1 ou 2)
var fog_of_war = true   # Controle da fog of war

# Domains (domínios)
var unit1_domain_center = 0  # Centro do domínio da unit 1
var unit2_domain_center = 0  # Centro do domínio da unit 2
var unit1_domain_name = ""   # Nome do domínio da unit 1
var unit2_domain_name = ""   # Nome do domínio da unit 2
var unit1_name = ""          # Nome da unit 1
var unit2_name = ""          # Nome da unit 2
var unit1_domain_label: Label # Label do nome do domínio 1
var unit2_domain_label: Label # Label do nome do domínio 2
var unit1_name_label: Label   # Label do nome da unit 1
var unit2_name_label: Label   # Label do nome da unit 2

# Revelação forçada (para mecânica de floresta)
var unit1_force_revealed = false  # Unit 1 foi revelada forçadamente
var unit2_force_revealed = false  # Unit 2 foi revelada forçadamente

# Sistema de Poder
var unit1_domain_power = 1  # Poder acumulado do domínio 1 (começa com 1)
var unit2_domain_power = 1  # Poder acumulado do domínio 2 (começa com 1)

# UI
var skip_turn_button: Button
var action_label: Label

func _ready():
	print("Gerando malha hexagonal expandida...")
	
	# Gerar malha hexagonal
	_generate_hex_grid()
	
	# Definir posições iniciais das unidades
	_set_initial_unit_positions()
	
	# Gerar terreno aleatório automaticamente
	_generate_random_terrain()
	
	print("Malha hexagonal criada: %d pontos, %d paths" % [points.size(), paths.size()])
	
	# Criar labels para as units
	unit1_label = Label.new()
	unit1_label.text = "🚶🏻‍♀️"  # Emoji de pessoa caminhando
	unit1_label.add_theme_font_size_override("font_size", 24)
	unit1_label.modulate = Color(1.0, 0.0, 0.0)  # Vermelho usando modulate
	add_child(unit1_label)
	
	unit2_label = Label.new()
	unit2_label.text = "🚶🏻‍♀️"  # Emoji de pessoa caminhando
	unit2_label.add_theme_font_size_override("font_size", 24)
	unit2_label.modulate = Color(0.5, 0.0, 0.8)  # Violeta usando modulate
	add_child(unit2_label)
	
	# Marcar pontas do mapa
	_mark_map_corners()
	
	# Posicionar labels nos pontos iniciais
	_update_units_visibility_and_position()
	
	# Criar UI
	_create_ui()

func _process(_delta):
	var mouse_pos = get_global_mouse_position()
	
	# Verificar hover em pontos (incluindo não renderizados)
	hovered_point = -1
	for i in range(points.size()):
		if mouse_pos.distance_to(points[i]) < 20:
			hovered_point = i
			break
	
	# Verificar hover em paths (incluindo não renderizadas)
	hovered_edge = -1
	if hovered_point == -1:
		for i in range(paths.size()):
			var path = paths[i]
			var path_points = path.points
			var p1 = points[path_points[0]]
			var p2 = points[path_points[1]]
			if _point_near_line(mouse_pos, p1, p2, 10):
				hovered_edge = i
				break
	
	queue_redraw()

func _draw():
	# Fundo branco expandido
	draw_rect(Rect2(-200, -200, 1200, 1000), Color.WHITE)
	
	# Desenhar paths (com ou sem fog of war)
	for i in range(paths.size()):
		var path = paths[i]
		# Renderizar baseado na fog of war
		var should_render = false
		if fog_of_war:
			# Com fog: adjacentes ao jogador atual, hover OU dentro do domínio do jogador atual
			should_render = _is_path_adjacent_to_current_unit(path) or hovered_edge == i or _is_path_in_current_player_domain(path)
		else:
			# Sem fog: todos os paths
			should_render = true
		
		if should_render:
			var path_points = path.points
			var p1 = points[path_points[0]]
			var p2 = points[path_points[1]]
			var color = _get_path_color(path.type)
			if hovered_edge == i:
				color = Color.MAGENTA
			draw_line(p1, p2, color, 8)  # Paths ainda mais grossos
	
	# Desenhar pontos (com ou sem fog of war)
	for i in range(points.size()):
		var current_unit_pos = unit1_position if current_player == 1 else unit2_position
		var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
		
		var should_render = false
		
		if fog_of_war:
			# Com fog: renderizar baseado na visibilidade
			# Sempre renderizar a unit do jogador atual
			if i == current_unit_pos:
				should_render = true
			# Renderizar unit inimiga apenas se estiver em ponto visível
			elif i == enemy_unit_pos and _is_point_visible_to_current_unit(i):
				should_render = true
			# Renderizar pontos visíveis ao jogador atual
			elif _is_point_visible_to_current_unit(i):
				should_render = true
			# Renderizar pontos em hover
			elif hovered_point == i:
				should_render = true
			# Renderizar pontos dentro do domínio do jogador atual
			elif _is_point_in_current_player_domain(i):
				should_render = true
		else:
			# Sem fog: renderizar todos os pontos
			should_render = true
		
		if should_render:
			var color = Color.BLACK
			
			# Magenta se estiver em hover
			if hovered_point == i:
				color = Color.MAGENTA
			# Magenta se a unit atual puder se mover para lá
			elif _can_current_unit_move_to_point(i):
				color = Color.MAGENTA
			
			draw_circle(points[i], 8, color)
	
	# Desenhar domínios
	_draw_domains()
	
	# Atualizar posição das unidades
	_update_units_visibility_and_position()

## Input handling para movimento da unidade e geração de terreno
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		# Verificar clique em pontos
		for i in range(points.size()):
			if mouse_pos.distance_to(points[i]) < 20:
				# Se clicou em ponto que a unit atual pode se mover, verificar ações
				if _can_current_unit_move_to_point(i):
					var current_actions = unit1_actions if current_player == 1 else unit2_actions
					if current_actions > 0:
						# Verificar se o domínio tem poder suficiente
						if not _has_domain_power_for_action():
							print("⚡ Sem poder! Domínio não tem poder para realizar ação.")
							return
						
						# Verificar se há unidade oculta no destino
						var movement_result = _attempt_movement(i)
						
						if movement_result.success:
							var old_pos = unit1_position if current_player == 1 else unit2_position
							print("🚶🏻‍♀️ Unit %d movendo do ponto %d para ponto %d (Ações: %d → %d)" % [current_player, old_pos, i, current_actions, current_actions - 1])
							
							# Consumir poder do domínio
							_consume_domain_power()
							
							if current_player == 1:
								unit1_position = i
								unit1_actions -= 1
							else:
								unit2_position = i
								unit2_actions -= 1
						else:
							# Movimento falhou devido a unidade oculta
							print("⚠️ Movimento bloqueado! %s" % movement_result.message)
							# Consumir poder e perder ação mesmo assim
							_consume_domain_power()
							if current_player == 1:
								unit1_actions -= 1
							else:
								unit2_actions -= 1
						
						_update_units_visibility_and_position()
						_update_action_display()
						queue_redraw()
						get_viewport().set_input_as_handled()
						return
					else:
						print("❌ Sem ações restantes! Use 'Skip Turn' para restaurar.")
				else:
					print("❌ Unit %d não pode se mover para ponto %d" % [current_player, i])
	
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Alternar fog of war
			fog_of_war = not fog_of_war
			var fog_status = "ATIVADA" if fog_of_war else "DESATIVADA"
			print("🌫️ Fog of War %s" % fog_status)
			queue_redraw()
			get_viewport().set_input_as_handled()

func _point_near_line(point, line_start, line_end, tolerance):
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len = line_vec.length()
	
	if line_len == 0:
		return point.distance_to(line_start) <= tolerance
	
	var t = point_vec.dot(line_vec) / (line_len * line_len)
	t = clamp(t, 0.0, 1.0)
	
	var closest_point = line_start + t * line_vec
	return point.distance_to(closest_point) <= tolerance

## Obter cor do path baseada no tipo (cores mais saturadas)
func _get_path_color(path_type: EdgeType) -> Color:
	match path_type:
		EdgeType.FIELD:
			return Color.GREEN          # Verde: field
		EdgeType.FOREST:
			return Color(0.2, 0.7, 0.2) # Verde mais saturado: forest
		EdgeType.MOUNTAIN:
			return Color(0.7, 0.7, 0.2) # Amarelo mais saturado: mountain
		EdgeType.WATER:
			return Color(0.2, 0.7, 0.7) # Ciano mais saturado: water
		_:
			return Color.BLACK

## Verificar se path é adjacente ao jogador atual
func _is_path_adjacent_to_current_unit(path: Dictionary) -> bool:
	# Path é adjacente se um dos pontos tem a unit do jogador atual
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	var path_points = path.points
	return path_points[0] == current_unit_pos or path_points[1] == current_unit_pos

## Verificar se path é adjacente a alguma unit (para hover)
func _is_path_adjacent_to_unit(path: Dictionary) -> bool:
	# Path é adjacente se um dos pontos tem alguma unit
	var path_points = path.points
	return path_points[0] == unit1_position or path_points[1] == unit1_position or \
		   path_points[0] == unit2_position or path_points[1] == unit2_position

## Verificar se ponto é visível ao jogador atual
func _is_point_visible_to_current_unit(point_index: int) -> bool:
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	return _is_point_visible_to_unit(point_index, current_unit_pos)

## Verificar se ponto é visível a alguma unit (para hover)
func _is_point_visible_to_any_unit(point_index: int) -> bool:
	return _is_point_visible_to_unit(point_index, unit1_position) or _is_point_visible_to_unit(point_index, unit2_position)

## Verificar se ponto é visível a uma unit específica
func _is_point_visible_to_unit(point_index: int, unit_pos: int) -> bool:
	# Verificar se existe path que permite visibilidade
	for path in paths:
		var path_points = path.points
		if (path_points[0] == unit_pos and path_points[1] == point_index) or \
		   (path_points[1] == unit_pos and path_points[0] == point_index):
			# Field e Water permitem ver
			if path.type == EdgeType.FIELD or path.type == EdgeType.WATER:
				return true
	return false

## Tentar movimento e verificar unidades ocultas
func _attempt_movement(target_point: int) -> Dictionary:
	# Verificar se há unidade inimiga no ponto de destino
	var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	
	# Se a unidade inimiga está no ponto de destino
	if enemy_unit_pos == target_point:
		# Verificar se o movimento é através de floresta
		var path_type = _get_path_type_between_points(current_unit_pos, target_point)
		
		# Verificar se a unidade inimiga estava oculta (não visível)
		var enemy_was_visible = false
		if current_player == 1:
			enemy_was_visible = unit2_label.visible
		else:
			enemy_was_visible = unit1_label.visible
		
		if path_type == EdgeType.FOREST and not enemy_was_visible:
			# Revelar a unidade inimiga na floresta
			print("🔍 Unidade inimiga revelada na floresta!")
			# Marcar unidade inimiga como revelada forçadamente
			if current_player == 1:
				unit2_force_revealed = true
			else:
				unit1_force_revealed = true
			return {"success": false, "message": "Unidade inimiga descoberta na floresta! Movimento cancelado."}
		else:
			# Movimento bloqueado por unidade visível ou terreno não-floresta
			return {"success": false, "message": "Ponto ocupado por unidade inimiga."}
	
	# Movimento bem-sucedido
	return {"success": true, "message": ""}

## Obter tipo de path entre dois pontos
func _get_path_type_between_points(point1: int, point2: int) -> EdgeType:
	for path in paths:
		var path_points = path.points
		if (path_points[0] == point1 and path_points[1] == point2) or \
		   (path_points[1] == point1 and path_points[0] == point2):
			return path.type
	
	# Se não encontrar path, retornar MOUNTAIN (bloqueado)
	return EdgeType.MOUNTAIN

## Verificar se o domínio tem poder para realizar ação
func _has_domain_power_for_action() -> bool:
	# Verificar se o centro do domínio está ocupado por inimigo
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
	
	# Se o centro do domínio estiver ocupado por inimigo, ações são gratuitas
	if enemy_unit_pos == domain_center:
		print("⚡ Domínio ocupado! Ações gratuitas para unidades originais.")
		return true
	
	# Caso contrário, verificar se tem poder
	var current_power = unit1_domain_power if current_player == 1 else unit2_domain_power
	return current_power > 0

## Consumir poder do domínio
func _consume_domain_power() -> void:
	# Verificar se o centro do domínio está ocupado por inimigo
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
	
	# Se o centro estiver ocupado, não consumir poder
	if enemy_unit_pos == domain_center:
		return
	
	# Consumir 1 poder
	if current_player == 1:
		unit1_domain_power = max(0, unit1_domain_power - 1)
		print("⚡ Domínio 1 consumiu 1 poder (Restante: %d)" % unit1_domain_power)
	else:
		unit2_domain_power = max(0, unit2_domain_power - 1)
		print("⚡ Domínio 2 consumiu 1 poder (Restante: %d)" % unit2_domain_power)

## Gerar poder para os domínios (uma vez por rodada)
func _generate_domain_power() -> void:
	print("🔄 Nova rodada - Gerando poder para domínios")
	
	# Domínio 1: gerar poder se não estiver ocupado
	if unit2_position != unit1_domain_center:
		unit1_domain_power += 1
		print("⚡ Domínio 1 (%s) gerou 1 poder (Total: %d)" % [unit1_domain_name, unit1_domain_power])
	else:
		print("⚡ Domínio 1 (%s) ocupado - não gerou poder" % unit1_domain_name)
	
	# Domínio 2: gerar poder se não estiver ocupado
	if unit1_position != unit2_domain_center:
		unit2_domain_power += 1
		print("⚡ Domínio 2 (%s) gerou 1 poder (Total: %d)" % [unit2_domain_name, unit2_domain_power])
	else:
		print("⚡ Domínio 2 (%s) ocupado - não gerou poder" % unit2_domain_name)

## Verificar se ponto está dentro do domínio do jogador atual
func _is_point_in_current_player_domain(point_index: int) -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	return _is_point_in_specific_domain(point_index, domain_center)

## Verificar se path está dentro do domínio do jogador atual
func _is_path_in_current_player_domain(path: Dictionary) -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var point1 = path.points[0]
	var point2 = path.points[1]
	
	# Path está no domínio se ambos os pontos estiverem no domínio do jogador atual
	return _is_point_in_specific_domain(point1, domain_center) and _is_point_in_specific_domain(point2, domain_center)

## Verificar se ponto está dentro de algum domínio
func _is_point_in_domain(point_index: int) -> bool:
	# Verificar se o ponto está dentro do domínio da unit 1
	if _is_point_in_specific_domain(point_index, unit1_domain_center):
		return true
	
	# Verificar se o ponto está dentro do domínio da unit 2
	if _is_point_in_specific_domain(point_index, unit2_domain_center):
		return true
	
	return false

## Verificar se ponto está dentro de um domínio específico
func _is_point_in_specific_domain(point_index: int, domain_center: int) -> bool:
	# O ponto está no domínio se for o centro ou um dos 6 vizinhos
	if point_index == domain_center:
		return true
	
	# Verificar se é um dos 6 pontos ao redor do centro
	var domain_coord = hex_coords[domain_center]
	var point_coord = hex_coords[point_index]
	
	for dir in range(6):
		var neighbor_coord = domain_coord + _hex_direction(dir)
		if point_coord.is_equal_approx(neighbor_coord):
			return true
	
	return false

## Verificar se path está dentro de algum domínio
func _is_path_in_domain(path: Dictionary) -> bool:
	# Path está no domínio se ambos os pontos estiverem no domínio
	var point1 = path.points[0]
	var point2 = path.points[1]
	
	# Verificar domínio da unit 1
	if _is_point_in_specific_domain(point1, unit1_domain_center) and _is_point_in_specific_domain(point2, unit1_domain_center):
		return true
	
	# Verificar domínio da unit 2
	if _is_point_in_specific_domain(point1, unit2_domain_center) and _is_point_in_specific_domain(point2, unit2_domain_center):
		return true
	
	return false

## Verificar se unit atual pode se mover para o ponto
func _can_current_unit_move_to_point(point_index: int) -> bool:
	var unit_pos = unit1_position if current_player == 1 else unit2_position
	return _can_unit_move_to_point(point_index, unit_pos)

## Verificar se uma unit específica pode se mover para o ponto
func _can_unit_move_to_point(point_index: int, unit_pos: int) -> bool:
	# Não pode mover para si mesmo
	if point_index == unit_pos:
		return false
	
	# Verificar se existe path que permite movimento
	for path in paths:
		var path_points = path.points
		if (path_points[0] == unit_pos and path_points[1] == point_index) or \
		   (path_points[1] == unit_pos and path_points[0] == point_index):
			# Field e Forest permitem mover
			if path.type == EdgeType.FIELD or path.type == EdgeType.FOREST:
				return true
	return false

## Gerar terreno aleatório com proporções
func _generate_random_terrain() -> void:
	print("🌍 Gerando terreno aleatório...")
	
	# Criar pool de tipos baseado nas proporções
	var terrain_pool = []
	# Field: 6/12 (50%)
	for i in range(6):
		terrain_pool.append(EdgeType.FIELD)
	# Forest: 2/12 (16.7%)
	for i in range(2):
		terrain_pool.append(EdgeType.FOREST)
	# Water: 2/12 (16.7%)
	for i in range(2):
		terrain_pool.append(EdgeType.WATER)
	# Mountain: 2/12 (16.7%)
	for i in range(2):
		terrain_pool.append(EdgeType.MOUNTAIN)
	
	# Embaralhar e aplicar aos paths
	terrain_pool.shuffle()
	for i in range(paths.size()):
		var pool_index = i % terrain_pool.size()
		paths[i].type = terrain_pool[pool_index]
	
	print("✨ Terreno aleatório gerado! Field: 50%, Forest/Water/Mountain: 16.7% cada")
	print("Pressione ESPAÇO novamente para regenerar.")

## Obter pontos externos (raio 3)
func _get_outer_points() -> Array[int]:
	var outer_points: Array[int] = []
	for i in range(hex_coords.size()):
		var coord = hex_coords[i]
		var distance = max(abs(coord.x), abs(coord.y), abs(-coord.x - coord.y))
		if distance == 3:
			outer_points.append(i)
	return outer_points

## Gerar malha hexagonal
func _generate_hex_grid() -> void:
	points.clear()
	hex_coords.clear()
	paths.clear()
	
	# Gerar pontos em coordenadas axiais
	var point_id = 0
	for radius in range(4):  # Raio 0 a 3
		if radius == 0:
			# Centro
			hex_coords.append(Vector2(0, 0))
			points.append(_hex_to_pixel(0, 0))
			point_id += 1
		else:
			# Pontos ao redor do centro
			for i in range(6):  # 6 direções
				for j in range(radius):  # Pontos ao longo de cada direção
					var q = _hex_direction(i).x * (radius - j) + _hex_direction((i + 1) % 6).x * j
					var r = _hex_direction(i).y * (radius - j) + _hex_direction((i + 1) % 6).y * j
					hex_coords.append(Vector2(q, r))
					points.append(_hex_to_pixel(q, r))
					point_id += 1
	
	# Gerar paths conectando vizinhos
	_generate_hex_paths()

## Converter coordenadas axiais para pixel (girado 60°)
func _hex_to_pixel(q: float, r: float) -> Vector2:
	# Coordenadas originais
	var x = hex_size * (3.0/2.0 * q)
	var y = hex_size * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r)
	
	# Aplicar rotação de 60° (pi/3 radianos)
	var angle = PI / 3.0  # 60 graus
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	
	var rotated_x = x * cos_angle - y * sin_angle
	var rotated_y = x * sin_angle + y * cos_angle
	
	return hex_center + Vector2(rotated_x, rotated_y)

## Obter direção hexagonal
func _hex_direction(direction: int) -> Vector2:
	var directions = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	return directions[direction]

## Gerar paths hexagonais
func _generate_hex_paths() -> void:
	var path_set = {}  # Para evitar duplicatas
	
	for i in range(hex_coords.size()):
		var coord = hex_coords[i]
		# Verificar 6 vizinhos
		for dir in range(6):
			var neighbor_coord = coord + _hex_direction(dir)
			var neighbor_index = _find_hex_coord_index(neighbor_coord)
			
			if neighbor_index != -1:
				# Criar ID único para o path (sempre menor índice primeiro)
				var path_id = "%d_%d" % [min(i, neighbor_index), max(i, neighbor_index)]
				
				if not path_set.has(path_id):
					paths.append({"points": [i, neighbor_index], "type": EdgeType.FIELD})
					path_set[path_id] = true

## Encontrar índice de coordenada hexagonal
func _find_hex_coord_index(coord: Vector2) -> int:
	for i in range(hex_coords.size()):
		if hex_coords[i].is_equal_approx(coord):
			return i
	return -1

## Definir posições iniciais das unidades (spawn oficial)
func _set_initial_unit_positions() -> void:
	# Obter os 6 cantos do mapa
	var corners = _get_map_corners()
	
	if corners.size() >= 2:
		# Embaralhar e escolher 2 cantos aleatórios
		corners.shuffle()
		var corner1 = corners[0]
		var corner2 = corners[1]
		
		# Encontrar ponto adjacente com 6 arestas
		unit1_position = _find_adjacent_six_edge_point(corner1)
		unit2_position = _find_adjacent_six_edge_point(corner2)
		
		# Definir centros dos domínios
		unit1_domain_center = unit1_position
		unit2_domain_center = unit2_position
		
		# Gerar nomes para domínios e unidades
		_generate_domain_and_unit_names()
		
		print("Unidades posicionadas no spawn oficial:")
		print("Unit1 (Vermelha) '%s' em ponto %d: %s (Domínio: %s)" % [unit1_name, unit1_position, hex_coords[unit1_position], unit1_domain_name])
		print("Unit2 (Violeta) '%s' em ponto %d: %s (Domínio: %s)" % [unit2_name, unit2_position, hex_coords[unit2_position], unit2_domain_name])
		print("Domínios criados nos pontos de spawn")
	else:
		print("Erro: Não foi possível encontrar cantos suficientes")

## Gerar nomes para domínios e unidades
func _generate_domain_and_unit_names() -> void:
	# Nomes de domínios com iniciais únicas
	var domain_names = ["Aldara", "Belthor", "Caldris", "Drakemoor", "Eldoria", "Frostheim"]
	var unit_names = [
		["Aldric", "Alara", "Arden", "Astrid"],
		["Bjorn", "Brenna", "Baldur", "Bianca"],
		["Castor", "Celia", "Cyrus", "Clara"],
		["Darius", "Diana", "Drake", "Delara"],
		["Elias", "Elena", "Erik", "Evelyn"],
		["Felix", "Freya", "Finn", "Fiona"]
	]
	
	# Embaralhar e escolher 2 domínios diferentes
	domain_names.shuffle()
	unit1_domain_name = domain_names[0]
	unit2_domain_name = domain_names[1]
	
	# Escolher nomes de unidades baseados na inicial do domínio
	var domain1_index = _get_domain_index(unit1_domain_name)
	var domain2_index = _get_domain_index(unit2_domain_name)
	
	unit_names[domain1_index].shuffle()
	unit_names[domain2_index].shuffle()
	
	unit1_name = unit_names[domain1_index][0]
	unit2_name = unit_names[domain2_index][0]
	
	# Criar labels para os nomes
	_create_name_labels()

## Obter índice do domínio baseado na inicial
func _get_domain_index(domain_name: String) -> int:
	var first_letter = domain_name.substr(0, 1)
	match first_letter:
		"A": return 0
		"B": return 1
		"C": return 2
		"D": return 3
		"E": return 4
		"F": return 5
		_: return 0

## Criar labels para nomes
func _create_name_labels() -> void:
	# Label do domínio 1
	unit1_domain_label = Label.new()
	unit1_domain_label.text = unit1_domain_name
	unit1_domain_label.add_theme_font_size_override("font_size", 12)
	unit1_domain_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	add_child(unit1_domain_label)
	
	# Label do domínio 2
	unit2_domain_label = Label.new()
	unit2_domain_label.text = unit2_domain_name
	unit2_domain_label.add_theme_font_size_override("font_size", 12)
	unit2_domain_label.add_theme_color_override("font_color", Color(0.5, 0.0, 0.8))
	add_child(unit2_domain_label)
	
	# Label da unit 1
	unit1_name_label = Label.new()
	unit1_name_label.text = unit1_name
	unit1_name_label.add_theme_font_size_override("font_size", 10)
	unit1_name_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	add_child(unit1_name_label)
	
	# Label da unit 2
	unit2_name_label = Label.new()
	unit2_name_label.text = unit2_name
	unit2_name_label.add_theme_font_size_override("font_size", 10)
	unit2_name_label.add_theme_color_override("font_color", Color(0.5, 0.0, 0.8))
	add_child(unit2_name_label)

## Encontrar ponto adjacente com 6 arestas
func _find_adjacent_six_edge_point(corner_index: int) -> int:
	var corner_coord = hex_coords[corner_index]
	
	# Verificar todos os 6 vizinhos hexagonais do canto
	for dir in range(6):
		var neighbor_coord = corner_coord + _hex_direction(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		
		if neighbor_index != -1:
			# Contar paths deste vizinho
			var path_count = 0
			for path in paths:
				var path_points = path.points
				if path_points[0] == neighbor_index or path_points[1] == neighbor_index:
					path_count += 1
			
			# Se tem 6 paths, é um ponto válido
			if path_count == 6:
				return neighbor_index
	
	# Se não encontrar nenhum vizinho com 6 paths, retornar o próprio canto
	return corner_index

## Desenhar domínios hexagonais
func _draw_domains() -> void:
	# Desenhar domínio da unit 1 (vermelho)
	if unit1_domain_center >= 0 and unit1_domain_center < points.size():
		_draw_domain_hexagon(unit1_domain_center, Color(1.0, 0.0, 0.0))
	
	# Desenhar domínio da unit 2 (violeta)
	if unit2_domain_center >= 0 and unit2_domain_center < points.size():
		_draw_domain_hexagon(unit2_domain_center, Color(0.5, 0.0, 0.8))

## Desenhar hexágono de domínio
func _draw_domain_hexagon(center_index: int, color: Color) -> void:
	# Verificar se o domínio deve ser visível (fog of war)
	if fog_of_war and not _is_domain_visible(center_index):
		return
	
	var center_pos = points[center_index]
	# Calcular raio baseado na distância real entre pontos adjacentes
	var radius = _get_edge_length(center_index)
	
	# Calcular os 6 vértices do hexágono
	var vertices = []
	for i in range(6):
		var angle = (i * PI / 3.0) + (PI / 6.0)  # Começar com ponta para cima
		var x = center_pos.x + radius * cos(angle)
		var y = center_pos.y + radius * sin(angle)
		vertices.append(Vector2(x, y))
	
	# Desenhar as 6 arestas do hexágono
	for i in range(6):
		var start = vertices[i]
		var end = vertices[(i + 1) % 6]
		draw_line(start, end, color, 4)  # Linha mais grossa

## Obter comprimento real de uma aresta
func _get_edge_length(point_index: int) -> float:
	# Encontrar um ponto adjacente e calcular a distância
	var point_coord = hex_coords[point_index]
	for dir in range(6):
		var neighbor_coord = point_coord + _hex_direction(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1:
			# Calcular distância entre os pontos
			var distance = points[point_index].distance_to(points[neighbor_index])
			return distance
	
	# Fallback para hex_size se não encontrar vizinho
	return hex_size

## Verificar se domínio é visível ao jogador atual
func _is_domain_visible(domain_center: int) -> bool:
	# Domínio sempre visível se for do jogador atual
	if (current_player == 1 and domain_center == unit1_domain_center) or \
	   (current_player == 2 and domain_center == unit2_domain_center):
		return true
	
	# Domínio inimigo visível se o centro ou qualquer ponto adjacente for visível
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	
	# Verificar se o centro do domínio é visível
	if _is_point_visible_to_unit(domain_center, current_unit_pos):
		return true
	
	# Verificar se algum ponto adjacente ao centro do domínio é visível
	var domain_coord = hex_coords[domain_center]
	for dir in range(6):
		var neighbor_coord = domain_coord + _hex_direction(dir)
		var neighbor_index = _find_hex_coord_index(neighbor_coord)
		if neighbor_index != -1 and _is_point_visible_to_unit(neighbor_index, current_unit_pos):
			return true
	
	return false

## Detectar as seis pontas do mapa (pontos com apenas 3 arestas)
func _get_map_corners() -> Array[int]:
	var corners: Array[int] = []
	
	# Contar paths conectados a cada ponto
	for i in range(points.size()):
		var path_count = 0
		
		# Contar quantos paths conectam a este ponto
		for path in paths:
			var path_points = path.points
			if path_points[0] == i or path_points[1] == i:
				path_count += 1
		
		# Pontas do hexágono têm apenas 3 paths
		if path_count == 3:
			corners.append(i)
	
	return corners

## Marcar pontas do mapa (pintar de magenta)
func _mark_map_corners() -> void:
	var corners = _get_map_corners()
	
	print("🔍 Pontas detectadas: %d pontos com 3 paths" % corners.size())
	for corner_index in corners:
		print("  Ponta %d: coordenada %s" % [corner_index, hex_coords[corner_index]])
	
	# Armazenar índices das pontas para pintar de magenta
	for corner_index in corners:
		# As pontas serão pintadas de magenta na função _draw()
		pass

## Criar interface do usuário
func _create_ui() -> void:
	# Botão Skip Turn
	skip_turn_button = Button.new()
	skip_turn_button.text = "Skip Turn"
	skip_turn_button.size = Vector2(100, 40)
	skip_turn_button.position = Vector2(680, 20)  # Canto superior direito
	skip_turn_button.pressed.connect(_on_skip_turn_pressed)
	add_child(skip_turn_button)
	
	# Label de ações
	action_label = Label.new()
	action_label.text = "Jogador 1 (Vermelho)\nAções: 1"
	action_label.position = Vector2(580, 70)
	action_label.add_theme_font_size_override("font_size", 14)
	add_child(action_label)

## Callback do botão Skip Turn
func _on_skip_turn_pressed() -> void:
	print("⏭️ Jogador %d pulando turno - Mudando para jogador %d" % [current_player, 3 - current_player])
	
	# Trocar jogador
	current_player = 3 - current_player  # 1 -> 2, 2 -> 1
	
	# Gerar poder para os domínios no início da rodada (quando volta ao jogador 1)
	if current_player == 1:
		_generate_domain_power()
	
	# Restaurar ações do novo jogador
	if current_player == 1:
		unit1_actions = 1
	else:
		unit2_actions = 1
	
	# Resetar revelações forçadas se as unidades não estiverem mais visíveis
	_check_and_reset_forced_revelations()
	
	_update_action_display()
	queue_redraw()

## Atualizar display de ações
func _update_action_display() -> void:
	if action_label:
		var player_name = "Jogador 1 (Vermelho)" if current_player == 1 else "Jogador 2 (Violeta)"
		var actions = unit1_actions if current_player == 1 else unit2_actions
		action_label.text = "%s\nAções: %d" % [player_name, actions]

## Atualizar posição e visibilidade das units
func _update_units_visibility_and_position():
	if unit1_label:
		var unit1_pos = points[unit1_position]
		unit1_label.position = unit1_pos + Vector2(-12, -35)  # Centralizar emoji acima do ponto
		
		# Unit 1 sempre visível para jogador 1, visível para jogador 2 apenas se estiver em ponto visível
		if not fog_of_war:
			# Sem fog: sempre visível
			unit1_label.visible = true
		elif current_player == 1:
			unit1_label.visible = true
		elif unit1_force_revealed:
			# Unit 1 foi revelada forçadamente (mecânica de floresta)
			unit1_label.visible = true
		else:
			unit1_label.visible = _is_point_visible_to_current_unit(unit1_position)
	
	if unit2_label:
		var unit2_pos = points[unit2_position]
		unit2_label.position = unit2_pos + Vector2(-12, -35)  # Centralizar emoji acima do ponto
		
		# Unit 2 sempre visível para jogador 2, visível para jogador 1 apenas se estiver em ponto visível
		if not fog_of_war:
			# Sem fog: sempre visível
			unit2_label.visible = true
		elif current_player == 2:
			unit2_label.visible = true
		elif unit2_force_revealed:
			# Unit 2 foi revelada forçadamente (mecânica de floresta)
			unit2_label.visible = true
		else:
			unit2_label.visible = _is_point_visible_to_current_unit(unit2_position)
	
	# Atualizar posições dos nomes
	_update_name_positions()

## Atualizar posições dos nomes
func _update_name_positions() -> void:
	# Posicionar nomes das unidades
	if unit1_name_label:
		var unit1_pos = points[unit1_position]
		unit1_name_label.position = unit1_pos + Vector2(-15, 15)  # Abaixo da unit
		unit1_name_label.visible = unit1_label.visible  # Mesma visibilidade da unit
	
	if unit2_name_label:
		var unit2_pos = points[unit2_position]
		unit2_name_label.position = unit2_pos + Vector2(-15, 15)  # Abaixo da unit
		unit2_name_label.visible = unit2_label.visible  # Mesma visibilidade da unit
	
	# Posicionar nomes dos domínios e atualizar poder
	if unit1_domain_label:
		var domain1_pos = points[unit1_domain_center]
		unit1_domain_label.position = domain1_pos + Vector2(-30, 35)  # Abaixo do domínio
		unit1_domain_label.text = "%s ⚡%d" % [unit1_domain_name, unit1_domain_power]
		unit1_domain_label.visible = _is_domain_visible(unit1_domain_center) or not fog_of_war
	
	if unit2_domain_label:
		var domain2_pos = points[unit2_domain_center]
		unit2_domain_label.position = domain2_pos + Vector2(-30, 35)  # Abaixo do domínio
		unit2_domain_label.text = "%s ⚡%d" % [unit2_domain_name, unit2_domain_power]
		unit2_domain_label.visible = _is_domain_visible(unit2_domain_center) or not fog_of_war

## Verificar e resetar revelações forçadas
func _check_and_reset_forced_revelations() -> void:
	# Resetar unit1_force_revealed se ela não estiver naturalmente visível
	if unit1_force_revealed and current_player == 2:
		if not _is_point_visible_to_current_unit(unit1_position):
			unit1_force_revealed = false
			print("🔍 Unit 1 não é mais visível - resetando revelação forçada")
	
	# Resetar unit2_force_revealed se ela não estiver naturalmente visível
	if unit2_force_revealed and current_player == 1:
		if not _is_point_visible_to_current_unit(unit2_position):
			unit2_force_revealed = false
			print("🔍 Unit 2 não é mais visível - resetando revelação forçada")