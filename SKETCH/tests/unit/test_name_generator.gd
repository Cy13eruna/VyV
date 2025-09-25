## Teste do Sistema de Geração de Nomes
## Verifica se o NameGenerator funciona corretamente

extends RefCounted

const NameGenerator = preload("res://scripts/core/name_generator.gd")
const Logger = preload("res://scripts/core/logger.gd")

## Executar todos os testes
func run_tests() -> Dictionary:
	print("🧪 === INICIANDO TESTES DO NAME GENERATOR ===")
	
	var results = {
		"total_tests": 0,
		"passed_tests": 0,
		"failed_tests": 0,
		"test_details": []
	}
	
	# Lista de testes
	var tests = [
		"test_domain_name_generation",
		"test_unit_name_generation", 
		"test_unique_initials",
		"test_unit_domain_relationship",
		"test_serialization",
		"test_stats_and_validation"
	]
	
	# Executar cada teste
	for test_name in tests:
		results.total_tests += 1
		var test_result = call(test_name)
		
		if test_result.passed:
			results.passed_tests += 1
			print("✅ %s: PASSOU" % test_name)
		else:
			results.failed_tests += 1
			print("❌ %s: FALHOU - %s" % [test_name, test_result.error])
		
		results.test_details.append(test_result)
	
	# Relatório final
	print("\n📊 === RESULTADO DOS TESTES ===")
	print("Total: %d | Passou: %d | Falhou: %d" % [results.total_tests, results.passed_tests, results.failed_tests])
	
	if results.failed_tests == 0:
		print("🎉 TODOS OS TESTES PASSARAM!")
	else:
		print("⚠️ %d TESTE(S) FALHARAM" % results.failed_tests)
	
	print("=== FIM DOS TESTES ===\n")
	return results

## Teste 1: Geração de nomes de domínios
func test_domain_name_generation() -> Dictionary:
	var name_gen = NameGenerator.new()
	
	# Gerar nome para domínio
	var domain_data = name_gen.generate_domain_name(1)
	
	# Verificações
	if domain_data.name.is_empty():
		return {"passed": false, "error": "Nome do domínio está vazio"}
	
	if domain_data.initial.is_empty():
		return {"passed": false, "error": "Inicial do domínio está vazia"}
	
	if domain_data.initial.length() != 1:
		return {"passed": false, "error": "Inicial deve ter exatamente 1 caractere"}
	
	if not domain_data.name.begins_with(domain_data.initial):
		return {"passed": false, "error": "Nome não começa com a inicial correta"}
	
	# Verificar se foi registrado
	if not name_gen.has_domain_name(1):
		return {"passed": false, "error": "Domínio não foi registrado"}
	
	return {"passed": true, "error": "", "data": domain_data}

## Teste 2: Geração de nomes de unidades
func test_unit_name_generation() -> Dictionary:
	var name_gen = NameGenerator.new()
	
	# Primeiro criar um domínio
	var domain_data = name_gen.generate_domain_name(1)
	
	# Depois criar unidade vinculada
	var unit_data = name_gen.generate_unit_name(1, 1)
	
	# Verificações
	if unit_data.name.is_empty():
		return {"passed": false, "error": "Nome da unidade está vazio"}
	
	if unit_data.domain_initial != domain_data.initial:
		return {"passed": false, "error": "Inicial da unidade não corresponde ao domínio"}
	
	if not unit_data.name.begins_with(unit_data.domain_initial):
		return {"passed": false, "error": "Nome da unidade não começa com a inicial correta"}
	
	# Verificar se foi registrado
	if not name_gen.has_unit_name(1):
		return {"passed": false, "error": "Unidade não foi registrada"}
	
	return {"passed": true, "error": "", "data": unit_data}

## Teste 3: Iniciais únicas para domínios
func test_unique_initials() -> Dictionary:
	var name_gen = NameGenerator.new()
	var used_initials = []
	
	# Criar vários domínios
	for i in range(5):
		var domain_data = name_gen.generate_domain_name(i)
		
		if domain_data.initial in used_initials:
			return {"passed": false, "error": "Inicial duplicada: %s" % domain_data.initial}
		
		used_initials.append(domain_data.initial)
	
	# Verificar se as iniciais estão sendo rastreadas
	var tracked_initials = name_gen.get_used_initials()
	if tracked_initials.size() != 5:
		return {"passed": false, "error": "Número incorreto de iniciais rastreadas"}
	
	return {"passed": true, "error": "", "data": used_initials}

## Teste 4: Relacionamento unidade-domínio
func test_unit_domain_relationship() -> Dictionary:
	var name_gen = NameGenerator.new()
	
	# Criar domínio e unidade
	var domain_data = name_gen.generate_domain_name(10)
	var unit_data = name_gen.generate_unit_name(10, 10)
	
	# Verificar relacionamento
	if not name_gen.validate_unit_domain_relationship(10, 10):
		return {"passed": false, "error": "Relacionamento válido não foi reconhecido"}
	
	# Testar relacionamento inválido
	var domain_data2 = name_gen.generate_domain_name(11)
	if name_gen.validate_unit_domain_relationship(10, 11):
		return {"passed": false, "error": "Relacionamento inválido foi aceito"}
	
	# Testar informações de relacionamento
	var relationship_info = name_gen.get_relationship_info(10, 10)
	if not relationship_info.relationship_valid:
		return {"passed": false, "error": "Informações de relacionamento incorretas"}
	
	return {"passed": true, "error": "", "data": relationship_info}

## Teste 5: Serialização e deserialização
func test_serialization() -> Dictionary:
	var name_gen = NameGenerator.new()
	
	# Criar alguns nomes
	name_gen.generate_domain_name(20)
	name_gen.generate_domain_name(21)
	name_gen.generate_unit_name(20, 20)
	
	# Serializar
	var serialized_data = name_gen.serialize()
	
	# Criar novo gerador e deserializar
	var name_gen2 = NameGenerator.new()
	if not name_gen2.deserialize(serialized_data):
		return {"passed": false, "error": "Falha na deserialização"}
	
	# Verificar se os dados foram restaurados
	if not name_gen2.has_domain_name(20):
		return {"passed": false, "error": "Domínio não foi restaurado"}
	
	if not name_gen2.has_unit_name(20):
		return {"passed": false, "error": "Unidade não foi restaurada"}
	
	if name_gen2.get_used_initials().size() != name_gen.get_used_initials().size():
		return {"passed": false, "error": "Iniciais usadas não foram restauradas"}
	
	return {"passed": true, "error": "", "data": serialized_data}

## Teste 6: Estatísticas e validação
func test_stats_and_validation() -> Dictionary:
	var name_gen = NameGenerator.new()
	
	# Estado inicial
	var initial_stats = name_gen.get_stats()
	if initial_stats.used_initials != 0:
		return {"passed": false, "error": "Estado inicial incorreto"}
	
	# Criar alguns nomes
	name_gen.generate_domain_name(30)
	name_gen.generate_domain_name(31)
	name_gen.generate_unit_name(30, 30)
	
	# Verificar estatísticas
	var stats = name_gen.get_stats()
	if stats.used_initials != 2:
		return {"passed": false, "error": "Contagem de iniciais incorreta"}
	
	if stats.domains_named != 2:
		return {"passed": false, "error": "Contagem de domínios incorreta"}
	
	if stats.units_named != 1:
		return {"passed": false, "error": "Contagem de unidades incorreta"}
	
	# Testar reset
	name_gen.reset_names()
	var reset_stats = name_gen.get_stats()
	if reset_stats.used_initials != 0:
		return {"passed": false, "error": "Reset não funcionou"}
	
	return {"passed": true, "error": "", "data": stats}

## Função para executar teste individual
func run_single_test(test_name: String) -> Dictionary:
	if has_method(test_name):
		return call(test_name)
	else:
		return {"passed": false, "error": "Teste não encontrado: %s" % test_name}

## Teste de stress - criar muitos domínios
func test_stress_many_domains() -> Dictionary:
	var name_gen = NameGenerator.new()
	var created_count = 0
	
	# Tentar criar mais domínios do que iniciais disponíveis
	for i in range(30):  # Mais que 26 letras
		var domain_data = name_gen.generate_domain_name(i)
		if not domain_data.name.is_empty():
			created_count += 1
	
	# Deve parar em 26 (número de letras do alfabeto)
	if created_count > 26:
		return {"passed": false, "error": "Criou mais domínios que iniciais disponíveis"}
	
	return {"passed": true, "error": "", "data": {"created": created_count}}

## Demonstração do sistema
func demonstrate_system() -> void:
	print("\n🎭 === DEMONSTRAÇÃO DO SISTEMA DE NOMES ===")
	
	var name_gen = NameGenerator.new()
	
	# Criar alguns domínios
	print("\n🏰 Criando domínios:")
	for i in range(3):
		var domain_data = name_gen.generate_domain_name(i)
		print("   • Domínio %d: %s (inicial %s)" % [i, domain_data.name, domain_data.initial])
	
	# Criar unidades para cada domínio
	print("\n⚔️ Criando unidades:")
	for i in range(3):
		var unit_data = name_gen.generate_unit_name(i, i)
		print("   • Unidade %d: %s (inicial %s) - Domínio: %d" % [i, unit_data.name, unit_data.domain_initial, i])
	
	# Mostrar relacionamentos
	print("\n🔗 Validando relacionamentos:")
	for i in range(3):
		var is_valid = name_gen.validate_unit_domain_relationship(i, i)
		var relationship_info = name_gen.get_relationship_info(i, i)
		print("   • Unidade %s ↔ Domínio %s: %s" % [
			relationship_info.unit_name, 
			relationship_info.domain_name, 
			"✅ Válido" if is_valid else "❌ Inválido"
		])
	
	# Estatísticas finais
	print("\n📊 Estatísticas:")
	var stats = name_gen.get_stats()
	print("   • Iniciais usadas: %d/%d" % [stats.used_initials, stats.total_initials])
	print("   • Domínios nomeados: %d" % stats.domains_named)
	print("   • Unidades nomeadas: %d" % stats.units_named)
	print("   • Iniciais disponíveis: %d" % stats.available_initials)
	
	print("\n=== FIM DA DEMONSTRAÇÃO ===\n")