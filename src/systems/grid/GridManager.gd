# res://src/systems/grid/GridManager.gd
extends Node2D

# Módulos estáticos
const Interaction = preload("res://src/systems/grid/GridInteractions.gd")
const Mover = preload("res://src/systems/movement/UnitMover.gd")
const PathfinderScript = preload("res://src/systems/movement/Pathfinder.gd") 

# Componentes
const GridDataScript = preload("res://src/systems/grid/GridData.gd")
const GridPainterScript = preload("res://src/systems/grid/GridPainter.gd")

var map_radius: int = 5 
var tile_size: float = 64.0

var data: GridDataScript = GridDataScript.new()
var painter: Node2D = null

# Estado de Seleção Local (Substituindo o GridSelector)
var selected_unit: Node2D = null
var reachable_nodes: Array = []

func _ready() -> void:
	painter = GridPainterScript.new()
	add_child(painter)

# --- FLUXO DE CONTROLE ---

func handle_click(click_pos: Vector2, active_units: Array, current_player_id: int, reachable_override: Array = []) -> void:
	var local_click = to_local(click_pos)

	# 1. Tentar mover: Se houver unidade selecionada
	if selected_unit:
		var valid_targets = reachable_override if reachable_override.size() > 0 else reachable_nodes
		var target = Interaction.get_target_move(local_click, valid_targets)
		
		if target != Vector2.ZERO:
			_perform_move(target)
			return

	# 2. Tentar selecionar
	var clicked_unit = Interaction.get_unit_at_pos(click_pos, active_units)
	_update_selection(clicked_unit, current_player_id)

# --- OPERAÇÕES DE ESTADO ---

func _perform_move(target: Vector2) -> void:
	if selected_unit.has_method("use_ap"):
		selected_unit.use_ap()
	
	Mover.move_unit(selected_unit, target, self)
	_clear_selection()

func _update_selection(unit: Node2D, player_id: int) -> void:
	# Limpa seleção anterior (incluindo o highlight visual da unidade antiga)
	_clear_selection()
	
	# Valida unidade: existe, é do jogador e TEM AP
	if unit and int(unit.get("owner_id")) == player_id:
		if unit.has_method("has_ap") and not unit.has_ap():
			return # Unidade exaurida não é selecionada nem ganha destaque

		# Se chegou aqui, a unidade é válida para seleção
		selected_unit = unit
		
		# Ativa o destaque visual na unidade
		if selected_unit.has_method("set_highlight"):
			selected_unit.set_highlight(true)

		var terrain_mgr = painter.terrain_ref if painter else null
		var current_ap = selected_unit.ap if "ap" in selected_unit else 1
		
		reachable_nodes = PathfinderScript.get_reachable_cells(
			selected_unit.grid_pos, 
			current_ap, 
			data, 
			terrain_mgr
		)
		
		# Atualiza os indicadores de movimento no chão
		var color_to_use = selected_unit.get("vagabond_color") if "vagabond_color" in selected_unit else Color.BLACK
		if painter:
			painter.update_reachable(reachable_nodes, color_to_use)

func _clear_selection() -> void:
	# Desativa o destaque visual da unidade atual antes de limpar a referência
	if selected_unit and selected_unit.has_method("set_highlight"):
		selected_unit.set_highlight(false)
	
	selected_unit = null
	reachable_nodes = []
	
	if painter:
		painter.update_reachable([], Color.BLACK)

func _deselect_all() -> void:
	_clear_selection()

# --- SETUP E UTILITÁRIOS ---

func setup_map(p_radius: int) -> void:
	self.map_radius = p_radius
	data.generate_hex_grid(map_radius, tile_size)
	if painter:
		painter.setup(data, tile_size)
	print("[GridManager] Malha hex gerada. Nós: ", data.nodes.size())

func world_to_grid(p_world_pos: Vector2) -> Vector2:
	return data.get_closest_node(to_local(p_world_pos), tile_size * 4.0)

func grid_to_world(p_grid_pos: Vector2) -> Vector2:
	return to_global(p_grid_pos)