#!/usr/bin/env python3
"""
Gerador de texturas VISÍVEIS com padrões distintos
Cria texturas com contraste alto para serem claramente perceptíveis
"""

def create_visible_texture_file(name, base_color, pattern_color, pattern_type):
    # Criar exatamente 64 pixels (192 bytes)
    pixels = []
    
    for y in range(8):
        for x in range(8):
            # Escolher cor baseada no padrão
            if pattern_type == "checkerboard":
                # Padrão xadrez
                use_pattern = (x + y) % 2 == 0
            elif pattern_type == "stripes_h":
                # Listras horizontais
                use_pattern = y % 2 == 0
            elif pattern_type == "stripes_v":
                # Listras verticais
                use_pattern = x % 2 == 0
            elif pattern_type == "dots":
                # Pontos
                use_pattern = (x % 3 == 1) and (y % 3 == 1)
            else:
                use_pattern = False
            
            if use_pattern:
                pixels.extend(pattern_color)
            else:
                pixels.extend(base_color)
    
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
    
    print(f"{name}: {len(pixels)} bytes criados com padrão {pattern_type}")

def main():
    print("Criando texturas VISÍVEIS com padrões distintos...")
    
    # Cores com ALTO CONTRASTE para serem bem visíveis
    textures = {
        "field": {
            "base": (100, 255, 100),      # Verde brilhante
            "pattern": (50, 150, 50),     # Verde escuro
            "type": "checkerboard"        # Xadrez
        },
        "forest": {
            "base": (0, 100, 0),          # Verde muito escuro
            "pattern": (0, 255, 0),       # Verde muito brilhante
            "type": "stripes_v"           # Listras verticais
        },
        "mountain": {
            "base": (150, 150, 150),      # Cinza claro
            "pattern": (50, 50, 50),      # Cinza muito escuro
            "type": "stripes_h"           # Listras horizontais
        },
        "water": {
            "base": (100, 150, 255),      # Azul claro
            "pattern": (0, 50, 150),      # Azul escuro
            "type": "dots"                # Pontos
        }
    }
    
    for name, config in textures.items():
        create_visible_texture_file(
            name, 
            config["base"], 
            config["pattern"], 
            config["type"]
        )
    
    print("Texturas VISÍVEIS criadas!")
    print("Agora as texturas devem ser claramente perceptíveis no jogo!")

if __name__ == "__main__":
    main()