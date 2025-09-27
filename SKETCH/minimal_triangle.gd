extends Node2D

# Pontos do triângulo equilátero
var points = [
	Vector2(400, 200),                    # Topo
	Vector2(400 - 86.6, 200 + 150),      # Inferior esquerdo
	Vector2(400 + 86.6, 200 + 150)       # Inferior direito
]

# Arestas (índices dos pontos)
var edges = [
	[0, 1],  # Topo -> Inferior esquerdo
	[1, 2],  # Inferior esquerdo -> Inferior direito
	[2, 0]   # Inferior direito -> Topo
]

# Estado do hover
var hovered_point = -1
var hovered_edge = -1

func _ready():
	print("Triângulo minimalista criado")

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
		var color = Color.MAGENTA if hovered_point == i else Color.BLACK
		draw_circle(points[i], 8, color)

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