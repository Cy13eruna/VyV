# res://src/systems/entities/Vagabond.gd
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
	_update_visual_state(true)

func _create_visuals() -> void:
	for child in get_children():
		child.queue_free()

	# Usamos modulate nos labels para aplicar a cor do jogador
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
	var is_owner = turn_mgr and owner_id == turn_mgr.current_player_index
	var is_lit = grid_pos in lit_nodes
	
	if is_owner:
		visible = true
		_update_visual_state(instant)
		return

	var target_alpha = _get_target_alpha() if is_lit else 0.0
	
	if instant:
		visible = is_lit
		modulate.a = target_alpha
		return

	if is_equal_approx(modulate.a, target_alpha): return

	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if is_lit:
		visible = true
		tween.tween_property(self, "modulate:a", target_alpha, 0.25)
	else:
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		tween.finished.connect(func(): if is_instance_valid(self) and not grid_pos in lit_nodes: visible = false)

# --- SISTEMA DE AP ---

func has_ap() -> bool:
	return ap > 0

func use_ap() -> bool:
	if has_ap():
		ap -= 1
		# Força o reset visual para garantir que saia do estado de highlight
		_update_visual_state()
		return true
	return false

func restore_ap() -> void:
	ap = max_ap
	_update_visual_state()

func _update_visual_state(instant: bool = false) -> void:
	var target_scale = Vector2.ONE
	var target_alpha = _get_target_alpha()
	# Garantimos que a cor base do Node2D seja sempre branca (neutra)
	# para que apenas a transparência e a escala mudem.
	var target_color = Color(1, 1, 1, target_alpha)
	
	if instant:
		scale = target_scale
		modulate = target_color
		return

	# Interrompe qualquer tween anterior para evitar conflitos de highlight/movimento
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.2)
	# Animamos o modulate inteiro para garantir que o brilho (RGB) volte ao normal (1,1,1)
	tween.tween_property(self, "modulate", target_color, 0.2)

func _get_target_alpha() -> float:
	return 1.0 if ap > 0 else 0.5

# --- SELEÇÃO ---

func set_highlight(active: bool) -> void:
	# Trava de AP: se não tem AP, ignoramos e forçamos o estado exaurido
	if not has_ap():
		_update_visual_state()
		return
		
	if not visible or modulate.a < 0.1: 
		return
	
	var target_scale = Vector2(1.1, 1.1) if active else Vector2.ONE
	# IMPORTANTE: Mantemos a cor branca pura (RGB 1,1,1) para não clarear nada
	var target_alpha = _get_target_alpha()
	var target_color = Color(1, 1, 1, target_alpha)
	
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.1)
	tween.tween_property(self, "modulate", target_color, 0.1)