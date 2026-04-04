# res://src/systems/upgrades/NewVagabond.gd
extends "res://src/systems/upgrades/Upgrade.gd"

# Armazenamos o caminho após encontrar a primeira vez para não buscar de novo
var _cached_path: String = ""

func _init() -> void:
	id = "new_vagabond"
	title = "New Vagabond"
	icon = "🚶‍♀️"

func get_description(domain: Node2D) -> String:
	# Use SEMPRE o método da classe pai para o texto ser fiel ao que será cobrado
	return "Creates a new basic unit to wander the world.\nCost: ⭐ %d" % get_cost(domain)

func execute(domain: Node2D) -> void:
	# 1. Deixa o pai cuidar da grana e do nível
	super.execute(domain)
	
	# 2. Busca o arquivo apenas se não soubermos onde ele está
	if _cached_path == "":
		_cached_path = _find_file_recursive("res://src/", "Vagabond.gd") # Busca limitada a src/ para ser rápido
	
	if _cached_path == "":
		push_error("[Upgrade Error] Vagabond.gd não existe.")
		return

	# 3. Spawn
	var VagabondClass = load(_cached_path)
	if not VagabondClass: return
	
	var new_v = VagabondClass.new()
	
	if "global_position" in new_v:
		new_v.global_position = domain.global_position
	
	if "player_id" in domain and "player_id" in new_v:
		new_v.player_id = domain.player_id
	
	var world_node = domain.get_parent()
	if world_node:
		world_node.add_child(new_v)
		print("[NewVagabond] Spawn realizado com sucesso de: ", _cached_path)

# Melhorei a performance da busca ignorando pastas irrelevantes
func _find_file_recursive(path: String, target: String) -> String:
	var dir = DirAccess.open(path)
	if not dir: return ""
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			if file_name in [".", "..", ".godot", ".tmp"]:
				file_name = dir.get_next()
				continue
			var found = _find_file_recursive(path + file_name + "/", target)
			if found != "": return found
		elif file_name.to_lower() == target.to_lower():
			return path + file_name
		file_name = dir.get_next()
	return ""