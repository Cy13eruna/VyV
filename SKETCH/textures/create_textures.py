#!/usr/bin/env python3
"""
Gerador de Texturas V&V
Cria texturas PNG baseadas em caracteres/emojis
"""

from PIL import Image, ImageDraw, ImageFont
import os

TEXTURE_SIZE = 256
BACKGROUND_COLORS = {
    'field': (200, 230, 200, 255),    # Verde claro
    'mountain': (180, 180, 200, 255), # Cinza azulado
    'forest': (50, 100, 50, 255),     # Verde escuro
    'water': (80, 150, 200, 255)      # Azul água
}

def create_field_texture():
    """Cria textura de campo com ; invertidos"""
    img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), BACKGROUND_COLORS['field'])
    draw = ImageDraw.Draw(img)
    
    # Usar fonte padrão
    try:
        font = ImageFont.truetype("arial.ttf", 16)
    except:
        font = ImageFont.load_default()
    
    # Desenhar ; invertidos bem juntinhos
    for y in range(0, TEXTURE_SIZE, 15):
        for x in range(0, TEXTURE_SIZE, 12):
            # Adicionar variação aleatória
            import random
            offset_x = random.randint(-3, 3)
            offset_y = random.randint(-3, 3)
            
            # Desenhar ; rotacionado (usando ؛ que é similar a ; invertido)
            draw.text((x + offset_x, y + offset_y), '؛', fill=(80, 150, 80, 255), font=font)
    
    img.save('SKETCH/textures/field/texture.png')
    print("✅ Textura de campo criada")

def create_mountain_texture():
    """Cria textura de montanha com ⛰"""
    img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), BACKGROUND_COLORS['mountain'])
    draw = ImageDraw.Draw(img)
    
    try:
        font = ImageFont.truetype("seguiemj.ttf", 20)  # Fonte com emojis
    except:
        try:
            font = ImageFont.truetype("arial.ttf", 20)
        except:
            font = ImageFont.load_default()
    
    # Desenhar ⛰ bem juntinhos
    for y in range(0, TEXTURE_SIZE, 25):
        for x in range(0, TEXTURE_SIZE, 25):
            import random
            offset_x = random.randint(-4, 4)
            offset_y = random.randint(-4, 4)
            
            # Usar ▲ como alternativa se ⛰ não funcionar
            draw.text((x + offset_x, y + offset_y), '▲', fill=(100, 100, 120, 255), font=font)
    
    img.save('SKETCH/textures/mountain/texture.png')
    print("✅ Textura de montanha criada")

def create_forest_texture():
    """Cria textura de floresta com 🌳"""
    img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), BACKGROUND_COLORS['forest'])
    draw = ImageDraw.Draw(img)
    
    try:
        font = ImageFont.truetype("seguiemj.ttf", 18)
    except:
        try:
            font = ImageFont.truetype("arial.ttf", 18)
        except:
            font = ImageFont.load_default()
    
    # Desenhar 🌳 bem juntinhas (usar ♠ como alternativa)
    for y in range(0, TEXTURE_SIZE, 22):
        for x in range(0, TEXTURE_SIZE, 22):
            import random
            offset_x = random.randint(-3, 3)
            offset_y = random.randint(-3, 3)
            
            draw.text((x + offset_x, y + offset_y), '♠', fill=(30, 180, 30, 255), font=font)
    
    img.save('SKETCH/textures/forest/texture.png')
    print("✅ Textura de floresta criada")

def create_water_texture():
    """Cria textura de água com 〰"""
    img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), BACKGROUND_COLORS['water'])
    draw = ImageDraw.Draw(img)
    
    try:
        font = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()
    
    # Desenhar 〰 bem juntinhas (usar ~ como alternativa)
    for y in range(0, TEXTURE_SIZE, 18):
        for x in range(0, TEXTURE_SIZE, 25):
            import random
            offset_x = random.randint(-4, 4)
            offset_y = random.randint(-4, 4)
            
            draw.text((x + offset_x, y + offset_y), '~~~', fill=(30, 100, 180, 255), font=font)
    
    img.save('SKETCH/textures/water/texture.png')
    print("✅ Textura de água criada")

def main():
    print("🎨 Criando texturas V&V...")
    
    # Criar diretórios se não existirem
    os.makedirs('SKETCH/textures/field', exist_ok=True)
    os.makedirs('SKETCH/textures/mountain', exist_ok=True)
    os.makedirs('SKETCH/textures/forest', exist_ok=True)
    os.makedirs('SKETCH/textures/water', exist_ok=True)
    
    create_field_texture()
    create_mountain_texture()
    create_forest_texture()
    create_water_texture()
    
    print("🎉 Todas as texturas foram criadas!")

if __name__ == "__main__":
    main()