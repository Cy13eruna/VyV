# res://src/entities/Vagabond.gd
extends Node2D

# Propriedades lógicas
var grid_pos: Vector2 
var owner_id: int = -1 
var vagabond_color: Color = Color.WHITE

func setup(p_global_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int) -> void:
	self.owner_id = p_owner_id
	self.grid_pos = p_grid_pos
	self.vagabond_color = p_color
	
	# Sincronização de posição
	self.global_position = p_global_pos
	
	# Garante que as unidades fiquem acima do GridPainter
	z_index = 10 
	
	_create_visuals()
	
	print("Vagabond: P", owner_id, " posicionado em Global: ", global_position)

func _create_visuals() -> void:
	# Limpeza de segurança
	for child in get_children():
		child.queue_free()

	# 1. Emoji do Vagabond (Agora colorido com a cor do jogador)
	var emoji_label = Label.new()
	emoji_label.text = "🚶"
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Usamos modulate para colorir o emoji sem perder os detalhes
	emoji_label.modulate = vagabond_color
	emoji_label.add_theme_font_size_override("font_size", 24)
	emoji_label.position = Vector2(-20, -35) 
	add_child(emoji_label)
	
	# 2. Texto de Identificação (Colorido com a cor do jogador)
	var text_label = Label.new()
	text_label.text = "VAGABOND" # Simplificado para "P0", "P1", etc.
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Aplicando a cor do jogador ao texto
	text_label.add_theme_color_override("font_color", vagabond_color)
	text_label.add_theme_font_size_override("font_size", 14)
	
	# Outline preto para garantir contraste e legibilidade
	text_label.add_theme_constant_override("outline_size", 6)
	text_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Posicionamento logo abaixo do boneco
	text_label.position = Vector2(-20, 0)
	add_child(text_label)

# Feedback visual ao selecionar (Melhorado para ser mais evidente sem a base)
func set_highlight(active: bool) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	if active:
		# Aumenta o brilho e pulsa levemente
		tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
		modulate = Color(1.5, 1.5, 1.5, 1.0) 
	else:
		# Volta ao normal
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
		modulate = Color.WHITE