extends Control

var current_domain: Node2D = null

func _ready() -> void:
	# Configuração básica de ocupação de tela
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Garante que cliques não passem para o mapa
	mouse_filter = Control.MOUSE_FILTER_STOP 

func setup(domain: Node2D) -> void:
	if not is_instance_valid(domain): 
		_close_tree()
		return
	
	current_domain = domain
	
	# Construímos os elementos visuais aqui, pois não temos um .tscn
	_build_ui()
	
	show()
	print("[TechTree] Interface construída para: %s" % domain.name)

func _build_ui() -> void:
	# 1. Fundo Escurecido (Overlay)
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	# 2. Painel Central
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 300)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(panel)
	
	# 3. Conteúdo (VBox)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)
	
	# Título
	var label = Label.new()
	label.text = "TECHNOLOGY TREE\n" + current_domain.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	# Exemplo de Botão de Tecnologia
	var tech_btn = Button.new()
	var cost = int(current_domain.domain_level)
	tech_btn.text = "Unlock Passive Income (Cost: %d)" % cost
	tech_btn.custom_minimum_size = Vector2(0, 50)
	tech_btn.pressed.connect(func(): _on_tech_button_pressed("passive_income"))
	vbox.add_child(tech_btn)
	
	# Botão de Fechar
	var close_btn = Button.new()
	close_btn.text = "CLOSE"
	close_btn.pressed.connect(_on_close_button_pressed)
	vbox.add_child(close_btn)

func unlock_tech(tech_id: String) -> void:
	if not is_instance_valid(current_domain):
		_close_tree()
		return
		
	var cost = int(current_domain.domain_level)
	if current_domain.power < cost:
		print("[TechTree] Poder insuficiente!")
		return

	# Pagamento e Evolução
	if current_domain.has_method("add_power"):
		current_domain.add_power(-cost)
	else:
		current_domain.power -= cost
	
	current_domain.domain_level += 1
	
	# Sinais Globais
	if is_instance_valid(Signals):
		Signals.tech_unlocked.emit(tech_id, current_domain)
		if Signals.has_signal("domain_upgraded"):
			Signals.domain_upgraded.emit(current_domain, current_domain.domain_level)
	
	_close_tree()

func _close_tree() -> void:
	current_domain = null
	
	# Como o NewTech.gd cria um CanvasLayer como pai,
	# precisamos deletar o pai para limpar tudo da tela.
	var parent = get_parent()
	if parent is CanvasLayer:
		parent.queue_free()
	else:
		queue_free()

# --- INPUT ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		accept_event() # Consome o clique para não afetar o mapa

# --- CALLBACKS ---

func _on_tech_button_pressed(id: String) -> void:
	unlock_tech(id)

func _on_close_button_pressed() -> void:
	_close_tree()