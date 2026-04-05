extends "res://src/systems/upgrades/Upgrade.gd"

func _init() -> void:
	id = "new_tech"
	title = "New Tech"
	icon = "🌟"

func get_description(domain: Node2D) -> String:
	var cost = get_cost(domain)
	return "Research new abilities.\nCost: ⭐ %d" % cost

func execute(domain: Node2D) -> void:
	if not is_instance_valid(domain): return
	var layer = CanvasLayer.new()
	layer.name = "TechTreeLayer"
	layer.layer = 125 
	domain.get_tree().root.add_child(layer)

	var tree_ui = TechTreeUI.new()
	layer.add_child(tree_ui)
	tree_ui.setup(domain)

# --- CLASSE INTERNA: TECH TREE ---

class TechTreeUI extends Control:
	var current_domain: Node2D
	var balloon: PanelContainer
	var circle_area: Control # Referência direta para evitar erros de 'null instance'
	var tech_folder = "res://src/systems/upgrades/techs/"
	
	var circle_radius: float = 75.0 
	var tech_buttons: Array[Button] = []

	func setup(domain: Node2D) -> void:
		current_domain = domain
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		var mask = Control.new()
		mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mask.gui_input.connect(func(event): 
			if event is InputEventMouseButton and event.pressed: _close()
		)
		add_child(mask)

		balloon = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color.WHITE
		style.shadow_size = 12
		style.shadow_color = Color(0, 0, 0, 0.25)
		style.set_corner_radius_all(20)
		style.content_margin_left = 25; style.content_margin_right = 25
		style.content_margin_top = 20; style.content_margin_bottom = 25
		balloon.add_theme_stylebox_override("panel", style)
		add_child(balloon)

		var content_vbox = VBoxContainer.new()
		content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		content_vbox.add_theme_constant_override("separation", 5)
		balloon.add_child(content_vbox)
		
		content_vbox.add_child(_create_label("TECH TREE", 18, Color.BLACK))
		content_vbox.add_child(_create_label("Unlocks a New Tech", 12, Color.DIM_GRAY))
		
		var top_gap = Control.new()
		top_gap.custom_minimum_size.y = 35 
		content_vbox.add_child(top_gap)

		circle_area = Control.new()
		circle_area.custom_minimum_size = Vector2(circle_radius * 2.5, circle_radius * 2.5)
		content_vbox.add_child(circle_area)

		_create_tech_list()

		call_deferred("_reposition")

	func _create_tech_list() -> void:
		var techs = [
			["🗡", "Fighter"],
			["🎣", "Fish"],
			["🚩", "Settlers"],
			["🍎", "Harvest"],
			["❤", "Healer"]
		]
		for i in range(techs.size()):
			var btn = _add_tech_option(techs[i][0], techs[i][1])
			tech_buttons.append(btn)

	func _add_tech_option(emoji: String, tech_id: String) -> Button:
		var btn = Button.new()
		btn.text = emoji
		btn.custom_minimum_size = Vector2(55, 55)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color.WHITE
		sb.set_border_width_all(2)
		sb.border_color = Color(0.9, 0.9, 0.9)
		sb.set_corner_radius_all(15)
		
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_color_override("font_color", Color.BLACK)
		btn.add_theme_font_size_override("font_size", 26)
		
		btn.pressed.connect(func(): _open_confirm_dialog(tech_id))
		add_child(btn) 
		return btn

	func _reposition() -> void:
		if not is_instance_valid(circle_area) or not is_instance_valid(balloon):
			return

		var center = get_viewport_rect().size / 2.0
		balloon.size = Vector2.ZERO
		await get_tree().process_frame
		
		balloon.global_position = center - (balloon.size / 2.0)
		
		var circle_center = circle_area.global_position + (circle_area.size / 2.0)
		
		for i in range(tech_buttons.size()):
			var angle = (float(i) / tech_buttons.size()) * TAU - PI/2
			var pos = Vector2(cos(angle), sin(angle)) * circle_radius
			var btn = tech_buttons[i]
			btn.global_position = circle_center + pos - (btn.size / 2.0)

	func _open_confirm_dialog(tech_id: String) -> void:
		var path = tech_folder + tech_id + ".gd"
		if not FileAccess.file_exists(path): return
		
		var tech_script = load(path).new()
		balloon.visible = false
		for b in tech_buttons: b.visible = false
		
		var confirm_balloon = PanelContainer.new()
		confirm_balloon.add_theme_stylebox_override("panel", balloon.get_theme_stylebox("panel"))
		add_child(confirm_balloon)
		
		var cvbox = VBoxContainer.new()
		cvbox.add_theme_constant_override("separation", 15)
		confirm_balloon.add_child(cvbox)
		
		cvbox.add_child(_create_label(tech_script.icon + " " + tech_script.title, 22, Color.BLACK))
		
		var desc = Label.new()
		desc.text = tech_script.description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size.x = 250
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.add_theme_color_override("font_color", Color.DARK_SLATE_GRAY)
		cvbox.add_child(desc)
		
		var cost = int(current_domain.get("domain_level")) if current_domain.get("domain_level") != null else 1
		
		var btn_doit = Button.new()
		btn_doit.text = "RESEARCH (⭐ %d)" % cost
		btn_doit.custom_minimum_size.y = 45
		btn_doit.pressed.connect(func(): _purchase_tech(tech_script, cost))
		cvbox.add_child(btn_doit)
		
		var btn_back = Button.new()
		btn_back.text = "CANCEL"
		btn_back.flat = true
		btn_back.add_theme_color_override("font_color", Color.GRAY)
		btn_back.pressed.connect(func():
			confirm_balloon.queue_free()
			balloon.visible = true
			for b in tech_buttons: b.visible = true
		)
		cvbox.add_child(btn_back)
		
		await get_tree().process_frame
		confirm_balloon.global_position = (get_viewport_rect().size / 2.0) - (confirm_balloon.size / 2.0)

	func _purchase_tech(tech_instance: RefCounted, cost: int) -> void:
		if current_domain.power >= cost:
			if current_domain.has_method("add_power"): current_domain.add_power(-cost)
			else: current_domain.power -= cost
			current_domain.domain_level += 1
			tech_instance.execute(current_domain)
			_close()

	func _create_label(txt: String, size: int, color: Color) -> Label:
		var l = Label.new()
		l.text = txt
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", color)
		l.add_theme_font_size_override("font_size", size)
		return l

	func _close() -> void:
		get_parent().queue_free()