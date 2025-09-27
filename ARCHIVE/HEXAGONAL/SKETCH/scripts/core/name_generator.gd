## NameGenerator - Sistema de Geração de Nomes para V&V
## Gera nomes únicos para domínios e unidades com iniciais relacionadas
## Garante que cada domínio tenha uma inicial única do alfabeto

class_name NameGenerator
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Sinais do gerador
signal domain_name_assigned(domain_id: int, name: String, initial: String)
signal unit_name_assigned(unit_id: int, name: String, domain_initial: String)

## Banco de nomes por inicial
var domain_names_by_initial: Dictionary = {
	"A": ["Abdula", "Aethros", "Arkania", "Astoria", "Avalon", "Azura"],
	"B": ["Baldur", "Byzantia", "Boreas", "Britannia", "Bastion", "Belmont"],
	"C": ["Caldris", "Celestia", "Crimson", "Caelum", "Cyprus", "Corona"],
	"D": ["Drakonia", "Delphia", "Dominion", "Damascus", "Darius", "Delphi"],
	"E": ["Eldoria", "Ethereal", "Empyrea", "Elysium", "Erebus", "Europa"],
	"F": ["Frostheim", "Felicia", "Fortuna", "Flamingo", "Fenris", "Fjord"],
	"G": ["Galdoria", "Grimhold", "Genesis", "Galatea", "Gondor", "Gaia"],
	"H": ["Hyperion", "Helios", "Harmony", "Hesperia", "Hades", "Horizon"],
	"I": ["Icarus", "Illyria", "Infinity", "Iris", "Ignis", "Ivory"],
	"J": ["Jericho", "Jupiter", "Jade", "Jasper", "Juno", "Journey"],
	"K": ["Kronos", "Kythera", "Kairos", "Karma", "Kestrel", "Kingdom"],
	"L": ["Lumina", "Lyra", "Leviathan", "Luna", "Liberty", "Legacy"],
	"M": ["Mystral", "Magnus", "Meridian", "Morpheus", "Mirage", "Majesty"],
	"N": ["Nebula", "Nexus", "Nirvana", "Neptune", "Nova", "Nemesis"],
	"O": ["Olympus", "Orion", "Oceania", "Omega", "Oracle", "Oasis"],
	"P": ["Phoenix", "Pandora", "Prism", "Poseidon", "Paradise", "Pinnacle"],
	"Q": ["Quantum", "Quasar", "Quest", "Quintus", "Quartz", "Quorum"],
	"R": ["Ragnarok", "Rhapsody", "Radiance", "Regulus", "Realm", "Raven"],
	"S": ["Solaris", "Seraphim", "Sanctuary", "Stellar", "Sphinx", "Summit"],
	"T": ["Tempest", "Titan", "Twilight", "Terra", "Trinity", "Throne"],
	"U": ["Utopia", "Umbra", "Unity", "Uranus", "Ultra", "Universe"],
	"V": ["Valhalla", "Vertex", "Vortex", "Venus", "Victory", "Virtue"],
	"W": ["Wyvern", "Whisper", "Wisdom", "Wonder", "Warrior", "Willow"],
	"X": ["Xerxes", "Xanadu", "Xenith", "Xylem", "Xenos", "Xiphias"],
	"Y": ["Yggdrasil", "Ysera", "Yonder", "Yukon", "Yearning", "Ymir"],
	"Z": ["Zephyr", "Zenith", "Zodiac", "Zeus", "Zion", "Zara"]
}

var unit_names_by_initial: Dictionary = {
	"A": ["Abdala", "Aeron", "Aris", "Astor", "Axel", "Azrael"],
	"B": ["Bjorn", "Bane", "Boris", "Blade", "Bruno", "Brix"],
	"C": ["Cain", "Cyrus", "Cole", "Cruz", "Castor", "Cliff"],
	"D": ["Drake", "Dante", "Darius", "Dean", "Drex", "Damon"],
	"E": ["Erik", "Ethan", "Enzo", "Edgar", "Elias", "Evan"],
	"F": ["Felix", "Finn", "Frost", "Ford", "Flynn", "Fang"],
	"G": ["Gareth", "Grim", "Gage", "Grey", "Gunnar", "Gideon"],
	"H": ["Hunter", "Hawk", "Hugo", "Heath", "Hector", "Haze"],
	"I": ["Ivan", "Isaac", "Igor", "Ira", "Indigo", "Ion"],
	"J": ["Jax", "Juno", "Jett", "Jace", "Jin", "Jorah"],
	"K": ["Kane", "Knox", "Kai", "Kael", "Kylo", "Kris"],
	"L": ["Lux", "Leo", "Lance", "Luke", "Lynx", "Liam"],
	"M": ["Max", "Mace", "Miles", "Milo", "Magnus", "Moss"],
	"N": ["Nyx", "Nash", "Neo", "Nolan", "Nero", "Nix"],
	"O": ["Orion", "Oscar", "Onyx", "Owen", "Odin", "Oz"],
	"P": ["Phoenix", "Pike", "Pax", "Porter", "Pierce", "Prism"],
	"Q": ["Quinn", "Quill", "Quest", "Quade", "Quin", "Quartz"],
	"R": ["Rex", "Raven", "Ryder", "Rage", "Rhys", "Ridge"],
	"S": ["Storm", "Sage", "Saber", "Seth", "Silas", "Spike"],
	"T": ["Titan", "Thorn", "Titus", "Troy", "Talon", "Trace"],
	"U": ["Ulric", "Uri", "Ugo", "Ulf", "Urban", "Usher"],
	"V": ["Vex", "Vale", "Vance", "Victor", "Viper", "Volt"],
	"W": ["Wolf", "Wade", "Wren", "Wyatt", "Ward", "West"],
	"X": ["Xander", "Xerxes", "Xavi", "Xen", "Xion", "Xylo"],
	"Y": ["York", "Yuki", "Yale", "Yves", "Yann", "Ymir"],
	"Z": ["Zane", "Zed", "Zeus", "Zion", "Zara", "Zephyr"]
}

## Controle de iniciais usadas
var used_initials: Array[String] = []
var domain_names_assigned: Dictionary = {}  # domain_id -> {name, initial}
var unit_names_assigned: Dictionary = {}    # unit_id -> {name, domain_initial}

## Inicializar gerador
func _init():
	Logger.debug("NameGenerator inicializado com %d iniciais disponíveis" % domain_names_by_initial.size(), "NameGenerator")

## Gerar nome para domínio
func generate_domain_name(domain_id: int) -> Dictionary:
	# Verificar se já tem nome
	if domain_names_assigned.has(domain_id):
		var existing = domain_names_assigned[domain_id]
		Logger.debug("Domínio %d já tem nome: %s (%s)" % [domain_id, existing.name, existing.initial], "NameGenerator")
		return existing
	
	# Encontrar inicial disponível
	var available_initials = _get_available_initials()
	if available_initials.is_empty():
		Logger.error("Não há iniciais disponíveis para novos domínios", "NameGenerator")
		return {"name": "Unnamed", "initial": "?"}
	
	# Escolher inicial aleatória
	var chosen_initial = available_initials[randi() % available_initials.size()]
	var available_names = domain_names_by_initial[chosen_initial]
	var chosen_name = available_names[randi() % available_names.size()]
	
	# Registrar uso
	used_initials.append(chosen_initial)
	var domain_data = {"name": chosen_name, "initial": chosen_initial}
	domain_names_assigned[domain_id] = domain_data
	
	# Emitir sinal
	domain_name_assigned.emit(domain_id, chosen_name, chosen_initial)
	
	Logger.info("Domínio %d nomeado: %s (inicial %s)" % [domain_id, chosen_name, chosen_initial], "NameGenerator")
	return domain_data

## Gerar nome para unidade baseado no domínio de origem
func generate_unit_name(unit_id: int, origin_domain_id: int) -> Dictionary:
	# Verificar se já tem nome
	if unit_names_assigned.has(unit_id):
		var existing = unit_names_assigned[unit_id]
		Logger.debug("Unidade %d já tem nome: %s (inicial %s)" % [unit_id, existing.name, existing.domain_initial], "NameGenerator")
		return existing
	
	# Verificar se domínio de origem tem nome
	if not domain_names_assigned.has(origin_domain_id):
		Logger.error("Domínio de origem %d não tem nome atribuído" % origin_domain_id, "NameGenerator")
		return {"name": "Unnamed", "domain_initial": "?"}
	
	# Obter inicial do domínio
	var domain_data = domain_names_assigned[origin_domain_id]
	var domain_initial = domain_data.initial
	
	# Escolher nome com a mesma inicial
	var available_names = unit_names_by_initial[domain_initial]
	var chosen_name = available_names[randi() % available_names.size()]
	
	# Registrar uso
	var unit_data = {"name": chosen_name, "domain_initial": domain_initial}
	unit_names_assigned[unit_id] = unit_data
	
	# Emitir sinal
	unit_name_assigned.emit(unit_id, chosen_name, domain_initial)
	
	Logger.info("Unidade %d nomeada: %s (inicial %s do domínio %s)" % [unit_id, chosen_name, domain_initial, domain_data.name], "NameGenerator")
	return unit_data

## Obter nome de domínio
func get_domain_name(domain_id: int) -> String:
	if domain_names_assigned.has(domain_id):
		return domain_names_assigned[domain_id].name
	return "Unnamed"

## Obter inicial de domínio
func get_domain_initial(domain_id: int) -> String:
	if domain_names_assigned.has(domain_id):
		return domain_names_assigned[domain_id].initial
	return "?"

## Obter nome de unidade
func get_unit_name(unit_id: int) -> String:
	if unit_names_assigned.has(unit_id):
		return unit_names_assigned[unit_id].name
	return "Unnamed"

## Obter inicial de unidade (baseada no domínio)
func get_unit_initial(unit_id: int) -> String:
	if unit_names_assigned.has(unit_id):
		return unit_names_assigned[unit_id].domain_initial
	return "?"

## Verificar se domínio tem nome
func has_domain_name(domain_id: int) -> bool:
	return domain_names_assigned.has(domain_id)

## Verificar se unidade tem nome
func has_unit_name(unit_id: int) -> bool:
	return unit_names_assigned.has(unit_id)

## Obter todas as iniciais usadas
func get_used_initials() -> Array[String]:
	return used_initials.duplicate()

## Obter iniciais disponíveis
func get_available_initials() -> Array[String]:
	return _get_available_initials()

## Resetar sistema de nomes
func reset_names() -> void:
	used_initials.clear()
	domain_names_assigned.clear()
	unit_names_assigned.clear()
	Logger.info("Sistema de nomes resetado", "NameGenerator")

## Obter estatísticas do sistema
func get_stats() -> Dictionary:
	return {
		"total_initials": domain_names_by_initial.size(),
		"used_initials": used_initials.size(),
		"available_initials": _get_available_initials().size(),
		"domains_named": domain_names_assigned.size(),
		"units_named": unit_names_assigned.size()
	}

## Serializar estado do gerador
func serialize() -> Dictionary:
	return {
		"used_initials": used_initials,
		"domain_names_assigned": domain_names_assigned,
		"unit_names_assigned": unit_names_assigned
	}

## Deserializar estado do gerador
func deserialize(data: Dictionary) -> bool:
	if not data.has("used_initials") or not data.has("domain_names_assigned"):
		Logger.error("Dados de deserialização inválidos", "NameGenerator")
		return false
	
	used_initials = data.get("used_initials", [])
	domain_names_assigned = data.get("domain_names_assigned", {})
	unit_names_assigned = data.get("unit_names_assigned", {})
	
	Logger.info("Estado do NameGenerator deserializado", "NameGenerator")
	return true

## Obter iniciais disponíveis (método privado)
func _get_available_initials() -> Array[String]:
	var available: Array[String] = []
	for initial in domain_names_by_initial.keys():
		if not used_initials.has(initial):
			available.append(initial)
	return available

## Validar relacionamento unidade-domínio
func validate_unit_domain_relationship(unit_id: int, domain_id: int) -> bool:
	if not has_unit_name(unit_id) or not has_domain_name(domain_id):
		return false
	
	var unit_initial = get_unit_initial(unit_id)
	var domain_initial = get_domain_initial(domain_id)
	
	return unit_initial == domain_initial

## Obter informações completas de relacionamento
func get_relationship_info(unit_id: int, domain_id: int) -> Dictionary:
	return {
		"unit_name": get_unit_name(unit_id),
		"unit_initial": get_unit_initial(unit_id),
		"domain_name": get_domain_name(domain_id),
		"domain_initial": get_domain_initial(domain_id),
		"relationship_valid": validate_unit_domain_relationship(unit_id, domain_id)
	}