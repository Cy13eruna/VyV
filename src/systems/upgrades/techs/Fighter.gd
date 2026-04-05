extends "res://src/systems/upgrades/techs/Tech.gd"

func _init() -> void:
	id = "Fighter"
	title = "Fighter"
	icon = "🗡"
	type_index = 1 # Trainment
	description = "[%s]: Hurt Vagabonds" % TYPES[type_index]

func execute(domain: Node2D) -> void:
	# Lógica de combate/treinamento aqui
	super.execute(domain)