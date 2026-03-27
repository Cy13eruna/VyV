extends Camera2D

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.2
@export var max_zoom: float = 4.0  # Aumentei um pouco para mapas grandes
@export var drag_speed: float = 1.0

var is_dragging: bool = false

# IMPORTANTE: Mudamos de _input para _unhandled_input
# Isso faz a câmera ignorar cliques que aconteceram em cima de botões da UI.
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

	# MOVIMENTO: Arrastar o mouse
	if event is InputEventMouseMotion and is_dragging:
		# Multiplicamos pela escala do zoom para que o arrasto seja consistente
		position -= event.relative * (1.0 / zoom.x) * drag_speed

func _set_zoom_level(level: float) -> void:
	var new_zoom = clamp(level, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)