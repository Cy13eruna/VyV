# res://src/systems/grid/GridManager.gd
extends Node2D

const HexMath = preload("res://src/core/math/HexMath.gd")
const GridDataScript = preload("res://src/systems/grid/GridData.gd")
const GridPainterScript = preload("res://src/systems/grid/GridPainter.gd")

var map_radius: int = 5 
var tile_size: float = 64.0

var data = null
var painter = null

# Variáveis de Estado de Jogo
var selected_vagabond = null
var current_reachable: Array = []

func _ready() -> void:
	data = GridDataScript.new()
	painter = GridPainterScript.new()
	add_child(painter)
	position = Vector2.ZERO

# --- SISTEMA DE CLIQUE E MOVIMENTAÇÃO ---

func handle_click(click_pos: Vector2, vagabond_manager: Node2D) -> void:
	var turn_manager = get_tree().current_scene.get_node_or_null("TurnManager")
	if not turn_manager:
		turn_manager = get_node_or_null("../../TurnManager")
	
	if not turn_manager: return

	var local_click = to_local(click_pos)
	print("\n[GridManager] Clique processado em Global: ", click_pos)

	# --- 1. PRIORIDADE MÁXIMA: MOVIMENTAÇÃO ---
	# Se já temos alguém selecionado, checamos primeiro se o clique foi em um destino.
	if selected_vagabond:
		var target_node = Vector2.ZERO
		var min_dist = 60.0 # Tolerância para os nós de destino
		
		for node_pos in current_reachable:
			var d = node_pos.distance_to(local_click)
			if d < min_dist:
				min_dist = d
				target_node = node_pos
		
		if target_node != Vector2.ZERO:
			print("Ação: Movendo P", selected_vagabond.owner_id, " para ", target_node)
			_move_selected_to(target_node)
			return # Sai da função, movimento realizado com sucesso!

	# --- 2. SEGUNDA PRIORIDADE: SELEÇÃO DE UNIDADE ---
	var found_v = null
	if vagabond_manager:
		for v in vagabond_manager.active_vagabonds:
			if not is_instance_valid(v): continue
			
			# Reduzimos o raio de clique da unidade (de 75 para 45) 
			# para não sobrepor os nós de movimento ao redor dela.
			var dist = v.global_position.distance_to(click_pos)
			if dist < 45.0: 
				found_v = v
				break
	
	if found_v:
		var turn_idx = turn_manager.current_player_index
		if int(found_v.owner_id) == int(turn_idx):
			# Se clicamos no que já está selecionado, não fazemos nada (evita flicker)
			if selected_vagabond == found_v:
				print("Aviso: P", found_v.owner_id, " já está selecionado.")
				return
				
			print("Sucesso: Selecionado P", found_v.owner_id)
			_select_vagabond(found_v)
			return 
		else:
			print("Aviso: Unidade de outro jogador (P", found_v.owner_id, ")")
			_deselect_all()
			return

	# --- 3. CLIQUE NO VAZIO ---
	print("Resultado: Clique fora de alcance. Desmarcando.")
	_deselect_all()

func _select_vagabond(vagabond) -> void:
	_deselect_all()
	selected_vagabond = vagabond
	
	if vagabond.has_method("set_highlight"):
		vagabond.set_highlight(true)
		
	if data.has_method("get_neighbors"):
		current_reachable = data.get_neighbors(vagabond.grid_pos)
		print("[GridManager] Nós alcançáveis: ", current_reachable.size())
	
	if painter:
		painter.update_reachable(current_reachable)

func _move_selected_to(target_grid_pos: Vector2) -> void:
	if not selected_vagabond: return
	
	var unit = selected_vagabond
	unit.grid_pos = target_grid_pos
	
	var target_global = to_global(target_grid_pos)
	var target_local = unit.get_parent().to_local(target_global)
	
	if unit.has_method("set_highlight"):
		unit.set_highlight(false)
		
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(unit, "position", target_local, 0.3)
	
	# Limpa estado para o próximo movimento ou seleção
	selected_vagabond = null
	current_reachable = []
	if painter: painter.update_reachable([])

func _deselect_all() -> void:
	if is_instance_valid(selected_vagabond) and selected_vagabond.has_method("set_highlight"):
		selected_vagabond.set_highlight(false)
		
	selected_vagabond = null
	current_reachable = []
	if painter: 
		painter.update_reachable([])

# --- MÉTODOS DE UTILITÁRIO MANTIDOS ---
func setup_map(new_radius: int) -> void:
	self.map_radius = new_radius
	generate_hexagonal_map()
	if painter:
		painter.setup(data, tile_size)
		painter.queue_redraw()

func world_to_grid(p_world_pos: Vector2) -> Vector2:
	var local_p = to_local(p_world_pos)
	if data == null or data.nodes == null or data.nodes.is_empty():
		return Vector2.ZERO
	var closest = data.get_closest_node(local_p, tile_size * 4.0)
	return closest if closest != null else Vector2.ZERO

func grid_to_world(p_grid_pos: Vector2) -> Vector2:
	return to_global(p_grid_pos)

func generate_hexagonal_map() -> void:
	data.clear()
	var r_pixel = (map_radius * tile_size * 0.5)
	var search_range = map_radius * 2
	for y in range(-search_range, search_range + 1):
		for x in range(-search_range * 2, search_range * 2 + 1):
			var coords = Vector2i(x, y)
			var points = HexMath.get_triangle_points(coords, tile_size)
			for p in points:
				if is_point_in_hexagon(p, r_pixel):
					data.add_node(p)
	
	for y in range(-search_range, search_range + 1):
		for x in range(-search_range * 2, search_range * 2 + 1):
			var coords = Vector2i(x, y)
			var points = HexMath.get_triangle_points(coords, tile_size)
			_try_connect(points[0], points[1])
			_try_connect(points[1], points[2])
			_try_connect(points[2], points[0])
	print("[GridManager] Mapa gerado com ", data.nodes.size(), " nós.")

func is_point_in_hexagon(p: Vector2, radius: float) -> bool:
	var h_limit = radius * 0.866025
	var d_v = abs(p.y)
	var d_d1 = abs(p.x * 0.866025 + p.y * 0.5)
	var d_d2 = abs(p.x * 0.866025 - p.y * 0.5)
	return d_v <= h_limit + 1.0 and d_d1 <= h_limit + 1.0 and d_d2 <= h_limit + 1.0

func _try_connect(p1: Vector2, p2: Vector2) -> void:
	var a = p1.snapped(Vector2(0.1, 0.1))
	var b = p2.snapped(Vector2(0.1, 0.1))
	if data.nodes.has(a) and data.nodes.has(b):
		data.add_edge(a, b)