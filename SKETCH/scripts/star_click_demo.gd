## Demo de Click em Estrelas - Refatorado com Classes
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

func _ready() -> void:
	print("StarClickDemo: Inicializando sistema refatorado...")
	
	# Inicializar componentes
	star_mapper = StarMapper.new()
	game_manager = GameManager.new()
	
	if hex_grid.is_initialized:
		_setup_system()
	else:
		hex_grid.grid_initialized.connect(_setup_system)
	
	set_process_unhandled_input(true)

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
	
	print("StarClickDemo: Sistema refatorado pronto!")
	print("  - Botão esquerdo: mover/posicionar unidade")
	print("  - Botão direito: criar domínio")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				_handle_star_click(mouse_event.global_position)
			elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
				_handle_domain_creation(mouse_event.global_position)

func _handle_star_click(global_pos: Vector2) -> void:
	var star_id = _get_star_id_from_mouse_position(global_pos)
	
	if star_id >= 0:
		print("✅ Estrela clicada: ID %d" % star_id)
		_handle_unit_action(star_id)
	else:
		print("❌ Clique fora das estrelas")

# Função removida - agora gerenciada pela classe Unit

func _handle_unit_action(star_id: int) -> void:
	# Se não há unidade, criar uma
	if not current_unit:
		current_unit = game_manager.create_unit(star_id)
		_update_adjacent_stars_display()
		return
	
	# Se unidade não está posicionada, posicionar
	if not current_unit.is_positioned():
		game_manager.position_unit_at_star(current_unit, star_id)
		_update_adjacent_stars_display()
		return
	
	# Verificar se é movimento válido
	var valid_stars = game_manager.get_valid_adjacent_stars(current_unit)
	if star_id in valid_stars:
		# Resetar ações antes do movimento para permitir movimento contínuo
		current_unit.reset_actions()
		game_manager.move_unit_to_star(current_unit, star_id)
		_update_adjacent_stars_display()
	else:
		print("❌ Movimento inválido! Clique apenas nas estrelas magenta")

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

func _handle_domain_creation(global_pos: Vector2) -> void:
	var star_id = _get_star_id_from_mouse_position(global_pos)
	
	if star_id >= 0:
		print("🏠 Criando domínio na estrela %d" % star_id)
		game_manager.create_domain(star_id)
	else:
		print("❌ Clique direito fora das estrelas")

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