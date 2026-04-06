# res://src/systems/upgrades/techs/Settlers.gd
extends "res://src/systems/upgrades/techs/Tech.gd"

func _init() -> void:
	id = "settlers"
	title = "Settlers"
	icon = "🚩"
	type_index = 2 # Global
	description = "[%s]: Settle New Domains" % TYPES[type_index]

func execute(domain: Node2D) -> void:
	# 1. Busca o DomainManager para registrar o desbloqueio global
	var domain_mgr = domain.get_tree().get_first_node_in_group("domain_manager")
	
	if is_instance_valid(domain_mgr):
		# 2. Ativa a flag de tecnologia e atualiza os Vagabonds existentes
		if domain_mgr.has_method("unlock_settlers_tech"):
			domain_mgr.unlock_settlers_tech()
		else:
			# Fallback caso a função não exista por algum motivo
			domain_mgr.set_meta("tech_settlers_unlocked", true)
			domain.get_tree().call_group("Units", "update_settler_status")
			
		print("[Tech: Settlers] Tecnologia ativada globalmente.")

	# Chama o comportamento base da Tech (emite sinais, gasta recursos, etc)
	super.execute(domain)