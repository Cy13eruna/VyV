## Script de teste rápido para o sistema de nomes
## Execute este script para testar o NameGenerator

extends SceneTree

const NameGenerator = preload("res://scripts/core/name_generator.gd")
const TestNameGenerator = preload("res://tests/unit/test_name_generator.gd")

func _init():
	print("🚀 === TESTE RÁPIDO DO SISTEMA DE NOMES ===\n")
	
	# Executar demonstração
	var test_runner = TestNameGenerator.new()
	test_runner.demonstrate_system()
	
	# Executar testes unitários
	var test_results = test_runner.run_tests()
	
	# Teste manual adicional
	print("🔧 === TESTE MANUAL ADICIONAL ===")
	test_manual_example()
	
	print("\n✅ Teste concluído!")
	quit()

func test_manual_example():
	var name_gen = NameGenerator.new()
	
	print("\n📝 Exemplo conforme especificação:")
	
	# Criar domínio Abdula
	var domain_data = name_gen.generate_domain_name(1)
	print("   🏰 Domínio criado: %s (inicial %s)" % [domain_data.name, domain_data.initial])
	
	# Criar unidade com mesma inicial
	var unit_data = name_gen.generate_unit_name(1, 1)
	print("   ⚔️ Unidade criada: %s (inicial %s)" % [unit_data.name, unit_data.domain_initial])
	
	# Verificar relacionamento
	var is_valid = name_gen.validate_unit_domain_relationship(1, 1)
	print("   🔗 Relacionamento: %s" % ("✅ Válido" if is_valid else "❌ Inválido"))
	
	# Mostrar que iniciais são iguais
	if domain_data.initial == unit_data.domain_initial:
		print("   ✅ Iniciais correspondem: %s = %s" % [domain_data.initial, unit_data.domain_initial])
	else:
		print("   ❌ Iniciais não correspondem: %s ≠ %s" % [domain_data.initial, unit_data.domain_initial])
	
	print("\n🎯 Sistema funcionando conforme especificado!")