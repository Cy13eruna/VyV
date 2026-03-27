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
	
	# Sincronização de posição:
	# Definimos a global_position para garantir que ele ignore deslocamentos do pai
	self.global_position = p_global_pos
	
	# Garante que as unidades fiquem acima do GridPainter
	z_index = 10 
	
	_create_visuals()
	
	print("Vagabond: P", owner_id, " posicionado em Global: ", global_position)

func _create_visuals() -> void:
	# Limpeza de segurança
	for child in get_children():
		child.queue_free()

	# 1. Base Visual (Um círculo para facilitar o clique)
	# Como não temos uma textura, usamos um Polygon2D pequeno como "sombra/base"
	var base = Polygon2D.new()
	var points = []
	for i in range(8):
		var angle = i * (PI / 4.0)
		points.append(Vector2(cos(angle), sin(angle)) * 15.0)
	base.polygon = points
	base.color = vagabond_color
	base.color.a = 0.5 # Semi-transparente
	add_child(base)

	# 2. Emoji do Vagabond
	var emoji_label = Label.new()
	emoji_label.text = "🚶"
	# Centralização absoluta para o clique bater com o visual
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_label.custom_minimum_size = Vector2(40, 40)
	emoji_label.position = Vector2(-20, -35) 
	add_child(emoji_label)
	
	# 3. Texto de Identificação
	var text_label = Label.new()
	# Mostra o ID do player para facilitar o debug de quem é a vez
	text_label.text = "VAGABOND"
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_color_override("font_color", Color.WHITE)
	text_label.add_theme_font_size_override("font_size", 12)
	text_label.add_theme_constant_override("outline_size", 4)
	text_label.add_theme_color_override("font_outline_color", Color.BLACK)
	text_label.position = Vector2(-20, 5)
	add_child(text_label)

# Opcional: Feedback visual ao selecionar
func set_highlight(active: bool) -> void:
	if active:
		modulate = Color(1.5, 1.5, 1.5, 1.0) # Brilho
		scale = Vector2(1.2, 1.2)
	else:
		modulate = Color.WHITE
		scale = Vector2(1.0, 1.0)