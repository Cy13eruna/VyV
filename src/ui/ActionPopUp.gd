# res://src/ui/ActionPopUp.gd

extends CanvasLayer

signal option_selected(action_id: String)
signal cancelled()

@onready var mask: Control = $BackgroundMask
@onready var balloon: PanelContainer = $BalloonContent
@onready var title_label: Label = $BalloonContent/VBox/Title
@onready var subtitle_label: Label = $BalloonContent/VBox/Subtitle
@onready var options_host: HBoxContainer = $BalloonContent/VBox/OptionsContainer

var is_open: bool = false

func _ready() -> void:
	visible = false
	# Clique na máscara (fora do balão) cancela o diálogo
	mask.gui_input.connect(_on_mask_input)

func open(title: String, subtitle: String, options: Array) -> void:
	title_label.text = title
	subtitle_label.text = subtitle
	
	# Limpa opções anteriores
	for child in options_host.get_children():
		child.queue_free()
	
	# Cria os botões circulares com emojis
	for opt in options:
		var btn = _create_option_button(opt.emoji, opt.id)
		options_host.add_child(btn)
	
	# Posicionamento: Balão quadrado com a "ponta" (pivô) no centro
	# Ajustamos o pivot para a base/centro para parecer que nasce do meio
	balloon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	balloon.position.y -= balloon.size.y / 2.0 + 20 # Sobe um pouco para a ponta bater no centro
	
	visible = true
	is_open = true

func _create_option_button(emoji: String, id: String) -> Button:
	var btn = Button.new()
	btn.text = emoji
	btn.custom_minimum_size = Vector2(60, 60)
	
	# Estilização básica para torná-lo circular (via código ou Theme)
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(30)
	style.bg_color = Color.WHITE
	style.border_width_all = 2
	style.border_color = Color.BLACK
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.add_theme_font_size_override("font_size", 32)
	
	btn.pressed.connect(func(): _on_option_clicked(id))
	return btn

func _on_option_clicked(id: String) -> void:
	option_selected.emit(id)
	# O sistema de controle (HUD) decidirá se abre outro pop-up ou fecha este
	close()

func _on_mask_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		cancelled.emit()
		close()

func close() -> void:
	visible = false
	is_open = false