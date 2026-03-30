# res://src/systems/entities/DomainManager.gd
extends Node2D

# Script carregado dinamicamente para evitar Parse Errors de dependência circular
var domain_script: GDScript = null

# Dados brutos para lógica (VisibilityManager / Save System)
var active_domains: Array = []
# Nós instanciados na árvore (Visual / MapEntity)
var domain_instances: Array = []

func _ready() -> void:
	add_to_group("domain_manager")
	# Carregamos o script via deferred para garantir que MapEntity já esteja registrada
	_load_resources.call_deferred()

func _load_resources() -> void:
	domain_script = load("res://src/systems/entities/Domain.gd")

## Limpa todos os domínios do mapa
func clear_domains() -> void:
	active_domains.clear()
	for inst in domain_instances:
		if is_instance_valid(inst):
			inst.queue_free()
	domain_instances.clear()

## Cria um novo domínio, tanto logicamente quanto visualmente
func create_domain(world_pos: Vector2, color: Color, owner_id: int = -1, tile_size: float = 64.0) -> void:
	# 1. Evita duplicatas por proximidade (precisão decimal)
	for d in active_domains:
		if d.pos.distance_to(world_pos) < 1.0: 
			return
			
	# 2. Adiciona à lista de dados brutos
	active_domains.append({
		"pos": world_pos,
		"color": color,
		"owner_id": owner_id
	})
	
	# 3. Instancia o objeto Domain (MapEntity)
	if not domain_script:
		domain_script = load("res://src/systems/entities/Domain.gd")

	var new_domain = Node2D.new()
	new_domain.set_script(domain_script)
	
	# Adiciona à árvore de cena antes do setup para o _ready disparar corretamente
	add_child(new_domain)
	
	# Configura a entidade usando o padrão MapEntity
	if new_domain.has_method("setup_domain"):
		# world_pos e grid_pos são o mesmo para domínios estáticos
		new_domain.setup_domain(world_pos, world_pos, color, owner_id, tile_size)
	
	domain_instances.append(new_domain)

## Lógica de spawn inicial baseada no número de jogadores
func spawn_domains(player_count: int, grid_mgr: Node2D, v_mgr: Node2D, turn_mgr: Node):
	clear_domains()
	
	if not grid_mgr or not grid_mgr.data: return
	
	# Captura o tile_size dinamicamente
	var t_size = grid_mgr.get("tile_size") if "tile_size" in grid_mgr else 64.0

	var nodes = grid_mgr.data.nodes.keys()
	nodes.shuffle()
	
	var spawned = 0
	for pos in nodes:
		if spawned >= player_count: break
		
		# Critério: Espaço aberto (6 vizinhos)
		if grid_mgr.data.nodes[pos].neighbors.size() == 6:
			if _is_space_free(pos):
				_create_capital(spawned, pos, grid_mgr, v_mgr, turn_mgr, t_size)
				spawned += 1

## Verifica se há espaço suficiente entre capitais
func _is_space_free(grid_pos: Vector2) -> bool:
	for domain in active_domains:
		if domain.pos.distance_to(grid_pos) < 200.0: 
			return false
	return true

## Helper para criar o domínio e a unidade inicial do jogador
func _create_capital(id: int, grid_pos: Vector2, grid: Node2D, v_mgr: Node2D, turn: Node, t_size: float):
	var color_options = turn.get("COLOR_OPTIONS")
	var player_colors = turn.get("player_colors")
	
	if not color_options or not player_colors: return
	
	var color_name = player_colors[id]
	var p_color = color_options[color_name]
	
	# Cria a entidade visual do Domínio
	create_domain(grid_pos, p_color, id, t_size)
	
	# Spawna o Vagabond (Unidade) na mesma posição
	if v_mgr and v_mgr.has_method("spawn_vagabond"):
		v_mgr.spawn_vagabond(grid_pos, id, p_color)