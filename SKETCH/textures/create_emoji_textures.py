#!/usr/bin/env python3
"""
Gerador de texturas baseadas nos emojis/caracteres solicitados
Cria padrões que representam visualmente os elementos específicos
"""

def create_emoji_texture_file(name, base_color, pattern_color, pattern_func):
    # Criar exatamente 64 pixels (192 bytes)
    pixels = []
    
    for y in range(8):
        for x in range(8):
            # Usar função específica para determinar se é padrão ou base
            if pattern_func(x, y):
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
    
    print(f"{name}: {len(pixels)} bytes criados")

def field_pattern(x, y):
    """Padrão de semicolons (؛) - pequenos pontos curvos"""
    # Criar padrão que lembra semicolons espalhados
    if (x + y * 2) % 4 == 0:
        return True
    if (x + y * 2) % 4 == 1 and y % 2 == 1:
        return True
    return False

def forest_pattern(x, y):
    """Padrão de árvores (🌳) - troncos verticais com copas"""
    # Troncos verticais
    if x % 3 == 1:
        return True
    # Copas das árvores (parte superior)
    if y < 3 and (x % 3 == 0 or x % 3 == 2):
        return True
    return False

def mountain_pattern(x, y):
    """Padrão de montanhas (⛰) - formas triangulares"""
    # Criar padrão triangular que lembra montanhas
    center_x = 4
    # Triângulo principal
    if abs(x - center_x) <= (7 - y):
        return True
    # Picos menores
    if y < 4 and (x == 1 or x == 6):
        return True
    return False

def water_pattern(x, y):
    """Padrão de água (〰) - ondas horizontais"""
    # Criar padrão ondulado horizontal
    # Onda senoidal simplificada
    wave_offset = int(2 * (x / 8.0) * 3.14159)
    wave_y = 4 + int(1.5 * (1 if wave_offset % 4 < 2 else -1))
    
    # Linha ondulada principal
    if abs(y - wave_y) <= 1:
        return True
    # Ondas secundárias
    if y == 2 or y == 6:
        if x % 4 < 2:
            return True
    return False

def main():
    print("Criando texturas baseadas nos emojis/caracteres solicitados...")
    
    # Cores que representam cada elemento
    textures = {
        "field": {
            "base": (180, 220, 180),      # Verde claro (fundo do campo)
            "pattern": (60, 120, 60),     # Verde escuro (semicolons)
            "func": field_pattern
        },
        "forest": {
            "base": (40, 80, 40),         # Verde escuro (fundo da floresta)
            "pattern": (20, 150, 20),     # Verde brilhante (árvores)
            "func": forest_pattern
        },
        "mountain": {
            "base": (120, 120, 140),      # Cinza azulado (fundo)
            "pattern": (80, 80, 100),     # Cinza escuro (montanhas)
            "func": mountain_pattern
        },
        "water": {
            "base": (100, 150, 200),      # Azul claro (água)
            "pattern": (50, 100, 160),    # Azul escuro (ondas)
            "func": water_pattern
        }
    }
    
    for name, config in textures.items():
        create_emoji_texture_file(
            name, 
            config["base"], 
            config["pattern"], 
            config["func"]
        )
    
    print("Texturas baseadas nos elementos solicitados criadas!")
    print("- Campo: Padrão de semicolons (؛)")
    print("- Floresta: Padrão de árvores (🌳)")
    print("- Montanha: Padrão de montanhas (⛰)")
    print("- Água: Padrão de ondas (〰)")

if __name__ == "__main__":
    main()