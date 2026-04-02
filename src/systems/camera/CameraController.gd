# res://src/systems/camera/CameraController.gd
extends Camera2D

@export var zoom_speed: float = 0.15
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0 
@export var drag_speed: float = 1.0

var is_dragging: bool = false
var is_tweening: bool = false
var _target_zoom: float = 1.0

func _ready() -> void:
	_target_zoom = zoom.x

func _unhandled_input(event: InputEvent) -> void:
	# ZOOM: Roda do mouse
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_target_zoom = clamp(_target_zoom + zoom_speed, min_zoom, max_zoom)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_target_zoom = clamp(_target_zoom - zoom_speed, min_zoom, max_zoom)
		
		# DRAG: Botão do meio ou Direito para arrastar
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			# Se o usuário interagir, cancelamos qualquer movimento automático (Tween)
			if is_dragging:
				is_tweening = false

	# MOVIMENTO: Arrastar o mouse
	if event is InputEventMouseMotion and is_dragging:
		# Invertemos o movimento para um feeling de "puxar o mapa"
		# Dividir pelo zoom garante que a velocidade de arrasto seja a mesma em qualquer nível de zoom
		position -= event.relative * (1.0 / zoom.x) * drag_speed

func _process(delta: float) -> void:
	# Suaviza o zoom continuamente para um feeling premium
	if not is_equal_approx(zoom.x, _target_zoom):
		var lerp_zoom = lerp(zoom.x, _target_zoom, 10.0 * delta)
		zoom = Vector2(lerp_zoom, lerp_zoom)

## Centraliza a câmera em uma posição global de forma suave.
## Chamada pelo Main.gd no início de cada turno.
func focus_on_position(target_global_pos: Vector2, duration: float = 0.8) -> void:
	is_tweening = true
	
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	# Interpola a posição global para o alvo
	tween.tween_property(self, "global_position", target_global_pos, duration)
	
	# Opcional: Resetamos o zoom para um nível padrão ao trocar de jogador
	# para que ninguém comece o turno "perdido" com zoom muito alto/baixo
	_target_zoom = 1.0 
	tween.tween_property(self, "zoom", Vector2.ONE, duration)
	
	tween.chain().finished.connect(func(): is_tweening = false)

## Centraliza e aplica um zoom específico (ex: para eventos de combate ou upgrades)
func focus_and_zoom(target_pos: Vector2, target_zoom: float = 1.2) -> void:
	_target_zoom = target_zoom
	focus_on_position(target_pos, 0.5)