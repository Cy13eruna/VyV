## Demo de Click em Estrelas
extends Node2D

const StarMapper = preload("res://scripts/star_mapper.gd")

@onready var hex_grid = $HexGrid
var star_mapper = null
var unit_emoji: Label = null
var adjacent_stars: Array[int] = []  # IDs das estrelas adjacentes
var magenta_stars: Array[Node2D] = []  # Estrelas magenta customizadas

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
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_star_click(mouse_event.global_position)

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
			_position_unit_on_star(star_pos)
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

func _position_unit_on_star(star_position: Vector2) -> void:
	if not unit_emoji:
		return
	
	# Converter posição da estrela (local do HexGrid) para posição global
	var global_star_pos = hex_grid.to_global(star_position)
	
	# Posicionar o emoji na posição global da estrela
	unit_emoji.global_position = global_star_pos
	# Centralizar o emoji na estrela (ajustar offset para tamanho menor)
	unit_emoji.global_position.x -= 9   # Metade da largura aproximada do emoji menor
	unit_emoji.global_position.y -= 9   # Metade da altura aproximada do emoji menor
	unit_emoji.visible = true
	
	# Destacar estrelas adjacentes em magenta
	_highlight_adjacent_stars(star_position)
	
	print("🚶🏻‍♀️ Unidade posicionada em %s (global: %s)" % [star_position, global_star_pos])

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
			adjacent_stars.append(i)
	
	# Mudar cor das estrelas para magenta
	_set_stars_color_magenta()
	
	print("🔮 %d estrelas adjacentes em magenta" % adjacent_stars.size())

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