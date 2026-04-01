# res://src/systems/entities/DomainManager.gd
extends Node2D

var domain_script: GDScript = null
var active_domains: Dictionary = {}
var domain_instances: Array = []

func _ready() -> void:
	add_to_group("domain_manager")
	_load_resources.call_deferred()

func _load_resources() -> void:
	domain_script = load("res://src/systems/entities/Domain.gd")

## --- API DE CONSULTA ---

func get_domain_positions_for_player(player_id: int) -> Array:
	var positions: Array = []
	for pos_key in active_domains:
		var domain = active_domains[pos_key]
		if domain.owner_id == player_id:
			positions.append(domain.pos)
	return positions

## Retorna a instância (Node) de um domínio em uma posição específica
func get_domain_at(world_pos: Vector2) -> Node2D:
	var clean_pos = world_pos.snapped(Vector2(0.1, 0.1))
	for inst in domain_instances:
		if is_instance_valid(inst) and inst.get("grid_pos").distance_to(clean_pos) < 1.0:
			return inst
	return null

## --- GESTÃO DE DOMÍNIOS ---

func clear_domains() -> void:
	active_domains.clear()
	for inst in domain_instances:
		if is_instance_valid(inst):
			inst.queue_free()
	domain_instances.clear()

## ATUALIZADO: Agora retorna a instância Node2D criada para que outros managers 
## possam acessar propriedades como o 'domain_name'.
func create_domain(world_pos: Vector2, color: Color, owner_id: int = -1, tile_size: float = 64.0) -> Node2D:
	var clean_pos = world_pos.snapped(Vector2(0.1, 0.1))
	var pos_key = str(clean_pos)
	
	if active_domains.has(pos_key):
		# Se já existe, tentamos retornar a instância existente
		return get_domain_at(clean_pos)
			
	active_domains[pos_key] = {
		"pos": clean_pos,
		"color": color,
		"owner_id": owner_id
	}
	
	if not domain_script:
		domain_script = load("res://src/systems/entities/Domain.gd")

	var new_domain = Node2D.new()
	new_domain.set_script(domain_script)
	
	# Adicionamos à árvore ANTES do setup para garantir que o _ready (e o nome) ocorra
	add_child(new_domain)
	
	if new_domain.has_method("setup_domain"):
		new_domain.setup_domain(clean_pos, clean_pos, color, owner_id, tile_size)
	
	new_domain.name = "Domain_" + pos_key.replace(".", "_")
	domain_instances.append(new_domain)
	
	return new_domain # <--- CRITICO: Permite ao VagabondManager ler o nome

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
		
		if grid_mgr.data.nodes[pos].neighbors.size() == 6:
			if _is_space_free(pos):
				_create_capital(spawned, pos, grid_mgr, v_mgr, turn_mgr, t_size)
				spawned += 1

func _is_space_free(grid_pos: Vector2) -> bool:
	var min_dist = 200.0 
	for pos_key in active_domains:
		var d = active_domains[pos_key]
		if d.pos.distance_to(grid_pos) < min_dist: 
			return false
	return true

func _create_capital(id: int, grid_pos: Vector2, grid: Node2D, v_mgr: Node2D, turn: Node, t_size: float):
	if not turn: return
	var color_options = turn.get("COLOR_OPTIONS")
	var player_colors = turn.get("player_colors")
	
	if color_options == null or player_colors == null or id >= player_colors.size():
		return
	
	var color_name = player_colors[id]
	var p_color = color_options[color_name]
	
	# 1. Criamos o domínio e pegamos a instância de volta
	var domain_inst = create_domain(grid_pos, p_color, id, t_size)
	
	# 2. Geramos o nome baseado no domínio criado
	var v_name = ""
	if is_instance_valid(domain_inst) and domain_inst.has_method("generate_vagabond_name"):
		v_name = domain_inst.generate_vagabond_name()
	
	# 3. Spawna a unidade com o nome injetado
	if v_mgr and v_mgr.has_method("_create_vagabond"):
		# Usamos a função interna do Manager que aceita o parâmetro de nome
		v_mgr._create_vagabond(grid_pos, p_color, id, grid, v_name)