# Script alternativo para criar texturas simples
# Use este se o outro script não funcionar

extends Node

func _ready():
	create_simple_solid_textures()

func create_simple_solid_textures():
	print("🎨 Criando texturas sólidas simples...")
	
	# Criar texturas sólidas de 1x1 pixel que serão esticadas
	create_solid_texture("field", Color(0.6, 0.8, 0.6))    # Verde claro
	create_solid_texture("forest", Color(0.2, 0.5, 0.2))   # Verde escuro
	create_solid_texture("mountain", Color(0.6, 0.6, 0.7)) # Cinza azulado
	create_solid_texture("water", Color(0.3, 0.6, 0.8))    # Azul água
	
	print("🎉 Texturas sólidas criadas!")
	print("🔄 Reinicie o jogo para carregar as novas texturas")

func create_solid_texture(terrain_name: String, color: Color):
	print("🎨 Criando textura sólida: %s" % terrain_name)
	
	# Criar uma imagem 1x1 com a cor sólida
	var image = Image.create(1, 1, false, Image.FORMAT_RGB8)
	image.set_pixel(0, 0, color)
	
	# Criar textura
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	# Salvar
	var path = "res://textures/%s/texture.tres" % terrain_name
	var result = ResourceSaver.save(texture, path)
	
	if result == OK:
		print("✅ Textura %s criada: %s" % [terrain_name, path])
	else:
		print("❌ Erro ao salvar %s: %d" % [terrain_name, result])