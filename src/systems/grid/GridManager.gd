# res://src/systems/grid/GridManager.gd
extends Node2D

# Módulos estáticos (Lógica pura)
const Interaction = preload("res://src/systems/grid/GridInteractions.gd")
const Mover = preload("res://src/systems/movement/UnitMover.gd")
# Carregamos como script para evitar erro de parse em chamadas estáticas
const PathfinderScript = preload("res://src/systems/movement/Pathfinder.gd") 

# Componentes
const GridDataScript = preload("res://src/systems/grid/GridData.gd")
const GridPainterScript = preload("res://src/systems/grid/GridPainter.gd")
const GridSelector = preload("res://src/systems/grid/GridSelector.gd")

var map_radius: int = 5 
var tile_size: float = 64.0

var data: GridDataScript = GridDataScript.new()
var painter: Node2D = null
var selector: GridSelector = GridSelector.new()

func _ready() -> void:
	painter = GridPainterScript.new()
	add_child(painter)

# --- FLUXO DE CONTROLE ---

## handle_click atualizado para aceitar a lista validada do Main.gd
func handle_click(click_pos: Vector2, active_units: Array, current_player_id: int, reachable_override: Array = []) -> void:
	var local_click = to_local(click_pos)

	# 1. Tentar mover: Se o Main passou um override, usamos ele. 
	# Caso contrário, usamos o que está no selector.
	if selector.unit:
		var valid_targets = reachable_override if reachable_override.size() > 0 else selector.reachable_nodes
		var target = Interaction.get_target_move(local_click, valid_targets)
		
		if target != Vector2.ZERO:
			_perform_move(target)
			return

	# 2. Tentar selecionar
	var clicked_unit = Interaction.get_unit_at_pos(click_pos, active_units)
	_update_selection(clicked_unit, current_player_id)

# --- OPERAÇÕES DE ESTADO ---

func _perform_move(target: Vector2) -> void:
	if selector.unit.has_method("use_ap"):
		selector.unit.use_ap()
	
	Mover.move_unit(selector.unit, target, self)
	_clear_selection()

func _update_selection(unit: Node2D, player_id: int) -> void:
	_clear_selection()
	
	if unit and int(unit.owner_id) == player_id:
		if unit.has_method("has_ap") and not unit.has_ap():
			return

		var terrain_mgr = painter.terrain_ref if painter else null
		
		# Chamada via referência de script para evitar o erro "Static function not found"
		var valid_nodes = PathfinderScript.get_reachable_cells(
			unit.grid_pos, 
			unit.ap if unit.has_method("get_ap") else 1, 
			data, 
			terrain_mgr
		)
		
		selector.select(unit, valid_nodes)
		
		var color_to_use = unit.get("vagabond_color") if "vagabond_color" in unit else Color.BLACK
		painter.update_reachable(selector.reachable_nodes, color_to_use)

func _clear_selection() -> void:
	selector.clear()
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