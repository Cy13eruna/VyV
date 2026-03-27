# res://src/ui/UIManager.gd
extends Node

var ui_container: CanvasLayer

func setup(p_container: CanvasLayer) -> void:
	ui_container = p_container

## Altera a tela atual e RETORNA a instância criada para o Main poder usar
func change_screen(script_path: String, extra_data: Variant = null) -> Control:
	if not ui_container: 
		push_error("UIManager: ui_container não definido!")
		return null
	
	# 1. Limpa a UI anterior (removendo imediatamente da árvore para evitar conflitos)
	for child in ui_container.get_children():
		ui_container.remove_child(child)
		child.queue_free()
	
	# 2. Carrega e instancia o script
	var res = load(script_path)
	if res and res is GDScript:
		var new_screen = res.new() 
		
		if new_screen is Control:
			# Garante que a tela de fundo não bloqueie a câmera RTS, 
			# mas os botões dentro dela funcionarão.
			new_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
			new_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			
			# Adiciona à árvore ANTES do setup (importante para alguns nós de UI)
			ui_container.add_child(new_screen)
			
			if new_screen.has_method("setup"):
				new_screen.setup(extra_data)
			
			return new_screen # <--- CRUCIAL: Retorna o objeto para o Main.gd
		else:
			push_error("UIManager: O script não herda de Control: " + script_path)
			new_screen.free()
	else:
		push_error("UIManager: Falha ao carregar script de UI em: " + script_path)
	
	return null