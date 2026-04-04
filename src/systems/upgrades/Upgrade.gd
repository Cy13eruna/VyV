# res://src/systems/upgrades/Upgrade.gd
extends RefCounted
class_name Upgrade

var id: String = "base_upgrade"
var title: String = "Upgrade"
var icon: String = "✨"

# Armazenamos os tempos de upgrade por domínio para não bloquear jogadores diferentes
static var _domain_cooldowns: Dictionary = {}

func get_cost(domain: Node2D) -> int:
	# .get() retorna o valor ou o padrão (1) se a propriedade não existir
	var current_level = int(domain.get("domain_level") if "domain_level" in domain else 1)
	return max(1, current_level)

func execute(domain: Node2D) -> void:
	# --- TRAVA ANTI-SPAM POR DOMÍNIO ---
	var current_time = Time.get_ticks_msec()
	var domain_id = domain.get_instance_id()
	
	if _domain_cooldowns.has(domain_id):
		if current_time - _domain_cooldowns[domain_id] < 150: # 150ms é o "sweet spot"
			return
	
	_domain_cooldowns[domain_id] = current_time

	# --- VALIDAÇÃO DE RECURSOS ---
	var cost = get_cost(domain)
	var power = int(domain.get("power") if "power" in domain else 0)
	
	if power < cost:
		print("[Upgrade] %s negado: Poder insuficiente (%d/%d)" % [title, power, cost])
		return

	# --- EXECUÇÃO (PAGAMENTO) ---
	if domain.has_method("add_power"):
		domain.add_power(-cost)
	elif "power" in domain:
		domain.power -= cost
		
	# --- EVOLUÇÃO (LÓGICA) ---
	# Priorizamos o método upgrade_level() pois ele contém o spawn de unidades
	if domain.has_method("upgrade_level"):
		domain.upgrade_level()
	elif "domain_level" in domain:
		domain.domain_level += 1
		
	print("[Upgrade] %s: Pago %d. Nível atual: %d" % [title, cost, domain.get("domain_level")])
	
	# Limpeza periódica do dicionário de cooldowns (opcional)
	if _domain_cooldowns.size() > 50: 
		_domain_cooldowns.clear()