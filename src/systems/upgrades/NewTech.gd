# res://src/systems/upgrades/NewTech.gd
extends "res://src/systems/upgrades/Upgrade.gd"

# Preload do script (já que não existe .tscn)
const TechTreeScript = preload("res://src/systems/upgrades/techs/TechTree.gd")

func _init() -> void:
	id = "new_tech"
	title = "New Tech"
	icon = "🌟"

func get_description(domain: Node2D) -> String:
	var cost = get_cost(domain)
	return "Open the Tech Tree to research new abilities.\nCost: ⭐ %d" % cost

func execute(domain: Node2D) -> void:
	if not is_instance_valid(domain): return

	print("[NewTech] Criando interface da TechTree 100% via código...")

	# 1. Criamos um CanvasLayer dedicado para garantir que a árvore fique no TOPO de tudo
	# Isso evita que o GameHUD ou o mapa cubram a árvore.
	var layer = CanvasLayer.new()
	layer.layer = 120 # Acima do HUD (que geralmente é 100)
	domain.get_tree().root.add_child(layer)

	# 2. Criamos o nó de controle e anexamos o script
	var tree_instance = Control.new()
	tree_instance.name = "TechTreeUI"
	tree_instance.set_script(TechTreeScript)
	
	# 3. Adicionamos a instância ao layer
	layer.add_child(tree_instance)
	
	# 4. EXTREMAMENTE IMPORTANTE: 
	# No Godot, após set_script, o objeto precisa de um frame para "virar" a classe nova.
	# Usamos call_deferred para garantir que o setup() rode após a inicialização.
	if tree_instance.has_method("setup"):
		tree_instance.call_deferred("setup", domain)
	else:
		# Se falhar aqui, o setup será chamado manualmente após um frame
		await domain.get_tree().process_frame
		if is_instance_valid(tree_instance):
			tree_instance.setup(domain)

	print("[NewTech] Instância enviada para a árvore de nós.")