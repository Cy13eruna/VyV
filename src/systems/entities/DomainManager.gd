# res://src/systems/entities/DomainManager.gd
extends Node2D

# Script carregado dinamicamente para evitar Parse Errors de dependência circular
var domain_script: GDScript = null

# Dados estruturados para lógica rápida { pos_string: {data} }
var active_domains: Dictionary = {}
# Nós instanciados na árvore (Visual / MapEntity)
var domain_instances: Array = []

func _ready() -> void:
	add_to_group("domain_manager")
	_load_resources.call_deferred()

func _load_resources() -> void:
	domain_script = load("res://src/systems/entities/Domain.gd")

## --- API DE CONSULTA PARA O PATHFINDER ---

## Retorna um array com as posições (Vector2) de todos os domínios de um jogador específico.
## Otimizado para garantir que o Pathfinder receba coordenadas idênticas às do grid.
func get_domain_positions_for_player(player_id: int) -> Array:
	var positions: Array = []
	for pos_key in active_domains:
		var domain = active_domains[pos_key]
		if domain.owner_id == player_id:
			# Retornamos o Vector2 original que foi snappado no registro
			positions.append(domain.pos)
	return positions

## --- GESTÃO DE DOMÍNIOS ---

func clear_domains() -> void:
	active_domains.clear()
	for inst in domain_instances:
		if is_instance_valid(inst):
			inst.queue_free()
	domain_instances.clear()

func create_domain(world_pos: Vector2, color: Color, owner_id: int = -1, tile_size: float = 64.0) -> void:
	# O SNAP 0.1 é a nossa "âncora" de precisão em todo o projeto
	var clean_pos = world_pos.snapped(Vector2(0.1, 0.1))
	var pos_key = str(clean_pos)
	
	# 1. Evita duplicatas ou sobreposição de donos no mesmo tile
	if active_domains.has(pos_key):
		return
			
	# 2. Adiciona ao dicionário de lógica (O(1) para buscas futuras)
	active_domains[pos_key] = {
		"pos": clean_pos,
		"color": color,
		"owner_id": owner_id
	}
	
	# 3. Instancia o objeto visual
	if not domain_script:
		domain_script = load("res://src/systems/entities/Domain.gd")

	var new_domain = Node2D.new()
	new_domain.set_script(domain_script)
	# Definimos o nome para facilitar debug no Scene Tree
	new_domain.name = "Domain_" + pos_key.replace(".", "_")
	add_child(new_domain)
	
	if new_domain.has_method("setup_domain"):
		# Passamos clean_pos para ambos os argumentos para manter consistência
		new_domain.setup_domain(clean_pos, clean_pos, color, owner_id, tile_size)
	
	domain_instances.append(new_domain)

## --- LÓGICA DE SPAWN ---

func spawn_domains(player_count: int, grid_mgr: Node2D, v_mgr: Node2D, turn_mgr: Node):
	clear_domains()
	if not grid_mgr or not grid_mgr.data: return
	
	var t_size = grid_mgr.get("tile_size") if "tile_size" in grid_mgr else 64.0
	var nodes = grid_mgr.data.nodes.keys()
	nodes.shuffle()
	
	var spawned = 0
	for pos in nodes:
		if spawned >= player_count: break
		
		# Critério: Espaço aberto (6 vizinhos) para Capitais
		if grid_mgr.data.nodes[pos].neighbors.size() == 6:
			if _is_space_free(pos):
				_create_capital(spawned, pos, grid_mgr, v_mgr, turn_mgr, t_size)
				spawned += 1

func _is_space_free(grid_pos: Vector2) -> bool:
	# Distância mínima entre capitais iniciais para não encavalarem
	var min_dist = 200.0 
	for pos_key in active_domains:
		var d = active_domains[pos_key]
		if d.pos.distance_to(grid_pos) < min_dist: 
			return false
	return true

func _create_capital(id: int, grid_pos: Vector2, grid: Node2D, v_mgr: Node2D, turn: Node, t_size: float):
	# Verificação defensiva de propriedades do TurnManager
	if not turn: return
	var color_options = turn.get("COLOR_OPTIONS")
	var player_colors = turn.get("player_colors")
	
	if color_options == null or player_colors == null or id >= player_colors.size():
		push_error("DomainManager: Erro ao acessar cores do TurnManager para o player ", id)
		return
	
	var color_name = player_colors[id]
	var p_color = color_options[color_name]
	
	# Criamos o dado lógico e visual
	create_domain(grid_pos, p_color, id, t_size)
	
	# Spawna a unidade inicial na posição da capital
	if v_mgr and v_mgr.has_method("spawn_vagabond"):
		v_mgr.spawn_vagabond(grid_pos, id, p_color)