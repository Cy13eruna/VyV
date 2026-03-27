# res://src/systems/entities/VagabondManager.gd
extends Node2D

var vagabond_script: GDScript
var active_vagabonds: Array = []

func _ready() -> void:
	global_position = Vector2.ZERO
	
	# Busca o script do Vagabond em ambos os caminhos possíveis
	var paths = ["res://src/systems/entities/Vagabond.gd", "res://src/entities/Vagabond.gd"]
	for path in paths:
		if ResourceLoader.exists(path):
			vagabond_script = load(path)
			print("VagabondManager: Script carregado.")
			break

# --- NOVA FUNÇÃO DE RESTAURAÇÃO ---

## Percorre todas as unidades vivas e restaura seus pontos de ação
func restore_all_units_ap() -> void:
	print("VagabondManager: Restaurando AP de todas as unidades...")
	for v in active_vagabonds:
		if is_instance_valid(v) and v.has_method("restore_ap"):
			v.restore_ap()

# ---------------------------------

func spawn_players(player_count: int, turn_manager: Node, map_radius: int) -> void:
	print("VagabondManager: Iniciando spawn aleatório...")
	
	# 1. Limpeza de unidades antigas
	for v in active_vagabonds:
		if is_instance_valid(v): v.queue_free()
	active_vagabonds.clear()
	
	var grid_manager = get_parent().get_node_or_null("GridManager")
	if not grid_manager or not grid_manager.data:
		push_error("VagabondManager: GridManager ou Data não encontrados!")
		return

	var all_nodes = grid_manager.data.nodes.keys()
	if all_nodes.is_empty():
		return

	# Ordenamos os nós pela distância do centro para priorizar as bordas
	all_nodes.sort_custom(func(a, b): return a.length() > b.length())

	# --- LÓGICA DE ALEATORIEDADE ---
	var random_start_offset = randf() * TAU
	var direction = 1 if randf() > 0.5 else -1
	var angle_step = (TAU / player_count) * direction

	for i in range(player_count):
		var current_angle = random_start_offset + (i * angle_step)
		var target_dir = Vector2(cos(current_angle), sin(current_angle))
		
		# Busca o nó na borda mais próximo da direção sorteada
		var best_node = all_nodes[0]
		var best_dot = -1.0
		
		# Verifica apenas os 60 nós mais externos para performance
		var search_pool = all_nodes.slice(0, min(60, all_nodes.size()))
		for node in search_pool:
			var dot = target_dir.dot(node.normalized())
			if dot > best_dot:
				best_dot = dot
				best_node = node
		
		# 4. Instanciação
		if not vagabond_script: 
			push_error("VagabondManager: Falha ao instanciar - Script não carregado!")
			return
			
		var vagabond = Node2D.new()
		vagabond.set_script(vagabond_script)
		vagabond.name = "Vagabond_P" + str(i)
		add_child(vagabond)
		
		var final_global_pos = grid_manager.to_global(best_node)
		
		if vagabond.has_method("setup"):
			var color_name = turn_manager.player_colors[i]
			var color_value = turn_manager.COLOR_OPTIONS[color_name]
			
			vagabond.setup(final_global_pos, best_node, color_value, i)
			# Garante que a posição física esteja correta após o setup
			vagabond.global_position = final_global_pos
			
			active_vagabonds.append(vagabond)
			print("VagabondManager: P", i, " spawnado em ângulo ", rad_to_deg(current_angle), "°")

func get_vagabond_at(pos: Vector2, radius: float = 60.0) -> Node2D:
	for v in active_vagabonds:
		if not is_instance_valid(v): continue
		if v.global_position.distance_to(pos) < radius:
			return v
	return null