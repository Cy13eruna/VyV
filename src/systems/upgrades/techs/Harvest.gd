extends "res://src/systems/upgrades/techs/Tech.gd"

func _init() -> void:
	id = "Harvest"
	title = "Harvest"
	icon = "🍎"
	type_index = 0 # Upgrade
	description = "[%s]: Constant Power from a Single Wood Tile" % TYPES[type_index]

func execute(domain: Node2D) -> void:
	# Lógica de colheita aqui
	super.execute(domain)