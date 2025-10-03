# Gerador de Texturas para V&V
# Este script gera texturas baseadas em caracteres/emojis

extends Node

const TEXTURE_SIZE = 256
const FONT_SIZE = 24

func _ready():
	generate_all_textures()

func generate_all_textures():
	print("🎨 Gerando texturas...")
	
	# Gerar textura de campo (ponto-e-vírgulas de cabeça para baixo)
	generate_field_texture()
	
	# Gerar textura de montanha (⛰)
	generate_mountain_texture()
	
	# Gerar textura de floresta (🌳)
	generate_forest_texture()
	
	# Gerar textura de água (〰)
	generate_water_texture()
	
	print("✅ Todas as texturas foram geradas!")

func generate_field_texture():
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.9, 0.8, 1.0))  # Fundo verde claro
	
	# Adicionar ponto-e-vírgulas de cabeça para baixo (;) rotacionados
	var font = ThemeDB.fallback_font
	if font:
		for y in range(0, TEXTURE_SIZE, 20):
			for x in range(0, TEXTURE_SIZE, 15):
				# Adicionar variação aleatória na posição
				var offset_x = randi() % 10 - 5
				var offset_y = randi() % 10 - 5
				var pos_x = x + offset_x
				var pos_y = y + offset_y
				
				# Desenhar ; rotacionado (de cabeça para baixo)
				if pos_x >= 0 and pos_x < TEXTURE_SIZE and pos_y >= 0 and pos_y < TEXTURE_SIZE:
					# Simular desenho de ; invertido usando pixels
					_draw_inverted_semicolon(image, pos_x, pos_y)
	
	image.save_png("res://textures/field/texture.png")
	print("✅ Textura de campo gerada")

func generate_mountain_texture():
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.7, 0.7, 0.8, 1.0))  # Fundo cinza azulado
	
	# Adicionar montanhas ⛰ bem juntinhas
	for y in range(0, TEXTURE_SIZE, 25):
		for x in range(0, TEXTURE_SIZE, 25):
			var offset_x = randi() % 8 - 4
			var offset_y = randi() % 8 - 4
			var pos_x = x + offset_x
			var pos_y = y + offset_y
			
			if pos_x >= 0 and pos_x < TEXTURE_SIZE and pos_y >= 0 and pos_y < TEXTURE_SIZE:
				_draw_mountain_symbol(image, pos_x, pos_y)
	
	image.save_png("res://textures/mountain/texture.png")
	print("✅ Textura de montanha gerada")

func generate_forest_texture():
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.4, 0.2, 1.0))  # Fundo verde escuro
	
	# Adicionar árvores 🌳 bem juntinhas
	for y in range(0, TEXTURE_SIZE, 22):
		for x in range(0, TEXTURE_SIZE, 22):
			var offset_x = randi() % 6 - 3
			var offset_y = randi() % 6 - 3
			var pos_x = x + offset_x
			var pos_y = y + offset_y
			
			if pos_x >= 0 and pos_x < TEXTURE_SIZE and pos_y >= 0 and pos_y < TEXTURE_SIZE:
				_draw_tree_symbol(image, pos_x, pos_y)
	
	image.save_png("res://textures/forest/texture.png")
	print("✅ Textura de floresta gerada")

func generate_water_texture():
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.3, 0.6, 0.8, 1.0))  # Fundo azul água
	
	# Adicionar ondas 〰 bem juntinhas
	for y in range(0, TEXTURE_SIZE, 18):
		for x in range(0, TEXTURE_SIZE, 30):
			var offset_x = randi() % 8 - 4
			var offset_y = randi() % 8 - 4
			var pos_x = x + offset_x
			var pos_y = y + offset_y
			
			if pos_x >= 0 and pos_x < TEXTURE_SIZE and pos_y >= 0 and pos_y < TEXTURE_SIZE:
				_draw_wave_symbol(image, pos_x, pos_y)
	
	image.save_png("res://textures/water/texture.png")
	print("✅ Textura de água gerada")

# Desenhar ponto-e-vírgula invertido usando pixels
func _draw_inverted_semicolon(image: Image, x: int, y: int):
	var color = Color(0.3, 0.6, 0.3, 1.0)  # Verde escuro
	
	# Desenhar vírgula (parte de baixo do ; invertido)
	for i in range(3):
		for j in range(2):
			if x + i < TEXTURE_SIZE and y + j < TEXTURE_SIZE:
				image.set_pixel(x + i, y + j, color)
	
	# Desenhar ponto (parte de cima do ; invertido)
	for i in range(2):
		for j in range(2):
			if x + i < TEXTURE_SIZE and y + j + 4 < TEXTURE_SIZE:
				image.set_pixel(x + i, y + j + 4, color)

# Desenhar símbolo de montanha usando pixels
func _draw_mountain_symbol(image: Image, x: int, y: int):
	var color = Color(0.4, 0.4, 0.5, 1.0)  # Cinza escuro
	
	# Desenhar triângulo simples para representar montanha
	for i in range(12):
		for j in range(i):
			if x + j - i/2 >= 0 and x + j - i/2 < TEXTURE_SIZE and y + i < TEXTURE_SIZE:
				image.set_pixel(x + j - i/2, y + i, color)

# Desenhar símbolo de árvore usando pixels
func _draw_tree_symbol(image: Image, x: int, y: int):
	var green = Color(0.1, 0.7, 0.1, 1.0)  # Verde brilhante
	var brown = Color(0.4, 0.2, 0.1, 1.0)  # Marrom
	
	# Desenhar copa da árvore (círculo)
	for i in range(-4, 5):
		for j in range(-4, 5):
			if i*i + j*j <= 16:  # Círculo
				if x + i >= 0 and x + i < TEXTURE_SIZE and y + j >= 0 and y + j < TEXTURE_SIZE:
					image.set_pixel(x + i, y + j, green)
	
	# Desenhar tronco
	for i in range(3):
		if x >= 0 and x < TEXTURE_SIZE and y + 5 + i < TEXTURE_SIZE:
			image.set_pixel(x, y + 5 + i, brown)

# Desenhar símbolo de onda usando pixels
func _draw_wave_symbol(image: Image, x: int, y: int):
	var color = Color(0.1, 0.4, 0.7, 1.0)  # Azul escuro
	
	# Desenhar linha ondulada
	for i in range(20):
		var wave_y = int(sin(i * 0.5) * 2)
		if x + i < TEXTURE_SIZE and y + wave_y >= 0 and y + wave_y < TEXTURE_SIZE:
			image.set_pixel(x + i, y + wave_y, color)
			# Adicionar espessura
			if y + wave_y + 1 < TEXTURE_SIZE:
				image.set_pixel(x + i, y + wave_y + 1, color)