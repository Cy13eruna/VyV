# Script simples para criar texturas com emojis
# Execute este script no Godot

extends Node

func _ready():
	create_emoji_textures_simple()

func create_emoji_textures_simple():
	print("🎨 Criando texturas com emojis específicos...")
	
	# Usar método direto com padrões que representam os emojis solicitados
	create_semicolon_texture()  # ؛ para campo
	create_tree_texture()       # 🌳 para floresta  
	create_mountain_texture()   # ⛰ para montanha
	create_wave_texture()       # 〰 para água
	
	print("🎉 Texturas com emojis específicos criadas!")

func create_semicolon_texture():
	print("🌾 Criando textura de campo com semicolons (؛)...")
	
	var image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	var bg_color = Color(0.7, 0.9, 0.7)      # Verde claro
	var semicolon_color = Color(0.3, 0.6, 0.3)  # Verde escuro
	
	# Padrão de semicolons espalhados
	var semicolon_positions = [
		[1, 1], [1, 2],  # Primeiro semicolon
		[4, 1], [4, 2],  # Segundo semicolon
		[6, 4], [6, 5],  # Terceiro semicolon
		[2, 6], [2, 7],  # Quarto semicolon
		[5, 6], [5, 7]   # Quinto semicolon
	]
	
	# Preencher fundo
	image.fill(bg_color)
	
	# Adicionar semicolons
	for pos in semicolon_positions:
		if pos[0] < 8 and pos[1] < 8:
			image.set_pixel(pos[0], pos[1], semicolon_color)
	
	save_texture(image, "field", "semicolons")

func create_tree_texture():
	print("🌲 Criando textura de floresta com árvores (🌳)...")
	
	var image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	var bg_color = Color(0.2, 0.4, 0.2)      # Verde escuro
	var tree_color = Color(0.1, 0.7, 0.1)    # Verde brilhante
	
	# Padrão de árvores
	image.fill(bg_color)
	
	# Árvore 1 (esquerda)
	image.set_pixel(1, 5, tree_color)  # Tronco
	image.set_pixel(1, 6, tree_color)  # Tronco
	image.set_pixel(0, 3, tree_color)  # Copa
	image.set_pixel(1, 3, tree_color)  # Copa
	image.set_pixel(2, 3, tree_color)  # Copa
	image.set_pixel(1, 4, tree_color)  # Copa
	
	# Árvore 2 (centro)
	image.set_pixel(4, 5, tree_color)  # Tronco
	image.set_pixel(4, 6, tree_color)  # Tronco
	image.set_pixel(3, 2, tree_color)  # Copa
	image.set_pixel(4, 2, tree_color)  # Copa
	image.set_pixel(5, 2, tree_color)  # Copa
	image.set_pixel(4, 3, tree_color)  # Copa
	image.set_pixel(4, 4, tree_color)  # Copa
	
	# Árvore 3 (direita)
	image.set_pixel(6, 6, tree_color)  # Tronco
	image.set_pixel(6, 7, tree_color)  # Tronco
	image.set_pixel(5, 4, tree_color)  # Copa
	image.set_pixel(6, 4, tree_color)  # Copa
	image.set_pixel(7, 4, tree_color)  # Copa
	image.set_pixel(6, 5, tree_color)  # Copa
	
	save_texture(image, "forest", "árvores")

func create_mountain_texture():
	print("⛰️ Criando textura de montanha com montanhas (⛰)...")
	
	var image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	var bg_color = Color(0.6, 0.6, 0.7)      # Cinza azulado
	var mountain_color = Color(0.4, 0.4, 0.5)  # Cinza escuro
	
	# Padrão de montanhas
	image.fill(bg_color)
	
	# Montanha principal (centro)
	image.set_pixel(3, 2, mountain_color)  # Pico
	image.set_pixel(2, 3, mountain_color)  # Lado esquerdo
	image.set_pixel(3, 3, mountain_color)  # Centro
	image.set_pixel(4, 3, mountain_color)  # Lado direito
	image.set_pixel(1, 4, mountain_color)  # Base esquerda
	image.set_pixel(2, 4, mountain_color)  # Base
	image.set_pixel(3, 4, mountain_color)  # Base
	image.set_pixel(4, 4, mountain_color)  # Base
	image.set_pixel(5, 4, mountain_color)  # Base direita
	
	# Montanha menor (esquerda)
	image.set_pixel(1, 3, mountain_color)  # Pico
	image.set_pixel(0, 4, mountain_color)  # Base
	image.set_pixel(1, 4, mountain_color)  # Base
	
	# Montanha menor (direita)
	image.set_pixel(6, 3, mountain_color)  # Pico
	image.set_pixel(5, 4, mountain_color)  # Base
	image.set_pixel(6, 4, mountain_color)  # Base
	image.set_pixel(7, 4, mountain_color)  # Base
	
	save_texture(image, "mountain", "montanhas")

func create_wave_texture():
	print("🌊 Criando textura de água com ondas (〰)...")
	
	var image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	var bg_color = Color(0.4, 0.6, 0.8)      # Azul claro
	var wave_color = Color(0.2, 0.4, 0.7)    # Azul escuro
	
	# Padrão de ondas
	image.fill(bg_color)
	
	# Onda 1 (superior)
	image.set_pixel(0, 2, wave_color)
	image.set_pixel(1, 1, wave_color)
	image.set_pixel(2, 1, wave_color)
	image.set_pixel(3, 2, wave_color)
	image.set_pixel(4, 2, wave_color)
	image.set_pixel(5, 1, wave_color)
	image.set_pixel(6, 1, wave_color)
	image.set_pixel(7, 2, wave_color)
	
	# Onda 2 (meio)
	image.set_pixel(0, 4, wave_color)
	image.set_pixel(1, 3, wave_color)
	image.set_pixel(2, 4, wave_color)
	image.set_pixel(3, 4, wave_color)
	image.set_pixel(4, 3, wave_color)
	image.set_pixel(5, 4, wave_color)
	image.set_pixel(6, 4, wave_color)
	image.set_pixel(7, 3, wave_color)
	
	# Onda 3 (inferior)
	image.set_pixel(0, 6, wave_color)
	image.set_pixel(1, 5, wave_color)
	image.set_pixel(2, 5, wave_color)
	image.set_pixel(3, 6, wave_color)
	image.set_pixel(4, 6, wave_color)
	image.set_pixel(5, 5, wave_color)
	image.set_pixel(6, 6, wave_color)
	image.set_pixel(7, 6, wave_color)
	
	save_texture(image, "water", "ondas")

func save_texture(image: Image, terrain_name: String, description: String):
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	var result = ResourceSaver.save(texture, "res://textures/%s/texture.tres" % terrain_name)
	if result == OK:
		print("✅ Textura %s criada com %s" % [terrain_name, description])
	else:
		print("❌ Erro ao salvar textura %s: %d" % [terrain_name, result])