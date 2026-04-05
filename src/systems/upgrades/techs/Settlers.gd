extends "res://src/systems/upgrades/techs/Tech.gd"

func _init() -> void:
	id = "settlers"
	title = "Settlers"
	icon = "🚩"
	type_index = 2 # Global
	description = "[%s]: Settle New Domains" % TYPES[type_index]

func execute(domain: Node2D) -> void:
	# Lógica de expansão aqui
	super.execute(domain)