# res://src/systems/entities/VagabondManager.gd
extends Node2D

var vagabond_script: GDScript
var active_vagabonds: Array = []

func _ready() -> void:
	# Importante: randomize() deve ser chamado no main.gd ou aqui 
	# para garantir que os resultados mudem a cada execução.
	global_position = Vector2.ZERO
	
	var paths = ["res://src/systems/entities/Vagabond.gd", "res://src/entities/Vagabond.gd"]
	for path in paths:
		if ResourceLoader.exists(path):
			vagabond_script = load(path)
			print("VagabondManager: Script carregado.")
			break

func spawn_players(player_count: int, turn_manager: Node, map_radius: int) -> void:
	print("VagabondManager: Iniciando spawn aleatório...")
	
	# 1. Limpeza
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
	
	# 1. Ponto de partida aleatório (0 a 360 graus em radianos)
	var random_start_offset = randf() * TAU
	
	# 2. Sentido aleatório (1 = Horário, -1 = Anti-horário)
	var direction = 1 if randf() > 0.5 else -1
	
	# 3. Distribuição angular base
	var angle_step = (TAU / player_count) * direction

	for i in range(player_count):
		# O ângulo final combina o ponto de partida sorteado com o passo da vez
		var current_angle = random_start_offset + (i * angle_step)
		var target_dir = Vector2(cos(current_angle), sin(current_angle))
		
		# Buscamos o nó na borda mais próximo desta direção sorteada
		var best_node = all_nodes[0]
		var best_dot = -1.0
		
		# Verificamos os nós mais distantes (bordas)
		var search_pool = all_nodes.slice(0, min(60, all_nodes.size()))
		for node in search_pool:
			var dot = target_dir.dot(node.normalized())
			if dot > best_dot:
				best_dot = dot
				best_node = node
		
		# 4. Instanciação
		if not vagabond_script: return
			
		var vagabond = Node2D.new()
		vagabond.set_script(vagabond_script)
		vagabond.name = "Vagabond_P" + str(i)
		add_child(vagabond)
		
		var final_global_pos = grid_manager.to_global(best_node)
		
		if vagabond.has_method("setup"):
			var color_name = turn_manager.player_colors[i]
			var color_value = turn_manager.COLOR_OPTIONS[color_name]
			
			vagabond.setup(final_global_pos, best_node, color_value, i)
			vagabond.global_position = final_global_pos
			
			active_vagabonds.append(vagabond)
			print("VagabondManager: P", i, " spawnado em ângulo ", rad_to_deg(current_angle), "°")

func get_vagabond_at(pos: Vector2, radius: float = 60.0) -> Node2D:
	for v in active_vagabonds:
		if not is_instance_valid(v): continue
		if v.global_position.distance_to(pos) < radius:
			return v
	return null