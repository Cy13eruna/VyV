# Criador Simples de Texturas V&V
# Execute este script no Godot para gerar texturas básicas

extends Node

const SIZE = 256

func _ready():
	create_simple_textures()

func create_simple_textures():
	print("🎨 Criando texturas simples...")
	
	create_field_texture()
	create_mountain_texture() 
	create_forest_texture()
	create_water_texture()
	
	print("✅ Texturas criadas com sucesso!")

func create_field_texture():
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	
	# Fundo verde claro
	image.fill(Color(0.78, 0.9, 0.78))
	
	# Padrão de pontos (simulando ;)
	var dark_green = Color(0.31, 0.44, 0.31)
	
	for y in range(0, SIZE, 12):
		for x in range(0, SIZE, 10):
			# Adicionar variação
			var offset_x = (randi() % 6) - 3
			var offset_y = (randi() % 6) - 3
			var px = x + offset_x
			var py = y + offset_y
			
			# Desenhar pequeno padrão de ;
			if px >= 0 and px < SIZE-2 and py >= 0 and py < SIZE-4:
				# Ponto superior
				image.set_pixel(px, py, dark_green)
				image.set_pixel(px+1, py, dark_green)
				# Vírgula inferior
				image.set_pixel(px, py+2, dark_green)
				image.set_pixel(px+1, py+3, dark_green)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	# Salvar como recurso
	ResourceSaver.save(texture, "res://textures/field/texture.tres")
	print("✅ Textura de campo criada")

func create_mountain_texture():
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	
	# Fundo cinza azulado
	image.fill(Color(0.71, 0.71, 0.78))
	
	# Padrão de triângulos (simulando ⛰)
	var dark_gray = Color(0.39, 0.39, 0.47)
	
	for y in range(0, SIZE, 20):
		for x in range(0, SIZE, 20):
			var offset_x = (randi() % 8) - 4
			var offset_y = (randi() % 8) - 4
			var px = x + offset_x
			var py = y + offset_y
			
			# Desenhar triângulo simples
			if px >= 0 and px < SIZE-8 and py >= 0 and py < SIZE-8:
				for i in range(8):
					for j in range(i):
						var triangle_x = px + j - i/2
						var triangle_y = py + i
						if triangle_x >= 0 and triangle_x < SIZE and triangle_y >= 0 and triangle_y < SIZE:
							image.set_pixel(triangle_x, triangle_y, dark_gray)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	ResourceSaver.save(texture, "res://textures/mountain/texture.tres")
	print("✅ Textura de montanha criada")

func create_forest_texture():
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	
	# Fundo verde escuro
	image.fill(Color(0.2, 0.39, 0.2))
	
	# Padrão de árvores (simulando 🌳)
	var bright_green = Color(0.12, 0.71, 0.12)
	var brown = Color(0.39, 0.2, 0.08)
	
	for y in range(0, SIZE, 18):
		for x in range(0, SIZE, 18):
			var offset_x = (randi() % 6) - 3
			var offset_y = (randi() % 6) - 3
			var px = x + offset_x
			var py = y + offset_y
			
			# Desenhar árvore simples
			if px >= 0 and px < SIZE-6 and py >= 0 and py < SIZE-8:
				# Copa (círculo)
				for i in range(-3, 4):
					for j in range(-3, 4):
						if i*i + j*j <= 9:  # Círculo
							var tree_x = px + 3 + i
							var tree_y = py + j + 2
							if tree_x >= 0 and tree_x < SIZE and tree_y >= 0 and tree_y < SIZE:
								image.set_pixel(tree_x, tree_y, bright_green)
				
				# Tronco
				for i in range(3):
					var trunk_y = py + 5 + i
					if trunk_y < SIZE:
						image.set_pixel(px + 3, trunk_y, brown)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	ResourceSaver.save(texture, "res://textures/forest/texture.tres")
	print("✅ Textura de floresta criada")

func create_water_texture():
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	
	# Fundo azul água
	image.fill(Color(0.31, 0.59, 0.78))
	
	# Padrão de ondas (simulando 〰)
	var dark_blue = Color(0.12, 0.39, 0.71)
	
	for y in range(0, SIZE, 15):
		for x in range(0, SIZE, 25):
			var offset_x = (randi() % 8) - 4
			var offset_y = (randi() % 8) - 4
			var px = x + offset_x
			var py = y + offset_y
			
			# Desenhar linha ondulada
			if px >= 0 and px < SIZE-20 and py >= 0 and py < SIZE-4:
				for i in range(20):
					var wave_y = int(sin(i * 0.5) * 2)
					var wave_x = px + i
					var wave_py = py + wave_y + 2
					if wave_x < SIZE and wave_py >= 0 and wave_py < SIZE:
						image.set_pixel(wave_x, wave_py, dark_blue)
						# Adicionar espessura
						if wave_py + 1 < SIZE:
							image.set_pixel(wave_x, wave_py + 1, dark_blue)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	ResourceSaver.save(texture, "res://textures/water/texture.tres")
	print("✅ Textura de água criada")