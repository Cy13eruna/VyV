extends Node2D

# Pontos do hexágono equilátero (7 pontos: 6 vértices + 1 centro)
var points = [
	Vector2(400, 200),                    # 0: Centro
	Vector2(400, 50),                     # 1: Topo
	Vector2(530, 125),                    # 2: Topo direito
	Vector2(530, 275),                    # 3: Inferior direito
	Vector2(400, 350),                    # 4: Inferior
	Vector2(270, 275),                    # 5: Inferior esquerdo
	Vector2(270, 125)                     # 6: Topo esquerdo
]

# Arestas do hexágono equilátero (12 arestas: 6 perímetro + 6 radiais)
var edges = [
	# Perímetro do hexágono (6 arestas)
	[1, 2],  # Topo -> Topo direito
	[2, 3],  # Topo direito -> Inferior direito
	[3, 4],  # Inferior direito -> Inferior
	[4, 5],  # Inferior -> Inferior esquerdo
	[5, 6],  # Inferior esquerdo -> Topo esquerdo
	[6, 1],  # Topo esquerdo -> Topo
	# Arestas radiais do centro (6 arestas)
	[0, 1],  # Centro -> Topo
	[0, 2],  # Centro -> Topo direito
	[0, 3],  # Centro -> Inferior direito
	[0, 4],  # Centro -> Inferior
	[0, 5],  # Centro -> Inferior esquerdo
	[0, 6]   # Centro -> Topo esquerdo
]

# Estado do hover
var hovered_point = -1
var hovered_edge = -1

# Emoji da unidade
var unit_position = 0  # Índice do ponto onde está a unidade
var unit_label: Label

func _ready():
	print("Hexágono equilátero com 7 pontos e 12 arestas criado")
	
	# Criar label para o emoji
	unit_label = Label.new()
	unit_label.text = "🚶🏻‍♀️"
	unit_label.add_theme_font_size_override("font_size", 24)
	add_child(unit_label)
	
	# Posicionar label no ponto inicial
	_update_unit_position()

func _process(_delta):
	var mouse_pos = get_global_mouse_position()
	
	# Verificar hover em pontos
	hovered_point = -1
	for i in range(points.size()):
		if mouse_pos.distance_to(points[i]) < 20:
			hovered_point = i
			break
	
	# Verificar hover em arestas (só se não estiver em ponto)
	hovered_edge = -1
	if hovered_point == -1:
		for i in range(edges.size()):
			var edge = edges[i]
			var p1 = points[edge[0]]
			var p2 = points[edge[1]]
			if _point_near_line(mouse_pos, p1, p2, 10):
				hovered_edge = i
				break
	
	queue_redraw()

func _draw():
	# Fundo branco
	draw_rect(Rect2(0, 0, 800, 600), Color.WHITE)
	
	# Desenhar arestas
	for i in range(edges.size()):
		var edge = edges[i]
		var p1 = points[edge[0]]
		var p2 = points[edge[1]]
		var color = Color.MAGENTA if hovered_edge == i else Color.BLACK
		draw_line(p1, p2, color, 3)
	
	# Desenhar pontos
	for i in range(points.size()):
		var color = Color.BLACK
		
		# Magenta se estiver em hover
		if hovered_point == i:
			color = Color.MAGENTA
		# Magenta se estiver conectado ao emoji por uma aresta
		elif _is_connected_to_unit(i):
			color = Color.MAGENTA
		
		draw_circle(points[i], 8, color)
	
	# Atualizar posição da unidade
	_update_unit_position()

## Input handling para movimento da unidade
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		# Verificar clique em pontos
		for i in range(points.size()):
			if mouse_pos.distance_to(points[i]) < 20:
				# Se clicou em ponto conectado à unidade, mover unidade para lá
				if _is_connected_to_unit(i):
					print("🚶🏻‍♀️ Movendo unidade do ponto %d para ponto %d" % [unit_position, i])
					unit_position = i
					_update_unit_position()
					queue_redraw()
					get_viewport().set_input_as_handled()
					return
				else:
					print("❌ Ponto %d não está conectado à unidade" % i)

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

## Atualizar posição do emoji da unidade
func _update_unit_position():
	if unit_label:
		var unit_pos = points[unit_position]
		unit_label.position = unit_pos + Vector2(-12, -35)  # Centralizar emoji acima do ponto