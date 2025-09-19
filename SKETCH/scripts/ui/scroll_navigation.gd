## ScrollNavigation - Sistema de navegação com barras de scroll
## Permite navegar pelo tabuleiro quando com zoom ativo

const GameConfig = preload("res://scripts/game_config.gd")

class_name ScrollNavigation
extends Control

## Referências dos componentes UI
@onready var h_scroll: HScrollBar
@onready var v_scroll: VScrollBar

## Referências do sistema
var camera_ref: Camera2D
var hex_grid_ref: Node2D
var config: GameConfig

## Configurações de navegação (vindas do GameConfig)
var scroll_sensitivity: float = 1.0
var smooth_scroll: bool = true
var scroll_speed: float = 5.0

## Estado do sistema
var is_enabled: bool = false
var grid_bounds: Rect2
var viewport_size: Vector2

## Sinais
signal scroll_changed(position: Vector2)

func _ready():
	config = GameConfig.get_instance()
	
	# Aplicar configurações do GameConfig
	scroll_sensitivity = config.scroll_sensitivity
	smooth_scroll = config.smooth_scroll
	
	_setup_scroll_bars()
	_connect_signals()

## Configurar referências do sistema
func setup_references(camera: Camera2D, hex_grid: Node2D) -> void:
	camera_ref = camera
	hex_grid_ref = hex_grid
	_update_grid_bounds()
	_update_scroll_ranges()

## Configurar barras de scroll
func _setup_scroll_bars() -> void:
	# Criar barra horizontal
	h_scroll = HScrollBar.new()
	h_scroll.name = "HorizontalScroll"
	h_scroll.anchors_preset = Control.PRESET_BOTTOM_WIDE
	h_scroll.offset_top = -20
	h_scroll.step = 1.0
	h_scroll.page = 100.0
	add_child(h_scroll)
	
	# Criar barra vertical
	v_scroll = VScrollBar.new()
	v_scroll.name = "VerticalScroll"
	v_scroll.anchors_preset = Control.PRESET_RIGHT_WIDE
	v_scroll.offset_left = -20
	v_scroll.step = 1.0
	v_scroll.page = 100.0
	add_child(v_scroll)
	
	# Inicialmente invisíveis
	h_scroll.visible = false
	v_scroll.visible = false

## Conectar sinais
func _connect_signals() -> void:
	if h_scroll:
		h_scroll.value_changed.connect(_on_h_scroll_changed)
	if v_scroll:
		v_scroll.value_changed.connect(_on_v_scroll_changed)

## Atualizar limites do grid
func _update_grid_bounds() -> void:
	if not hex_grid_ref:
		return
	
	var dot_positions = hex_grid_ref.get_dot_positions()
	if dot_positions.is_empty():
		return
	
	var min_pos = dot_positions[0]
	var max_pos = dot_positions[0]
	
	for pos in dot_positions:
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)
	
	# Adicionar margem
	var margin = 100.0
	grid_bounds = Rect2(
		min_pos - Vector2(margin, margin),
		(max_pos - min_pos) + Vector2(margin * 2, margin * 2)
	)

## Atualizar ranges das barras de scroll
func _update_scroll_ranges() -> void:
	if not camera_ref or not h_scroll or not v_scroll:
		return
	
	viewport_size = get_viewport().get_visible_rect().size
	var zoom = camera_ref.zoom.x
	var visible_area = viewport_size / zoom
	
	# Configurar barra horizontal
	h_scroll.min_value = grid_bounds.position.x
	h_scroll.max_value = grid_bounds.position.x + grid_bounds.size.x - visible_area.x
	h_scroll.page = visible_area.x
	
	# Configurar barra vertical
	v_scroll.min_value = grid_bounds.position.y
	v_scroll.max_value = grid_bounds.position.y + grid_bounds.size.y - visible_area.y
	v_scroll.page = visible_area.y
	
	# Atualizar valores atuais
	_update_scroll_values()

## Atualizar valores das barras baseado na posição da câmera
func _update_scroll_values() -> void:
	if not camera_ref or not h_scroll or not v_scroll:
		return
	
	var camera_pos = camera_ref.global_position
	var zoom = camera_ref.zoom.x
	var visible_area = viewport_size / zoom
	
	# Calcular posição do canto superior esquerdo da área visível
	var top_left = camera_pos - visible_area * 0.5
	
	# Atualizar valores sem triggerar sinais
	h_scroll.set_value_no_signal(top_left.x)
	v_scroll.set_value_no_signal(top_left.y)

## Habilitar/desabilitar sistema de scroll
func set_enabled(enabled: bool) -> void:
	is_enabled = enabled
	
	if h_scroll and v_scroll:
		h_scroll.visible = enabled
		v_scroll.visible = enabled
	
	if enabled:
		_update_grid_bounds()
		_update_scroll_ranges()
	
	EventBus.emit_info("Scroll navigation %s" % ("enabled" if enabled else "disabled"))

## Verificar se deve mostrar barras de scroll baseado no zoom
func update_visibility_based_on_zoom() -> void:
	if not camera_ref or not config.auto_show_scrollbars:
		return
	
	var zoom = camera_ref.zoom.x
	var should_show = zoom >= config.min_zoom_for_scrollbars
	
	if should_show != is_enabled:
		set_enabled(should_show)

## Callback: mudança na barra horizontal
func _on_h_scroll_changed(value: float) -> void:
	if not camera_ref or not is_enabled:
		return
	
	var zoom = camera_ref.zoom.x
	var visible_area = viewport_size / zoom
	var new_camera_x = value + visible_area.x * 0.5
	
	if smooth_scroll:
		var tween = create_tween()
		tween.tween_property(camera_ref, "global_position:x", new_camera_x, 0.1)
	else:
		camera_ref.global_position.x = new_camera_x
	
	scroll_changed.emit(camera_ref.global_position)

## Callback: mudança na barra vertical
func _on_v_scroll_changed(value: float) -> void:
	if not camera_ref or not is_enabled:
		return
	
	var zoom = camera_ref.zoom.x
	var visible_area = viewport_size / zoom
	var new_camera_y = value + visible_area.y * 0.5
	
	if smooth_scroll:
		var tween = create_tween()
		tween.tween_property(camera_ref, "global_position:y", new_camera_y, 0.1)
	else:
		camera_ref.global_position.y = new_camera_y
	
	scroll_changed.emit(camera_ref.global_position)

## Atualizar quando a câmera muda (por outros meios)
func on_camera_moved() -> void:
	if is_enabled:
		_update_scroll_values()

## Atualizar quando o zoom muda
func on_zoom_changed() -> void:
	update_visibility_based_on_zoom()
	if is_enabled:
		_update_scroll_ranges()

## Centralizar câmera no grid
func center_camera() -> void:
	if not camera_ref:
		return
	
	var center = grid_bounds.get_center()
	camera_ref.global_position = center
	
	if is_enabled:
		_update_scroll_values()

## Configurar sensibilidade do scroll
func set_scroll_sensitivity(sensitivity: float) -> void:
	scroll_sensitivity = clamp(sensitivity, 0.1, 5.0)
	
	if h_scroll and v_scroll:
		h_scroll.step = scroll_sensitivity
		v_scroll.step = scroll_sensitivity

## Configurar scroll suave
func set_smooth_scroll(enabled: bool) -> void:
	smooth_scroll = enabled

## Obter informações do sistema
func get_navigation_info() -> Dictionary:
	return {
		"is_enabled": is_enabled,
		"grid_bounds": grid_bounds,
		"viewport_size": viewport_size,
		"scroll_sensitivity": scroll_sensitivity,
		"smooth_scroll": smooth_scroll,
		"h_scroll_range": [h_scroll.min_value, h_scroll.max_value] if h_scroll else [0, 0],
		"v_scroll_range": [v_scroll.min_value, v_scroll.max_value] if v_scroll else [0, 0]
	}