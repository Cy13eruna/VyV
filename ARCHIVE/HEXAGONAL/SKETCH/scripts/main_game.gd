## V&V Game - Sistema Refatorado com Arquitetura Modular
## Arquivo principal drasticamente simplificado usando GameController
##
## ✅ REFATORAÇÃO COMPLETA REALIZADA!
## 🎯 Responsabilidade única: Inicialização e orquestração de alto nível
## 📋 Sistemas extraídos: TurnManager, InputHandler, UIManager, GameController
## 🚀 Arquitetura modular seguindo princípios SOLID

extends Node2D

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")
const ObjectFactories = preload("res://scripts/core/object_factories.gd")
const ResourceCleanup = preload("res://scripts/core/resource_cleanup.gd")
const GameConfig = preload("res://scripts/core/game_config.gd")

# Importar sistemas principais
const StarMapper = preload("res://scripts/entities/star_mapper.gd")
const GameManagerClass = preload("res://scripts/game/game_manager.gd")
const SpawnManager = preload("res://scripts/game/managers/spawn_manager.gd")

## Referências dos sistemas principais
@onready var hex_grid = $HexGrid
var star_mapper: StarMapper
var game_manager  # Tipagem dinâmica para evitar problemas de resolução
var game_controller  # Tipagem dinâmica para evitar problemas de resolução
var spawn_manager: SpawnManager

## Estado do sistema
var current_domain_count: int = 6
var map_initialized: bool = false

func _ready() -> void:
	Logger.info("Inicializando sistema refatorado com GameController...", "MainGame")
	
	# Inicializar sistema de cleanup
	ResourceCleanup.initialize()
	
	# Inicializar ObjectPool primeiro
	ObjectFactories.setup_object_pools()
	
	# Inicializar componentes
	_initialize_core_systems()
	
	# Configurar mapa baseado em argumentos de console
	_step_0_console_input()
	
	# Configurar cleanup automático no exit
	get_tree().auto_accept_quit = false
	if get_tree().has_signal("quit_request"):
		get_tree().quit_request.connect(_on_quit_request)
	else:
		# Fallback para versões mais antigas do Godot
		get_tree().set_quit_on_go_back(false)

## Inicializar sistemas principais
func _initialize_core_systems() -> void:
	if not star_mapper:
		star_mapper = StarMapper.new()
	if not game_manager:
		game_manager = GameManagerClass.new()
	if not game_controller:
		# Carregar dinamicamente para evitar problemas de dependência
		var GameControllerClass = load("res://scripts/game/managers/game_controller.gd")
		if GameControllerClass:
			game_controller = GameControllerClass.new()
			Logger.debug("GameController carregado dinamicamente", "MainGame")
		else:
			Logger.error("Falha ao carregar GameController", "MainGame")
	if not spawn_manager:
		spawn_manager = SpawnManager.new()
	
	Logger.debug("Sistemas principais inicializados", "MainGame")

## Configurar sistema completo após inicialização do mapa
func _setup_complete_system() -> void:
	# Aguardar um frame para garantir que tudo está pronto
	await get_tree().process_frame
	
	# Inicializar GameController com todas as referências
	if game_controller and game_controller.has_method("initialize"):
		game_controller.initialize(self, hex_grid, star_mapper, game_manager)
		
		# Aguardar mais um frame para garantir que hex_grid está completamente pronto
		await get_tree().process_frame
		
		# Configurar zoom inicial baseado no número de domínios
		if game_controller.has_method("setup_initial_zoom"):
			game_controller.setup_initial_zoom(current_domain_count)
			Logger.info("Zoom de mapeamento de estrelas configurado pelo GameController", "MainGame")
	else:
		Logger.warning("GameController não disponível ou métodos não encontrados", "MainGame")
	
	# Configurar sistema de turnos
	if game_manager and game_controller and game_controller.has_method("setup_turn_system"):
		var all_domains = game_manager.get_all_domains()
		var all_units = game_manager.get_all_units()
		game_controller.setup_turn_system(all_units, all_domains)
	
	# Aguardar outro frame para interface estar pronta
	await get_tree().process_frame
	
	# Iniciar jogo
	if game_controller and game_controller.has_method("start_game"):
		game_controller.start_game()
	map_initialized = true
	
	Logger.info("Sistema completo configurado e jogo iniciado!", "MainGame")
	
	# Mostrar relatório inicial de nomes
	await get_tree().create_timer(1.0).timeout  # Aguardar 1 segundo
	_show_names_report()
	
	# Aplicar melhorias estéticas automaticamente
	await get_tree().create_timer(0.5).timeout
	_apply_aesthetic_improvements()
	
	# Mostrar relatório de poder inicial
	await get_tree().create_timer(0.5).timeout
	_show_power_report()

## Processar input através do GameController
func _unhandled_input(event: InputEvent) -> void:
	if not map_initialized or not game_controller:
		return
	
	# Comando especial para testar sistema de nomes
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_N:  # Tecla N para mostrar relatório de nomes
			_show_names_report()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_R:  # Tecla R para recriar labels de nomes
			_recreate_name_labels()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_A:  # Tecla A para aplicar melhorias estéticas
			_apply_aesthetic_improvements()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_P:  # Tecla P para relatório de poder
			_show_power_report()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_T:  # Tecla T para produzir poder (simular turno)
			_produce_power_turn()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_U:  # Tecla U para atualizar displays de poder
			_update_power_displays()
			get_viewport().set_input_as_handled()
			return
	
	if game_controller and game_controller.has_method("process_input"):
		if game_controller.process_input(event):
			get_viewport().set_input_as_handled()

## === SISTEMA DE CRIAÇÃO DE MAPA (MANTIDO) ===

## Passo 0: Aguardar input via console para quantidade de domínios
func _step_0_console_input() -> void:
	var domain_count = _get_domain_count_from_console()
	_execute_map_creation_steps(domain_count)

func _get_domain_count_from_console() -> int:
	var args = OS.get_cmdline_args()
	var domain_count = 6
	
	for arg in args:
		if arg.begins_with("--domain-count="):
			domain_count = int(arg.split("=")[1])
			break
	
	return GameConfig.validate_domain_count(domain_count)

func _execute_map_creation_steps(domain_count: int) -> void:
	current_domain_count = domain_count
	var map_width = GameConfig.get_map_width(domain_count)
	
	_step_1_render_board(map_width)
	
	if hex_grid.is_initialized:
		_continue_remaining_steps()
	else:
		hex_grid.grid_initialized.connect(_continue_remaining_steps, CONNECT_ONE_SHOT)

func _step_1_render_board(width: int) -> void:
	var hex_radius = (width + 1) / 2
	hex_grid.config.set_grid_width(hex_radius)
	hex_grid.config.set_grid_height(hex_radius)
	hex_grid.rebuild_grid()

func _continue_remaining_steps() -> void:
	if not hex_grid.is_grid_ready():
		get_tree().create_timer(0.5).timeout.connect(_continue_remaining_steps, CONNECT_ONE_SHOT)
		return
	
	_step_2_map_stars()
	_step_3_position_domains()
	# Zoom será configurado pelo GameController em _setup_complete_system()
	
	_setup_complete_system()

func _step_2_map_stars() -> void:
	if not hex_grid or not hex_grid.is_grid_ready():
		return
	
	var dot_positions = hex_grid.get_dot_positions()
	star_mapper.map_stars(dot_positions)
	
	if game_manager:
		var setup_result = game_manager.setup_references(hex_grid, star_mapper, self)
		if setup_result and setup_result.is_error():
			Logger.error("Falha ao configurar referências do GameManager: %s" % setup_result.get_error(), "MainGame")
		
		# IMPORTANTE: Configurar GameManager no sistema de highlight
		if hex_grid and hex_grid.has_method("set_game_manager_reference"):
			hex_grid.set_game_manager_reference(game_manager)
			Logger.info("GameManager configurado no sistema de highlight", "MainGame")
	
	if game_manager:
		if not game_manager.unit_created.is_connected(_on_unit_created):
			game_manager.unit_created.connect(_on_unit_created)
		if not game_manager.domain_created.is_connected(_on_domain_created):
			game_manager.domain_created.connect(_on_domain_created)

func _step_3_position_domains() -> void:
	if not game_manager or not spawn_manager:
		return
	
	# Configurar referências
	var setup_result = game_manager.setup_references(hex_grid, star_mapper, self)
	if setup_result and setup_result.is_error():
		Logger.error("Falha ao configurar referências do GameManager: %s" % setup_result.get_error(), "MainGame")
		return
	
	spawn_manager.initialize(hex_grid, star_mapper, game_manager)
	
	# Executar spawn usando SpawnManager
	var spawned_count = spawn_manager.spawn_domains(current_domain_count)
	Logger.info("Domínios posicionados: %d/%d" % [spawned_count, current_domain_count], "MainGame")

func _step_4_adjust_zoom() -> void:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var base_zoom = GameConfig.get_initial_zoom(current_domain_count)
	camera.zoom = Vector2(base_zoom, base_zoom)
	
	var dot_positions = hex_grid.get_dot_positions()
	if dot_positions.size() > 0:
		var center = Vector2.ZERO
		for pos in dot_positions:
			center += pos
		center /= dot_positions.size()
		camera.global_position = hex_grid.to_global(center)

## === SPAWN DELEGADO PARA SPAWNMANAGER ===

## Callbacks dos sistemas (simplificados)
func _on_unit_created(unit) -> void:
	Logger.debug("Unidade criada via callback", "MainGame")

func _on_domain_created(domain) -> void:
	Logger.debug("Domínio criado via callback", "MainGame")

## Callback para quit request
func _on_quit_request() -> void:
	Logger.info("Quit request recebido, executando cleanup...", "MainGame")
	
	# Cleanup completo de recursos
	ResourceCleanup.cleanup_all_resources()
	
	# Aguardar frames para processamento
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Aceitar quit após cleanup
	get_tree().quit()

## Limpeza
func _exit_tree():
	Logger.info("MainGame _exit_tree chamado", "MainGame")
	
	if game_controller and game_controller.has_method("cleanup"):
		game_controller.cleanup()
	
	# Cleanup de emergência
	ResourceCleanup.emergency_cleanup()
	
	Logger.info("MainGame limpo", "MainGame")

# ================================================================
# SISTEMA DE TESTE DE NOMES
# ================================================================

## Mostrar relatório completo do sistema de nomes
func _show_names_report() -> void:
	if not game_manager:
		print("⚠️ GameManager não disponível")
		return
	
	print("\n🎮 === RELATÓRIO DO SISTEMA DE NOMES V&V ===")
	# Atalhos de teclado removidos conforme solicitado
	
	# Usar o relatório do GameManager
	game_manager.print_names_report()
	
	# Informações adicionais sobre o jogo
	print("\n🎯 Informações do Jogo:")
	print("   • Domínios no mapa: %d" % current_domain_count)
	print("   • Total de domínios criados: %d" % game_manager.get_all_domains().size())
	print("   • Total de unidades criadas: %d" % game_manager.get_all_units().size())
	
	# Exemplo de relacionamento
	var domains = game_manager.get_all_domains()
	var units = game_manager.get_all_units()
	
	if domains.size() > 0 and units.size() > 0:
		print("\n💡 Exemplo de Relacionamento:")
		var example_domain = domains[0]
		var example_unit = null
		
		# Encontrar unidade do primeiro domínio
		for unit in units:
			if unit.get_origin_domain_id() == example_domain.get_domain_id():
				example_unit = unit
				break
		
		if example_unit:
			print("   🏰 Domínio: %s (inicial %s)" % [example_domain.get_domain_name(), example_domain.get_domain_initial()])
			print("   ⚔️ Unidade: %s (inicial %s)" % [example_unit.get_unit_name(), example_unit.get_unit_initial()])
			print("   🔗 Relacionamento: %s" % ("✅ Válido" if example_unit.validate_domain_relationship() else "❌ Inválido"))
	
	print("\n=== FIM DO RELATÓRIO ===\n")
	# Atalhos de teclado removidos conforme solicitado

## Comando de debug para criar domínio e unidade de teste
func _create_test_domain_and_unit() -> void:
	if not game_manager or not hex_grid or not star_mapper:
		print("❌ Sistemas não inicializados")
		return
	
	var dot_positions = hex_grid.get_dot_positions()
	if dot_positions.size() == 0:
		print("❌ Nenhuma estrela disponível")
		return
	
	# Encontrar estrela livre
	var free_star_id = -1
	for i in range(dot_positions.size()):
		var occupied = false
		for domain in game_manager.get_all_domains():
			if domain.get_center_star_id() == i:
				occupied = true
				break
		if not occupied:
			free_star_id = i
			break
	
	if free_star_id == -1:
		print("❌ Nenhuma estrela livre disponível")
		return
	
	# Criar domínio e unidade com nomes
	var result = game_manager.spawn_domain_with_unit_colored(free_star_id, Color.CYAN)
	if result:
		var domain = result.domain
		var unit = result.unit
		print("✅ Criado: Domínio %s e Unidade %s" % [domain.get_domain_name(), unit.get_unit_name()])
	else:
		print("❌ Falha ao criar domínio e unidade de teste")

## Forçar recriação dos labels de nomes
func _recreate_name_labels() -> void:
	if not game_manager:
		print("⚠️ GameManager não disponível")
		return
	
	print("🔄 Recriando labels de nomes...")
	game_manager.recreate_all_name_labels()
	print("✅ Labels de nomes recriados!")
	
	# Mostrar relatório atualizado
	await get_tree().create_timer(0.5).timeout
	_show_names_report()

## Mostrar relatório de poder
func _show_power_report() -> void:
	if not game_manager:
		print("⚠️ GameManager não disponível")
		return
	
	game_manager.print_power_report()

## Produzir poder em todos os domínios (simular turno)
func _produce_power_turn() -> void:
	if not game_manager:
		print("⚠️ GameManager não disponível")
		return
	
	print("🔄 Produzindo poder para todos os domínios...")
	var power_report = game_manager.produce_power_for_all_domains()
	print("✅ Poder produzido!")
	print("   • Total produzido: %d" % power_report.total_produced)
	print("   • Domínios: %d" % power_report.domains_count)
	
	# Mostrar relatório de poder atualizado
	await get_tree().create_timer(0.5).timeout
	_show_power_report()

## Atualizar displays de poder
func _update_power_displays() -> void:
	if not game_manager:
		print("⚠️ GameManager não disponível")
		return
	
	print("🔄 Atualizando displays de poder...")
	game_manager.force_update_power_displays()
	print("✅ Displays atualizados!")
	
	# Mostrar relatório de poder atualizado
	await get_tree().create_timer(0.5).timeout
	_show_power_report()

## Método auxiliar para criar labels de nome (chamado via call_deferred)
func _ensure_labels_created(domain, unit) -> void:
	if not domain or not unit:
		return
	
	# Forçar criação do label do domínio se tem nome mas não tem label
	if domain.has_name() and not domain.name_label:
		domain._create_name_label(self)
	
	# Forçar criação do label da unidade se tem nome mas não tem label
	if unit.has_name() and not unit.name_label:
		unit._create_name_label(self)
	
	Logger.debug("Labels de nome criados para domínio %s e unidade %s" % [domain.get_domain_name(), unit.get_unit_name()], "MainGame")

## Aplicar melhorias estéticas nos labels
func _apply_aesthetic_improvements() -> void:
	if not game_manager:
		print("⚠️ GameManager não disponível")
		return
	
	print("🎨 Aplicando melhorias estéticas...")
	game_manager.apply_aesthetic_improvements()
	print("✅ Melhorias estéticas aplicadas!")
	print("   • Fontes menores: Domínios 10px, Unidades 8px")
	print("   • Unidades mais próximas: 8px de distância")
	print("   • Qualidade melhorada: Renderização nítida")
	
	# Mostrar relatório atualizado
	await get_tree().create_timer(0.5).timeout
	_show_names_report()