#!/usr/bin/env python3
"""
Criador de texturas PURAS com apenas os emojis solicitados
Remove completamente padrões geométricos
"""

def create_pure_emoji_texture(name, emoji_positions, emoji_color, bg_color):
    # Criar exatamente 64 pixels (192 bytes)
    pixels = []
    
    # Criar grid 8x8 com fundo
    grid = [[bg_color for _ in range(8)] for _ in range(8)]
    
    # Colocar emojis apenas nas posições especificadas
    for pos in emoji_positions:
        x, y = pos
        if 0 <= x < 8 and 0 <= y < 8:
            grid[y][x] = emoji_color
    
    # Converter grid para pixels
    for y in range(8):
        for x in range(8):
            pixels.extend(grid[y][x])
    
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
    
    print(f"{name}: {len(pixels)} bytes criados - APENAS emoji, sem padrões")

def main():
    print("APAGANDO padrões geométricos e criando APENAS emojis...")
    
    # Cores de fundo neutras
    bg_field = (240, 250, 240)      # Fundo muito claro
    bg_forest = (240, 250, 240)     # Fundo muito claro
    bg_mountain = (240, 250, 240)   # Fundo muito claro
    bg_water = (240, 250, 240)      # Fundo muito claro
    
    # Cores dos emojis (bem visíveis)
    emoji_field = (0, 0, 0)         # Preto para semicolons
    emoji_forest = (0, 100, 0)      # Verde escuro para árvores
    emoji_mountain = (100, 100, 100) # Cinza para montanhas
    emoji_water = (0, 0, 150)       # Azul escuro para ondas
    
    # CAMPO: Apenas semicolons (؛) nas posições específicas
    semicolon_positions = [
        (2, 2), (2, 3),  # Semicolon 1
        (5, 2), (5, 3),  # Semicolon 2
        (1, 5), (1, 6),  # Semicolon 3
        (6, 5), (6, 6)   # Semicolon 4
    ]
    
    # FLORESTA: Apenas árvores (🌳) nas posições específicas
    tree_positions = [
        (1, 6), (1, 5), (1, 4), (0, 3), (1, 3), (2, 3),  # Árvore 1
        (4, 6), (4, 5), (4, 4), (3, 2), (4, 2), (5, 2),  # Árvore 2
        (6, 7), (6, 6), (6, 5), (5, 4), (6, 4), (7, 4)   # Árvore 3
    ]
    
    # MONTANHA: Apenas montanhas (⛰) nas posições específicas
    mountain_positions = [
        (3, 1),                                    # Pico principal
        (2, 2), (3, 2), (4, 2),                   # Meio
        (1, 3), (2, 3), (3, 3), (4, 3), (5, 3),  # Base
        (0, 4), (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4)  # Chão
    ]
    
    # ÁGUA: Apenas ondas (〰) nas posições específicas
    wave_positions = [
        (0, 2), (1, 1), (2, 1), (3, 2), (4, 2), (5, 1), (6, 1), (7, 2),  # Onda 1
        (0, 4), (1, 3), (2, 4), (3, 4), (4, 3), (5, 4), (6, 4), (7, 3),  # Onda 2
        (0, 6), (1, 5), (2, 5), (3, 6), (4, 6), (5, 5), (6, 6), (7, 6)   # Onda 3
    ]
    
    # Criar texturas PURAS (sem padrões geométricos)
    create_pure_emoji_texture("field", semicolon_positions, emoji_field, bg_field)
    create_pure_emoji_texture("forest", tree_positions, emoji_forest, bg_forest)
    create_pure_emoji_texture("mountain", mountain_positions, emoji_mountain, bg_mountain)
    create_pure_emoji_texture("water", wave_positions, emoji_water, bg_water)
    
    print("CONCLUÍDO: Padrões geométricos APAGADOS!")
    print("Agora há APENAS os emojis que você solicitou:")
    print("- Campo: APENAS semicolons (؛)")
    print("- Floresta: APENAS árvores (🌳)")
    print("- Montanha: APENAS montanhas (⛰)")
    print("- Água: APENAS ondas (〰)")
    print("SEM padrões geométricos!")

if __name__ == "__main__":
    main()