#!/usr/bin/env python3
"""
Gerador de texturas com exatamente 192 bytes
"""

def create_texture_file(name, r, g, b):
    # Criar exatamente 64 pixels (192 bytes)
    pixels = []
    for i in range(64):
        pixels.extend([r, g, b])
    
    # Verificar
    assert len(pixels) == 192, f"Erro: {len(pixels)} bytes"
    
    # Converter para string
    data_str = ", ".join(str(x) for x in pixels)
    
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
    
    # Salvar
    with open(f"SKETCH/textures/{name}/texture.tres", "w") as f:
        f.write(content)
    
    print(f"{name}: {len(pixels)} bytes criados")

def main():
    print("Criando texturas com exatamente 192 bytes...")
    
    # Cores RGB
    textures = {
        "field": (204, 230, 204),
        "forest": (51, 102, 51),
        "mountain": (178, 178, 204),
        "water": (76, 153, 204)
    }
    
    for name, (r, g, b) in textures.items():
        create_texture_file(name, r, g, b)
    
    print("Concluido!")

if __name__ == "__main__":
    main()