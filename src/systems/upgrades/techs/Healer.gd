extends "res://src/systems/upgrades/techs/Tech.gd"

func _init() -> void:
	id = "Healer"
	title = "Healer"
	icon = "❤"
	type_index = 1 # Trainment
	description = "[%s]: Heal Vagabonds" % TYPES[type_index]

func execute(domain: Node2D) -> void:
	# Lógica de cura/treinamento aqui
	super.execute(domain)