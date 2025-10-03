# Script para criar texturas com tamanho exato
# 8x8 pixels = 64 pixels × 3 bytes RGB = 192 bytes exatos

extends Node

func _ready():
	create_exact_size_textures()

func create_exact_size_textures():
	print("🎯 Criando texturas com tamanho exato (192 bytes)...")
	
	create_exact_texture("field", Color(0.8, 0.9, 0.8), Color(0.3, 0.6, 0.3))
	create_exact_texture("forest", Color(0.2, 0.4, 0.2), Color(0.1, 0.7, 0.1))
	create_exact_texture("mountain", Color(0.7, 0.7, 0.8), Color(0.4, 0.4, 0.5))
	create_exact_texture("water", Color(0.3, 0.6, 0.8), Color(0.1, 0.4, 0.7))
	
	print("✅ Texturas com tamanho exato criadas!")

func create_exact_texture(name: String, color1: Color, color2: Color):
	print("🎨 Criando %s..." % name)
	
	# Criar exatamente 192 bytes (64 pixels × 3 bytes RGB)
	var data = PackedByteArray()
	
	# 8x8 = 64 pixels
	for i in range(64):
		var color = color1 if (i % 4 < 2) else color2
		
		# Adicionar RGB (3 bytes por pixel)
		data.append(int(color.r * 255))
		data.append(int(color.g * 255))
		data.append(int(color.b * 255))
	
	# Verificar tamanho
	if data.size() != 192:
		print("❌ Erro: tamanho incorreto %d (esperado 192)" % data.size())
		return
	
	# Criar arquivo .tres manualmente
	var content = """[gd_resource type="ImageTexture" format=3]

[sub_resource type="Image" id="Image_1"]
data = {
"data": PackedByteArray(%s),
"format": "RGB8",
"height": 8,
"mipmaps": false,
"width": 8
}

[resource]
image = SubResource("Image_1")""" % _array_to_string(data)
	
	# Salvar arquivo
	var file = FileAccess.open("res://textures/%s/texture.tres" % name, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		print("✅ %s criado com %d bytes" % [name, data.size()])
	else:
		print("❌ Erro ao salvar %s" % name)

func _array_to_string(data: PackedByteArray) -> String:
	var result = ""
	for i in range(data.size()):
		if i > 0:
			result += ", "
		result += str(data[i])
	return result