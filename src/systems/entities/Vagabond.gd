# res://src/systems/entities/Vagabond.gd
extends "res://src/systems/entities/MapEntity.gd"

class_name Vagabond

signal action_points_changed(current_ap: int, max_ap: int)
signal exhaustion_triggered()

# --- PROPRIEDADES DE ATRIBUTOS ---

@export var max_ap: int = 1
@export var ap: int = 1:
	set(v):
		ap = clamp(v, 0, max_ap)
		action_points_changed.emit(ap, max_ap)
		if ap == 0: 
			exhaustion_triggered.emit()
		# Chamamos sem 'instant' para vermos a transição suave
		_update_visual_state()

@export var move_range: int = 4 

var _is_highlighted: bool = false

# --- CICLO DE VIDA ---

func setup(p_global_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int) -> void:
	super.setup(p_global_pos, p_grid_pos, p_color, p_owner_id)
	self.z_index = 10 
	
	# Criamos os nós primeiro
	_create_visuals()
	# Forçamos o estado inicial (transparente se começar com 0 AP)
	_update_visual_state(true)

func _apply_visuals() -> void:
	_create_visuals()
	_update_visual_state(true)

func _create_visuals() -> void:
	# Limpeza rigorosa para evitar fantasmas visuais
	var old_view = get_node_or_null("View")
	if old_view:
		old_view.name = "OldView"
		old_view.queue_free()

	var view = Marker2D.new()
	view.name = "View"
	add_child(view)

	var emoji = Label.new()
	emoji.name = "Emoji"
	emoji.text = "🚶‍♀️" 
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji.modulate = entity_color 
	emoji.add_theme_font_size_override("font_size", 28)
	emoji.position = Vector2(-20, -40) 
	view.add_child(emoji)
	
	var label = Label.new()
	label.name = "IDLabel"
	label.text = "VAGABOND"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", entity_color)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.position = Vector2(-25, 0)
	view.add_child(label)

# --- FEEDBACKS VISUAIS (O CORAÇÃO DO PROBLEMA) ---

func _update_visual_state(instant: bool = false) -> void:
	var view = get_node_or_null("View")
	if not view: return

	# 1. Definimos os alvos de visual
	var target_scale = Vector2(1.25, 1.25) if _is_highlighted else Vector2.ONE
	
	# Se ap == 0, fica transparente (40% opacidade)
	var target_alpha = 1.0 if ap > 0 else 0.7
	
	# 2. Aplicamos
	if instant:
		view.scale = target_scale
		view.modulate.a = target_alpha
	else:
		# Se houver um tween rodando nesta propriedade, o novo o substituirá
		var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT)
		
		# Feedback de Seleção
		tween.tween_property(view, "scale", target_scale, 0.2).set_trans(Tween.TRANS_QUAD)
		
		# Feedback de Exaustão (Alpha)
		# Nota: Modulamos a 'view' inteira para afetar Emoji e Label simultaneamente
		tween.tween_property(view, "modulate:a", target_alpha, 0.25)

# --- RESTO DA LÓGICA ---

func use_ap() -> bool:
	if has_ap():
		ap -= 1 # O setter cuidará do _update_visual_state()
		_play_action_animation()
		return true
	return false

func restore_ap() -> void:
	ap = max_ap # O setter cuidará do visual

func set_highlight(active: bool) -> void:
	_is_highlighted = active
	_update_visual_state()

func _play_action_animation() -> void:
	var view = get_node_or_null("View")
	if view:
		var jump = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		jump.tween_property(view, "position:y", -15, 0.1)
		jump.chain().tween_property(view, "position:y", 0, 0.1)

# Sistema de FOW herdado e simplificado
func update_fow_visibility(lit_nodes: Array, instant: bool = false) -> void:
	var is_lit = self.grid_pos in lit_nodes
	var target_alpha = 1.0 if is_lit else 0.0
	
	if instant:
		self.modulate.a = target_alpha
		self.visible = is_lit
	else:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", target_alpha, 0.3)
		if is_lit: self.visible = true
		else: tween.finished.connect(func(): if is_instance_valid(self): self.visible = false)

func has_ap() -> bool:
	return ap > 0