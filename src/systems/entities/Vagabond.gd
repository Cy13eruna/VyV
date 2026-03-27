# res://src/entities/Vagabond.gd
extends Node2D

# Propriedades lógicas
var grid_pos: Vector2 
var owner_id: int = -1 
var vagabond_color: Color = Color.WHITE

# Sistema de Ação
var ap: int = 1 

func setup(p_global_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int) -> void:
	self.owner_id = p_owner_id
	self.grid_pos = p_grid_pos
	self.vagabond_color = p_color
	self.global_position = p_global_pos
	z_index = 10 
	_create_visuals()

func _create_visuals() -> void:
	for child in get_children():
		child.queue_free()

	var emoji_label = Label.new()
	emoji_label.name = "Emoji"
	emoji_label.text = "🚶"
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_label.modulate = vagabond_color
	emoji_label.add_theme_font_size_override("font_size", 24)
	emoji_label.position = Vector2(-20, -35) 
	add_child(emoji_label)
	
	var text_label = Label.new()
	text_label.name = "IDLabel"
	text_label.text = "VAGABOND"
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_color_override("font_color", vagabond_color)
	text_label.add_theme_font_size_override("font_size", 14)
	text_label.add_theme_constant_override("outline_size", 6)
	text_label.add_theme_color_override("font_outline_color", Color.BLACK)
	text_label.position = Vector2(-20, 0)
	add_child(text_label)

# --- SISTEMA DE AP ---

func has_ap() -> bool:
	return ap > 0

func use_ap() -> bool:
	if has_ap():
		ap -= 1
		_animate_ap_change()
		return true
	return false

func reset_ap() -> void:
	ap = 1
	_animate_ap_change()

func _animate_ap_change() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	if ap > 0:
		tween.tween_property(self, "modulate", Color.WHITE, 0.3)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
	else:
		tween.tween_property(self, "modulate", Color(0.4, 0.4, 0.4, 0.8), 0.4)
		tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.4)

# Feedback visual ao selecionar (VERSÃO CORRIGIDA)
func set_highlight(active: bool) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	
	if active:
		var intensity = 1.5 if ap > 0 else 1.1
		var target_scale = Vector2(1.3, 1.3) if ap > 0 else Vector2(0.95, 0.95)
		
		tween.tween_property(self, "scale", target_scale, 0.1)
		tween.tween_property(self, "modulate", Color(intensity, intensity, intensity, 1.0), 0.1)
	else:
		# Em vez de tentar adivinhar a cor aqui, chamamos o método de animação de AP
		# que já sabe exatamente como a unidade deve estar (escala e cor)
		# Mas primeiro, vamos matar esse tween atual e deixar o _animate fazer o trabalho
		tween.kill() 
		_animate_ap_change()