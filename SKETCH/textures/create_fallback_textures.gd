# Script de fallback para criar texturas básicas
# Método mais robusto usando apenas GDScript

extends Node

func _ready():
	print("🔧 Iniciando criação de texturas de fallback...")
	create_fallback_textures()

func create_fallback_textures():
	# Tentar diferentes métodos até um funcionar
	
	# Método 1: Texturas 4x4 com padrão simples
	if create_small_pattern_textures():
		print("✅ Método 1 funcionou: texturas 4x4")
		return
	
	# Método 2: Texturas 1x1 sólidas
	if create_single_pixel_textures():
		print("✅ Método 2 funcionou: texturas 1x1")
		return
	
	# Método 3: Usar ImageTexture.create_from_image() se disponível
	if create_direct_textures():
		print("✅ Método 3 funcionou: criação direta")
		return
	
	print("❌ Todos os métodos falharam")

func create_small_pattern_textures() -> bool:
	print("🔄 Tentando método 1: texturas 4x4...")
	
	var textures = {
		"field": Color(0.6, 0.8, 0.6),
		"forest": Color(0.2, 0.5, 0.2),
		"mountain": Color(0.6, 0.6, 0.7),
		"water": Color(0.3, 0.6, 0.8)
	}
	
	for terrain_name in textures:
		var color = textures[terrain_name]
		
		# Criar dados para imagem 4x4
		var data = PackedByteArray()
		for i in range(16):  # 4x4 pixels
			data.append(int(color.r * 255))
			data.append(int(color.g * 255))
			data.append(int(color.b * 255))
		
		# Tentar criar imagem
		var image = Image.create_from_data(4, 4, false, Image.FORMAT_RGB8, data)
		if image == null:
			print("❌ Falha no método 1 para %s" % terrain_name)
			return false
		
		# Tentar criar textura
		var texture = ImageTexture.new()
		texture.set_image(image)
		
		# Tentar salvar
		var path = "res://textures/%s/texture.tres" % terrain_name
		var result = ResourceSaver.save(texture, path)
		
		if result != OK:
			print("❌ Falha ao salvar %s: %d" % [terrain_name, result])
			return false
		
		print("✅ Criado %s (4x4)" % terrain_name)
	
	return true

func create_single_pixel_textures() -> bool:
	print("🔄 Tentando método 2: texturas 1x1...")
	
	var textures = {
		"field": Color(0.6, 0.8, 0.6),
		"forest": Color(0.2, 0.5, 0.2),
		"mountain": Color(0.6, 0.6, 0.7),
		"water": Color(0.3, 0.6, 0.8)
	}
	
	for terrain_name in textures:
		var color = textures[terrain_name]
		
		# Criar dados para imagem 1x1
		var data = PackedByteArray()
		data.append(int(color.r * 255))
		data.append(int(color.g * 255))
		data.append(int(color.b * 255))
		
		# Tentar criar imagem
		var image = Image.create_from_data(1, 1, false, Image.FORMAT_RGB8, data)
		if image == null:
			print("❌ Falha no método 2 para %s" % terrain_name)
			return false
		
		# Tentar criar textura
		var texture = ImageTexture.new()
		texture.set_image(image)
		
		# Tentar salvar
		var path = "res://textures/%s/texture.tres" % terrain_name
		var result = ResourceSaver.save(texture, path)
		
		if result != OK:
			print("❌ Falha ao salvar %s: %d" % [terrain_name, result])
			return false
		
		print("✅ Criado %s (1x1)" % terrain_name)
	
	return true

func create_direct_textures() -> bool:
	print("🔄 Tentando método 3: criação direta...")
	
	var textures = {
		"field": Color(0.6, 0.8, 0.6),
		"forest": Color(0.2, 0.5, 0.2),
		"mountain": Color(0.6, 0.6, 0.7),
		"water": Color(0.3, 0.6, 0.8)
	}
	
	for terrain_name in textures:
		var color = textures[terrain_name]
		
		# Tentar criar textura diretamente
		var texture = ImageTexture.new()
		
		# Criar imagem usando método alternativo
		var image = Image.create(2, 2, false, Image.FORMAT_RGB8)
		image.fill(color)
		
		if image == null:
			print("❌ Falha no método 3 para %s" % terrain_name)
			return false
		
		texture.set_image(image)
		
		# Tentar salvar
		var path = "res://textures/%s/texture.tres" % terrain_name
		var result = ResourceSaver.save(texture, path)
		
		if result != OK:
			print("❌ Falha ao salvar %s: %d" % [terrain_name, result])
			return false
		
		print("✅ Criado %s (2x2)" % terrain_name)
	
	return true