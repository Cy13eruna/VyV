## Teste rápido das barras de scroll
extends Control

var h_scroll: HScrollBar
var v_scroll: VScrollBar

func _ready():
	# Criar barra horizontal
	h_scroll = HScrollBar.new()
	h_scroll.anchors_preset = Control.PRESET_BOTTOM_WIDE
	h_scroll.offset_top = -30
	h_scroll.offset_bottom = -10
	h_scroll.min_value = 0
	h_scroll.max_value = 100
	h_scroll.value = 50
	h_scroll.modulate = Color.RED  # Vermelho para debug
	add_child(h_scroll)
	
	# Criar barra vertical
	v_scroll = VScrollBar.new()
	v_scroll.anchors_preset = Control.PRESET_RIGHT_WIDE
	v_scroll.offset_left = -30
	v_scroll.offset_right = -10
	v_scroll.min_value = 0
	v_scroll.max_value = 100
	v_scroll.value = 50
	v_scroll.modulate = Color.BLUE  # Azul para debug
	add_child(v_scroll)
	
	print("Barras de scroll criadas - H: ", h_scroll.visible, " V: ", v_scroll.visible)