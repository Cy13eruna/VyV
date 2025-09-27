extends Node2D

# Pontos do hexágono equilátero girado 30° (7 pontos: 6 vértices + 1 centro)
var points = [
	Vector2(400, 200),                    # 0: Centro
	Vector2(530, 200),                    # 1: Direita
	Vector2(465, 312.5),                  # 2: Inferior direito
	Vector2(335, 312.5),                  # 3: Inferior esquerdo
	Vector2(270, 200),                    # 4: Esquerda
	Vector2(335, 87.5),                   # 5: Superior esquerdo
	Vector2(465, 87.5)                    # 6: Superior direito
]

# Tipos de arestas
enum EdgeType {
	GREEN,          # Verde: padrão (move + vê)
	GREEN_GRAY,     # Verde acizentado: move mas não vê
	YELLOW_GRAY,    # Amarelo acizentado: não move nem vê
	CYAN_GRAY       # Ciano acizentado: vê mas não move
}

# Arestas do hexágono girado com tipos (12 arestas: 6 perímetro + 6 radiais)
var edges = [
	# Perímetro do hexágono (6 arestas)
	{"points": [1, 2], "type": EdgeType.GREEN},      # Direita -> Inferior direito
	{"points": [2, 3], "type": EdgeType.GREEN_GRAY}, # Inferior direito -> Inferior esquerdo
	{"points": [3, 4], "type": EdgeType.YELLOW_GRAY},# Inferior esquerdo -> Esquerda
	{"points": [4, 5], "type": EdgeType.CYAN_GRAY},  # Esquerda -> Superior esquerdo
	{"points": [5, 6], "type": EdgeType.GREEN},      # Superior esquerdo -> Superior direito
	{"points": [6, 1], "type": EdgeType.GREEN_GRAY}, # Superior direito -> Direita
	# Arestas radiais do centro (6 arestas)
	{"points": [0, 1], "type": EdgeType.GREEN},      # Centro -> Direita
	{"points": [0, 2], "type": EdgeType.GREEN_GRAY}, # Centro -> Inferior direito
	{"points": [0, 3], "type": EdgeType.YELLOW_GRAY},# Centro -> Inferior esquerdo
	{"points": [0, 4], "type": EdgeType.CYAN_GRAY},  # Centro -> Esquerda
	{"points": [0, 5], "type": EdgeType.GREEN},      # Centro -> Superior esquerdo
	{"points": [0, 6], "type": EdgeType.GREEN_GRAY}  # Centro -> Superior direito
]

# Estado do hover
var hovered_point = -1
var hovered_edge = -1

# Unit (unidade)
var unit_position = 0  # Índice do ponto onde está a unit
var unit_label: Label
var unit_actions = 1   # Pontos de ação da unit

# UI
var skip_turn_button: Button
var action_label: Label

func _ready():
	print("Hexágono equilátero com 7 pontos e 12 arestas criado")
	
	# Criar label para a unit
	unit_label = Label.new()
	unit_label.text = "🚶🏻‍♀️"
	unit_label.add_theme_font_size_override("font_size", 24)
	add_child(unit_label)
	
	# Posicionar label no ponto inicial
	_update_unit_position()
	
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
	
	# Verificar hover em arestas (incluindo não renderizadas)
	hovered_edge = -1
	if hovered_point == -1:
		for i in range(edges.size()):
			var edge = edges[i]
			var edge_points = edge.points
			var p1 = points[edge_points[0]]
			var p2 = points[edge_points[1]]
			if _point_near_line(mouse_pos, p1, p2, 10):
				hovered_edge = i
				break
	
	queue_redraw()

func _draw():
	# Fundo branco
	draw_rect(Rect2(0, 0, 800, 600), Color.WHITE)
	
	# Desenhar arestas (adjacentes + hover)
	for i in range(edges.size()):
		var edge = edges[i]
		# Renderizar se adjacente à unit OU em hover
		if _is_edge_adjacent_to_unit(edge) or hovered_edge == i:
			var edge_points = edge.points
			var p1 = points[edge_points[0]]
			var p2 = points[edge_points[1]]
			var color = _get_edge_color(edge.type)
			if hovered_edge == i:
				color = Color.MAGENTA
			draw_line(p1, p2, color, 3)
	
	# Desenhar pontos (visíveis + hover)
	for i in range(points.size()):
		# Renderizar se é a unit, visível à unit OU em hover
		if i == unit_position or _is_point_visible_to_unit(i) or hovered_point == i:
			var color = Color.BLACK
			
			# Magenta se estiver em hover
			if hovered_point == i:
				color = Color.MAGENTA
			# Magenta se estiver conectado à unit e puder se mover
			elif _can_unit_move_to_point(i):
				color = Color.MAGENTA
			
			draw_circle(points[i], 8, color)
	
	# Atualizar posição da unidade
	_update_unit_position()

## Input handling para movimento da unidade e geração de terreno
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		# Verificar clique em pontos
		for i in range(points.size()):
			if mouse_pos.distance_to(points[i]) < 20:
				# Se clicou em ponto que a unit pode se mover, verificar ações
				if _can_unit_move_to_point(i):
					if unit_actions > 0:
						print("🚶🏻‍♀️ Movendo unit do ponto %d para ponto %d (Ações: %d → %d)" % [unit_position, i, unit_actions, unit_actions - 1])
						unit_position = i
						unit_actions -= 1
						_update_unit_position()
						_update_action_display()
						queue_redraw()
						get_viewport().set_input_as_handled()
						return
					else:
						print("❌ Sem ações restantes! Use 'Skip Turn' para restaurar.")
				else:
					print("❌ Unit não pode se mover para ponto %d" % i)
	
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Gerar terreno aleatório
			_generate_random_terrain()
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

## Verificar se ponto está conectado à unidade por uma aresta
func _is_connected_to_unit(point_index: int) -> bool:
	# Não destacar o próprio ponto da unidade
	if point_index == unit_position:
		return false
	
	# Verificar se existe aresta entre unit_position e point_index
	for edge in edges:
		if (edge[0] == unit_position and edge[1] == point_index) or \
		   (edge[1] == unit_position and edge[0] == point_index):
			return true
	
	return false

## Obter cor da aresta baseada no tipo
func _get_edge_color(edge_type: EdgeType) -> Color:
	match edge_type:
		EdgeType.GREEN:
			return Color.GREEN
		EdgeType.GREEN_GRAY:
			return Color(0.5, 0.7, 0.5)  # Verde acizentado
		EdgeType.YELLOW_GRAY:
			return Color(0.7, 0.7, 0.5)  # Amarelo acizentado
		EdgeType.CYAN_GRAY:
			return Color(0.5, 0.7, 0.7)  # Ciano acizentado
		_:
			return Color.BLACK

## Verificar se aresta é adjacente à unit
func _is_edge_adjacent_to_unit(edge: Dictionary) -> bool:
	# Aresta é adjacente se um dos pontos é a unit
	var edge_points = edge.points
	return edge_points[0] == unit_position or edge_points[1] == unit_position

## Verificar se ponto é visível à unit
func _is_point_visible_to_unit(point_index: int) -> bool:
	# Verificar se existe aresta que permite visibilidade
	for edge in edges:
		var edge_points = edge.points
		if (edge_points[0] == unit_position and edge_points[1] == point_index) or \
		   (edge_points[1] == unit_position and edge_points[0] == point_index):
			# Verde e Ciano permitem ver
			if edge.type == EdgeType.GREEN or edge.type == EdgeType.CYAN_GRAY:
				return true
	return false

## Verificar se unit pode se mover para o ponto
func _can_unit_move_to_point(point_index: int) -> bool:
	# Não pode mover para si mesmo
	if point_index == unit_position:
		return false
	
	# Verificar se existe aresta que permite movimento
	for edge in edges:
		var edge_points = edge.points
		if (edge_points[0] == unit_position and edge_points[1] == point_index) or \
		   (edge_points[1] == unit_position and edge_points[0] == point_index):
			# Verde e Verde acizentado permitem mover
			if edge.type == EdgeType.GREEN or edge.type == EdgeType.GREEN_GRAY:
				return true
	return false

## Gerar terreno aleatório
func _generate_random_terrain() -> void:
	print("🌍 Gerando terreno aleatório...")
	
	# Gerar tipo aleatório para cada aresta
	for i in range(edges.size()):
		var random_type = randi() % 4  # 0-3
		match random_type:
			0:
				edges[i].type = EdgeType.GREEN
			1:
				edges[i].type = EdgeType.GREEN_GRAY
			2:
				edges[i].type = EdgeType.YELLOW_GRAY
			3:
				edges[i].type = EdgeType.CYAN_GRAY
	
	print("✨ Terreno aleatório gerado! Pressione ESPAÇO novamente para regenerar.")

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
	action_label.text = "Ações: 1"
	action_label.position = Vector2(680, 70)
	action_label.add_theme_font_size_override("font_size", 16)
	add_child(action_label)

## Callback do botão Skip Turn
func _on_skip_turn_pressed() -> void:
	print("⏭️ Pulando turno - Ações restauradas!")
	unit_actions = 1
	_update_action_display()
	queue_redraw()

## Atualizar display de ações
func _update_action_display() -> void:
	if action_label:
		action_label.text = "Ações: %d" % unit_actions

## Atualizar posição da unit
func _update_unit_position():
	if unit_label:
		var unit_pos = points[unit_position]
		unit_label.position = unit_pos + Vector2(-12, -35)  # Centralizar emoji acima do ponto