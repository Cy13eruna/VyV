# res://src/systems/upgrades/NewVagabond.gd
extends RefCounted

# Metadados para a UI
var id: String = "new_vagabond"
var title: String = "New Vagabond"
var icon: String = "🚶‍♀️"

func get_description(domain: Node2D) -> String:
	return "Creates a new basic unit to wander the world.\nCost: ⭐ %d" % domain.get("domain_level")

func get_cost(domain: Node2D) -> int:
	return int(domain.get("domain_level"))

## A lógica principal que antes estava no HUD agora vive aqui
func execute(domain: Node2D) -> void:
	# Se o domínio tem o método, usamos, senão alteramos as propriedades
	if domain.has_method("upgrade_level"):
		domain.upgrade_level()
	else:
		var current_level = domain.get("domain_level")
		domain.add_power(-current_level)
		domain.set("domain_level", current_level + 1)
	
	# Aqui você também poderia disparar o spawn da unidade física
	print("Upgrade executado: New Vagabond em ", domain.name)