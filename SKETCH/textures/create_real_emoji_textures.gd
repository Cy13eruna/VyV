# Script para criar texturas com emojis REAIS renderizados
# Execute este script no Godot para gerar texturas com os emojis solicitados

extends Node

func _ready():
	create_real_emoji_textures()

func create_real_emoji_textures():
	print("🎨 Criando texturas com emojis REAIS...")
	
	# Criar texturas com emojis renderizados
	create_emoji_texture("field", "؛", Color(0.7, 0.9, 0.7), Color(0.3, 0.6, 0.3))
	create_emoji_texture("forest", "🌳", Color(0.2, 0.4, 0.2), Color(0.1, 0.7, 0.1))
	create_emoji_texture("mountain", "⛰", Color(0.6, 0.6, 0.7), Color(0.4, 0.4, 0.5))
	create_emoji_texture("water", "〰", Color(0.4, 0.6, 0.8), Color(0.2, 0.4, 0.7))
	
	print("🎉 Texturas com emojis REAIS criadas!")

func create_emoji_texture(terrain_name: String, emoji: String, bg_color: Color, emoji_color: Color):
	print("🎨 Criando textura %s com emoji: %s" % [terrain_name, emoji])
	
	# Criar uma imagem maior para renderizar o emoji
	var render_size = 64
	var image = Image.create(render_size, render_size, false, Image.FORMAT_RGB8)
	image.fill(bg_color)
	
	# Criar um SubViewport para renderizar o emoji
	var viewport = SubViewport.new()
	viewport.size = Vector2i(render_size, render_size)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# Criar um Label para o emoji
	var label = Label.new()
	label.text = emoji
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", emoji_color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(render_size, render_size)
	
	# Adicionar à árvore temporariamente
	add_child(viewport)
	viewport.add_child(label)
	
	# Renderizar
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Capturar a imagem renderizada
	var rendered_image = viewport.get_texture().get_image()
	
	# Redimensionar para 8x8
	rendered_image.resize(8, 8, Image.INTERPOLATE_LANCZOS)
	
	# Criar textura
	var texture = ImageTexture.new()
	texture.set_image(rendered_image)
	
	# Salvar
	var result = ResourceSaver.save(texture, "res://textures/%s/texture.tres" % terrain_name)
	if result == OK:
		print("✅ Textura %s criada com emoji real" % terrain_name)
	else:
		print("❌ Erro ao salvar textura %s: %d" % [terrain_name, result])
	
	# Limpar
	viewport.queue_free()

# Versão alternativa usando Canvas
func create_emoji_texture_canvas(terrain_name: String, emoji: String, bg_color: Color, emoji_color: Color):
	print("🎨 Criando textura %s com emoji (canvas): %s" % [terrain_name, emoji])
	
	# Criar imagem base
	var image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	
	# Preencher com padrão que representa o emoji
	for y in range(8):
		for x in range(8):
			var use_emoji_color = false
			
			match emoji:
				"؛":  # Semicolon - pontos pequenos
					use_emoji_color = (x % 3 == 1) and (y % 3 == 1)
				"🌳":  # Árvore - forma vertical
					use_emoji_color = (x == 3 or x == 4) or (y < 3 and abs(x - 3.5) < 2)
				"⛰":  # Montanha - forma triangular
					use_emoji_color = abs(x - 4) <= (7 - y) and y > 2
				"〰":  # Onda - forma ondulada
					var wave = int(4 + 2 * sin(x * PI / 4))
					use_emoji_color = abs(y - wave) <= 1
			
			if use_emoji_color:
				image.set_pixel(x, y, emoji_color)
			else:
				image.set_pixel(x, y, bg_color)
	
	# Criar textura
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	# Salvar
	var result = ResourceSaver.save(texture, "res://textures/%s/texture.tres" % terrain_name)
	if result == OK:
		print("✅ Textura %s criada com padrão emoji" % terrain_name)
	else:
		print("❌ Erro ao salvar textura %s: %d" % [terrain_name, result])