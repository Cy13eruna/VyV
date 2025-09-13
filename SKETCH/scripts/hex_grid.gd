extends Node2D
class_name HexGrid

@export var hex_size: float = 35.0
@export var grid_width: int = 25
@export var grid_height: int = 18
@export var hex_color: Color = Color.WHITE
@export var border_color: Color = Color.BLACK
@export var border_width: float = 2.0
@export var dot_radius: float = 6.0
@export var dot_color: Color = Color.WHITE
@export var dot_star_size: float = 3.0
@export var diamond_width: float = 35.0
@export var diamond_height: float = 60.0
@export var diamond_color: Color = Color.GREEN

var hex_positions: Array[Vector2] = []
var all_dots: Array[Vector2] = []  # Todas as bolinhas (vértices + centros)
var diamond_colors: Array[Color] = []  # Cores dos losangos

# Cache para otimização
var cached_connections: Array[Dictionary] = []  # Conexões pré-calculadas
var cached_diamonds: Array[PackedVector2Array] = []  # Geometria dos losangos
var cached_stars: Array[PackedVector2Array] = []  # Geometria das estrelas
var is_cache_built: bool = false

func _ready():
	generate_hex_grid()
	# Forçar reconstrução do cache após reversão da rotação
	is_cache_built = false
	build_cache()

func _draw():
	draw_hex_grid_optimized()

func generate_hex_grid():
	hex_positions.clear()
	all_dots.clear()
	diamond_colors.clear()
	
	# Definir cores dos losangos conforme proporções
	generate_diamond_colors()
	
	# Cálculos precisos para encaixe perfeito
	var hex_width = hex_size * sqrt(3.0)  # Largura real do hexágono flat-top
	var hex_height = hex_size * 2.0       # Altura real do hexágono
	var horizontal_spacing = hex_width     # Espaçamento horizontal sem gaps
	var vertical_spacing = hex_height * 0.75  # Espaçamento vertical para encaixe
	
	for row in range(grid_height):
		for col in range(grid_width):
			var x = col * horizontal_spacing
			var y = row * vertical_spacing
			
			# Offset para linhas ímpares (encaixe perfeito)
			if row % 2 == 1:
				x += horizontal_spacing * 0.5
			
			# Ajustar posição para preencher tela desde a esquerda
			x -= 50  # Mover para a esquerda
			
			var center = Vector2(x, y)
			hex_positions.append(center)
			
			# Adicionar centro à lista de pontos
			all_dots.append(center)
			
			# Adicionar vértices à lista de pontos
			for i in range(6):
				var angle = deg_to_rad(60 * i - 30)
				var vertex_pos = center + Vector2(cos(angle), sin(angle)) * hex_size
				all_dots.append(vertex_pos)

func draw_hex_grid_optimized():
	# Desenhar losangos usando cache
	for i in range(cached_connections.size()):
		var connection = cached_connections[i]
		var diamond_geometry = cached_diamonds[i]
		var color = connection["color"]
		draw_colored_polygon(diamond_geometry, color)
	
	# Desenhar estrelas usando cache
	for i in range(cached_stars.size()):
		var star_geometry = cached_stars[i]
		draw_colored_polygon(star_geometry, dot_color)

func draw_hexagon(center: Vector2, size: float, fill_color: Color, stroke_color: Color, stroke_width: float):
	var points: PackedVector2Array = []
	
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		var point = center + Vector2(cos(angle), sin(angle)) * size
		points.append(point)
	
	if fill_color.a > 0:
		draw_colored_polygon(points, fill_color)
	
	if stroke_width > 0 and stroke_color.a > 0:
		for i in range(6):
			var start = points[i]
			var end = points[(i + 1) % 6]
			draw_line(start, end, stroke_color, stroke_width)

func draw_hex_vertices(center: Vector2, size: float):
	# Desenha bolinhas nos 6 vértices do hexágono
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		var vertex_pos = center + Vector2(cos(angle), sin(angle)) * size
		draw_circle(vertex_pos, dot_radius, dot_color)

func draw_connections():
	# Conecta cada ponto aos seus 6 vizinhos mais próximos com losangos
	var connection_distance = hex_size * 1.1  # Distância máxima para conexão
	var drawn_connections = {}  # Para evitar desenhar a mesma conexão duas vezes
	var color_index = 0
	
	for i in range(all_dots.size()):
		var dot_a = all_dots[i]
		var connections_made = 0
		
		for j in range(all_dots.size()):
			if i == j or connections_made >= 6:
				continue
				
			var dot_b = all_dots[j]
			var distance = dot_a.distance_to(dot_b)
			
			# Conectar se estiver dentro da distância e não passou de 6 conexões
			if distance <= connection_distance:
				# Criar chave única para evitar duplicação
				var connection_key = str(min(i, j)) + "-" + str(max(i, j))
				if not drawn_connections.has(connection_key):
					var diamond_color_to_use = diamond_colors[color_index % diamond_colors.size()]
					draw_diamond_connection(dot_a, dot_b, diamond_color_to_use)
					drawn_connections[connection_key] = true
					color_index += 1
					connections_made += 1

func draw_diamond_connection(point_a: Vector2, point_b: Vector2, color: Color = Color.GREEN):
	# Desenha um losango alinhado à linha entre dois pontos
	var direction = (point_b - point_a).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	var distance = point_a.distance_to(point_b)
	
	# Vértices agudos (pontas) tocam os pontos
	var tip_a = point_a  # Ponta aguda A
	var tip_b = point_b  # Ponta aguda B
	
	# Vértices obtusos calculados para encaixe perfeito
	# Usar distância entre pontos para calcular largura ideal
	var optimal_width = distance * 0.6  # 60% da distância para encaixe
	var half_width = optimal_width / 2.0
	
	# Centro do losango
	var center = (point_a + point_b) / 2.0
	
	# Vértices obtusos posicionados para encontrar outros losangos
	var side_left = center + perpendicular * half_width
	var side_right = center - perpendicular * half_width
	
	# Criar array de pontos do losango
	var diamond_points = PackedVector2Array([tip_a, side_left, tip_b, side_right])
	
	# Desenhar o losango preenchido
	draw_colored_polygon(diamond_points, color)

func generate_diamond_colors():
	# Gerar cores conforme proporções especificadas
	var total_diamonds = grid_width * grid_height * 7  # Estimativa de losangos
	
	# Cores definidas
	var color_00FF00 = Color(0.0, 1.0, 0.0, 1.0)  # Verde claro - 1/3
	var color_007E00 = Color(0.0, 0.494, 0.0, 1.0)  # Verde escuro - 1/6
	var color_00FFFF = Color(0.0, 1.0, 1.0, 1.0)  # Ciano - 1/6
	var color_666666 = Color(0.4, 0.4, 0.4, 1.0)  # Cinza - 1/6
	
	# Calcular quantidades
	var count_00FF00 = int(total_diamonds / 3.0)  # 1/3
	var count_007E00 = int(total_diamonds / 6.0)  # 1/6
	var count_00FFFF = int(total_diamonds / 6.0)  # 1/6
	var count_666666 = int(total_diamonds / 6.0)  # 1/6
	
	# Preencher array com as cores
	for i in range(count_00FF00):
		diamond_colors.append(color_00FF00)
	for i in range(count_007E00):
		diamond_colors.append(color_007E00)
	for i in range(count_00FFFF):
		diamond_colors.append(color_00FFFF)
	for i in range(count_666666):
		diamond_colors.append(color_666666)
	
	# Embaralhar para distribuição aleatória
	diamond_colors.shuffle()

func draw_six_pointed_star(center: Vector2, outer_radius: float, inner_radius: float, color: Color):
	# Desenha uma estrela de 6 pontas
	var points: PackedVector2Array = []
	
	for i in range(12):  # 6 pontas externas + 6 pontas internas
		var angle = deg_to_rad(30 * i)  # 30 graus entre cada ponto
		var radius = outer_radius if i % 2 == 0 else inner_radius
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	# Desenhar a estrela preenchida
	draw_colored_polygon(points, color)

func build_cache():
	# Construir cache de conexões e geometria (executa apenas uma vez)
	if is_cache_built:
		return
	
	cached_connections.clear()
	cached_diamonds.clear()
	cached_stars.clear()
	
	# Pré-calcular conexões (otimizado)
	var connection_distance = hex_size * 1.1
	var drawn_connections = {}  # Hash para evitar duplicação
	var color_index = 0
	
	# Usar spatial hash para otimizar busca de vizinhos
	var spatial_grid = build_spatial_grid()
	
	for i in range(all_dots.size()):
		var dot_a = all_dots[i]
		var nearby_dots = get_nearby_dots(dot_a, spatial_grid, connection_distance)
		
		for j in nearby_dots:
			if i >= j:  # Evitar duplicação
				continue
				
			var dot_b = all_dots[j]
			var distance = dot_a.distance_to(dot_b)
			
			if distance <= connection_distance:
				# Armazenar conexão
				var diamond_color_to_use = diamond_colors[color_index % diamond_colors.size()]
				cached_connections.append({
					"point_a": dot_a,
					"point_b": dot_b,
					"color": diamond_color_to_use
				})
				
				# Pré-calcular geometria do losango
				var diamond_geometry = calculate_diamond_geometry(dot_a, dot_b)
				cached_diamonds.append(diamond_geometry)
				
				color_index += 1
	
	# Pré-calcular geometria das estrelas
	for dot_pos in all_dots:
		var star_geometry = calculate_star_geometry(dot_pos, dot_radius, dot_star_size)
		cached_stars.append(star_geometry)
	
	is_cache_built = true

func build_spatial_grid() -> Dictionary:
	# Criar grid espacial para busca rápida de vizinhos
	var grid = {}
	var cell_size = hex_size * 2.0
	
	for i in range(all_dots.size()):
		var dot = all_dots[i]
		var cell_x = int(dot.x / cell_size)
		var cell_y = int(dot.y / cell_size)
		var cell_key = str(cell_x) + "," + str(cell_y)
		
		if not grid.has(cell_key):
			grid[cell_key] = []
		grid[cell_key].append(i)
	
	return grid

func get_nearby_dots(position: Vector2, spatial_grid: Dictionary, max_distance: float) -> Array[int]:
	# Buscar pontos próximos usando spatial grid
	var nearby: Array[int] = []
	var cell_size = hex_size * 2.0
	var search_radius = int(max_distance / cell_size) + 1
	
	var center_x = int(position.x / cell_size)
	var center_y = int(position.y / cell_size)
	
	for dx in range(-search_radius, search_radius + 1):
		for dy in range(-search_radius, search_radius + 1):
			var cell_key = str(center_x + dx) + "," + str(center_y + dy)
			if spatial_grid.has(cell_key):
				for index in spatial_grid[cell_key]:
					nearby.append(index)
	
	return nearby

func calculate_diamond_geometry(point_a: Vector2, point_b: Vector2) -> PackedVector2Array:
	# Calcular geometria do losango SEM rotação (revertido)
	var direction = (point_b - point_a).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	var distance = point_a.distance_to(point_b)
	
	# Vértices agudos (pontas) tocam os pontos
	var tip_a = point_a  # Ponta aguda A
	var tip_b = point_b  # Ponta aguda B
	
	# Vértices obtusos calculados para encaixe perfeito
	var optimal_width = distance * 0.6  # 60% da distância para encaixe
	var half_width = optimal_width / 2.0
	
	# Centro do losango
	var center = (point_a + point_b) / 2.0
	
	# Vértices obtusos posicionados normalmente (SEM rotação)
	var side_left = center + perpendicular * half_width
	var side_right = center - perpendicular * half_width
	
	return PackedVector2Array([tip_a, side_left, tip_b, side_right])

func calculate_star_geometry(center: Vector2, outer_radius: float, inner_radius: float) -> PackedVector2Array:
	# Calcular geometria da estrela (mesma lógica, mas retorna array)
	var points: PackedVector2Array = []
	
	for i in range(12):
		var angle = deg_to_rad(30 * i)
		var radius = outer_radius if i % 2 == 0 else inner_radius
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	return points

# Função de rotação removida - não é mais necessária após reversão