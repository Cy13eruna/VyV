# Script para criar texturas básicas
# Execute este script no Godot para gerar texturas simples

extends Node

func _ready():
	create_basic_textures()

func create_basic_textures():
	print("🎨 Criando texturas básicas...")
	
	# Criar e salvar textura de campo
	create_field_texture()
	
	# Criar e salvar textura de floresta
	create_forest_texture()
	
	# Criar e salvar textura de montanha
	create_mountain_texture()
	
	# Criar e salvar textura de água
	create_water_texture()
	
	print("🎉 Todas as texturas básicas foram criadas!")
	print("🔄 Reinicie o jogo para carregar as novas texturas")

func create_field_texture():
	print("🌾 Criando textura de campo...")
	
	# Criar array de bytes manualmente
	var width = 64
	var height = 64
	var data = PackedByteArray()
	
	# Preencher dados RGB byte por byte
	for y in range(height):
		for x in range(width):
			# Padrão de campo: verde claro com pontos escuros
			var color: Color
			if (x + y) % 8 < 2:  # Padrão de pontos (;)
				color = Color(0.3, 0.6, 0.3)  # Verde escuro
			else:
				color = Color(0.8, 0.9, 0.8)  # Verde claro
			
			# Converter para bytes RGB
			data.append(int(color.r * 255))
			data.append(int(color.g * 255))
			data.append(int(color.b * 255))
	
	# Criar imagem a partir dos dados
	var image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, data)
	
	if image == null:
		print("❌ Falha ao criar imagem de campo")
		return
	
	# Salvar como recurso Godot
	var texture = ImageTexture.new()
	texture.set_image(image)
	var result = ResourceSaver.save(texture, "res://textures/field/texture.tres")
	if result == OK:
		print("✅ Textura de campo criada: texture.tres")
	else:
		print("❌ Erro ao salvar textura de campo: %d" % result)

func create_forest_texture():
	print("🌲 Criando textura de floresta...")
	
	# Criar array de bytes manualmente
	var width = 64
	var height = 64
	var data = PackedByteArray()
	
	# Preencher dados RGB byte por byte
	for y in range(height):
		for x in range(width):
			# Padrão de floresta: verde escuro com árvores
			var color: Color
			if (x % 12 < 6) and (y % 12 < 6):  # Padrão de árvores
				color = Color(0.1, 0.7, 0.1)  # Verde brilhante
			else:
				color = Color(0.2, 0.4, 0.2)  # Verde escuro
			
			# Converter para bytes RGB
			data.append(int(color.r * 255))
			data.append(int(color.g * 255))
			data.append(int(color.b * 255))
	
	# Criar imagem a partir dos dados
	var image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, data)
	
	if image == null:
		print("❌ Falha ao criar imagem de floresta")
		return
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	var result = ResourceSaver.save(texture, "res://textures/forest/texture.tres")
	if result == OK:
		print("✅ Textura de floresta criada: texture.tres")
	else:
		print("❌ Erro ao salvar textura de floresta: %d" % result)

func create_mountain_texture():
	print("⛰️ Criando textura de montanha...")
	
	# Criar array de bytes manualmente
	var width = 64
	var height = 64
	var data = PackedByteArray()
	
	# Preencher dados RGB byte por byte
	for y in range(height):
		for x in range(width):
			# Padrão de montanha: cinza com triângulos
			var color: Color
			if (x + y) % 20 < 10:  # Padrão de montanhas
				color = Color(0.4, 0.4, 0.5)  # Cinza escuro
			else:
				color = Color(0.7, 0.7, 0.8)  # Cinza claro
			
			# Converter para bytes RGB
			data.append(int(color.r * 255))
			data.append(int(color.g * 255))
			data.append(int(color.b * 255))
	
	# Criar imagem a partir dos dados
	var image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, data)
	
	if image == null:
		print("❌ Falha ao criar imagem de montanha")
		return
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	var result = ResourceSaver.save(texture, "res://textures/mountain/texture.tres")
	if result == OK:
		print("✅ Textura de montanha criada: texture.tres")
	else:
		print("❌ Erro ao salvar textura de montanha: %d" % result)

func create_water_texture():
	print("🌊 Criando textura de água...")
	
	# Criar array de bytes manualmente
	var width = 64
	var height = 64
	var data = PackedByteArray()
	
	# Preencher dados RGB byte por byte
	for y in range(height):
		for x in range(width):
			# Padrão de água: azul com ondas
			var color: Color
			if y % 8 < 2:  # Padrão de ondas horizontais
				color = Color(0.1, 0.4, 0.7)  # Azul escuro
			else:
				color = Color(0.3, 0.6, 0.8)  # Azul claro
			
			# Converter para bytes RGB
			data.append(int(color.r * 255))
			data.append(int(color.g * 255))
			data.append(int(color.b * 255))
	
	# Criar imagem a partir dos dados
	var image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, data)
	
	if image == null:
		print("❌ Falha ao criar imagem de água")
		return
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	var result = ResourceSaver.save(texture, "res://textures/water/texture.tres")
	if result == OK:
		print("✅ Textura de água criada: texture.tres")
	else:
		print("❌ Erro ao salvar textura de água: %d" % result)