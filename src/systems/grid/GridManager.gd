# res://src/systems/grid/GridManager.gd
extends Node2D

# Módulos estáticos (Lógica pura)
const Interaction = preload("res://src/systems/grid/GridInteractions.gd")
const Mover = preload("res://src/systems/grid/UnitMover.gd")

# Componentes de Dados, Visual e Estado
const GridDataScript = preload("res://src/systems/grid/GridData.gd")
const GridPainterScript = preload("res://src/systems/grid/GridPainter.gd")
const GridSelector = preload("res://src/systems/grid/GridSelector.gd")

# Propriedades de configuração
var map_radius: int = 5 
var tile_size: float = 64.0

# Instâncias de componentes
var data: GridDataScript = GridDataScript.new()
var painter: Node2D = null
var selector: GridSelector = GridSelector.new()

func _ready() -> void:
	# Inicializa o pintor
	painter = GridPainterScript.new()
	add_child(painter)
	position = Vector2.ZERO

# --- FLUXO DE CONTROLE (ORQUESTRAÇÃO) ---

func handle_click(click_pos: Vector2, active_units: Array, current_player_id: int) -> void:
	var local_click = to_local(click_pos)

	# 1. Prioridade: Tentar mover (Se houver unidade ativa no selector)
	if selector.unit:
		var target = Interaction.get_target_move(local_click, selector.reachable_nodes)
		if target != Vector2.ZERO:
			_perform_move(target)
			return

	# 2. Segunda Prioridade: Tentar selecionar unidade
	var clicked_unit = Interaction.get_unit_at_pos(click_pos, active_units)
	_update_selection(clicked_unit, current_player_id)

# --- OPERAÇÕES DE ESTADO ---

func _perform_move(target: Vector2) -> void:
	# O Mover cuida da animação e atualização de grid_pos
	Mover.move_unit(selector.unit, target, self)
	_clear_selection()

func _update_selection(unit: Node2D, player_id: int) -> void:
	_clear_selection()
	
	# Regra de Negócio: Só seleciona se pertencer ao jogador do turno
	if unit and int(unit.owner_id) == player_id:
		# O Selector gerencia o estado e o highlight visual da unidade
		var neighbors = data.get_neighbors(unit.grid_pos)
		selector.select(unit, neighbors)
		
		# O Painter gerencia os indicadores de movimento no chão
		painter.update_reachable(selector.reachable_nodes)
	else:
		# Clique no vazio ou unidade inimiga desmarca tudo
		print("GridManager: Seleção limpa ou unidade inválida.")

func _clear_selection() -> void:
	selector.clear()
	if painter:
		painter.update_reachable([])

# Alias para compatibilidade com chamadas externas (como main.gd)
func _deselect_all() -> void:
	_clear_selection()

# --- SETUP E UTILITÁRIOS ---

func setup_map(p_radius: int) -> void:
	self.map_radius = p_radius
	# Delega a geração matemática para o GridData
	data.generate_hex_grid(map_radius, tile_size)
	
	if painter:
		painter.setup(data, tile_size)
		painter.queue_redraw()
	
	print("[GridManager] Malha hex gerada. Nós: ", data.nodes.size())

func world_to_grid(p_world_pos: Vector2) -> Vector2:
	var local_p = to_local(p_world_pos)
	# Busca o nó mais próximo no banco de dados
	return data.get_closest_node(local_p, tile_size * 4.0)

func grid_to_world(p_grid_pos: Vector2) -> Vector2:
	return to_global(p_grid_pos)