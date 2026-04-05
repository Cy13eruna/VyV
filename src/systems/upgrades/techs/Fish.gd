extends "res://src/systems/upgrades/techs/Tech.gd"

func _init() -> void:
	id = "Fish"
	title = "Fish"
	icon = "🎣"
	type_index = 0 # Upgrade
	description = "[%s]: Random Power from All Water Tiles" % TYPES[type_index]

func execute(domain: Node2D) -> void:
	# Lógica de pesca aqui
	super.execute(domain)