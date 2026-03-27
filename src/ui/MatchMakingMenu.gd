# res://src/ui/MatchMakingMenu.gd
extends Control

signal match_requested(player_count: int)

const OPTIONS = {
	2: 9,
	3: 11,
	4: 13,
	6: 15
}

func setup(_p_data: Dictionary) -> void:
	# Importante: O menu precisa bloquear o mouse para o fundo não ser "transparente" ao clique
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()

func _build_interface() -> void:
	# 1. Adiciona o Fundo Preto Sólido
	var bg = ColorRect.new()
	bg.name = "BackgroundBlack"
	bg.color = Color.BLACK
	# Faz o retângulo ocupar a tela inteira
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 2. Container dos Botões
	var vbox = VBoxContainer.new()
	vbox.name = "ButtonContainer"
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	# Centraliza o container na tela
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER) 
	# Garante que os botões fiquem centralizados em relação ao container
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	
	for key in OPTIONS.keys():
		var btn = Button.new()
		btn.text = str(key) # Apenas o número, como solicitado
		btn.custom_minimum_size = Vector2(150, 45)
		btn.pressed.connect(_on_option_selected.bind(key))
		vbox.add_child(btn)

func _on_option_selected(player_count: int) -> void:
	# 1. Emitimos o sinal para o Main agir
	match_requested.emit(player_count)
	
	# 2. Verificação de segurança: Só tenta acessar a árvore se ainda estiver nela
	if is_inside_tree():
		var v_port = get_viewport()
		if v_port:
			var focus_owner = v_port.get_focused_control() # Versão Godot 4+
			if focus_owner:
				focus_owner.release_focus()
	
	# 3. Se deleta
	queue_free()