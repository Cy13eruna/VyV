# res://src/systems/tasks/Panel.gd
extends CanvasLayer

var is_open: bool = false
var metrics_ref: Node = null

# Lista de biomas sincronizada com o Terrain.gd
const EXPECTED_BIOMES = ["plains", "hills", "woods", "waters"]

var container: Control
var background: ColorRect
var label: RichTextLabel

func _ready() -> void:
	self.layer = 125 
	_find_metrics()
	_build_ui()
	container.hide()

func _find_metrics() -> void:
	metrics_ref = get_tree().get_first_node_in_group("metrics_manager")
	if metrics_ref and metrics_ref.has_signal("data_updated"):
		# Se o dado mudar no Metrics, a UI atualiza automaticamente
		if not metrics_ref.data_updated.is_connected(_update_content):
			metrics_ref.data_updated.connect(_update_content)

func _build_ui() -> void:
	container = Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	
	background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.92) # Um pouco mais escuro para contraste
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 50
	background.offset_top = 50
	background.offset_right = -50
	background.offset_bottom = -50
	container.add_child(background)
	
	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 80
	label.offset_top = 80
	label.offset_right = -80
	label.offset_bottom = -80
	label.scroll_active = true 
	container.add_child(label)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Atalho 'Ç' (unicode 231/199)
		if event.unicode == 231 or event.unicode == 199:
			_toggle_panel()

func _toggle_panel() -> void:
	is_open = !is_open
	container.visible = is_open
	if is_open:
		# Re-checa a referência caso o Metrics tenha sido reiniciado
		if not metrics_ref:
			_find_metrics()
		_update_content()

func _update_content() -> void:
	# Só processa texto se o painel estiver visível para poupar CPU
	if not is_open: return
	
	if not metrics_ref or not "data" in metrics_ref:
		label.text = "[center][color=red]MÉTRICAS INDISPONÍVEIS[/color]\n[font_size=14]O Metrics.gd não foi encontrado ou não está pronto.[/font_size][/center]"
		return
		
	var d = metrics_ref.data
	var t = "[center][b][font_size=32][color=yellow]LIVE MAP STATISTICS[/color][/font_size][/b][/center]\n"
	t += "[center][i]Atalho 'Ç' para fechar[/i][/center]\n\n"
	
	# --- GLOBAL SYSTEM ---
	t += "[b][color=cyan]> WORLD GRAPH DATA[/color][/b]\n"
	t += " • Nodes in Memory: [color=white]%d[/color]\n" % d.global.nodes_memory
	t += " • Edges in Memory: [color=white]%d[/color]\n\n" % d.global.edges_memory
	
	# --- PLAYER SECTION ---
	if d.players.is_empty():
		t += "[center][color=gray][i]Aguardando atividade dos jogadores...[/i][/color][/center]"
	else:
		for p_id in d.players:
			var p = d.players[p_id]
			var p_color = "yellow" if p_id == 0 else "magenta"
			
			t += "[b][color=%s]> PLAYER %d[/color][/b]\n" % [p_color, p_id + 1]
			
			# Distribuição de Domínio
			t += "  [color=#aaaaaa]Domain Biomes:[/color]\n"
			var domain_total = 0
			for biome in EXPECTED_BIOMES:
				var val = p.current_domain_distribution.get(biome, 0)
				t += "    - %s: [color=white]%d[/color]\n" % [biome.capitalize(), val]
				domain_total += val
			t += "  [b]Total Control:[/b] [color=white]%d nodes[/color]\n" % domain_total
			
			t += "\n"
			
			# Histórico de Viagem
			t += "  [color=#aaaaaa]Travel History:[/color]\n"
			var travel_total = 0
			for biome in EXPECTED_BIOMES:
				var val = p.travel_history.get(biome, 0)
				t += "    - %s: [color=white]%d[/color]\n" % [biome.capitalize(), val]
				travel_total += val
			t += "  [b]Total Exploration:[/b] [color=white]%d steps[/color]\n" % travel_total
			t += "[color=gray]------------------------------------[/color]\n\n"
		
	label.text = t