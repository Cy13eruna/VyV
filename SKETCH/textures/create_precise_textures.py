#!/usr/bin/env python3
"""
Criador de texturas com contagem precisa de bytes
Gera exatamente 192 bytes para cada textura 8x8 RGB8
"""

def create_texture_data(r, g, b):
    """Cria dados de textura com exatamente 192 bytes"""
    data = []
    # 8x8 = 64 pixels, cada pixel = 3 bytes RGB = 192 bytes total
    for i in range(64):
        data.extend([r, g, b])
    
    # Verificar tamanho
    assert len(data) == 192, f"Erro: {len(data)} bytes, esperado 192"
    
    return data

def create_tres_file(name, r, g, b):
    """Cria arquivo .tres com dados precisos"""
    data = create_texture_data(r, g, b)
    
    # Converter para string
    data_str = ", ".join(str(x) for x in data)
    
    content = f"""[gd_resource type="ImageTexture" format=3]

[sub_resource type="Image" id="Image_1"]
data = {{
"data": PackedByteArray({data_str}),
"format": "RGB8",
"height": 8,
"mipmaps": false,
"width": 8
}}

[resource]
image = SubResource("Image_1")"""
    
    # Salvar arquivo
    with open(f"SKETCH/textures/{name}/texture.tres", "w") as f:
        f.write(content)
    
    print(f"✅ {name}: {len(data)} bytes criados")

def main():
    print("🎯 Criando texturas com contagem precisa de bytes...")
    
    # Cores para cada terreno (RGB 0-255)
    textures = {
        "field": (204, 230, 204),     # Verde claro
        "forest": (51, 102, 51),      # Verde escuro
        "mountain": (178, 178, 204),  # Cinza azulado
        "water": (76, 153, 204)       # Azul água
    }
    
    for name, (r, g, b) in textures.items():
        create_tres_file(name, r, g, b)
    
    print("🎉 Todas as texturas criadas com exatamente 192 bytes!")

if __name__ == "__main__":
    main()