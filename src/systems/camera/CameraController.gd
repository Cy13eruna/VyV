# res://src/systems/camera/CameraController.gd
extends Camera2D

@export var zoom_speed: float = 0.25
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0 
@export var drag_speed: float = 1.0

var is_dragging: bool = false
var is_tweening: bool = false

func _unhandled_input(event: InputEvent) -> void:
	# ZOOM: Roda do mouse
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_set_zoom_level(zoom.x + zoom_speed)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_set_zoom_level(zoom.x - zoom_speed)
		
		# DRAG: Botão do meio ou Direito para arrastar
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			# Se o usuário começar a arrastar, cancelamos qualquer movimento automático em curso
			if is_dragging:
				is_tweening = false

	# MOVIMENTO: Arrastar o mouse
	if event is InputEventMouseMotion and is_dragging:
		# Multiplicamos pela escala do zoom para que o arrasto seja consistente
		position -= event.relative * (1.0 / zoom.x) * drag_speed

func _set_zoom_level(level: float) -> void:
	var new_zoom = clamp(level, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)

## Centraliza a câmera em uma posição global de forma suave.
## Chamado pelo GameHUD quando o menu de upgrade é aberto.
func focus_on_position(target_global_pos: Vector2, duration: float = 0.3) -> void:
	is_tweening = true
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Interpola a posição global para o alvo
	tween.tween_property(self, "global_position", target_global_pos, duration)
	
	# Ao terminar, libera a trava
	tween.finished.connect(func(): is_tweening = false)

## Opcional: Centraliza e aplica um zoom específico
func focus_and_zoom(target_pos: Vector2, target_zoom: float = 1.2) -> void:
	focus_on_position(target_pos)
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var clamped_zoom = clamp(target_zoom, min_zoom, max_zoom)
	tween.tween_property(self, "zoom", Vector2(clamped_zoom, clamped_zoom), 0.3)