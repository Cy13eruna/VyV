# res://src/entities/Vagabond.gd
extends Node2D

# Propriedades lógicas
var grid_pos: Vector2 
var owner_id: int = -1 
var vagabond_color: Color = Color.WHITE

# Sistema de Ação
var max_ap: int = 1
var ap: int = 1 

func setup(p_global_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int) -> void:
	self.owner_id = p_owner_id
	self.grid_pos = p_grid_pos
	self.vagabond_color = p_color
	self.global_position = p_global_pos
	z_index = 10 
	_create_visuals()
	_animate_ap_change()

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

# --- SISTEMA DE VISIBILIDADE (FOG OF WAR) ---

func update_fow_visibility(lit_nodes: Array, instant: bool = false) -> void:
	var turn_mgr = get_tree().root.get_node_or_null("Main/TurnManager")
	if turn_mgr and owner_id == turn_mgr.current_player_index:
		visible = true
		modulate.a = 1.0
		return

	var is_lit = grid_pos in lit_nodes
	var target_alpha = 1.0 if is_lit else 0.0
	
	if instant:
		visible = is_lit
		modulate.a = target_alpha
		return

	if is_equal_approx(modulate.a, target_alpha):
		return

	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if is_lit:
		visible = true
		tween.tween_property(self, "modulate:a", 1.0, 0.25)
	else:
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		await tween.finished
		if is_instance_valid(self) and not grid_pos in lit_nodes:
			visible = false

# --- SISTEMA DE AP ---

func has_ap() -> bool:
	return ap > 0

func use_ap() -> bool:
	if has_ap():
		ap -= 1
		_animate_ap_change()
		return true
	return false

func restore_ap() -> void:
	ap = max_ap
	_animate_ap_change()

func _animate_ap_change() -> void:
	var target_scale: Vector2 = Vector2(1.0, 1.0) if ap > 0 else Vector2(0.85, 0.85)
	var target_color: Color = Color.WHITE if ap > 0 else Color(0.3, 0.3, 0.3, 0.7)
	target_color.a = modulate.a 

	if scale.is_equal_approx(target_scale) and modulate.is_equal_approx(target_color):
		return

	# Limpa tweens antigos para este objeto antes de criar um novo
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.3)
	tween.tween_property(self, "modulate", target_color, 0.3)

func set_highlight(active: bool) -> void:
	if not visible or modulate.a < 0.1: return
	
	if active:
		var intensity = 1.5 if ap > 0 else 1.1
		var target_scale = Vector2(1.2, 1.2) if ap > 0 else Vector2(0.9, 0.9)
		var flash_color = Color(intensity, intensity, intensity, modulate.a)
		
		# Verificação de redundância para evitar tween vazio no highlight
		if scale.is_equal_approx(target_scale) and modulate.is_equal_approx(flash_color):
			return

		var tween = create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", target_scale, 0.1)
		tween.tween_property(self, "modulate", flash_color, 0.1)
	else:
		_animate_ap_change()